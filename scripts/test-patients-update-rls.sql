-- =============================================================================
-- Teste de RLS — policy patients_update_staff (Fase de correção 2026-08-02)
--
-- Trava a decisão da migration 20260802120000: admin NÃO deve conseguir dar
-- UPDATE direto em patients (a policy consistentemente nega, tanto USING
-- quanto WITH CHECK), porque um UPDATE seguido de SELECT devolveria a linha
-- inteira do paciente — o que a migration 20260720120011
-- (restrict_admin_patient_access) proíbe por privacidade clínica. As ações
-- administrativas de verdade (ativar/inativar, excluir) passam por RPCs
-- SECURITY DEFINER que bypassam esta policy e continuam funcionando.
--
-- Roda em LOCAL ou STAGING, dentro de uma transação com ROLLBACK no fim.
--
--   docker exec -i supabase_db_<projeto> psql -U postgres -d postgres \
--     -v ON_ERROR_STOP=1 -f scripts/test-patients-update-rls.sql
-- =============================================================================

begin;

create temporary table _results(caso text, status text) on commit drop;
grant insert, select on _results to authenticated;

create or replace function pg_temp.check_case(p_caso text, p_ok boolean)
returns void language plpgsql as $$
begin
  insert into _results values (p_caso, case when p_ok then 'PASS' else 'FAIL' end);
  if not p_ok then
    raise exception 'FALHOU: %', p_caso;
  end if;
end;
$$;

-- ── Cenário: clínica com um admin, um psicólogo dono do paciente, e um
-- segundo psicólogo sem vínculo com ele ──────────────────────────────────────

do $$
declare
  v_clinic uuid;
begin
  select id into v_clinic from public.clinics limit 1;

  insert into auth.users (id, email) values
    ('eeeeeeee-0000-4000-8000-000000000001', 'admin.patients.rls@teste.local'),
    ('eeeeeeee-0000-4000-8000-000000000002', 'psi.dono.patients.rls@teste.local'),
    ('eeeeeeee-0000-4000-8000-000000000003', 'psi.outro.patients.rls@teste.local')
  on conflict (id) do nothing;

  insert into public.profiles (id, clinic_id, role, full_name, email, is_active)
  values
    ('eeeeeeee-0000-4000-8000-000000000001', v_clinic, 'platform_admin',
     'Admin Patients RLS', 'admin.patients.rls@teste.local', true),
    ('eeeeeeee-0000-4000-8000-000000000002', v_clinic, 'psychologist',
     'Psi Dono Patients RLS', 'psi.dono.patients.rls@teste.local', true),
    ('eeeeeeee-0000-4000-8000-000000000003', v_clinic, 'psychologist',
     'Psi Outro Patients RLS', 'psi.outro.patients.rls@teste.local', true)
  on conflict (id) do nothing;

  insert into public.patients (id, clinic_id, full_name, responsible_psychologist_id, is_active)
  values ('ffffffff-0000-4000-8000-000000000001', v_clinic, 'Paciente Update RLS',
          'eeeeeeee-0000-4000-8000-000000000002', true)
  on conflict (id) do nothing;
end;
$$;

-- ── 1. Admin não consegue UPDATE direto (nem para a própria ação de
-- ativar/inativar — essa passa pela RPC set_patient_active_status, que é
-- SECURITY DEFINER e não usa esta policy) ────────────────────────────────────

set local role authenticated;
set local request.jwt.claims = '{"sub":"eeeeeeee-0000-4000-8000-000000000001","role":"authenticated"}';

do $$
declare
  v_rows int;
begin
  update public.patients set is_active = false
   where id = 'ffffffff-0000-4000-8000-000000000001';
  get diagnostics v_rows = row_count;
  perform pg_temp.check_case(
    '01 admin não atualiza paciente via UPDATE direto', v_rows = 0
  );
end;
$$;

reset role;

-- ── 2. Psicólogo dono consegue atualizar o próprio paciente ─────────────────

set local role authenticated;
set local request.jwt.claims = '{"sub":"eeeeeeee-0000-4000-8000-000000000002","role":"authenticated"}';

do $$
declare
  v_rows int;
begin
  update public.patients set full_name = 'Paciente Update RLS Editado'
   where id = 'ffffffff-0000-4000-8000-000000000001';
  get diagnostics v_rows = row_count;
  perform pg_temp.check_case(
    '02 psicólogo dono atualiza o próprio paciente', v_rows = 1
  );
end;
$$;

reset role;

-- ── 3. Psicólogo sem vínculo não consegue atualizar o paciente de outro ─────

set local role authenticated;
set local request.jwt.claims = '{"sub":"eeeeeeee-0000-4000-8000-000000000003","role":"authenticated"}';

do $$
declare
  v_rows int;
begin
  update public.patients set full_name = 'Invasão'
   where id = 'ffffffff-0000-4000-8000-000000000001';
  get diagnostics v_rows = row_count;
  perform pg_temp.check_case(
    '03 psicólogo sem vínculo não atualiza paciente de outro', v_rows = 0
  );
end;
$$;

reset role;

-- ── 4. As RPCs administrativas continuam funcionando (SECURITY DEFINER,
-- não passam por esta policy) ────────────────────────────────────────────────

do $$
declare
  v_secdef boolean;
begin
  select prosecdef into v_secdef
    from pg_proc where proname = 'set_patient_active_status';
  perform pg_temp.check_case(
    '04 set_patient_active_status é SECURITY DEFINER (bypassa a policy)',
    v_secdef
  );

  select prosecdef into v_secdef
    from pg_proc where proname = 'delete_patient_as_admin';
  perform pg_temp.check_case(
    '05 delete_patient_as_admin é SECURITY DEFINER (bypassa a policy)',
    v_secdef
  );
end;
$$;

select caso, status from _results order by caso;

select
  count(*) filter (where status = 'PASS') as passou,
  count(*) filter (where status = 'FAIL') as falhou,
  case when count(*) filter (where status = 'FAIL') = 0
       then 'OK' else 'FALHAS ENCONTRADAS' end as resultado
from _results;

rollback;
