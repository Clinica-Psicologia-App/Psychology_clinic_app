# Checklist de validação clínica — instrumentos importados

Documento para **revisão humana** (psicólogo responsável + gestão clínica/jurídica).  
Não substitui parecer formal. O banco reflete a planilha `ProjetoApp_questionários.xlsx` no estado das migrations **014** (YSQ) e **015** (YAMI).

**Referências técnicas:** [ysq-import-report.md](./ysq-import-report.md), [yami-import-report.md](./yami-import-report.md)

---

## Como usar este checklist

| Coluna / símbolo | Significado |
|------------------|-------------|
| ☐ | Pendente de validação |
| ☑ | Validado e aceito |
| ✗ | Rejeitado / requer correção |
| N/A | Não aplicável na planilha |
| **Estado no banco** | Valor atual importado (não editar manualmente) |

**Responsável:** _________________________ **Data:** _____________

---

## 1. Checklist geral (por instrumento)

Aplicar uma linha por instrumento (`YSQ_FOUNDATION_V1`, `YAMI_MODES_FOUNDATION_V1`).

| Critério | YSQ_FOUNDATION_V1 | YAMI_MODES_FOUNDATION_V1 | Notas |
|----------|-------------------|--------------------------|-------|
| Nome do instrumento adequado (código + nome exibido) | ☐ | ☐ | YSQ: “YSQ — Fundação (Esquemas)”; YAMI: “YAMI — Modos Esquemáticos Foundation v1” |
| Correspondência com instrumento oficial (YSQ-S3 / SMI 1.1) | ☐ | ☐ | Confirmar manual/autor vs. planilha do projeto |
| Licença / autorização de uso (Young, SMI, tradução) | ☐ | ☐ | **Pendente** — ver tabela de pendências |
| Escala correta (min/max e rótulos) | ☐ | ☐ | Ambos: **1–6** no banco |
| Instruções ao respondente corretas | ☐ | ☐ | `questionnaire_versions.instructions` |
| Faixas de severidade corretas (labels e cortes) | ☐ | ☐ | Baixo 1,0–2,4; Médio 2,5–3,9; Ativado 4,0–5,0 |
| Regras de pontuação (mapeamento item → constructo) | ☐ | ☐ | `question_scoring_rules` |
| **Reverse score** confirmado (item a item) | ☐ | ☐ | Banco: **todos `false`** (planilha não informa) |
| **Pesos** confirmados | ☐ | ☐ | Banco: **todos peso 1** (planilha não informa) |
| Versão `v1-foundation` pode permanecer **active** | ☐ | ☐ | Nova versão se correção quebrar comparabilidade |
| Uso terapêutico oficial autorizado | ☐ | ☐ | Até lá: apenas validação / homologação |

---

## 2. Checklist YSQ (`YSQ_FOUNDATION_V1`)

**Banco:** `questionnaires.code = YSQ_FOUNDATION_V1`  
**Migration:** `20250531140014_seed_real_ysq_foundation.sql`  
**Versão active:** `v1-foundation` (`77777777-7777-7777-7777-777777777801`)

### 2.1 Estrutura importada

| Item | Esperado (planilha) | No banco | Validado |
|------|---------------------|----------|----------|
| Domínios (`schema_domains`) | 5 | 5 | ☐ |
| Esquemas (`schemas`) | 18 | 18 | ☐ |
| Perguntas (`questions`) | 90 | 90 | ☐ |
| Regras (`question_scoring_rules`) | 90 (1:1) | 90 | ☐ |
| Faixas (`severity_ranges`) | 54 (3 × 18 esquemas) | 54 | ☐ |

### 2.2 Domínios — validar nomes

| code SQL | Nome importado | ☐ OK | Observação clínica |
|----------|----------------|------|-------------------|
| `YSQ_DOMAIN_DISCONNECTION_REJECTION` | Primeiro Domínio-Desconexão e rejeição | ☐ | |
| `YSQ_DOMAIN_IMPAIRED_AUTONOMY` | Segundo Domínio-Autonomia e Desempenho prejudicados | ☐ | |
| `YSQ_DOMAIN_IMPAIRED_LIMITS` | Terceiro Domínio-Limites prejudicados | ☐ | Só **2** esquemas — completo? |
| `YSQ_DOMAIN_OTHER_DIRECTEDNESS` | Quarto Domínio-Direcionamento para o outro | ☐ | |
| `YSQ_DOMAIN_OVERVIGILANCE_INHIBITION` | Quinto Domínio-Supervigilância e Inibição | ☐ | |

### 2.3 Esquemas — validar nomes (18)

| # | Nome importado | Domínio | ☐ OK |
|---|----------------|---------|------|
| 1 | Abandono/Instabilidade | Desconexão e rejeição | ☐ |
| 2 | Desconfiança/Abuso | Desconexão e rejeição | ☐ |
| 3 | Privação emocional | Desconexão e rejeição | ☐ |
| 4 | Defectividade/Vergonha | Desconexão e rejeição | ☐ |
| 5 | Isolamento social/Alienação | Desconexão e rejeição | ☐ |
| 6 | Dependência/Incompetência | Autonomia e Desempenho prejudicados | ☐ |
| 7 | Vulnerabilidade ao dano ou doença | Autonomia e Desempenho prejudicados | ☐ |
| 8 | Emaranhamento/Self subdesenvolvido | Autonomia e Desempenho prejudicados | ☐ |
| 9 | Fracasso | Autonomia e Desempenho prejudicados | ☐ |
| 10 | Merecimento/Grandiosidade | Limites prejudicados | ☐ |
| 11 | Autocontrole/Autodisciplina insuficientes | Limites prejudicados | ☐ |
| 12 | Subjugação | Direcionamento para o outro | ☐ |
| 13 | Autos sacrifico | Direcionamento para o outro | ☐ |
| 14 | Busca de aprovação/Reconhecimento | Direcionamento para o outro | ☐ |
| 15 | Negativismo/Pessimismo | Supervigilância e Inibição | ☐ |
| 16 | Inibição emocional | Supervigilância e Inibição | ☐ |
| 17 | Padrões inflexíveis/Crítica exagerada | Supervigilância e Inibição | ☐ |
| 18 | Postura punitiva | Supervigilância e Inibição | ☐ |

### 2.4 Item → esquema (90 itens)

| Critério | Validado |
|----------|----------|
| Cada item 1–90 mapeado ao esquema correto (manual YSQ-S3) | ☐ |
| 5 itens por esquema (18 × 5 = 90) | ☐ |
| Textos dos itens conferidos com instrumento oficial | ☐ |
| Amostragem: revisar itens 1, 18, 45, 90 (mínimo) | ☐ |
| Revisão completa dos 90 itens | ☐ |

Consulta SQL (homologação):

```sql
SELECT q.code, q.order_index, s.name AS schema_name, d.name AS domain_name
FROM question_scoring_rules r
JOIN questions q ON q.id = r.question_id
JOIN schemas s ON s.id = r.schema_id
JOIN schema_domains d ON d.id = r.domain_id
WHERE r.questionnaire_version_id = '77777777-7777-7777-7777-777777777801'
ORDER BY q.order_index;
```

### 2.5 Escala e faixas

| Critério | Estado no banco | Validado |
|----------|-----------------|----------|
| Escala Likert 1–6 | `scale_min=1`, `scale_max=6` | ☐ |
| Rótulos 1–6 (planilha col. E–J) | Metadado na planilha; app usa escala numérica | ☐ |
| Faixas Baixo / Médio / Ativado por esquema | 1,0–2,4 / 2,5–3,9 / 4,0–5,0 | ☐ |
| Label “Ativado” aceito clinicamente | Literal da planilha | ☐ |

### 2.6 Pontuação

| Critério | Estado no banco | Validado |
|----------|-----------------|----------|
| Peso = 1 em todos os itens | Sim | ☐ |
| `reverse_score = false` em todos | Sim | ☐ |
| Algum item exige reverse no YSQ-S3 oficial | ☐ N/A / ☐ Sim (listar) | |

---

## 3. Checklist YAMI (`YAMI_MODES_FOUNDATION_V1`)

**Banco:** `questionnaires.code = YAMI_MODES_FOUNDATION_V1`  
**Migration:** `20250531150015_seed_yami_modes_foundation.sql`  
**Versão active:** `v1-foundation` (`88888888-8888-8888-8888-888888888801`)  
**Modelagem:** modos → tabela `schemas` (domínio único `YAMI_DOMAIN_SCHEMA_MODES`)

### 3.1 Estrutura importada

| Item | Esperado (planilha) | No banco | Validado |
|------|---------------------|----------|----------|
| Modos (`schemas`) | 19 rótulos distintos | 19 | ☐ |
| Perguntas | 124 | 124 | ☐ |
| Regras | 124 | 124 | ☐ |
| Faixas | 57 (3 × 19 modos) | 57 | ☐ |

### 3.2 Modo → item — validar mapeamento

| Critério | Validado |
|----------|----------|
| Cada item 1–124 atribuído ao modo correto (SMI 1.1) | ☐ |
| Itens sem modo na coluna B usam último modo preenchido (regra da importação) | ☐ |
| Textos conferidos com SMI / tradução autorizada | ☐ |
| Amostragem: itens 1, 50, 100, 124 | ☐ |
| Revisão completa 124 itens | ☐ |

Consulta SQL:

```sql
SELECT q.code, q.order_index, s.code AS mode_code, s.name AS mode_name
FROM question_scoring_rules r
JOIN questions q ON q.id = r.question_id
JOIN schemas s ON s.id = r.schema_id
WHERE r.questionnaire_version_id = '88888888-8888-8888-8888-888888888801'
ORDER BY q.order_index;
```

### 3.3 Grafias duplicadas e typos (revisão obrigatória)

| Modo no banco (`YAMI_MODE_*`) | Nome importado | Itens | ☐ Unificar? | ☐ Manter separado? |
|------------------------------|----------------|-------|-------------|-------------------|
| 02 | Criança  Feliz (espaço duplo) | 1 | ☐ | ☐ |
| 11 | Criança Feliz | 8 | ☐ | ☐ |
| 15 | Autoconfortador Desligado | 1 | ☐ | ☐ |
| 16 | Auto Confortador Desligado | 1 | ☐ | ☐ |
| 17 | Auto Confortador desligada | 1 | ☐ | ☐ |
| 18 | **Ciança** Vulnerável | 1 | ☐ | ☐ |
| 19 | **Ciança** Feliz | 1 | ☐ | ☐ |

### 3.4 Modos com poucos ou muitos itens

| code | Modo | Itens | ☐ Distribuição OK? |
|------|------|-------|-------------------|
| 01 | Intimidação e Ataque | 1 | ☐ |
| 02 | Criança  Feliz | 1 | ☐ |
| 03 | Pais Punitivos | 10 | ☐ |
| 04 | Criança Vulnerável | 9 | ☐ |
| 05 | Pais Exigentes e Críticos | 10 | ☐ |
| 06 | Vencido Submisso | 2 | ☐ |
| 07 | Auto Engrandecedor | 10 | ☐ |
| 08 | Criança Impulsiva | 2 | ☐ |
| 09 | Criança Indisciplinada | 6 | ☐ |
| 10 | Criança Raivosa | 10 | ☐ |
| 11 | Criança Feliz | 8 | ☐ |
| 12 | Adulto Saudável | 10 | ☐ |
| 13 | Criança Zangada | 1 | ☐ |
| 14 | Protetor Desligado | 7 | ☐ |
| 15–19 | Confortador / Ciança (ver §3.3) | 1 cada | ☐ |

### 3.5 Escala e faixas

| Critério | Estado no banco | Validado |
|----------|-----------------|----------|
| Frequência 1–6 (Nunca… → O tempo todo) | 1–6 | ☐ |
| Instruções (SMI) | Texto `INSTRUÇÕES:` da planilha | ☐ |
| Faixas Baixo / Médio / Ativado por modo | Igual YSQ | ☐ |

### 3.6 Pontuação

| Critério | Estado no banco | Validado |
|----------|-----------------|----------|
| Peso = 1 em todos os itens | Sim | ☐ |
| `reverse_score = false` em todos | Sim | ☐ |
| SMI oficial define reverse/pesos por item | ☐ Ver manual | |

---

## 4. Tabela de pendências

Preencher **decisão clínica** e **ação técnica** após reunião de validação. Status inicial: reflete análise da importação (maio/2026).

| ID | Item | Instrumento | Problema | Decisão clínica | Ação técnica necessária | Status |
|----|------|-------------|----------|-----------------|-------------------------|--------|
| P01 | Licenciamento YSQ-S3 | YSQ | Uso terapêutico não documentado no repo | ☐ Pendente | Arquivar licença; só então marcar instrumento “oficial” | Aberto |
| P02 | Licenciamento SMI 1.1 | YAMI | Rodapé planilha cita Young; licença não verificada | ☐ Pendente | Idem P01 | Aberto |
| P03 | Nome `YSQ_FOUNDATION_V1` vs YSQ-S3 | YSQ | Código interno pode não coincidir com publicação | ☐ Pendente | Renomear código só via migration se necessário | Aberto |
| P04 | Domínio Limites com 2 esquemas | YSQ | Menos esquemas que outros domínios na planilha | ☐ Pendente | Confirmar completude YSQ-S3 | Aberto |
| P05 | Grafia `Autos sacrifico` | YSQ | Possível typo | ☐ Pendente | Migration correção texto + metadata | Aberto |
| P06 | Label faixa `Ativado` | YSQ, YAMI | Nomenclatura não usual | ☐ Pendente | Atualizar `severity_ranges.label` se aprovado | Aberto |
| P07 | Duplicata `Criança  Feliz` / `Criança Feliz` | YAMI | Dois modos, 1 vs 8 itens | ☐ Pendente | Unificar modos + remapear regras (nova versão?) | Aberto |
| P08 | Typos `Ciança` Vulnerável / Feliz | YAMI | Grafia incorreta na planilha | ☐ Pendente | Corrigir `schemas.name` ou unificar | Aberto |
| P09 | Três grafias Confortador Desligado | YAMI | 15, 16, 17 — modos distintos com 1 item | ☐ Pendente | Unificar em um modo | Aberto |
| P10 | Modos com 1 item apenas | YAMI | 01, 02, 13, 15–19 | ☐ Pendente | Confirmar se erro de planilha ou SMI | Aberto |
| P11 | Reverse scoring | YSQ, YAMI | Planilha não especifica; banco `false` | ☐ Pendente | Atualizar `question_scoring_rules` se manual exigir | Aberto |
| P12 | Pesos ≠ 1 | YSQ, YAMI | Planilha não especifica; banco peso 1 | ☐ Pendente | Atualizar regras se manual exigir | Aberto |
| P13 | Modos em `schemas` vs entidade Modo | YAMI | Semântica UI “esquemas” | ☐ Aceitar / ☐ Documentar | Copy Flutter futura; sem mudança DB obrigatória | Aberto |
| P14 | `question_category_items` vazio | YSQ, YAMI | Legado MVP sem categorias | ☐ Pendente | Opcional: seed categorias legado | Aberto |
| P15 | Planilha fora do repo | Ambos | Fonte em `~/Documents/` | ☐ Pendente | Copiar para `docs/scoring-engine/sources/` versionado | Aberto |

---

## 5. Orientação para correções técnicas

### 5.1 Princípios

1. **Só criar migrations de correção** depois que a linha na tabela de pendências tiver **decisão clínica** e responsável assinado.
2. **Não alterar** `questions`, `question_scoring_rules`, `severity_ranges` ou versões **active** manualmente no Supabase Studio sem migration versionada.
3. Se a correção mudar texto de item, mapeamento ou faixas de forma que invalide resultados já calculados:
   - Arquivar versão atual: `UPDATE questionnaire_versions SET status = 'archived' WHERE id = …`
   - Inserir nova versão (`v1.1-correcao-…`) com `published_at` e regras corrigidas
   - Manter questionário `code` estável (`YSQ_FOUNDATION_V1`) quando possível
4. **Não** reimportar Excel direto em produção sem diff revisado e migration idempotente.
5. Motor (`finish-questionnaire`) e Flutter **não** precisam mudar para correções de catálogo — apenas dados.

### 5.2 Tipos de migration de correção (exemplos)

| Tipo de correção | Exemplo de migration |
|----------------|----------------------|
| Texto de pergunta | `UPDATE questions SET text = … WHERE id = …` |
| Unificar modos YAMI | `UPDATE question_scoring_rules SET schema_id = …`, depois `DELETE` schemas duplicados |
| Reverse / peso | `UPDATE question_scoring_rules SET reverse_score = true, weight = …` |
| Faixas | `UPDATE severity_ranges SET label, min_score, max_score = …` |
| Nova versão | `INSERT questionnaire_versions` + regras; archive anterior |

### 5.3 Critérios para liberar uso clínico oficial

Todos devem estar ☑:

- [ ] P01 e P02 (licenciamento) resolvidos ou uso limitado a pesquisa interna documentada
- [ ] Checklists §2 e §3 revisados (amostragem mínima + decisão sobre itens críticos P04–P10)
- [ ] Nenhuma pendência **Aberta** com impacto alto sem plano de correção
- [ ] Homologação app: seguir [clinical-homologation.md](./clinical-homologation.md) (paciente completa; staff vê snapshot + tabela §4 preenchida)
- [ ] Registro em prontuário: interpretação é responsabilidade do psicólogo (já refletido no Flutter)

### 5.4 O que permanece fora deste checklist

- `MVP_DEMO` — demonstrativo; validação clínica separada (não oficial)
- Interpretação textual automática, PDF, dashboard, IA
- Outras abas da planilha (Personalidade, Apego, Parentais)

---

## Histórico de revisões

| Data | Revisor | Resumo |
|------|--------|--------|
| 2026-05-31 | — | Documento criado; pendências iniciais da importação 014/015 |
