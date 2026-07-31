-- =============================================================================
-- Migration: corrige YAMI (modos duplicados/typo) e adiciona camada estruturada
--            de schema_domains/schemas para o YPI (PARENTAL_STYLES_V1).
-- =============================================================================

-- ── 1. YAMI — desativa modos duplicados / com typo ───────────────────────────
--
-- MODE_11 = duplicata de MODE_02 ("Criança Feliz")
-- MODE_16 = duplicata de MODE_15 ("Autoconfortador Desligado")
-- MODE_17 = duplicata de MODE_15 ("Auto Confortador desligada")
-- MODE_18 = typo + duplicata de MODE_04 ("Ciança Vulnerável")
-- MODE_19 = typo + duplicata de MODE_02 ("Ciança Feliz")
-- Nenhum destes tem question_scoring_rules — seguro desativar.

UPDATE public.schemas
SET is_active = false
WHERE code IN ('YAMI_MODE_11', 'YAMI_MODE_16', 'YAMI_MODE_17', 'YAMI_MODE_18', 'YAMI_MODE_19');

-- Corrige espaço duplo em MODE_02
UPDATE public.schemas
SET name = 'Criança Feliz'
WHERE code = 'YAMI_MODE_02';

-- ── 2. YPI — camada de schema_domains e schemas ───────────────────────────────
--
-- O YPI avalia os mesmos 17 esquemas do YSQ, mas pela perspectiva dos
-- comportamentos parentais. Organizamos sob os mesmos 5 domínios Young para
-- manter consistência clínica. O scoring_method permanece legacy_category_average
-- — esta camada serve para exibição e referência clínica.

INSERT INTO public.schema_domains (id, clinic_id, code, name, description, sort_order, is_active)
VALUES
  ('b1000001-0000-4000-a000-000000000001', NULL,
   'YPI_DOMAIN_DISCONNECTION_REJECTION',
   'D1 · Desconexão e Rejeição',
   'Comportamentos parentais associados a esquemas de desconexão e rejeição.',
   0, true),
  ('b1000001-0000-4000-a000-000000000002', NULL,
   'YPI_DOMAIN_IMPAIRED_AUTONOMY',
   'D2 · Autonomia e Desempenho Prejudicados',
   'Comportamentos parentais associados a esquemas de autonomia e desempenho prejudicados.',
   1, true),
  ('b1000001-0000-4000-a000-000000000003', NULL,
   'YPI_DOMAIN_IMPAIRED_LIMITS',
   'D3 · Limites Prejudicados',
   'Comportamentos parentais associados a esquemas de limites prejudicados.',
   2, true),
  ('b1000001-0000-4000-a000-000000000004', NULL,
   'YPI_DOMAIN_OTHER_DIRECTEDNESS',
   'D4 · Direcionamento para o Outro',
   'Comportamentos parentais associados a esquemas de direcionamento para o outro.',
   3, true),
  ('b1000001-0000-4000-a000-000000000005', NULL,
   'YPI_DOMAIN_OVERVIGILANCE_INHIBITION',
   'D5 · Supervigilância e Inibição',
   'Comportamentos parentais associados a esquemas de supervigilância e inibição.',
   4, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  name        = EXCLUDED.name,
  description = EXCLUDED.description,
  sort_order  = EXCLUDED.sort_order,
  is_active   = EXCLUDED.is_active;

INSERT INTO public.schemas (id, domain_id, clinic_id, code, name, description, sort_order, is_active)
VALUES
  -- D1 · Desconexão e Rejeição (4 esquemas)
  ('b2000001-0000-4000-a000-000000000001', 'b1000001-0000-4000-a000-000000000001', NULL,
   'YPI_SCHEMA_PRIVACAO_EMOCIONAL', 'Privação Emocional',
   'Falta de cuidado emocional, afeto e atenção por parte dos cuidadores.', 0, true),
  ('b2000001-0000-4000-a000-000000000002', 'b1000001-0000-4000-a000-000000000001', NULL,
   'YPI_SCHEMA_ABANDONO', 'Abandono',
   'Ausência física ou emocional persistente do cuidador.', 1, true),
  ('b2000001-0000-4000-a000-000000000003', 'b1000001-0000-4000-a000-000000000001', NULL,
   'YPI_SCHEMA_DESCONFIANCA_ABUSO', 'Desconfiança/Abuso',
   'Comportamentos enganosos, abusivos ou de exploração por parte do cuidador.', 2, true),
  ('b2000001-0000-4000-a000-000000000004', 'b1000001-0000-4000-a000-000000000001', NULL,
   'YPI_SCHEMA_DEFECTIVIDADE_VERGONHA', 'Defectividade/Vergonha',
   'Críticas, rejeição ou mensagens de inadequação transmitidas pelo cuidador.', 3, true),

  -- D2 · Autonomia e Desempenho Prejudicados (4 esquemas)
  ('b2000001-0000-4000-a000-000000000005', 'b1000001-0000-4000-a000-000000000002', NULL,
   'YPI_SCHEMA_DEPENDENCIA_INCOMPETENCIA', 'Dependência/Incompetência',
   'Superproteção ou mensagens de incapacidade transmitidas pelo cuidador.', 0, true),
  ('b2000001-0000-4000-a000-000000000006', 'b1000001-0000-4000-a000-000000000002', NULL,
   'YPI_SCHEMA_VULNERABILIDADE_DANO_DOENCA', 'Vulnerabilidade ao Dano ou Doença',
   'Comportamentos do cuidador que transmitem o mundo como perigoso.', 1, true),
  ('b2000001-0000-4000-a000-000000000007', 'b1000001-0000-4000-a000-000000000002', NULL,
   'YPI_SCHEMA_EMARANHAMENTO', 'Emaranhamento/Self Subdesenvolvido',
   'Fusão excessiva e falta de limites saudáveis na relação com o cuidador.', 2, true),
  ('b2000001-0000-4000-a000-000000000008', 'b1000001-0000-4000-a000-000000000002', NULL,
   'YPI_SCHEMA_FRACASSO', 'Fracasso',
   'Expectativas negativas ou mensagens de fracasso transmitidas pelo cuidador.', 3, true),

  -- D3 · Limites Prejudicados (2 esquemas)
  ('b2000001-0000-4000-a000-000000000009', 'b1000001-0000-4000-a000-000000000003', NULL,
   'YPI_SCHEMA_ARROGO_GRANDIOSIDADE', 'Arrogo/Grandiosidade',
   'Permissividade excessiva ou transmissão de senso de superioridade.', 0, true),
  ('b2000001-0000-4000-a000-000000000010', 'b1000001-0000-4000-a000-000000000003', NULL,
   'YPI_SCHEMA_AUTOCONTROLE_INSUFICIENTE', 'Autocontrole/Autodisciplina Insuficientes',
   'Falta de limites, disciplina ou regras consistentes por parte do cuidador.', 1, true),

  -- D4 · Direcionamento para o Outro (3 esquemas)
  ('b2000001-0000-4000-a000-000000000011', 'b1000001-0000-4000-a000-000000000004', NULL,
   'YPI_SCHEMA_SUBJUGACAO', 'Subjugação',
   'Controle excessivo e supressão da autonomia e vontade da criança.', 0, true),
  ('b2000001-0000-4000-a000-000000000012', 'b1000001-0000-4000-a000-000000000004', NULL,
   'YPI_SCHEMA_AUTO_SACRIFICIO', 'Autossacrifício',
   'Cuidador que coloca suas necessidades em segundo plano e espera o mesmo da criança.', 1, true),
  ('b2000001-0000-4000-a000-000000000013', 'b1000001-0000-4000-a000-000000000004', NULL,
   'YPI_SCHEMA_BUSCA_APROVACAO', 'Busca de Aprovação/Reconhecimento',
   'Amor condicional ao desempenho ou à aprovação social da criança.', 2, true),

  -- D5 · Supervigilância e Inibição (4 esquemas)
  ('b2000001-0000-4000-a000-000000000014', 'b1000001-0000-4000-a000-000000000005', NULL,
   'YPI_SCHEMA_NEGATIVISMO_PESSIMISMO', 'Negativismo/Pessimismo',
   'Perspectiva pessimista ou foco nos aspectos negativos transmitidos pelo cuidador.', 0, true),
  ('b2000001-0000-4000-a000-000000000015', 'b1000001-0000-4000-a000-000000000005', NULL,
   'YPI_SCHEMA_INIBICAO_EMOCIONAL', 'Inibição Emocional',
   'Supressão da expressão emocional pelo cuidador.', 1, true),
  ('b2000001-0000-4000-a000-000000000016', 'b1000001-0000-4000-a000-000000000005', NULL,
   'YPI_SCHEMA_PADROES_INFLEXIVEIS', 'Padrões Inflexíveis/Crítica Exagerada',
   'Exigências rígidas e perfeccionismo impostos pelo cuidador.', 2, true),
  ('b2000001-0000-4000-a000-000000000017', 'b1000001-0000-4000-a000-000000000005', NULL,
   'YPI_SCHEMA_POSTURA_PUNITIVA', 'Postura Punitiva',
   'Punições excessivas, culpa ou raiva como forma de disciplina do cuidador.', 3, true)
ON CONFLICT (id) DO UPDATE SET
  domain_id   = EXCLUDED.domain_id,
  code        = EXCLUDED.code,
  name        = EXCLUDED.name,
  description = EXCLUDED.description,
  sort_order  = EXCLUDED.sort_order,
  is_active   = EXCLUDED.is_active;
