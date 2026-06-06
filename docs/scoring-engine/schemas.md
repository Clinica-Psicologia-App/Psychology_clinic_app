# Esquemas mal-adaptativos

> **Fonte:** `Questionários de Esquemas.xlsx` — **arquivo não encontrado**.  
> Nenhum esquema foi listado ou deduzido sem a planilha.

## Definição (para alinhamento)

**Esquema:** constructo clínico da Terapia do Esquema (ex.: Esquemas de Young no YSQ). Cada esquema deve estar ligado a um ou mais itens de questionário conforme a planilha-fonte.

---

## Lista de esquemas (PENDENTE)

| Esquema | Domínio | Perguntas associadas (IDs ou códigos) | Questionário(s) | Status |
|---------|---------|----------------------------------------|-----------------|--------|
| *—* | *—* | *—* | *—* | **PENDENTE** |

---

## Template por esquema

```markdown
### [NOME_DO_ESQUEMA]

- **Domínio:** PENDENTE
- **Descrição (planilha):** PENDENTE
- **Itens / perguntas:** lista de question_id ou número do item
- **Peso por item (se variável):** PENDENTE
- **Reverse scoring nos itens:** PENDENTE (sim/não por item)
```

---

## Relação esquema ↔ banco de dados (hipótese a validar)

| Hipótese | Validar com Excel + clínico |
|----------|----------------------------|
| 1 esquema = 1 `question_categories` | ? |
| 1 esquema = N perguntas via `question_category_items` | Provável (modelo atual) |
| Esquema e domínio são a mesma coluna na planilha | ? |

---

## Validação necessária

- [ ] Nomenclatura oficial dos esquemas (PT) e sinônimos.
- [ ] Esquemas compartilhados entre YSQ, SMI e outros instrumentos?
- [ ] Itens órfãos (sem esquema) — como tratar?
