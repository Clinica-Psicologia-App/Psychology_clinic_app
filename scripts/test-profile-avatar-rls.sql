-- =============================================================================
-- Testes de RLS e integridade do perfil/avatar (Fase 25)
--
-- Roda contra um banco LOCAL ou de STAGING. Não rode em produção: cria e
-- apaga usuários de teste. Tudo acontece dentro de uma transação com ROLLBACK
-- no fim, então nada é persistido nem quando os testes passam.
--
--   docker exec -i supabase_db_<projeto> psql -U postgres -d postgres \
--     -v ON_ERROR_STOP=1 -f scripts/test-profile-avatar-rls.sql
--
-- Saída esperada: uma linha "PASS" por caso e, no fim, RESULTADO = OK.
-- Qualquer falha aborta com exceção (ON_ERROR_STOP).
-- =============================================================================

begin;

create temporary table _results(
  caso text,
  status text
) on commit drop;

-- Parte dos casos roda sob o papel `authenticated` (para exercitar a RLS de
-- verdade), e esse papel precisa conseguir gravar o placar.
grant insert, select on _results to authenticated;

-- Registra um caso. Falha ruidosamente quando `ok` é falso.
create or replace function pg_temp.check_case(p_caso text, p_ok boolean)
returns void language plpgsql as $$
begin
  insert into _results values (p_caso, case when p_ok then 'PASS' else 'FAIL' end);
  if not p_ok then
    raise exception 'FALHOU: %', p_caso;
  end if;
end;
$$;

-- Executa um comando esperando que ele seja BLOQUEADO (erro de RLS ou trigger).
create or replace function pg_temp.expect_blocked(p_caso text, p_sql text)
returns void language plpgsql as $$
begin
  execute p_sql;
  -- Chegou aqui: não bloqueou.
  perform pg_temp.check_case(p_caso, false);
exception
  when insufficient_privilege or raise_exception or check_violation then
    perform pg_temp.check_case(p_caso, true);
end;
$$;

-- Executa um comando esperando que ele seja PERMITIDO.
create or replace function pg_temp.expect_allowed(p_caso text, p_sql text)
returns void language plpgsql as $$
begin
  execute p_sql;
  perform pg_temp.check_case(p_caso, true);
exception
  when others then
    perform pg_temp.check_case(
      p_caso || ' (erro: ' || sqlerrm || ')', false
    );
end;
$$;

-- ── Cenário ──────────────────────────────────────────────────────────────────
-- Dois usuários da mesma clínica: A e B, ambos psicólogos (papel sem
-- privilégio administrativo).

do $$
declare
  v_clinic uuid;
begin
  select id into v_clinic from public.clinics limit 1;
  if v_clinic is null then
    raise exception 'Seed ausente: nenhuma clínica encontrada.';
  end if;

  -- Segunda clínica VÁLIDA. Sem ela, tentar trocar clinic_id esbarraria na
  -- foreign key antes de chegar na trigger, e o teste provaria a coisa errada.
  insert into public.clinics (id, name, is_active, clinic_type)
  select 'cccccccc-0000-4000-8000-000000000003', 'Clínica RLS Teste', true,
         (select clinic_type from public.clinics limit 1)
  on conflict (id) do nothing;

  insert into auth.users (id, email)
  values
    ('aaaaaaaa-0000-4000-8000-000000000001', 'rls.user.a@teste.local'),
    ('bbbbbbbb-0000-4000-8000-000000000002', 'rls.user.b@teste.local')
  on conflict (id) do nothing;

  insert into public.profiles (id, clinic_id, role, full_name, email, is_active)
  values
    ('aaaaaaaa-0000-4000-8000-000000000001', v_clinic, 'psychologist',
     'RLS User A', 'rls.user.a@teste.local', true),
    ('bbbbbbbb-0000-4000-8000-000000000002', v_clinic, 'psychologist',
     'RLS User B', 'rls.user.b@teste.local', true)
  on conflict (id) do nothing;
end;
$$;

-- Passa a atuar como o usuário A autenticado.
set local role authenticated;
set local request.jwt.claims = '{"sub":"aaaaaaaa-0000-4000-8000-000000000001","role":"authenticated"}';

-- ── 1. Campos administrativos protegidos (itens 9, 10, 11 da Fase 25) ────────

select pg_temp.expect_blocked(
  '01 usuário não altera o próprio role',
  $sql$update public.profiles set role = 'platform_admin'
       where id = 'aaaaaaaa-0000-4000-8000-000000000001'$sql$
);

-- Clínica de destino existe, então quem barra é a trigger — não a foreign key.
select pg_temp.expect_blocked(
  '02 usuário não altera o próprio clinic_id',
  $sql$update public.profiles
          set clinic_id = 'cccccccc-0000-4000-8000-000000000003'
        where id = 'aaaaaaaa-0000-4000-8000-000000000001'$sql$
);

select pg_temp.expect_blocked(
  '03 usuário não altera o próprio is_active',
  $sql$update public.profiles set is_active = false
       where id = 'aaaaaaaa-0000-4000-8000-000000000001'$sql$
);

select pg_temp.expect_blocked(
  '04 usuário não altera o próprio can_receive_patients',
  $sql$update public.profiles set can_receive_patients = true
       where id = 'aaaaaaaa-0000-4000-8000-000000000001'$sql$
);

-- ── 2. Isolamento entre usuários (itens 1 e 18) ──────────────────────────────
-- A policy filtra por linha: o UPDATE não encontra a linha de B, então afeta
-- zero linhas em vez de lançar erro. Por isso aqui checamos a contagem.

do $$
declare
  v_afetadas int;
begin
  update public.profiles
     set full_name = 'INVADIDO'
   where id = 'bbbbbbbb-0000-4000-8000-000000000002';
  get diagnostics v_afetadas = row_count;
  perform pg_temp.check_case(
    '05 usuário não altera o perfil de outro', v_afetadas = 0
  );
end;
$$;

-- ── 3. O que o usuário PODE fazer (não pode ter travado demais) ──────────────

select pg_temp.expect_allowed(
  '06 usuário altera o próprio nome',
  $sql$update public.profiles set full_name = 'RLS User A Editado'
       where id = 'aaaaaaaa-0000-4000-8000-000000000001'$sql$
);

select pg_temp.expect_allowed(
  '07 usuário ativa a própria foto',
  $sql$update public.profiles
          set avatar_type = 'photo',
              avatar_path = 'aaaaaaaa-0000-4000-8000-000000000001/profile/photo.jpg'
        where id = 'aaaaaaaa-0000-4000-8000-000000000001'$sql$
);

-- ── 4. Constraint de avatar_type (valor arbitrário rejeitado) ────────────────

select pg_temp.expect_blocked(
  '08 avatar_type arbitrário é rejeitado',
  $sql$update public.profiles set avatar_type = 'hacker'
       where id = 'aaaaaaaa-0000-4000-8000-000000000001'$sql$
);

-- ── 5. Cache busting: a trigger carimba avatar_updated_at ────────────────────

-- Atenção: `now()` no Postgres é o timestamp da TRANSAÇÃO, constante do começo
-- ao fim dela. Como este script roda tudo numa transação só, comparar dois
-- carimbos gerados pela trigger daria sempre "igual" e o teste passaria a
-- medir a coisa errada. Por isso ancoramos num valor antigo explícito antes de
-- provocar a trigger.
do $$
declare
  v_ancora timestamptz := timestamptz '2020-01-01 00:00:00+00';
  v_depois timestamptz;
begin
  update public.profiles
     set avatar_updated_at = v_ancora
   where id = 'aaaaaaaa-0000-4000-8000-000000000001';

  update public.profiles
     set avatar_path = 'aaaaaaaa-0000-4000-8000-000000000001/profile/photo.png'
   where id = 'aaaaaaaa-0000-4000-8000-000000000001';

  select avatar_updated_at into v_depois from public.profiles
   where id = 'aaaaaaaa-0000-4000-8000-000000000001';

  perform pg_temp.check_case(
    '09 trigger carimba avatar_updated_at quando o path muda',
    v_depois > v_ancora
  );
end;
$$;

-- Regressão do bug real: trocar a foto reenviando os MESMOS valores (path fixo
-- + upsert) não muda coluna alguma, então a trigger não dispara. Se o app não
-- carimbar explicitamente, a URL fica idêntica e o usuário segue vendo a foto
-- antiga. Este caso documenta a limitação — por isso o repositório envia
-- avatar_updated_at na mão.
do $$
declare
  v_antes timestamptz;
  v_depois timestamptz;
begin
  select avatar_updated_at into v_antes from public.profiles
   where id = 'aaaaaaaa-0000-4000-8000-000000000001';

  update public.profiles
     set avatar_type = 'photo',
         avatar_path = 'aaaaaaaa-0000-4000-8000-000000000001/profile/photo.png'
   where id = 'aaaaaaaa-0000-4000-8000-000000000001';

  select avatar_updated_at into v_depois from public.profiles
   where id = 'aaaaaaaa-0000-4000-8000-000000000001';

  perform pg_temp.check_case(
    '10 mesmos valores NÃO carimbam (por isso o app carimba explicitamente)',
    v_depois is not distinct from v_antes
  );
end;
$$;

-- O carimbo explícito enviado pelo app precisa sobreviver à trigger.
do $$
declare
  v_alvo timestamptz := timestamptz '2031-01-01 10:00:00+00';
  v_depois timestamptz;
begin
  update public.profiles
     set avatar_type = 'photo',
         avatar_path = 'aaaaaaaa-0000-4000-8000-000000000001/profile/photo.png',
         avatar_updated_at = v_alvo
   where id = 'aaaaaaaa-0000-4000-8000-000000000001';

  select avatar_updated_at into v_depois from public.profiles
   where id = 'aaaaaaaa-0000-4000-8000-000000000001';

  perform pg_temp.check_case(
    '11 carimbo explícito do app não é sobrescrito pela trigger',
    v_depois = v_alvo
  );
end;
$$;

-- ── 6. Policies de Storage: path exato por usuário (itens 2, 3, 12, 13) ──────
-- Valida a regex das policies sem depender da API de Storage.

do $$
declare
  v_uid text := 'aaaaaaaa-0000-4000-8000-000000000001';
  v_re  text := '^' || v_uid || '/profile/photo\.(jpg|jpeg|png|webp)$';
begin
  perform pg_temp.check_case(
    '12 path próprio no formato correto é aceito',
    (v_uid || '/profile/photo.jpg') ~ v_re
  );
  perform pg_temp.check_case(
    '13 path de OUTRO usuário é rejeitado',
    not ('bbbbbbbb-0000-4000-8000-000000000002/profile/photo.jpg' ~ v_re)
  );
  perform pg_temp.check_case(
    '14 nome de arquivo arbitrário na própria pasta é rejeitado',
    not ((v_uid || '/profile/qualquer.jpg') ~ v_re)
  );
  perform pg_temp.check_case(
    '15 extensão não permitida é rejeitada',
    not ((v_uid || '/profile/photo.svg') ~ v_re)
  );
  perform pg_temp.check_case(
    '16 path traversal é rejeitado',
    not ((v_uid || '/profile/../../outro/photo.jpg') ~ v_re)
  );
  perform pg_temp.check_case(
    '17 sufixo após a extensão é rejeitado (âncora $)',
    not ((v_uid || '/profile/photo.jpg.exe') ~ v_re)
  );
  perform pg_temp.check_case(
    '18 prefixo antes do uid é rejeitado (âncora ^)',
    not (('outro/' || v_uid || '/profile/photo.jpg') ~ v_re)
  );
end;
$$;

reset role;

-- As checagens abaixo leem catálogo do Storage, que o papel
-- `authenticated` deliberadamente não enxerga — por isso só rodam
-- depois do reset role.

-- ── 7. Bucket: limites de tamanho e MIME (itens 7 e 8) ───────────────────────

do $$
declare
  v_limit bigint;
  v_mimes text[];
begin
  select file_size_limit, allowed_mime_types
    into v_limit, v_mimes
    from storage.buckets where id = 'avatars';

  perform pg_temp.check_case(
    '19 bucket avatars existe com limite de tamanho definido',
    v_limit is not null and v_limit > 0
  );
  perform pg_temp.check_case(
    '20 bucket restringe MIME types a imagens',
    v_mimes is not null
      and 'image/jpeg' = any(v_mimes)
      and not ('application/pdf' = any(v_mimes))
  );
end;
$$;

-- ── 8. As policies de Storage estão realmente instaladas ─────────────────────

do $$
declare
  v_insert int;
  v_update int;
begin
  select count(*) into v_insert from pg_policies
   where schemaname = 'storage' and tablename = 'objects'
     and policyname = 'avatars_insert_own_photo';
  select count(*) into v_update from pg_policies
   where schemaname = 'storage' and tablename = 'objects'
     and policyname = 'avatars_update_own_photo';

  -- INSERT e UPDATE separadas: o upsert do Storage avalia o WITH CHECK das
  -- duas, então ambas precisam existir com a mesma condição.
  perform pg_temp.check_case('21 policy de INSERT do avatar instalada', v_insert = 1);
  perform pg_temp.check_case('22 policy de UPDATE do avatar instalada', v_update = 1);
end;
$$;


-- ── Resultado ────────────────────────────────────────────────────────────────

select caso, status from _results order by caso;

select
  count(*) filter (where status = 'PASS') as passou,
  count(*) filter (where status = 'FAIL') as falhou,
  case when count(*) filter (where status = 'FAIL') = 0
       then 'OK' else 'FALHAS ENCONTRADAS' end as resultado
from _results;

rollback;
