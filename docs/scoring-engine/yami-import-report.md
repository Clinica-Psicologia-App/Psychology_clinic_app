# Relatório de importação — YAMI-Modos Esquemáticos

**Data:** 2026-05-31  
**Fonte:** `~/Documents/ProjetoApp_questionários.xlsx`, aba `YAMI-Modos Esquemáticos (2)`  
**Migration:** `supabase/migrations/20250531150015_seed_yami_modes_foundation.sql`  
**Questionário:** `YAMI_MODES_FOUNDATION_V1` (`88888888-8888-8888-8888-888888888301`)

## Decisão de modelagem: modos → `schemas`

A planilha traz apenas a coluna **Modos** (sem domínio hierárquico como no YSQ). O motor de apuração agrupa por `schema_id` e `domain_id`.

| Opção | Decisão |
|-------|---------|
| Nova entidade `modes` | **Não** — exigiria migration de schema e alteração do motor (fora do escopo). |
| `schema_domains` + `schemas` | **Sim** — um domínio sintético `YAMI_DOMAIN_SCHEMA_MODES` e cada **modo** como linha em `schemas` (nome = rótulo da planilha). |
| Reutilizar domínios Young do YSQ | **Não** — modos SMI/YAMI não são esquemas mal-adaptativos Young. |

O snapshot estruturado (`scoring-demo-1`) expõe agrupamentos em `schemas[]` com os nomes dos modos; semanticamente são **modos esquemáticos**, não esquemas YSQ.

## Resumo quantitativo

| Entidade | Quantidade |
|----------|------------|
| Domínios (`schema_domains`) | **1** (container `YAMI_DOMAIN_SCHEMA_MODES`) |
| Modos (`schemas`) | **19** (rótulos distintos na planilha) |
| Perguntas (`questions`) | **124** (itens 1–124; compatível com SMI 1.1 citado na planilha) |
| Versão (`questionnaire_versions`) | **1** (`v1-foundation`, `active`) |
| Regras (`question_scoring_rules`) | **124** (peso **1**, `reverse_score` **false** — não constam na aba) |
| Faixas (`severity_ranges`) | **57** (3 faixas × 19 modos, cabeçalho linha 2) |

## Escala (planilha)

| Valor | Rótulo |
|-------|--------|
| 1 | Nunca ou quase nunca |
| 2 | Raramente |
| 3 | Às vezes |
| 4 | Muitas vezes |
| 5 | Grande parte do tempo |
| 6 | O tempo todo |

Pergunta-guia (linha 2): *"Em geral, com que frequência esta frase se aplica a mim?"*

## Faixas de severidade (cabeçalho → por modo)

| Label | min_score | max_score |
|-------|-----------|-----------|
| Baixo | 1,0 | 2,4 |
| Médio | 2,5 | 3,9 |
| Ativado | 4,0 | 5,0 |

## Modos importados (19)

Códigos SQL: `YAMI_MODE_01` … `YAMI_MODE_19` (ordem de primeira aparição na planilha).

| code | Nome na planilha | Itens |
|------|------------------|-------|
| YAMI_MODE_01 | Intimidação e Ataque | 1 |
| YAMI_MODE_02 | Criança  Feliz | 1 |
| YAMI_MODE_03 | Pais Punitivos | 10 |
| YAMI_MODE_04 | Criança Vulnerável | 9 |
| YAMI_MODE_05 | Pais Exigentes e Críticos | 10 |
| YAMI_MODE_06 | Vencido Submisso | 2 |
| YAMI_MODE_07 | Auto Engrandecedor | 10 |
| YAMI_MODE_08 | Criança Impulsiva | 2 |
| YAMI_MODE_09 | Criança Indisciplinada | 6 |
| YAMI_MODE_10 | Criança Raivosa | 10 |
| YAMI_MODE_11 | Criança Feliz | 8 |
| YAMI_MODE_12 | Adulto Saudável | 10 |
| YAMI_MODE_13 | Criança Zangada | 1 |
| YAMI_MODE_14 | Protetor Desligado | 7 |
| YAMI_MODE_15 | Autoconfortador Desligado | 1 |
| YAMI_MODE_16 | Auto Confortador Desligado | 1 |
| YAMI_MODE_17 | Auto Confortador desligada | 1 |
| YAMI_MODE_18 | Ciança Vulnerável | 1 |
| YAMI_MODE_19 | Ciança Feliz | 1 |

Itens sem repetição de modo na coluna B usam o **último modo** preenchido (comportamento da planilha).

## Itens não importados

| Item | Motivo |
|------|--------|
| Rótulos de escala soltos nas colunas B (1–6, "Nunca…", etc.) | Metadados; não são modos |
| Linhas de instrução no rodapé (col. B) | Texto agregado em `instructions` quando na col. C |
| Referência bibliográfica (col. C, rodapé) | Metadado, não é pergunta |
| Abas YSQ, Personalidade, etc. | Fora do escopo desta migration |
| `question_category_items` | Legado MVP; não preenchido |
| MVP_DEMO / YSQ (`1111…`, `7777…`, `6666…`) | Preservados |

## Dúvidas clínicas e de dados

1. **Duplicatas / typos de modo:** `Criança  Feliz` vs `Criança Feliz`; `Ciança Vulnerável` / `Ciança Feliz`; três grafias de "Auto(n) Confortador Desligado". Importados como modos **distintos** (fiel à planilha) — revisar com psicólogo se devem ser unificados.
2. **Contagem por modo irregular:** 1–10 itens por modo (não 5 fixos como YSQ). Reflete a planilha, não normalização clínica.
3. **SMI 1.1 / licenciamento:** rodapé cita "Inventário de Modos Esquemáticos (SMI 1.1) Jeffrey Young, Ph.D." — confirmar licença de uso.
4. **`reverse_score` e pesos:** ausentes na aba → todos peso 1, sem reverse.
5. **Domínio único sintético:** agrupamento `domains[]` no snapshot terá uma única entrada; modos aparecem em `schemas[]`.
6. **Banner Flutter:** `YAMI_MODES_FOUNDATION_V1` usa mensagem genérica de questionário estruturado (não alterado nesta tarefa).
7. **Classificação "Ativado":** label literal da planilha (não "Alto" clínico).

## UUIDs (prefixo `88888888-…`)

| Recurso | ID |
|---------|-----|
| Questionário | `…88301` |
| Versão | `…88801` |
| Domínio | `…88601` |
| Modos (schemas) | `…88710` – `…88728` |
| Perguntas | `888888850001` – `88888885007c` (último segmento 12 hex) |
| Regras | `888888890001` – `88888889007c` |

## Validação

```bash
supabase db reset   # local
# Listar questionários ativos
# Fluxo: start-questionnaire → 124 respostas → finish-questionnaire → snapshot scoring-demo-1
```

## Coexistência

| Questionário | Código | Versão active |
|--------------|--------|---------------|
| MVP demo | `MVP_DEMO` | `v1-demo` (6666…) |
| YSQ | `YSQ_FOUNDATION_V1` | `v1-foundation` (7777…) |
| YAMI | `YAMI_MODES_FOUNDATION_V1` | `v1-foundation` (8888…) |

Cada um possui no máximo uma versão `active` (índice por `questionnaire_id`).
