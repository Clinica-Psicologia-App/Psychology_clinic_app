# Mapeamento pergunta ↔ esquema ↔ domínio

> **Fonte Excel:** não disponível no workspace.  
> Não preencher esquemas/domínios por inferência até leitura das planilhas.

## Campos obrigatórios por pergunta

| Campo | Descrição | Fonte |
|-------|-----------|-------|
| `question_id` | Identificador estável (código ou UUID após import) | Excel / seed |
| `questionnaire` | Instrumento pai | Excel |
| `texto` | Enunciado apresentado ao paciente | Excel |
| `esquema` | Esquema mal-adaptativo (Terapia do Esquema) | `Questionários de Esquemas.xlsx` |
| `domínio` | Agrupamento clínico superior ao esquema | Excel |
| `peso` | Peso na categoria/esquema (`question_category_items.weight`) | Excel |
| `reverse_scoring` | Se a pontuação deve ser invertida | Excel |

---

## Tabela mestra (PENDENTE — Excel)

| question_id | questionário | texto (resumo) | esquema | domínio | peso | reverse_scoring |
|-------------|--------------|----------------|---------|---------|------|-----------------|
| *—* | *—* | *—* | *—* | *—* | *—* | *—* |

---

## MVP_DEMO (REPO-MVP — apenas referência de schema)

| question_id (code) | questionário | texto | esquema | domínio | peso | reverse_scoring |
|--------------------|--------------|-------|---------|---------|------|-----------------|
| Q01 | MVP_DEMO | Sinto que as pessoas importantes não estarão disponíveis… | **Não mapeado** | `DEMO_GERAL` (categoria técnica, não esquema clínico) | 1 | **Não documentado** |
| Q02 | MVP_DEMO | Tenho dificuldade em confiar nas pessoas próximas… | **Não mapeado** | `DEMO_GERAL` | 1 | **Não documentado** |
| Q03 | MVP_DEMO | Sinto que não pertenço em grupos sociais… | **Não mapeado** | `DEMO_GERAL` | 1 | **Não documentado** |
| Q04 | MVP_DEMO | Preciso de aprovação dos outros… | **Não mapeado** | `DEMO_GERAL` | 1 | **Não documentado** |
| Q05 | MVP_DEMO | Tenho medo de perder o controle das emoções… | **Não mapeado** | `DEMO_GERAL` | 1 | **Não documentado** |

**Nota:** No MVP, `question_categories` agrupa por `DEMO_GERAL`, não por esquema clínico Young. Isso **não** reflete a estrutura esperada dos instrumentos reais.

---

## Perguntas de validação

- [ ] Um item pode pertencer a mais de um esquema com pesos diferentes?
- [ ] `reverse_scoring` aplica-se a todos os itens de uma escala ou item a item?
- [ ] Após reverse, a escala permanece no mesmo intervalo numérico (ex.: 1–6)?
- [ ] Existe mapeamento fixo item→esquema na planilha ou é derivado por fórmula?
