# Domínios clínicos

> **Fonte:** `Questionários de Esquemas.xlsx` — **arquivo não encontrado**.  
> Nenhum domínio clínico foi inferido ou inventado neste documento.

## Definição (para alinhamento)

**Domínio:** agrupamento clínico de alto nível que organiza vários **esquemas** (ex.: domínios da classificação de Young, fatores do SMI, etc.). Deve constar explicitamente nas planilhas-fonte.

No schema do banco (`question_categories`), a tabela nomeada "categoria" pode corresponder a **domínio**, **esquema** ou **modo** conforme o instrumento — **isso precisa ser validado** na extração (ver [gap-analysis.md](./gap-analysis.md)).

---

## Lista de domínios (PENDENTE)

| Domínio (nome) | Descrição | Esquemas pertencentes | Questionário(s) | Status |
|----------------|-----------|------------------------|-----------------|--------|
| *—* | *—* | *—* | *—* | **PENDENTE** |

---

## Template por domínio

```markdown
### [NOME_DO_DOMÍNIO]

- **Descrição clínica:** (texto da planilha)
- **Esquemas incluídos:** lista
- **Instrumentos que usam este domínio:** lista
- **Notas / referência bibliográfica:** PENDENTE
```

---

## O que existe hoje no repositório (não é domínio clínico)

| code | name | questionnaire | Observação |
|------|------|---------------|------------|
| `DEMO_GERAL` | Categoria demonstração | `MVP_DEMO` | Agrupa 5 itens fictícios para teste de fluxo; **não** documentar como domínio clínico |

---

## Validação necessária

- [ ] Lista oficial de domínios da Terapia do Esquema usada na clínica.
- [ ] Correspondência domínio ↔ `question_categories` no banco (1:1 ou N:N).
- [ ] Domínios são iguais em todos os instrumentos ou específicos por questionário?
