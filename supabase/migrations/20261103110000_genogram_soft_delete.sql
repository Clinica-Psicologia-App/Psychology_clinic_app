-- =============================================================================
-- Genograma: exclusão lógica de pessoas (reunião de 31/10/2026, item G1).
--
-- Até aqui `genogram_people` não tinha política de DELETE, então a exclusão
-- pelo app era barrada pelo banco sem erro. Em vez de liberar o DELETE físico
-- (que apagaria em cascata vínculos, notas clínicas e ligações com a linha do
-- tempo), a pessoa passa a ser marcada com `deleted_at` e some para todos pela
-- própria RLS. O dado fica no banco para auditoria e eventual recuperação.
--
--  * Quem exclui: o paciente, no próprio genograma, e a equipe com vínculo.
--    A pessoa "self" não pode ser excluída.
--  * Só a função `delete_genogram_person` altera `deleted_at`; UPDATE direto
--    pelo cliente não consegue marcar nem desmarcar.
--  * Relações e ligações com acontecimentos de uma pessoa excluída também
--    deixam de aparecer (nada é apagado).
--  * A auditoria existente (trg_genogram_people_audit) registra a alteração.
-- =============================================================================

BEGIN;

ALTER TABLE public.genogram_people
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz,
  ADD COLUMN IF NOT EXISTS deleted_by uuid REFERENCES public.profiles (id) ON DELETE SET NULL;

COMMENT ON COLUMN public.genogram_people.deleted_at IS
  'Exclusão lógica: pessoa removida pelo paciente ou pela equipe. Escondida pela RLS; mantida para auditoria.';

-- Pessoa excluída some para todos (RLS). Linhas ocultas também não podem ser
-- alteradas por UPDATE direto.
DROP POLICY IF EXISTS genogram_people_select ON public.genogram_people;
CREATE POLICY genogram_people_select
  ON public.genogram_people
  FOR SELECT
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.user_can_access_patient(patient_id)
    AND deleted_at IS NULL
  );

-- Relações de uma pessoa excluída ficam escondidas (a subconsulta passa pela
-- RLS de genogram_people, que já filtra as excluídas).
DROP POLICY IF EXISTS genogram_relationships_select ON public.genogram_relationships;
CREATE POLICY genogram_relationships_select
  ON public.genogram_relationships
  FOR SELECT
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.user_can_access_patient(patient_id)
    AND EXISTS (SELECT 1 FROM public.genogram_people a WHERE a.id = person_a_id)
    AND EXISTS (SELECT 1 FROM public.genogram_people b WHERE b.id = person_b_id)
  );

-- Ligações pessoa ↔ acontecimento: somem junto com a pessoa.
DROP POLICY IF EXISTS timeline_event_people_select ON public.timeline_event_people;
CREATE POLICY timeline_event_people_select
  ON public.timeline_event_people
  FOR SELECT
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.user_can_access_patient(patient_id)
    AND EXISTS (SELECT 1 FROM public.genogram_people p WHERE p.id = person_id)
  );

-- Cliente nenhum altera deleted_at/deleted_by por UPDATE direto: só a função
-- abaixo (SECURITY DEFINER, executa como dono da função).
CREATE OR REPLACE FUNCTION public.guard_genogram_person_deleted_at()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
  IF current_user IN ('authenticated', 'anon') THEN
    IF TG_OP = 'INSERT' THEN
      NEW.deleted_at := NULL;
      NEW.deleted_by := NULL;
    ELSE
      NEW.deleted_at := OLD.deleted_at;
      NEW.deleted_by := OLD.deleted_by;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_genogram_people_guard_deleted_at ON public.genogram_people;
CREATE TRIGGER trg_genogram_people_guard_deleted_at
  BEFORE INSERT OR UPDATE ON public.genogram_people
  FOR EACH ROW
  EXECUTE FUNCTION public.guard_genogram_person_deleted_at();

-- Exclusão lógica de uma pessoa do genograma.
CREATE OR REPLACE FUNCTION public.delete_genogram_person(p_person_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_person public.genogram_people%ROWTYPE;
BEGIN
  SELECT * INTO v_person
  FROM public.genogram_people
  WHERE id = p_person_id AND deleted_at IS NULL;

  IF NOT FOUND
     OR v_person.clinic_id IS DISTINCT FROM public.current_clinic_id()
     OR NOT public.user_can_access_patient(v_person.patient_id) THEN
    RAISE EXCEPTION 'Pessoa não encontrada' USING ERRCODE = 'P0002';
  END IF;

  IF v_person.relationship_to_patient = 'self' THEN
    RAISE EXCEPTION 'A pessoa do próprio paciente não pode ser excluída'
      USING ERRCODE = '42501';
  END IF;

  UPDATE public.genogram_people
  SET deleted_at = timezone('utc', now()),
      deleted_by = auth.uid()
  WHERE id = p_person_id;
END;
$$;

REVOKE ALL ON FUNCTION public.delete_genogram_person(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_genogram_person(uuid) TO authenticated;

COMMIT;
