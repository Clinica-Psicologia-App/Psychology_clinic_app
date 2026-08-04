-- Indicação de obras da Biblioteca (psicólogo → paciente) e acesso do paciente.
-- O paciente só vê obras que lhe foram indicadas; a ficha clínica (camada do
-- psicólogo) segue restrita ao staff pela política do catálogo.

CREATE TABLE IF NOT EXISTS public.library_indications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  work_id UUID NOT NULL REFERENCES public.library_works(id) ON DELETE CASCADE,
  psychologist_id UUID NOT NULL REFERENCES public.profiles(id),
  objective TEXT,
  scope TEXT,                       -- filme completo | temporada | episódio(s)
  status TEXT NOT NULL DEFAULT 'Indicado',
  indicated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  watched_at TIMESTAMPTZ,
  activation_0_10 INT CHECK (activation_0_10 BETWEEN 0 AND 10),
  share_responses BOOLEAN NOT NULL DEFAULT false,
  patient_responses JSONB,          -- respostas do "depois de assistir"
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS library_indications_patient_idx
  ON public.library_indications (patient_id);
CREATE UNIQUE INDEX IF NOT EXISTS library_indications_unique
  ON public.library_indications (patient_id, work_id);

ALTER TABLE public.library_indications ENABLE ROW LEVEL SECURITY;

-- Staff que pode acessar o paciente gerencia as indicações dele.
DROP POLICY IF EXISTS library_indications_staff ON public.library_indications;
CREATE POLICY library_indications_staff
  ON public.library_indications FOR ALL TO authenticated
  USING (
    public.current_role()::TEXT <> 'patient'
    AND public.user_can_access_patient(patient_id)
  )
  WITH CHECK (
    public.current_role()::TEXT <> 'patient'
    AND public.user_can_access_patient(patient_id)
  );

-- Paciente lê as próprias indicações.
DROP POLICY IF EXISTS library_indications_patient_select
  ON public.library_indications;
CREATE POLICY library_indications_patient_select
  ON public.library_indications FOR SELECT TO authenticated
  USING (
    patient_id IN (
      SELECT id FROM public.patients WHERE profile_id = auth.uid()
    )
  );

-- Paciente atualiza as próprias (progresso, ativação, respostas, compartilhar).
DROP POLICY IF EXISTS library_indications_patient_update
  ON public.library_indications;
CREATE POLICY library_indications_patient_update
  ON public.library_indications FOR UPDATE TO authenticated
  USING (
    patient_id IN (
      SELECT id FROM public.patients WHERE profile_id = auth.uid()
    )
  )
  WITH CHECK (
    patient_id IN (
      SELECT id FROM public.patients WHERE profile_id = auth.uid()
    )
  );

-- O paciente NÃO recebe acesso direto à tabela do catálogo (evita ler a camada
-- do psicólogo e nomes de esquema — RLS é por linha, não por coluna). O acesso
-- do paciente é por uma RPC que devolve apenas os campos seguros.
CREATE OR REPLACE FUNCTION public.get_my_library()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_patient UUID;
  v_result JSONB;
BEGIN
  SELECT id INTO v_patient FROM public.patients WHERE profile_id = auth.uid();
  IF v_patient IS NULL THEN
    RETURN '[]'::jsonb;
  END IF;

  SELECT COALESCE(jsonb_agg(item ORDER BY item->>'indicated_at' DESC), '[]'::jsonb)
  INTO v_result
  FROM (
    SELECT jsonb_build_object(
      'indication_id', li.id,
      'status', li.status,
      'objective', li.objective,
      'scope', li.scope,
      'indicated_at', li.indicated_at,
      'watched_at', li.watched_at,
      'activation_0_10', li.activation_0_10,
      'share_responses', li.share_responses,
      'patient_responses', li.patient_responses,
      'work', jsonb_build_object(
        'id', w.id,
        'display_title', w.display_title,
        'work_type', w.work_type,
        'is_animation', w.is_animation,
        'year', w.year,
        'genres', w.genres,
        'duration', w.duration,
        'seasons', w.seasons,
        'rating', w.rating,
        'synopsis', w.synopsis,
        'cover_url', w.cover_url,
        'intensity', w.intensity,
        'patient_layer', w.patient_layer
      )
    ) AS item
    FROM public.library_indications li
    JOIN public.library_works w ON w.id = li.work_id
    WHERE li.patient_id = v_patient
      AND w.is_published
  ) sub;

  RETURN v_result;
END;
$$;

REVOKE ALL ON FUNCTION public.get_my_library() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_my_library() TO authenticated;

-- RPC: psicólogo indica uma obra ao paciente.
CREATE OR REPLACE FUNCTION public.indicate_library_work(
  p_patient_id UUID,
  p_work_id UUID,
  p_objective TEXT DEFAULT NULL,
  p_scope TEXT DEFAULT NULL
)
RETURNS public.library_indications
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row public.library_indications%ROWTYPE;
  v_clinic UUID;
BEGIN
  IF public.current_role()::TEXT = 'patient' THEN
    RAISE EXCEPTION USING ERRCODE = '42501',
      MESSAGE = 'Apenas o profissional pode indicar obras';
  END IF;
  IF NOT public.user_can_access_patient(p_patient_id) THEN
    RAISE EXCEPTION USING ERRCODE = '42501',
      MESSAGE = 'Sem acesso a este paciente';
  END IF;

  SELECT clinic_id INTO v_clinic FROM public.patients WHERE id = p_patient_id;

  INSERT INTO public.library_indications (
    clinic_id, patient_id, work_id, psychologist_id, objective, scope
  )
  VALUES (v_clinic, p_patient_id, p_work_id, auth.uid(), p_objective, p_scope)
  ON CONFLICT (patient_id, work_id) DO UPDATE SET
    objective = COALESCE(EXCLUDED.objective, library_indications.objective),
    scope = COALESCE(EXCLUDED.scope, library_indications.scope),
    updated_at = timezone('utc', now())
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

REVOKE ALL ON FUNCTION public.indicate_library_work(UUID, UUID, TEXT, TEXT)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.indicate_library_work(UUID, UUID, TEXT, TEXT)
  TO authenticated;
