# Relatório de importação — YSQ-Esquemas

**Data da extração:** 2026-05-31  
**Fonte:** `/Users/starkbfs/Documents/ProjetoApp_questionários.xlsx` (aba `YSQ-Esquemas`)  
**Migration gerada:** `supabase/migrations/20250531140014_seed_real_ysq_foundation.sql`  
**Questionário no banco:** `YSQ_FOUNDATION_V1` (`77777777-7777-7777-7777-777777777301`)

## Resumo quantitativo

| Entidade | Quantidade importada | Observação |
|----------|----------------------|------------|
| Domínios (`schema_domains`) | **5** | Coluna B, linhas com padrão `Primeiro…Quinto Domínio-` |
| Esquemas (`schemas`) | **18** | Coluna C; 5 itens cada |
| Perguntas (`questions`) | **90** | Coluna D, itens numerados 1–90 |
| Versão (`questionnaire_versions`) | **1** | `v1-foundation`, `active`, escala 1–6 |
| Regras (`question_scoring_rules`) | **90** | 1:1 pergunta → esquema; peso 1 |
| Faixas (`severity_ranges`) | **54** | 3 faixas × 18 esquemas |

## Escala (planilha)

Rótulos na linha 2 (colunas E–J), valores **1 a 6**:

| Valor | Rótulo na planilha |
|-------|-------------------|
| 1 | Interamente Falsa |
| 2 | Em grande parte falsa |
| 3 | Levemente mais verdadeira do que falsa |
| 4 | Moderadamente verdadeira |
| 5 | Em grande parte verdadeira |
| 6 | Descreve perfeitamente |

## Faixas de severidade (planilha → `severity_ranges`)

Aplicadas **por esquema** (média ponderada 1–6, mesma lógica do motor DEMO):

| Label (planilha) | min_score | max_score |
|------------------|-----------|-----------|
| Baixo | 1,0 | 2,4 |
| Médio | 2,5 | 3,9 |
| Ativado | 4,0 | 5,0 |

## Domínios importados

| code (SQL) | Nome (planilha) |
|------------|-----------------|
| `YSQ_DOMAIN_DISCONNECTION_REJECTION` | Primeiro Domínio-Desconexão e rejeição |
| `YSQ_DOMAIN_IMPAIRED_AUTONOMY` | Segundo Domínio-Autonomia e Desempenho prejudicados |
| `YSQ_DOMAIN_IMPAIRED_LIMITS` | Terceiro Domínio-Limites prejudicados |
| `YSQ_DOMAIN_OTHER_DIRECTEDNESS` | Quarto Domínio-Direcionamento para o outro |
| `YSQ_DOMAIN_OVERVIGILANCE_INHIBITION` | Quinto Domínio-Supervigilância e Inibição |

## Esquemas importados (18)

| # | Nome (planilha) | Domínio |
|---|-----------------|---------|
| 1 | Abandono/Instabilidade | Desconexão e rejeição |
| 2 | Desconfiança/Abuso | Desconexão e rejeição |
| 3 | Privação emocional | Desconexão e rejeição |
| 4 | Defectividade/Vergonha | Desconexão e rejeição |
| 5 | Isolamento social/Alienação | Desconexão e rejeição |
| 6 | Dependência/Incompetência | Autonomia e Desempenho prejudicados |
| 7 | Vulnerabilidade ao dano ou doença | Autonomia e Desempenho prejudicados |
| 8 | Emaranhamento/Self subdesenvolvido | Autonomia e Desempenho prejudicados |
| 9 | Fracasso | Autonomia e Desempenho prejudicados |
| 10 | Merecimento/Grandiosidade | Limites prejudicados |
| 11 | Autocontrole/Autodisciplina insuficientes | Limites prejudicados |
| 12 | Subjugação | Direcionamento para o outro |
| 13 | Autos sacrifico | Direcionamento para o outro |
| 14 | Busca de aprovação/Reconhecimento | Direcionamento para o outro |
| 15 | Negativismo/Pessimismo | Supervigilância e Inibição |
| 16 | Inibição emocional | Supervigilância e Inibição |
| 17 | Padrões inflexíveis/Crítica exagerada | Supervigilância e Inibição |
| 18 | Postura punitiva | Supervigilância e Inibição |

## Itens **não** importados

| Item | Motivo |
|------|--------|
| Abas `Visão geral`, `YAMI-Modos…`, `Personalidade`, `Estilos de Apego`, `Estilos Parentais` | Fora do escopo desta carga (somente `YSQ-Esquemas`) |
| 3 linhas de instrução ao respondente (col. B, após item 90) | Texto agregado em `questionnaire_versions.instructions`, não são domínios |
| Cabeçalhos Likert (col. E–J linha 2) | Metadados de escala; valores 1–6 aplicados em `questions` e regras |
| `reverse_score` por item | **Não consta** na aba; todas as regras com `reverse_score = false` |
| Pesos diferentes de 1 | **Não consta** na aba; peso 1 em todas as regras |
| `question_categories` / `question_category_items` | Legado MVP; não alterado nesta migration |
| Seed `MVP_DEMO` / catálogo `6666…` | Preservados (sem remoção) |
| Colunas vazias / formatação Excel (col. > D) | Sem dados de apuração |

## Dúvidas e pontos para validação clínica

1. **Nome do instrumento:** código `YSQ_FOUNDATION_V1` indica fundação a partir da planilha do projeto — confirmar se corresponde ao **YSQ-S3** oficial (número de itens 90 e 18 esquemas × 5 itens é compatível com YSQ-S3).
2. **Grafia na planilha:** `Autos sacrifico` (item de esquema) — manter grafia da fonte ou corrigir para “Auto sacrifício”?
3. **Domínio “Limites prejudicados”:** apenas **2** esquemas na planilha (Merecimento/Grandiosidade; Autocontrole/…) vs 4–5 nos outros domínios — confirmar se está completo.
4. **Faixa “Ativado”** vs nomenclatura clínica usual (“Alto” / “Clínico”) — labels importados **literalmente** da planilha.
5. **Licenciamento / uso terapêutico:** migration inclui aviso na descrição do questionário; parecer jurídico/clínico pendente.
6. **`questionnaire_versions.status = active`:** coexistência com `MVP_DEMO` é segura (questionários distintos); app deve listar ambos se `is_active`.
7. **Snapshot Flutter:** banner “demonstrativo” ainda aparece para qualquer `scoring-demo-1`-compatible snapshot — copy específica para YSQ real é tarefa futura.
8. **Arquivo fora do repo:** planilha lida em `Documents/`; recomenda-se copiar versão versionada para `docs/scoring-engine/sources/` quando autorizado.

## UUIDs fixos (prefixo `77777777-…`)

| Recurso | ID |
|---------|-----|
| Questionário | `77777777-7777-7777-7777-777777777301` |
| Versão | `77777777-7777-7777-7777-777777777801` |
| Domínios | `…7601` – `…7605` |
| Esquemas | `…7710` – `…7727` |
| Perguntas | `…7501` – `…7590` |
| Regras | `…7901` – `…7990` |

## Como aplicar

```bash
# Local (Docker)
supabase db reset

# Remoto
supabase db push
```

## Regenerar migration a partir da planilha

Reexecutar o script de geração (ajustar caminho do Excel se necessário) ou editar manualmente a migration após revisão clínica.
