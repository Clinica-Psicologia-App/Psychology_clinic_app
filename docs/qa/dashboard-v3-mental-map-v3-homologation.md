# QA e homologação — Dashboard v3 + Mapa Mental v3

**Data:** 2026-06-07  
**Escopo:** validação de experiência clínica, usabilidade e consistência visual das fatias implementadas em Flutter.  
**Fora de escopo desta rodada:** alteração de banco, scoring, Edge Functions, catálogo de questionários, D2/D4/D5 do dashboard (comparativo, domínios YSQ expandidos), IA e inferência automática.

**Specs de referência:**

- [dashboard-v3-spec.md](../product/dashboard-v3-spec.md) — D1 + D3 entregues; D2/D4/D5 pendentes
- [mental-map-v3-spec.md](../product/mental-map-v3-spec.md) — M1–M5 entregues
- [mobile-app.md](../mobile-app.md) — rotas e comportamento por módulo

**Homologação MVP anterior:** [final-mvp-homologation.md](../demo/final-mvp-homologation.md)

---

## Pré-requisitos

| Item | Comando / ação |
|------|----------------|
| Backend local | `supabase start` · `supabase db reset` · `supabase functions serve` |
| App mobile | `cd mobile && flutter pub get && flutter run --dart-define-from-file=env.local.json` |
| Automação baseline | `cd mobile && flutter test` (esperado: **197** testes OK) |
| Contas seed | Ver [final-mvp-homologation.md §4](../demo/final-mvp-homologation.md) — senha `TesteMVP2025!` |

**Rotas principais:**

| Módulo | Paciente | Staff |
|--------|----------|-------|
| Dashboard v3 | `/patient/clinical-dashboard` | `/{admin\|psychologist}/patients/:patientId/clinical-dashboard` |
| Mapa Mental v3 | `/patient/mental-map` | `/{admin\|psychologist}/patients/:patientId/mental-map` |

**Papéis na homologação:** executar cada cenário como **paciente** e **psicólogo** quando aplicável. Staff deve validar dados agregados do paciente Maria Silva (`11111111-1111-1111-1111-111111111201`).

**Como simular cenários parciais:** usar paciente recém-criado (sem instrumentos) ou desmarcar dados no roteiro manual; para instrumentos isolados, concluir apenas o questionário desejado e validar degradación graciosa nos demais painéis.

---

## 1. Checklist Dashboard v3

Legenda: `[ ]` pendente · `[x]` OK · `[!]` falha · `[—]` N/A

### 1.1 Automação e smoke

- [ ] `flutter test` verde antes da sessão manual
- [ ] Dashboard abre sem crash (paciente e staff)
- [ ] Banner *Dashboard em validação clínica* visível
- [ ] Pull-to-refresh / botão atualizar funciona
- [ ] Empty state central quando caso sem dados clínicos

### 1.2 Paciente sem dados

**Setup:** paciente novo ou Maria Silva sem problemas/objetivos/instrumentos concluídos.

| # | Verificação | Esperado |
|---|-------------|----------|
| D0.1 | Header executivo (nome, KPIs) | Zeros ou labels neutros; sem crash |
| D0.2 | Prioridades YSQ/YAMI/apego/enfrentamento | Chips ou painéis vazios com hint |
| D0.3 | Sinais recentes | Empty seguro (sem check-in / timeline) |
| D0.4 | Callouts orientativos | Sugestões de instrumentos/check-in pendentes, **sem interpretação clínica** |
| D0.5 | Parentais (D3) | Seção oculta ou empty se sem `PARENTAL_STYLES_V1` |
| D0.6 | Detalhes colapsáveis por instrumento | Expandem com empty + CTA trilha/questionários |
| D0.7 | Trilha *Dashboard clínico* | Disponível (sem resultados estruturados) |

### 1.3 Paciente com YSQ

**Setup:** `YSQ_FOUNDATION_V1` concluído com snapshot estruturado.

| # | Verificação | Esperado |
|---|-------------|----------|
| D-YSQ.1 | Top 3 esquemas no grid de prioridades | Nomes + scores coerentes com resultado staff |
| D-YSQ.2 | Mini-barras / destaques YSQ | Ordem decrescente por score |
| D-YSQ.3 | Seção YSQ colapsável | Barras completas ao expandir |
| D-YSQ.4 | KPI instrumentos | Contagem reflete resposta concluída |
| D-YSQ.5 | Staff — histórico rápido | Data da última aplicação visível |
| D-YSQ.6 | Sem YAMI | Painel YAMI permanece empty (não quebra layout) |

### 1.4 Paciente com YAMI

**Setup:** `YAMI_MODES_FOUNDATION_V1` concluído.

| # | Verificação | Esperado |
|---|-------------|----------|
| D-YAMI.1 | Top 3 modos no grid de prioridades | Coerente com snapshot |
| D-YAMI.2 | Seção YAMI colapsável | Barras de modos visíveis |
| D-YAMI.3 | Trilha *Dashboard clínico* | Em andamento |

### 1.5 Paciente com Apego

**Setup:** `ATTACHMENT_STYLES_V1` concluído.

| # | Verificação | Esperado |
|---|-------------|----------|
| D-ATT.1 | Chip/painel de apego nas prioridades | Estilos principais com score |
| D-ATT.2 | Seção Apego colapsável | Barras ou lista estruturada |
| D-ATT.3 | Empty gracioso se único instrumento | Demais seções não quebram |

### 1.6 Paciente com YCI

**Setup:** `YCI_FOUNDATION_V1` concluído.

| # | Verificação | Esperado |
|---|-------------|----------|
| D-YCI.1 | Painel enfrentamento (YCI) | Destaque YCI Geral ou schemas top |
| D-YCI.2 | Seção YCI colapsável | Scores legíveis |
| D-YCI.3 | Com YRAI junto | Ambos aparecem no bloco enfrentamento |

### 1.7 Paciente com YRAI

**Setup:** `YRAI_FOUNDATION_V1` concluído.

| # | Verificação | Esperado |
|---|-------------|----------|
| D-YRAI.1 | Painel enfrentamento (YRAI) | Destaque coerente com snapshot |
| D-YRAI.2 | Seção YRAI colapsável | Dados sem recálculo |

### 1.8 Paciente com Parentais

**Setup:** `PARENTAL_STYLES_V1` concluído com `snapshot.contexts[]` (múltiplas figuras).

| # | Verificação | Esperado |
|---|-------------|----------|
| D-PAR.1 | Seção D3 — estilos parentais por figura | Chip/card por figura (Mãe, Pai, etc.) |
| D-PAR.2 | Top score por figura | Maior schema por contexto |
| D-PAR.3 | Contagem respondida | Itens/completion quando disponível no snapshot |
| D-PAR.4 | Sem inferência entre figuras | Apenas dados registrados |

### 1.9 Paciente com Timeline

**Setup:** ≥ 1 evento em `patient_timeline_events`.

| # | Verificação | Esperado |
|---|-------------|----------|
| D-TL.1 | Sinais recentes — evento timeline | Título + data/período |
| D-TL.2 | Evento sensível | Indicador visual (ícone/borda); título conforme policy v3 |
| D-TL.3 | Sem check-in | Timeline ainda aparece; check-in empty separado |

### 1.10 Paciente com Check-ins

**Setup:** ≥ 1 check-in registrado (ideal: hoje + histórico).

| # | Verificação | Esperado |
|---|-------------|----------|
| D-CI.1 | KPI check-in no header | Humor/ansiedade/energia ou “sem check-in” |
| D-CI.2 | Sinais recentes | Valores numéricos do último registro |
| D-CI.3 | Callout check-in ausente | Aparece se > 7 dias sem registro |
| D-CI.4 | Staff | Somente leitura (sem criar check-in na UI staff) |

### 1.11 Caso completo (regressão integrada)

**Setup:** Maria Silva seed + instrumentos + problemas + objetivos + timeline + check-in.

| # | Verificação | Esperado |
|---|-------------|----------|
| D-FULL.1 | Visão executiva coesa | Header + prioridades + sinais preenchidos |
| D-FULL.2 | Scroll longo | Sem overflow; seções colapsáveis reduzem altura |
| D-FULL.3 | Personalidade | Placeholder ou empty (fora de escopo v3) |
| D-FULL.4 | Paciente vs staff | Mesma estrutura; staff com histórico expandido |

---

## 2. Checklist Mapa Mental v3

### 2.1 Automação e smoke

- [ ] Mapa abre sem crash (paciente e staff)
- [ ] Banner *Mapa mental em construção* / disclaimer visível
- [ ] Pull-to-refresh funciona
- [ ] Empty state quando `mentalMapHasRelevantData == false`

### 2.2 Hub completo (M1)

**Setup:** caso com dados em todos os 8 nós.

| # | Verificação | Esperado |
|---|-------------|----------|
| M-HUB.1 | Centro clínico | Nome + problemas/objetivos ativos + último check-in |
| M-HUB.2 | Anel principal | Esquemas · Modos · Problemas · Objetivos |
| M-HUB.3 | Anel contextual | Apego · Enfrentamento · Parentais · História/Vínculos |
| M-HUB.4 | Status preenchido/pendente | Borda sólida vs tracejada + ícone |
| M-HUB.5 | Até 3 itens por nó | Truncamento com ellipsis |
| M-HUB.6 | Hub parcial (4/8 nós) | Layout estável; nós vazios como *Pendente* |
| M-HUB.7 | Hub vazio | Centro + 8 nós tracejados; mensagem formação |

### 2.3 Tab Núcleo (M2)

| # | Verificação | Esperado |
|---|-------------|----------|
| M-NUC.1 | Top esquemas YSQ | Até 5 com barras; data última aplicação |
| M-NUC.2 | Top modos YAMI | Idem |
| M-NUC.3 | Problemas por intensidade | Top 3 ordenados |
| M-NUC.4 | Apego / enfrentamento | Aparecem se houver snapshot |
| M-NUC.5 | Empty tab | Painel empty + hint; sem crash |
| M-NUC.6 | Aviso anti-inferência | Texto estático sobre origem dos dados |
| M-NUC.7 | CTA dashboard clínico | Navega para rota correta |

### 2.4 Tab História (M3)

| # | Verificação | Esperado |
|---|-------------|----------|
| M-HIS.1 | Timeline top 5 | Cronologia; impacto emocional quando não sensível |
| M-HIS.2 | Genograma resumido | Contagem pessoas/relações + amostra |
| M-HIS.3 | Parentais por figura | Chips figura — estilo dominante |
| M-HIS.4 | Apego predominante | Badge quando ATTACHMENT concluído |
| M-HIS.5 | Itens sensíveis | Título mascarado + ícone cadeado |
| M-HIS.6 | CTAs timeline / genograma | Rotas corretas paciente vs staff |
| M-HIS.7 | Empty tab | CTAs para módulos de origem |

### 2.5 Tab Plano (M4)

| # | Verificação | Esperado |
|---|-------------|----------|
| M-PLN.1 | Objetivos ativos | Título + data meta |
| M-PLN.2 | Problemas ativos | Proximidade visual; **sem setas causais** |
| M-PLN.3 | Sparkline check-in | Aparece com ≥ 2 check-ins; oculto com 1 |
| M-PLN.4 | Séries humor/ansiedade/energia | CustomPainter; gaps para valores null |
| M-PLN.5 | Recursos terapêuticos | Contagem liberados/concluídos se houver |
| M-PLN.6 | Empty tab | Hint + CTA objetivos |
| M-PLN.7 | Aviso anti-inferência | Objetivos ≠ problemas linkados automaticamente |

### 2.6 Bottom sheets (M5)

| # | Verificação | Esperado |
|---|-------------|----------|
| M-BS.1 | Toque em nó preenchido | Sheet com título, itens, origem, data |
| M-BS.2 | Toque em nó pendente | Sheet empty + CTA módulo |
| M-BS.3 | CTA primário | Dashboard / problemas / objetivos / timeline conforme nó |
| M-BS.4 | CTA secundário staff | Ver resultado quando `responseId` existe |
| M-BS.5 | Fechar sheet | Drag handle + navegação não quebra estado |

### 2.7 CTAs e navegação

| # | Verificação | Esperado |
|---|-------------|----------|
| M-NAV.1 | Esquemas/Modos/Apego/Enfrent./Parentais → dashboard | Rota staff com `patientId` |
| M-NAV.2 | Problemas → problemas | Lista correta |
| M-NAV.3 | Objetivos → objetivos | Lista correta |
| M-NAV.4 | História → timeline + genograma | Primário timeline; secundário genograma |
| M-NAV.5 | Cards resumo por módulo (abaixo) | *Ver detalhes* mantidos da v2 |
| M-NAV.6 | Paciente não acessa rotas staff | Redirect conforme `route_access_test` |

### 2.8 Responsividade

| # | Verificação | Esperado |
|---|-------------|----------|
| M-RES.1 | Largura < 560px | Hub em grid scrollável; tabs legíveis |
| M-RES.2 | Largura 560–900px | Hub radial 8 nós |
| M-RES.3 | Tab Núcleo tablet | YSQ | YAMI lado a lado se ≥ 640px |
| M-RES.4 | Tab Plano tablet | Objetivos | Problemas lado a lado se ≥ 560px |
| M-RES.5 | Textos longos | Ellipsis; sem overflow amarelo |

---

## 3. Checklist visual

| # | Área | Verificação | Dispositivo / condição | Esperado |
|---|------|-------------|------------------------|----------|
| V1 | Overflow | Dashboard scroll completo | Phone pequeno (~360×640) | Sem faixas amarelas |
| V2 | Overflow | Mapa hub + tabs + cards | Phone pequeno | Grid scrollável; tabs não cortadas |
| V3 | Textos longos | Nome paciente 40+ chars | Qualquer | Ellipsis no centro do hub |
| V4 | Textos longos | Esquema/modo nome longo | Dashboard + Mapa | Truncamento em barras e nós |
| V5 | Textos longos | Título problema/objetivo | Tabs Plano/Núcleo | maxLines + ellipsis |
| V6 | Dark mode | Tema escuro | **N/A** | App usa apenas `AppTheme.light` — registrar como pendência de produto se necessário |
| V7 | Tablet | Dashboard layout | ≥ 768px | Prioridades em duas colunas quando previsto |
| V8 | Tablet | Mapa radial | ≥ 560px | 8 nós visíveis sem sobreposição crítica |
| V9 | Dispositivo pequeno | Segmented control tabs | < 360px | Scroll horizontal ou quebra de linha aceitável |
| V10 | Consistência | Cores severity / chips | Dashboard vs Mapa | Mesma paleta Material 3 |
| V11 | Consistência | Banners disclaimer | Ambos módulos | Sempre visíveis no topo |
| V12 | Consistência | Empty panels | HomologationEmptyPanel | Ícone + título + hint uniformes |
| V13 | Acessibilidade | Contraste chips/bordas | Light theme | Legível em sol direto (smoke) |
| V14 | Animação | Tab switch Mapa | — | AnimatedSwitcher suave; sem flicker |

---

## 4. Checklist clínico

Preencher com psicóloga homologadora. Escala: **Útil** · **Redundante** · **Ausente** · **Confuso**

### 4.1 Utilidade clínica

| # | Pergunta | Dashboard | Mapa | Notas |
|---|----------|-----------|------|-------|
| C1 | A visão executiva ajuda a preparar sessão em < 2 min? | | | |
| C2 | Prioridades YSQ/YAMI refletem o que importa no caso? | | | |
| C3 | Parentais por figura são claros para formulação? | | | |
| C4 | O hub do mapa comunica “formulação visual” do caso? | | | |
| C5 | Tab Núcleo substitui abrir YSQ/YAMI separados? | | | |
| C6 | Tab História integra timeline + genograma + parentais? | | | |
| C7 | Tab Plano + sparkline apoiam acompanhamento semanal? | | | |
| C8 | Bottom sheet dá detalhe suficiente antes de ir ao módulo? | | | |

### 4.2 Redundância

| # | Pergunta | Avaliação | Ação sugerida |
|---|----------|-----------|---------------|
| C9 | Cards resumo por módulo abaixo do mapa repetem tabs? | | Manter / colapsar / remover em v4 |
| C10 | Dashboard prioridades vs Mapa tab Núcleo | | OK complementar / consolidar |
| C11 | Síntese clínica textual vs hub visual | | OK / revisar texto |
| C12 | Callouts dashboard vs trilha | | OK / reduzir ruído |

### 4.3 Lacunas (informações ausentes)

| # | Lacuna potencial | Bloqueante? | Decisão |
|---|------------------|-------------|---------|
| C13 | Comparativo longitudinal (D4) | Não (pendente spec) | Roadmap |
| C14 | Domínios YSQ expandidos (D5) | Não | Roadmap |
| C15 | Grafo relacional no mapa | Não (proibido v3) | Fora de escopo |
| C16 | Interpretação / hipótese automática | — | **Não implementar** |
| C17 | Personalidade no dashboard | Não | Placeholder OK |
| C18 | Genograma gráfico | Não | Lista OK para MVP |

### 4.4 Clareza da formulação

| # | Critério | OK? | Observação |
|---|----------|-----|------------|
| C19 | Fica claro o que veio de instrumento vs registro clínico? | | |
| C20 | Fica claro que não há diagnóstico automático? | | |
| C21 | Ordem Núcleo → História → Plano faz sentido clínico? | | |
| C22 | Linguagem adequada para paciente (DP-03)? | | |
| C23 | Staff consegue usar em supervisão sem planilha paralela? | | |

---

## 5. Critérios de aceite

### 5.1 Técnicos (obrigatórios)

- [ ] `flutter test` verde (197 testes) no commit homologado
- [ ] Zero alteração em `supabase/migrations/`, Edge Functions e scoring nesta rodada
- [ ] Dashboard e Mapa abrem para paciente e staff sem crash
- [ ] Cenário **sem dados** não quebra em nenhum painel/tab
- [ ] Checklists §1 e §2 executados ou amostra representativa documentada na tabela §6

### 5.2 UX / visual (obrigatórios)

- [ ] Sem overflow visível nos cenários V1–V5
- [ ] Hub Mapa + tabs usáveis em largura < 560px
- [ ] Bottom sheets fecham e CTAs navegam corretamente (M-NAV.1–M-NAV.5)
- [ ] Banners de disclaimer presentes em Dashboard e Mapa

### 5.3 Clínico (obrigatórios para aprovação formal)

- [ ] Psicóloga confirma utilidade mínima (C1, C4, C19, C20) como **Útil** ou **Útil com ressalvas**
- [ ] Nenhum item **Confuso** bloqueante sem plano de correção ou aceite explícito
- [ ] Redundâncias C9–C12 discutidas; decisão registrada
- [ ] Lacunas C13–C18 comunicadas como roadmap, não como bug

### 5.4 Não bloqueantes (registrar apenas)

- [ ] Dark mode (V6) — app só light theme
- [ ] Dashboard D2/D4/D5 — não entregues nesta fatia
- [ ] Homologação formal YSQ/YAMI scores — ver [clinical-homologation.md](../scoring-engine/clinical-homologation.md)

---

## 6. Tabela de feedbacks

| ID | Módulo | Feedback | Prioridade | Decisão | Responsável | Status |
|----|--------|----------|------------|---------|-------------|--------|
| FB-DM-01 | — | *(exemplo)* Top YSQ no dashboard difícil de ler em telas 360px | Média | Ajustar padding mobile | Dev | Aberto |
| FB-DM-02 | — | *(exemplo)* Tab Plano: sparkline confunde paciente | Baixa | Manter + texto explicativo | Produto | Aberto |
| | | | | | | |
| | | | | | | |
| | | | | | | |

**Prioridade:** Alta (bloqueia homologação) · Média (corrigir antes de demo) · Baixa (backlog)  
**Decisão:** Corrigir · Aceitar · Adiar · Fora de escopo  
**Status:** Aberto · Em andamento · Resolvido · Aceito

---

## 7. Registro da sessão

| Campo | Valor |
|-------|-------|
| Data | |
| Participantes | |
| Build / commit | |
| Ambiente | Local · Staging · APK debug |
| `flutter test` | Pass / Fail — ___ testes |
| Resultado geral | Aprovado · Aprovado com ressalvas · Reprovado |
| Próxima ação | |

---

## 8. Referências

| Documento | Uso |
|-----------|-----|
| [final-mvp-homologation.md](../demo/final-mvp-homologation.md) | Roteiros paciente/staff, contas seed, segurança |
| [post-feedback-homologation-qa.md](./post-feedback-homologation-qa.md) | FH-01 a FH-04 |
| [post-roadmap-stabilization.md](./post-roadmap-stabilization.md) | Rotas e RLS |
| [dashboard-v3-spec.md](../product/dashboard-v3-spec.md) | Escopo D1–D5 |
| [mental-map-v3-spec.md](../product/mental-map-v3-spec.md) | Escopo M1–M5 |
| [clinical-homologation.md](../scoring-engine/clinical-homologation.md) | Homologação scores YSQ/YAMI |
