# Onboarding do primeiro questionário clínico real (Supabase)

Guia técnico e clínico para cadastrar um instrumento **validado pela equipe** no Postgres, substituindo gradualmente o catálogo fictício `MVP_DEMO` — **sem inserir conteúdo inventado neste repositório**.

## Princípios

| Regra | Detalhe |
|-------|---------|
| Fonte de verdade | Supabase / SQL revisado — não Excel |
| Conteúdo clínico | Somente texto, pesos, reverse e faixas aprovados por psicólogo responsável + documentação do instrumento (licença, manual, artigo) |
| MVP atual | `MVP_DEMO` + seed §16 permanecem até desativação explícita |
| Código | Não alterar `finish-questionnaire`, Flutter ou seed demo nesta etapa de planejamento |
| Motor | `finish-questionnaire` já lê `questionnaire_versions` **active** + `question_scoring_rules` + `severity_ranges` |

## Papéis

| Papel | Responsabilidade |
|-------|------------------|
| Psicólogo clínico | Validar itens, mapeamento pergunta→esquema, reverse scoring, faixas de severidade, instruções ao paciente |
| Dev / dados | Gerar UUIDs, aplicar templates SQL, checagens de integridade, deploy em ambiente de homologação |
| Admin plataforma | Executar SQL no Supabase (Studio ou CLI) com role que satisfaz RLS de escrita em catálogo global |

## O que **não** fazer

- Copiar itens de YSQ/SMI ou outros instrumentos protegidos sem licença e parecer formal
- Preencher templates com “exemplos plausíveis” para produção
- Publicar `status = active` antes da revisão clínica
- Ter duas versões `active` no mesmo `questionnaire_id` (índice único na migration 013)
- Misturar `clinic_id` do domínio com `clinic_id` do esquema filho (trigger exige alinhamento)

## Inventário de artefatos no banco

Ordem recomendada de cadastro (detalhe SQL em `supabase/templates/scoring/`):

```text
1. schema_domains          → 01_insert_domains.sql
2. schemas                 → 02_insert_schemas.sql
3. questionnaires          → 03_insert_questionnaire.sql
4. questions               → 04_insert_questions.sql
5. questionnaire_versions  → 05_insert_questionnaire_version.sql
6. question_scoring_rules  → 06_insert_scoring_rules.sql
7. severity_ranges         → 07_insert_severity_ranges.sql
```

### Legado MVP (opcional até descontinuar)

O app e o snapshot por categoria ainda usam `question_categories` + `question_category_items`. Para paridade com a UI atual de “Resultados por categoria”, planejar em SQL separado (fora dos templates 01–07):

- `question_categories` — uma ou mais categorias de agregação legada
- `question_category_items` — vínculo pergunta ↔ categoria + peso

Isso **não** substitui o motor em `question_scoring_rules`; é camada de compatibilidade.

## Fluxo clínico (antes de qualquer INSERT)

1. **Escolher instrumento** — nome oficial, versão do manual, escala (ex.: Likert 1–6), número de itens.
2. **Documentar fonte** — PDF/manual, data da versão, responsável pela validação (registro em wiki/issue, não no repo se houver restrição).
3. **Planilha de trabalho interna** (fora do repo, se necessário) com colunas: `code`, texto do item, `schema`/`domain`, peso, reverse, faixa esperada — revisada pelo psicólogo.
4. **Definir escopo multi-tenant** — catálogo **global** (`clinic_id` NULL) ou extensão por clínica (`{{CLINIC_ID_OR_NULL}}` = UUID).
5. **Gerar UUIDs fixos** — um UUID por entidade; anotar em planilha de implantação (evita reordenar FKs).
6. **Redigir SQL** — copiar templates, substituir placeholders, revisar em par.
7. **Homologação** — aplicar em projeto Supabase de teste; `start-questionnaire` / `finish-questionnaire` com paciente de teste.
8. **Publicar versão** — só então `status = active` e `published_at` preenchido; arquivar versão DEMO anterior **se** substituir o mesmo `questionnaire_id`.

## Fluxo técnico (passo a passo)

### Passo 0 — Planejamento de IDs

Definir e registrar (planilha ou doc interno aprovado):

| Placeholder | Tabela | Exemplo de uso |
|-------------|--------|----------------|
| `{{CLINIC_ID_OR_NULL}}` | `schema_domains`, `schemas` | `NULL` ou UUID da clínica |
| `{{DOMAIN_ID}}` | `schema_domains` | Um UUID por domínio |
| `{{SCHEMA_ID}}` | `schemas` | Um UUID por esquema |
| `{{QUESTIONNAIRE_ID}}` | `questionnaires`, `questions`, `questionnaire_versions` | Instrumento novo |
| `{{QUESTION_ID}}` | `questions`, `question_scoring_rules` | Um UUID por item |
| `{{VERSION_ID}}` | `questionnaire_versions`, regras, faixas | Versão `draft` primeiro |

Templates 06–07 usam auxiliares `{{SCHEMA_ID_SQL}}` / `{{DOMAIN_ID_SQL}}`: substituir por `'{{SCHEMA_ID}}'::uuid` ou `NULL` conforme o escopo da faixa/regra.

Placeholders adicionais (`{{DOMAIN_CODE}}`, `{{QUESTION_TEXT}}`, etc.) são **campos de conteúdo** preenchidos exclusivamente com dados validados pela equipe clínica.

Gerar UUIDs v4 no Studio ou:

```bash
uuidgen | tr '[:upper:]' '[:lower:]'
```

### Passo 1 — Domínios (`schema_domains`)

- Arquivo: `01_insert_domains.sql`
- Campos obrigatórios: `code`, `name` (únicos no escopo global ou por clínica)
- `sort_order` para exibição no app (futuro)

### Passo 2 — Esquemas (`schemas`)

- Arquivo: `02_insert_schemas.sql`
- `domain_id` = `{{DOMAIN_ID}}`
- `clinic_id` deve ser igual ao do domínio pai (ou ambos NULL)

### Passo 3 — Questionário (`questionnaires`)

- Arquivo: `03_insert_questionnaire.sql`
- `code` único em toda a plataforma (ex.: prefixo institucional, **não** `MVP_DEMO`)
- `is_active = true` só quando aprovado para uso no app

### Passo 4 — Perguntas (`questions`)

- Arquivo: `04_insert_questions.sql`
- Texto do item = redação **aprovada** (não placeholder do template)
- `order_index` contínuo a partir de 0
- `answer_type` e `scale_min` / `scale_max` alinhados ao instrumento

### Passo 5 — Versão (`questionnaire_versions`)

- Arquivo: `05_insert_questionnaire_version.sql`
- Começar com `status = draft`
- `scoring_method`: usar identificador acordado (ex.: `weighted_sum`; motor atual aceita texto livre)
- `scale_min` / `scale_max` = escala default da versão
- `instructions` = texto ao paciente validado
- Para `active`: definir `published_at` (obrigatório por constraint)

**Substituir MVP_DEMO:** preferível criar **novo** `questionnaires.code` e deixar `MVP_DEMO` intacto para demos; ou arquivar versão `6666…6801` (`v1-demo`) antes de ativar versão real no mesmo questionário.

### Passo 6 — Regras (`question_scoring_rules`)

- Arquivo: `06_insert_scoring_rules.sql`
- Uma linha por pergunta na versão (único `(questionnaire_version_id, question_id)`)
- `schema_id` e `domain_id` coerentes (trigger: domínio do esquema)
- `weight` > 0; `reverse_score` conforme manual
- `metadata` opcional (ex.: `source_page`, `item_number`) — sem interpretação clínica

### Passo 7 — Faixas (`severity_ranges`)

- Arquivo: `07_insert_severity_ranges.sql`
- Escopo por `schema_id` (recomendado) e/ou `domain_id` (fallback no motor)
- `min_score` / `max_score` na mesma unidade da **média ponderada** usada no motor (ver `docs/scoring-engine/database-schema.md`)
- `label` descritivo (ex.: “Baixo”) — **não** equivale a diagnóstico

### Passo 8 — Ativação e verificação

```sql
-- Exemplo: conferir versão active única
SELECT questionnaire_id, id, version, status
FROM public.questionnaire_versions
WHERE questionnaire_id = '{{QUESTIONNAIRE_ID}}'::uuid;

-- Regras sem pergunta órfã
SELECT r.*
FROM public.question_scoring_rules r
LEFT JOIN public.questions q ON q.id = r.question_id
WHERE r.questionnaire_version_id = '{{VERSION_ID}}'::uuid
  AND (q.id IS NULL OR q.questionnaire_id <> (
    SELECT questionnaire_id FROM public.questionnaire_versions WHERE id = r.questionnaire_version_id
  ));
```

Teste E2E: `supabase/tests/edge-functions-flow.ps1` com paciente de teste após aplicar SQL no ambiente local/remoto.

## Coexistência com `MVP_DEMO`

| Cenário | Comportamento |
|---------|----------------|
| Paciente responde `MVP_DEMO` | Motor usa versão active de `MVP_DEMO` (seed §16) |
| Novo instrumento com outro `questionnaire_id` | `start-questionnaire` deve referenciar o novo id (app lista questionários ativos) |
| Dois questionários com versão active | Permitido — uma active **por** questionário |

## Checklist de aceite clínico-técnico

- [ ] Parecer do psicólogo responsável arquivado (fora ou dentro do processo da clínica)
- [ ] Todos os UUIDs documentados na planilha de implantação
- [ ] Templates 01–07 preenchidos sem placeholders restantes
- [ ] Nenhum texto “fictício” / “demo” no instrumento real
- [ ] Versão publicada: `active` + `published_at`
- [ ] `finish-questionnaire` gera `snapshot.version = scoring-demo-1` (motor genérico; nome da versão no JSON é o do banco)
- [ ] Flutter exibe apuração com aviso demonstrativo **apenas** se ainda houver rótulos DEMO; para instrumento real, revisar copy do app em tarefa futura
- [ ] `MVP_DEMO` continua disponível para treinamento/demo

## Referências

| Recurso | Caminho |
|---------|---------|
| Schema detalhado | [database-schema.md](./database-schema.md) |
| Templates SQL | `supabase/templates/scoring/` |
| Motor | `supabase/functions/_shared/scoring/` |
| Seed DEMO (não editar para instrumento real) | `supabase/seed.sql` §16 |

## Próxima evolução (fora deste documento)

- Painel admin web para CRUD do catálogo
- Desligar `question_category_items` quando UI não depender mais de categorias legado
- Copy no Flutter específica para instrumento validado (remover banner “demonstrativo” quando `metadata.demo` ausente)
