# Faixas de severidade (classificação clínica)

> **Fonte Excel:** **PENDENTE**.  
> **Não foram definidas** faixas baixo / moderado / alto / muito alto neste documento — conforme instrução de não inventar cortes.

---

## Estrutura esperada (a preencher por instrumento e por esquema/domínio)

Para cada combinação **instrumento × esquema** (ou **instrumento × domínio**), documentar:

| Faixa | Label (PT) | Limite inferior | Limite superior | Inclusivo? | Fonte |
|-------|------------|-----------------|-----------------|------------|-------|
| Baixo | *—* | *—* | *—* | *—* | **PENDENTE** |
| Moderado | *—* | *—* | *—* | *—* | **PENDENTE** |
| Alto | *—* | *—* | *—* | *—* | **PENDENTE** |
| Muito alto | *—* | *—* | *—* | *—* | **PENDENTE** |

### Variáveis a esclarecer antes de preencher

- A faixa aplica-se a **pontuação bruta**, **média**, **percentual** ou **T-score**?
- Limites são **fechados** `[a, b]` ou semiabertos?
- Faixas diferem por **sexo**, **idade** ou versão do instrumento?
- Existe categoria **“não classificável”** (ex.: itens insuficientes)?

---

## Inventário por instrumento (PENDENTE)

### YSQ-S3 (ou equivalente na planilha)

| Esquema / domínio | Baixo | Moderado | Alto | Muito alto | Status |
|-------------------|-------|----------|------|------------|--------|
| *—* | — | — | — | — | **PENDENTE** |

### SMI (ou equivalente na planilha)

| Esquema / domínio | Baixo | Moderado | Alto | Muito alto | Status |
|-------------------|-------|----------|------|------------|--------|
| *—* | — | — | — | — | **PENDENTE** |

### Demais instrumentos

**PENDENTE** — listar após leitura dos Excel.

---

## Estado atual no produto (REPO-MVP)

| Campo | Valor |
|-------|--------|
| `questionnaire_results.classification` | Sempre `pending_review` no placeholder |
| Faixas na UI | Não exibidas como severidade clínica |
| Seed demo | Snapshot com `note` de agregação placeholder |

---

## Validação necessária

- [ ] Quem define e homologa os cortes (equipe clínica / literatura)?
- [ ] Versão publicada dos limiares (referência bibliográfica por instrumento).
- [ ] Tradução PT altera interpretação dos cortes?
- [ ] Mapeamento faixa → cor/label na UI (fora desta etapa, mas depende desta tabela).
