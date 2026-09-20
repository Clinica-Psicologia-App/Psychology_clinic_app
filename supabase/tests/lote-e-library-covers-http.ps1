#requires -Version 7.0
# Local Auth + Storage. Checks bytes/existence, not just HTTP status. Cleans finally.
$ErrorActionPreference='Stop'
$config=supabase status -o json | ConvertFrom-Json
if($LASTEXITCODE -ne 0){throw 'Local Supabase unavailable'}
$base=$config.API_URL.TrimEnd('/')
if(([uri]$base).Host -notin @('127.0.0.1','localhost','::1')){throw 'Local only'}
$anon=$config.ANON_KEY; $service=$config.SERVICE_ROLE_KEY
$prefix='lote-e-http-'+[guid]::NewGuid().ToString('N')
$password='TestAa1!'+[guid]::NewGuid().ToString('N')
$ids=[Collections.Generic.List[string]]::new()
$objects=[Collections.Generic.List[string]]::new()
$avatars=[Collections.Generic.List[string]]::new()
$bytesA=[Convert]::FromBase64String('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/l9sAAAAASUVORK5CYII=')
# Distinct byte payloads; no external image/network dependency.
$bytesB=[byte[]]($bytesA+@(1)); $bytesC=[byte[]]($bytesA+@(2))
$script:passed=0
function Check($ok,$label){if(!$ok){throw "FAIL: $label"};$script:passed++;Write-Host "PASS: $label"}
function Request($method,$path,$token,$body=$null,[byte[]]$bytes=$null,[bool]$upsert=$false){
 $key=if($token -eq $service){$service}else{$anon}
 $headers=@{apikey=$key;Authorization="Bearer $token";'Cache-Control'='no-cache'}
 if($upsert){$headers['x-upsert']='true'}
 $p=@{Method=$method;Uri="$base$path";Headers=$headers;SkipHttpErrorCheck=$true}
 if($null -ne $bytes){$p.ContentType='image/png';$p.Body=$bytes}
 elseif($null -ne $body){$p.ContentType='application/json';$p.Body=$body|ConvertTo-Json -Depth 8 -Compress}
 $r=Invoke-WebRequest @p
 $data=$null
 if($r.Headers.'Content-Type' -match 'json' -and $r.Content){$data=$r.Content|ConvertFrom-Json -NoEnumerate}
 return @{Status=[int]$r.StatusCode;Data=$data;Bytes=[Convert]::ToBase64String($r.RawContentStream.ToArray())}
}
function List-Object($bucket,$name,$token){
 $split=$name.LastIndexOf('/')
 $r=Request POST "/storage/v1/object/list/$bucket" $token @{prefix=$name.Substring(0,$split+1);search=$name.Substring($split+1);limit=100}
 if($r.Status -ne 200){throw 'List failed'}
 return @($r.Data | Where-Object {$_.name -eq $name.Substring($split+1)})
}
function Read-Bytes($bucket,$name){
 $r=Request GET "/storage/v1/object/authenticated/$bucket/$name" $service
 if($r.Status -ne 200){throw 'Readback failed'}
 return $r.Bytes
}
function Probe($label,$token,$allowed,$bucket='library-covers'){
 $name="$prefix/$label-existing.png"; $fresh="$prefix/$label-new.png"
 if($bucket -eq 'library-covers'){$objects.Add($name);$objects.Add($fresh)}else{$avatars.Add($name);$avatars.Add($fresh)}
 $seed=Request POST "/storage/v1/object/$bucket/$name" $service $null $bytesA
 if($seed.Status -ne 200){throw 'Object fixture failed'}
 $public=Request GET "/storage/v1/object/public/$bucket/$name" $anon
 Check ($public.Status -eq 200 -and $public.Bytes -eq [Convert]::ToBase64String($bytesA)) "$label public URL"
 $listed=@(List-Object $bucket $name $token)
 # Avatars already has public metadata SELECT; E must not grant foreign writes.
 Check ($listed.Count -eq $(if($allowed -or $bucket -eq 'avatars'){1}else{0})) "$label SELECT metadata"
 $insert=Request POST "/storage/v1/object/$bucket/$fresh" $token $null $bytesA
 Check ($(if($allowed){$insert.Status -eq 200}else{$insert.Status -ge 400 -and $insert.Data.statusCode -eq '403'})) "$label INSERT status"
 Check (@(List-Object $bucket $fresh $service).Count -eq $(if($allowed){1}else{0})) "$label INSERT effect"
 $update=Request PUT "/storage/v1/object/$bucket/$name" $token $null $bytesB
 Check ($(if($allowed){$update.Status -eq 200}else{$update.Status -ge 400})) "$label UPDATE status"
 $expected=if($allowed){$bytesB}else{$bytesA}
 Check ((Read-Bytes $bucket $name) -eq [Convert]::ToBase64String($expected)) "$label UPDATE bytes"
 $overwrite=Request POST "/storage/v1/object/$bucket/$name" $token $null $bytesC $true
 Check ($(if($allowed){$overwrite.Status -eq 200}else{$overwrite.Status -ge 400})) "$label upsert status"
 $expected=if($allowed){$bytesC}else{$bytesA}
 Check ((Read-Bytes $bucket $name) -eq [Convert]::ToBase64String($expected)) "$label upsert bytes"
 $delete=Request DELETE "/storage/v1/object/$bucket" $token @{prefixes=@($name)}
 Check ($delete.Status -eq 200) "$label DELETE request"
 Check (@(List-Object $bucket $name $service).Count -eq $(if($allowed){0}else{1})) "$label DELETE effect"
 if(!$allowed){Check ((Read-Bytes $bucket $name) -eq [Convert]::ToBase64String($bytesA)) "$label forbidden object intact"}
}
function Add-Profile($user,$role,$active){
 $p=Request POST '/rest/v1/profiles' $service @{id=$user.Id;email=$user.Email;full_name='E fixture';role=$role;clinic_id='11111111-1111-1111-1111-111111111101';is_active=$active}
 if($p.Status -ne 201){throw 'Profile fixture failed'}
}
function New-Identity($label,$role,$active,$claim){
 $email="$prefix-$label@example.test"
 $body=@{email=$email;password=$password;email_confirm=$true}
 if($claim){$body.app_metadata=@{role='platform_admin'}}
 $r=Request POST '/auth/v1/admin/users' $service $body
 if(!$r.Data.id){throw 'Auth fixture failed'}
 $ids.Add($r.Data.id)
 $user=@{Id=$r.Data.id;Email=$email}
 if($role){Add-Profile $user $role $active}
 $user.Access=Login $user
 return $user
}
function Login($user){
 $r=Request POST '/auth/v1/token?grant_type=password' $anon @{email=$user.Email;password=$password}
 if(!$r.Data.access_token){throw 'Login failed'}
 $user.Refresh=$r.Data.refresh_token;return $r.Data.access_token
}
function Refresh($user){
 $r=Request POST '/auth/v1/token?grant_type=refresh_token' $anon @{refresh_token=$user.Refresh}
 if(!$r.Data.access_token){throw 'Refresh failed'}
 $user.Refresh=$r.Data.refresh_token;return $r.Data.access_token
}
function Patch-Profile($user,$values){
 $r=Request PATCH "/rest/v1/profiles?id=eq.$($user.Id)" $service $values
 if($r.Status -ne 204){throw 'Profile change failed'}
}
function Claim-Role($token){
 $part=$token.Split('.')[1].Replace('-','+').Replace('_','/')
 $part=$part.PadRight($part.Length+(4-$part.Length%4)%4,'=')
 $claims=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($part))|ConvertFrom-Json
 return $claims.app_metadata.role
}
try{
 Probe 'anon' $anon $false
 Probe 'service' $service $true
 foreach($role in @('patient','psychologist','platform_admin')){
  $user=New-Identity $role $role $true $false
  Probe "$role-no-claim" $user.Access ($role -eq 'platform_admin')
  if($role -eq 'platform_admin'){Probe 'other-bucket' $user.Access $false 'avatars'}
 }
 $missing=New-Identity 'missing' $null $true $false
 Probe 'missing-no-claim' $missing.Access $false
 $claimed=New-Identity 'claimed-missing' $null $true $true
 Probe 'missing-claim' $claimed.Access $false
 $user=New-Identity 'admin-claim' 'platform_admin' $true $true
 Check ((Claim-Role $user.Access) -eq 'platform_admin') 'trusted Auth emitted administrative claim'
 Probe 'active-claim' $user.Access $true
 Patch-Profile $user @{is_active=$false}
 Probe 'inactive-old' $user.Access $false
 $token=Refresh $user
 Check ((Claim-Role $token) -eq 'platform_admin') 'inactive refresh retains stale authority claim'
 Probe 'inactive-refresh' $token $false
 Probe 'inactive-login' (Login $user) $false
 $r=Request DELETE "/rest/v1/profiles?id=eq.$($user.Id)" $service
 if($r.Status -ne 204){throw 'Profile delete failed'}
 Probe 'removed-old' $user.Access $false
 $token=Refresh $user
 Check ((Claim-Role $token) -eq 'platform_admin') 'removed refresh retains claim'
 Probe 'removed-refresh' $token $false
 Probe 'removed-login' (Login $user) $false
 Add-Profile $user 'platform_admin' $true
 Patch-Profile $user @{role='patient'}
 Probe 'demoted-old' $user.Access $false
 Patch-Profile $user @{is_active=$false}
 Probe 'demoted-inactive' $user.Access $false
 # Only this disposable identity: prove absence of claim does not block reactivation.
 $r=Request PUT "/auth/v1/admin/users/$($user.Id)" $service @{app_metadata=@{role=$null}}
 if($r.Status -ne 200){throw 'Fixture metadata clear failed'}
 Patch-Profile $user @{role='platform_admin';is_active=$true}
 $token=Refresh $user
 Check ([string]::IsNullOrEmpty((Claim-Role $token))) 'reactivated token has no administrative claim'
 Probe 'reactivated-no-claim' $token $true
 Write-Host "Lote E HTTP passed: $script:passed checks"
}finally{
 $failed=@()
 foreach($bucket in @('library-covers','avatars')){
  $names=if($bucket -eq 'library-covers'){@($objects)}else{@($avatars)}
  if($names.Count){try{$r=Request DELETE "/storage/v1/object/$bucket" $service @{prefixes=$names};if($r.Status -ne 200){$failed+=$bucket}}catch{$failed+=$bucket}}
 }
 foreach($id in $ids){try{$r=Request DELETE "/auth/v1/admin/users/$id" $service;if($r.Status -ne 200){$failed+=$id}}catch{$failed+=$id}}
 foreach($bucket in @('library-covers','avatars')){
  $left=Request POST "/storage/v1/object/list/$bucket" $service @{prefix="$prefix/";limit=1000}
  if($left.Status -ne 200 -or @($left.Data).Count){$failed+="remaining objects in $bucket"}
 }
 if($failed.Count){throw "Cleanup failed: $($failed -join ', ')"}
 Write-Host "Cleaned $($ids.Count) identities and all objects in both buckets"
}
