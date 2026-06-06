# Catálogo de questionários

> **Fonte:** `ProjetoApp_questionários.xlsx` e `Questionários de Esquemas.xlsx` — **não localizados no workspace** (maio/2026).  
> Conteúdo abaixo: estrutura de documentação + único instrumento verificável no repo (`MVP_DEMO`, fictício).

Legenda de status:

| Status | Significado |
|--------|-------------|
| **PENDENTE** | Aguardando leitura dos Excel |
| **REPO-MVP** | Apenas seed/código atual; não é instrumento clínico validado |

---

## Inventário (a partir dos Excel)

| # | Nome (planilha) | Versão | Qtd. perguntas | Escala | Instruções ao paciente | Status |
|---|-----------------|--------|----------------|--------|------------------------|--------|
| — | *A preencher após análise de `ProjetoApp_questionários.xlsx`* | — | — | — | — | **PENDENTE** |
| — | *A preencher após análise de `Questionários de Esquemas.xlsx`* | — | — | — | — | **PENDENTE** |

### Checklist por questionário (template)

Para cada instrumento identificado nas planilhas, documentar:

```markdown
### [NOME_DO_INSTRUMENTO]

- **Código interno sugerido:** (ex.: YSQ_S3)
- **Versão / edição:** PENDENTE
- **Quantidade de perguntas:** PENDENTE
- **Escala de resposta:** PENDENTE (ex.: Likert 1–6, 0–4, etc.)
- **Instruções ao paciente (texto integral):** PENDENTE
- **Tempo estimado / ordem de aplicação:** PENDENTE
- **Observações da planilha:** PENDENTE
```

---

## Referência técnica no repositório (não substitui os Excel)

### MVP_DEMO — Inventário Demo — 5 itens

| Campo | Valor (verificado em `supabase/seed.sql`) |
|-------|------------------------------------------|
| Código | `MVP_DEMO` |
| Versão | **Não documentada** (instrumento fictício de demo) |
| Quantidade de perguntas | **5** |
| Escala | Likert **1–6** (`answer_type = likert_scale`, `scale_min = 1`, `scale_max = 6`) |
| Instruções ao paciente | **Não há** texto de instrução na seed; descrição do instrumento: *"Questionário fictício para demonstração do fluxo (Likert 1–6). Não é instrumento clínico validado."* |
| Categorias de apuração | 1 — `DEMO_GERAL` ("Categoria demonstração") |
| Status | **REPO-MVP** |

Itens (códigos `Q01`–`Q05`): textos fictícios na seed; marcados com sufixo *(fictício)*.

---

## Instrumentos mencionados na documentação do projeto (não extraídos)

| Instrumento | Onde citado | Status neste documento |
|-------------|-------------|------------------------|
| YSQ-S3 | `docs/next-steps.md` | **PENDENTE** — aguardando Excel |
| SMI | `docs/next-steps.md` | **PENDENTE** — aguardando Excel |
| Outros em `Questionários de Esquemas.xlsx` | Arquivo ausente | **PENDENTE** |

---

## Validação necessária (negócio)

- [ ] Lista completa de questionários é a mesma em ambos os Excel?
- [ ] Versão oficial de cada instrumento (tradução PT, número de itens).
- [ ] Instruções ao paciente: texto único por instrumento ou por bloco?
- [ ] Quais instrumentos entram no MVP de produção vs. fase 2?
