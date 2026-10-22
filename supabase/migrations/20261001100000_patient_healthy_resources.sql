-- Recursos Saudáveis: recursos positivos já identificados no paciente pelo terapeuta.
-- Uma linha por (paciente, profissional). Atualizada in-place (upsert).

create table if not exists public.patient_healthy_resources (
  id                  uuid primary key default gen_random_uuid(),
  patient_id          uuid not null references public.patients(id) on delete cascade,
  psychologist_id     uuid not null references public.profiles(id) on delete cascade,
  selected_predefined text[] not null default '{}',
  custom_resources    text[] not null default '{}',
  observations        text,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),

  unique (patient_id, psychologist_id)
);

-- RLS: psicólogo só acessa os registros dos seus próprios pacientes.
alter table public.patient_healthy_resources enable row level security;

create policy "staff_select_own" on public.patient_healthy_resources
  for select using (
    psychologist_id = auth.uid()
    and user_can_access_patient(patient_id)
  );

create policy "staff_insert_own" on public.patient_healthy_resources
  for insert with check (
    psychologist_id = auth.uid()
    and user_can_access_patient(patient_id)
  );

create policy "staff_update_own" on public.patient_healthy_resources
  for update using (
    psychologist_id = auth.uid()
  );

create policy "staff_delete_own" on public.patient_healthy_resources
  for delete using (
    psychologist_id = auth.uid()
  );

-- Atualiza updated_at automaticamente.
create or replace function public.touch_healthy_resources()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger trg_touch_healthy_resources
  before update on public.patient_healthy_resources
  for each row execute function public.touch_healthy_resources();
