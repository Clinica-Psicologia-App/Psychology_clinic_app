# Regras de cálculo (apuração)

> **Regras clínicas dos Excel:** **PENDENTE** — arquivos não disponíveis.  
> **Não implementar** com base neste documento até validação clínica.

---

## 1. Regras esperadas por instrumento (PENDENTE — Excel)

Para cada questionário em [questionnaires-catalog.md](./questionnaires-catalog.md), documentar:

| Regra | Descrição | Instrumento | Valor / fórmula | Fonte |
|-------|-----------|-------------|-----------------|-------|
| Soma | Σ respostas (ou ponderada) | *—* | *—* | **PENDENTE** |
| Média | Média simples ou ponderada | *—* | *—* | **PENDENTE** |
| Pesos | Peso por item/categoria | *—* | *—* | **PENDENTE** |
| Normalização | % do máximo teórico, T-score, etc. | *—* | *—* | **PENDENTE** |
| Reverse scoring | Inversão de itens | *—* | *—* | **PENDENTE** |
| Agregação por esquema | Como agrupar itens | *—* | *—* | **PENDENTE** |
| Agregação por domínio | Roll-up de esquemas | *—* | *—* | **PENDENTE** |
| Critério de severidade | Limiares → classificação | *—* | *—* | **PENDENTE** |
| Exceções | Itens excluídos, missing, mínimo de itens | *—* | *—* | **PENDENTE** |

---

## 2. Placeholder técnico no repositório (NÃO é motor clínico)

Documentado em [mvp-placeholder-only.md](./mvp-placeholder-only.md).

Resumo **verificado** em `supabase/functions/finish-questionnaire/index.ts`:

| Etapa | Comportamento atual |
|-------|---------------------|
| Entrada | `answer_value` numérico por pergunta; `weight` em `question_category_items` |
| Por categoria | `total_score` = Σ (`answer_value` × `weight`) |
| Média | `average_score` = `total / weightSum` se `weightSum > 0` |
| Percentual | **Não calculado** (`percentage` permanece null) |
| Classificação | Fixo `pending_review` — **sem faixas clínicas** |
| Snapshot | JSON com itens e nota *"Placeholder aggregation — clinical engine not applied"* |

Isso serve apenas para **demo de fluxo** (`MVP_DEMO`), não para YSQ/SMI ou regras das planilhas.

---

## 3. Alinhamento com modelo de dados (planejado)

De `docs/database-model.md` (intenção de produto, **não validada clinicamente**):

1. Ler respostas da `response_id` concluída.
2. Aplicar pesos de `question_category_items`.
3. Gravar `questionnaire_results` por (`response_id`, `category_id`).
4. Campos: `total_score`, `average_score`, `percentage`, `classification`, `snapshot`.

**Gap:** fórmulas por instrumento e cortes de `classification` **não** estão nos Excel disponíveis nesta etapa.

---

## 4. Perguntas de validação

- [ ] Média é simples ou ponderada por instrumento?
- [ ] Normalização usa máximo teórico fixo ou depende de itens respondidos?
- [ ] Respostas faltantes: imputação, exclusão do esquema ou bloqueio?
- [ ] Mesma fórmula para todos os instrumentos ou tabela por instrumento?
- [ ] `classification` é por esquema, domínio ou global?
