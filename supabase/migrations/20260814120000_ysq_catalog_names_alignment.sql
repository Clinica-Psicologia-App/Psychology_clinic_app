-- =============================================================================
-- Alinha os nomes do catálogo YSQ ao material clínico da psicóloga responsável.
--
-- Fonte: planilha "QuestionárioS de EsquemaS" + validação por escrito em
-- ago/2026. A ORDEM (sort_order) já estava correta nos 5 domínios e não é
-- tocada aqui — só a grafia dos nomes.
--
-- Nota sobre respostas antigas: o nome exibido no app vem do JSONB `snapshot`,
-- congelado quando a resposta é concluída. Esta migration corrige a fonte de
-- verdade para respostas futuras; a exibição de respostas antigas é corrigida
-- no cliente, que resolve o nome pelo código em `ysq_taxonomy.dart`.
-- =============================================================================

-- Domínios: remove o prefixo ordinal ("Primeiro Domínio-"), que a UI agora
-- compõe a partir de sort_order, e adota os termos da cliente.
UPDATE public.schema_domains SET name = 'Desconexão e rejeição'
  WHERE code = 'YSQ_DOMAIN_DISCONNECTION_REJECTION';

UPDATE public.schema_domains SET name = 'Autonomia e desempenho prejudicados'
  WHERE code = 'YSQ_DOMAIN_IMPAIRED_AUTONOMY';

UPDATE public.schema_domains SET name = 'Limites prejudicados'
  WHERE code = 'YSQ_DOMAIN_IMPAIRED_LIMITS';

-- "Direcionamento para o outro" -> termo da cliente.
UPDATE public.schema_domains SET name = 'Orientação para o outro'
  WHERE code = 'YSQ_DOMAIN_OTHER_DIRECTEDNESS';

-- "Supervigilância" -> "Hipervigilância", termo usado pela cliente.
UPDATE public.schema_domains SET name = 'Hipervigilância e inibição'
  WHERE code = 'YSQ_DOMAIN_OVERVIGILANCE_INHIBITION';

-- Esquemas: 4 correções de nome.
UPDATE public.schemas SET name = 'Arrogo/Grandiosidade'
  WHERE code = 'YSQ_SCHEMA_ENTITLEMENT_GRANDIOSITY';

-- Erro de digitação no seed original ("Autos sacrifico").
UPDATE public.schemas SET name = 'Autossacrifício'
  WHERE code = 'YSQ_SCHEMA_SELF_SACRIFICE';

UPDATE public.schemas SET name = 'Vulnerabilidade ao dano ou à doença'
  WHERE code = 'YSQ_SCHEMA_VULNERABILITY';

UPDATE public.schemas SET name = 'Autocontrole/Autodisciplina insuficiente'
  WHERE code = 'YSQ_SCHEMA_INSUFFICIENT_SELF_CONTROL';
