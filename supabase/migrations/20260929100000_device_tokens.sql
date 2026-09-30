-- Tokens de dispositivo para push notifications (FCM).
-- Cada usuário pode ter múltiplos tokens (dispositivos / reinstalações).
create table if not exists public.device_tokens (
  id          uuid primary key default gen_random_uuid(),
  profile_id  uuid not null references public.profiles(id) on delete cascade,
  token       text not null,
  platform    text not null check (platform in ('android', 'ios', 'web')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (profile_id, token)
);

alter table public.device_tokens enable row level security;

do $$ begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename  = 'device_tokens'
      and policyname = 'device_tokens_owner_all'
  ) then
    execute $p$
      create policy "device_tokens_owner_all" on public.device_tokens
        for all
        using  (profile_id = auth.uid())
        with check (profile_id = auth.uid())
    $p$;
  end if;
end $$;

-- Mantém updated_at atualizado automaticamente.
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists device_tokens_set_updated_at on public.device_tokens;
create trigger device_tokens_set_updated_at
  before update on public.device_tokens
  for each row execute function public.set_updated_at();
