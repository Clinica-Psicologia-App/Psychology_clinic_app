-- =============================================================================
-- Catálogo de referência — Necessidades Emocionais Centrais (Terapia do Esquema)
-- Alimenta o checklist "Necessidades emocionais percebidas" do Bloco 4.
-- Padrão de catálogo global igual a schema_domains/schemas (clinic_id NULL = global).
-- =============================================================================

CREATE TABLE public.emotional_needs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id   UUID REFERENCES public.clinics (id) ON DELETE CASCADE,
  code        TEXT NOT NULL,
  name        TEXT NOT NULL,
  description TEXT,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  is_active   BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT emotional_needs_code_not_empty CHECK (char_length(trim(code)) > 0),
  CONSTRAINT emotional_needs_name_not_empty CHECK (char_length(trim(name)) > 0),
  CONSTRAINT emotional_needs_sort_order_non_negative CHECK (sort_order >= 0)
);

COMMENT ON TABLE public.emotional_needs IS
  'Catálogo das necessidades emocionais centrais (Young). clinic_id NULL = catálogo global; UUID = extensão da clínica.';

CREATE INDEX idx_emotional_needs_clinic_id ON public.emotional_needs (clinic_id);
CREATE INDEX idx_emotional_needs_is_active ON public.emotional_needs (is_active);
CREATE INDEX idx_emotional_needs_sort_order ON public.emotional_needs (sort_order);

CREATE UNIQUE INDEX idx_emotional_needs_code_global
  ON public.emotional_needs (lower(code))
  WHERE clinic_id IS NULL;

CREATE UNIQUE INDEX idx_emotional_needs_code_clinic
  ON public.emotional_needs (clinic_id, lower(code))
  WHERE clinic_id IS NOT NULL;

CREATE TRIGGER trg_emotional_needs_set_updated_at
  BEFORE UPDATE ON public.emotional_needs
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- -----------------------------------------------------------------------------
-- RLS — leitura por qualquer usuário autenticado da clínica; gestão só admin.
-- -----------------------------------------------------------------------------

ALTER TABLE public.emotional_needs ENABLE ROW LEVEL SECURITY;

CREATE POLICY emotional_needs_select
  ON public.emotional_needs
  FOR SELECT
  TO authenticated
  USING (public.current_clinic_id() IS NOT NULL);

CREATE POLICY emotional_needs_insert
  ON public.emotional_needs
  FOR INSERT
  TO authenticated
  WITH CHECK (public.current_role() = 'admin');

CREATE POLICY emotional_needs_update
  ON public.emotional_needs
  FOR UPDATE
  TO authenticated
  USING (public.current_role() = 'admin')
  WITH CHECK (public.current_role() = 'admin');

CREATE POLICY emotional_needs_delete
  ON public.emotional_needs
  FOR DELETE
  TO authenticated
  USING (public.current_role() = 'admin');

-- -----------------------------------------------------------------------------
-- Seed — 5 necessidades emocionais centrais de Young (catálogo global)
-- -----------------------------------------------------------------------------

INSERT INTO public.emotional_needs (id, clinic_id, code, name, description, sort_order, is_active)
VALUES
  ('99999999-9999-9999-9999-999999999001', NULL, 'EMOTIONAL_NEED_SECURE_ATTACHMENT',
    'Vínculos seguros', 'Segurança, estabilidade, cuidado, aceitação e pertencimento.', 0, true),
  ('99999999-9999-9999-9999-999999999002', NULL, 'EMOTIONAL_NEED_AUTONOMY_COMPETENCE',
    'Autonomia e competência', 'Senso de identidade, independência e capacidade de se virar sozinho.', 1, true),
  ('99999999-9999-9999-9999-999999999003', NULL, 'EMOTIONAL_NEED_FREEDOM_EXPRESSION',
    'Liberdade de expressão', 'Poder expressar necessidades e emoções válidas sem medo.', 2, true),
  ('99999999-9999-9999-9999-999999999004', NULL, 'EMOTIONAL_NEED_SPONTANEITY_PLAY',
    'Espontaneidade e lazer', 'Brincar, divertir-se e ter prazer.', 3, true),
  ('99999999-9999-9999-9999-999999999005', NULL, 'EMOTIONAL_NEED_REALISTIC_LIMITS',
    'Limites realistas', 'Autocontrole, disciplina e respeito a limites e aos outros.', 4, true);
