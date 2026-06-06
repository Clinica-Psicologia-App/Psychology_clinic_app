# Gap analysis — motor clínico (etapa de extração)

**Data da análise:** 2026-05-31  
**Escopo:** Documentação pré-implementação (sem código de cálculo, sem migrations, sem Edge Functions novas).

---

## 1. Resumo executivo

A estrutura de documentação em `docs/scoring-engine/` foi criada para receber as regras clínicas dos questionários. **A extração completa dos arquivos-fonte não pôde ser realizada** porque:

- `ProjetoApp_questionários.xlsx` — **não encontrado** no workspace nem em pastas comuns do usuário (`Downloads`, `Desktop`, `Documents`, busca `mdfind`).
- `Questionários de Esquemas.xlsx` — **não encontrado** nas mesmas buscas.

**Conclusão:** O motor clínico **não pode ser validado nem implementado** com base nesta entrega até que os Excel sejam adicionados (sugestão: `docs/scoring-engine/sources/`) e uma segunda rodada de extração seja executada.

---

## 2. Informações encontradas

### 2.1 No repositório (técnico / MVP)

| Achado | Local | Relevância para motor clínico |
|--------|-------|------------------------------|
| Modelo relacional para pesos e resultados | `question_categories`, `question_category_items`, `questionnaire_results` | Suporta implementação futura |
| Fluxo planejado de apuração | `docs/database-model.md` | Hipótese de Σ, média, %, `classification` — **não validado clinicamente** |
| Agregação placeholder | `finish-questionnaire` | Σ(`answer_value` × `weight`), média = total/peso, `classification = pending_review` |
| Instrumento fictício 5 itens Likert 1–6 | `seed.sql` (`MVP_DEMO`) | Apenas teste de fluxo |
| Menção futura YSQ-S3, SMI | `docs/next-steps.md` | Indica instrumentos alvo; **sem detalhe de itens/regras** |

### 2.2 Documentação gerada nesta etapa

| Documento | Conteúdo |
|-----------|----------|
| `questionnaires-catalog.md` | Template + `MVP_DEMO` |
| `question-mapping.md` | Template + 5 itens sem esquema clínico |
| `domains.md` | Template vazio |
| `schemas.md` | Template vazio |
| `scoring-rules.md` | Template + referência placeholder |
| `severity-ranges.md` | Template vazio (sem faixas inventadas) |
| `mvp-placeholder-only.md` | Comportamento código atual |

---

## 3. Informações ausentes (bloqueantes)

| # | Ausência | Impacto |
|---|----------|---------|
| A1 | Arquivos Excel não disponíveis | Impossível listar questionários reais |
| A2 | Versão/edição de cada instrumento | Impossível versionar seed e resultados |
| A3 | Textos de instrução ao paciente | Impossível UX de aplicação fiel |
| A4 | Lista completa de perguntas por instrumento | Impossível importar `questions` |
| A5 | Mapeamento pergunta → esquema | Impossível `question_category_items` clínico |
| A6 | Mapeamento esquema → domínio | Impossível hierarquia e dashboard futuro |
| A7 | Pesos por item (se ≠ 1) | Cálculo incorreto se assumir peso 1 |
| A8 | Itens com reverse scoring | Risco de pontuação invertida |
| A9 | Fórmulas de soma/média/normalização por instrumento | Motor inconsistente |
| A10 | Tabelas de cortes (baixo/moderado/alto/muito alto) | `classification` indefinida |
| A11 | Regras para respostas incompletas | Comportamento em draft parcial |
| A12 | Exceções (itens excluídos, subescalas) | Casos especiais não cobertos |

---

## 4. Ambiguidades (resolver com planilha + clínico)

| ID | Ambiguidade | Opções | Responsável sugerido |
|----|-------------|--------|----------------------|
| B1 | `question_categories` = domínio, esquema ou modo? | 1:1 com esquema; 1:1 com domínio; hierarquia em duas tabelas | Clínico + arquiteto |
| B2 | Um item em vários esquemas? | Sim (pesos diferentes) / Não | Planilha + clínico |
| B3 | Escala única ou múltiplas por app? | Likert 1–6 global / por instrumento | Planilha |
| B4 | Classificação por esquema ou domínio agregado? | Por esquema / roll-up / ambos | Clínico |
| B5 | Mesmo nome de esquema entre YSQ e SMI? | Mesmo constructo / homônimos | Planilha |
| B6 | `ProjetoApp` vs `Questionários de Esquemas` — qual é master? | Prioridade de arquivo em conflito | Product owner |
| B7 | Percentual no resultado — fórmula do máximo teórico | Σ pesos × max escala / outro | Planilha |

---

## 5. Perguntas para validação antes da implementação

### 5.1 Escopo de produto

1. Quais questionários entram no **primeiro release** do motor (lista fechada)?
2. Resultados devem ser **somente leitura staff** ou também resumo para paciente?
3. Recálculo retroativo ao alterar regras — necessário?

### 5.2 Clínico / conteúdo

4. Fornecer os dois Excel em `docs/scoring-engine/sources/` (ou link seguro).
5. Confirmar versão traduzida e número oficial de itens (YSQ-S3, SMI, outros).
6. Quem homologa faixas de severidade e referência bibliográfica?
7. Itens com pontuação reversa — lista explícita por `question_id`?

### 5.3 Técnico

8. Motor em **SQL `SECURITY DEFINER`**, **Edge Function** ou híbrido?
9. `classification` valores fixos enum ou texto livre por instrumento?
10. Armazenar só scores finais ou também passos intermediários no `snapshot`?

---

## 6. Riscos se implementar sem esta validação

| Risco | Severidade |
|-------|------------|
| Pontuação clínica incorreta | **Alta** |
| Interpretação errada de severidade | **Alta** |
| Retrabalho em migrations/seed | Média |
| Perda de confiança na demo com cliente | Alta |

---

## 7. Critérios de aceite desta etapa

| Critério | Atendido? |
|----------|-----------|
| Documentação estruturada criada | **Sim** |
| Nenhuma regra inventada | **Sim** |
| Nenhum código de cálculo | **Sim** |
| Extração completa dos Excel | **Não** — bloqueado por arquivos ausentes |
| Pronto para implementar motor | **Não** — depende de §5 |

---

## 8. Próximos passos recomendados

1. Adicionar `ProjetoApp_questionários.xlsx` e `Questionários de Esquemas.xlsx` em `docs/scoring-engine/sources/`.
2. Executar segunda rodada: preencher todos os `.md` a partir das abas/colunas reais.
3. Reunião de validação clínica (checklist §5).
4. Gerar especificação de implementação (fora desta etapa) após sign-off.

---

## 9. Referência rápida — o que já funciona no app (sem motor clínico)

- Paciente responde questionário via Edge Functions.
- Staff vê respostas e snapshot **placeholder** em Resultados.
- Isso **não** valida regras das planilhas Excel.
