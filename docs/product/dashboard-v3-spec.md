# Dashboard Clínico v3 — Especificação de produto

**Versão:** 3.0 (spec)  
**Data:** 2026-06-07  
**Status:** Fatia 1 implementada (D1 + D3) — D2/D4/D5 pendentes  
**Escopo:** Somente Flutter (domain + presentation). **Sem** alteração de banco, scoring, Edge Functions ou questionários.

**Baseline:** Dashboard v2 (`features/clinical_dashboard/`) — home por instrumento, visão do caso, barras horizontais a partir de `snapshot`, placeholders Parentais/Personalidade.

**Objetivo v3:** Transformar o dashboard de catálogo de instrumentos em **visão clínica orientada ao caso** — o psicólogo (e, em versão reduzida, o paciente) enxerga formulação, prioridades e evolução usando **apenas dados já persistidos**.

---

## Princípios de produto

| Princípio | Regra |
|-----------|--------|
| **Sem recálculo** | Scores vêm exclusivamente de `questionnaire_results.snapshot` já gravado |
| **Sem interpretação automática** | Nenhum texto clínico gerado; labels vêm do catálogo/snapshot |
| **Apoio, não diagnóstico** | Banner fixo de validação clínica em todas as telas |
| **Staff vs paciente** | Staff vê histórico, comparativo e detalhe completo; paciente vê resumo educativo sem scores brutos detalhados (decisão DP-03 — ver § Papéis) |
| **Degradação graciosa** | Instrumento ausente, snapshot legado (`mvp-1`) ou sem `severity_ranges` não quebra a tela |

---

## Mapa de telas

| # | Tela | Rota (mantida) | Papel |
|---|------|----------------|-------|
| D1 | Visão clínica do caso | `/patient/clinical-dashboard` · `…/patients/:id/clinical-dashboard` | Paciente + Staff |
| D2 | Painel de instrumento | Scroll inline / expansão na D1 | Staff (completo) · Paciente (reduzido) |
| D3 | Estilos parentais por figura | Seção dedicada na D1 | Staff + Paciente |
| D4 | Comparativo longitudinal | Seção ou sub-rota `…/clinical-dashboard/compare/:code` | **Somente staff** |
| D5 | Domínios YSQ | Expansão dentro do painel YSQ (D2) | Staff |

Rotas existentes permanecem; D4 pode ser query `?compare=YSQ` ou segmento opcional — decisão na implementação.

---

## D1 — Visão clínica do caso

### Objetivo clínico

Oferecer em uma única tela a **formulação resumida do caso** para preparação de sessão: o que está ativo (problemas, objetivos), o que os instrumentos destacam (top esquemas/modos), sinais recentes (check-in) e pendências (instrumentos não aplicados). Reduz cliques entre módulos isolados.

### Dados utilizados

| Fonte | Campos / uso |
|-------|----------------|
| `questionnaire_responses` + `questionnaire_results` | Última resposta concluída por código (`YSQ`, `YAMI`, `ATTACHMENT_STYLES_V1`, `YCI`, `YRAI`); contagem de aplicações |
| `snapshot` (`scoring-demo-1`) | `schemas[]`, `domains[]`, `severity`, `scale_max`, `contexts[]` (parental) |
| `patient_problems` | Status `active`/`improved`; título, intensidade 0–10 |
| `therapy_goals` | Status `active`; título, `target_date` |
| `patient_check_ins` | Último registro; humor, ansiedade, energia |
| `patient_timeline_events` | Top eventos por `emotional_impact` e data |
| `profiles` / `patients` | Nome do paciente (staff) |

Agregação: estender `clinical_case_summary_builder.dart` — **sem novas queries além das já usadas pelo repositório v2**.

### Layout proposto

```
┌─────────────────────────────────────────────┐
│ ← Dashboard clínico          [↻ refresh]   │
├─────────────────────────────────────────────┤
│ ⚠ Banner validação clínica (fixo)           │
├─────────────────────────────────────────────┤
│ VISÃO DO CASO — Maria Silva                 │
│ ┌─────────┬─────────┬─────────┬─────────┐   │
│ │ 3 prob. │ 2 obj.  │ 5 instr.│ check-in│   │
│ │ ativos  │ ativos  │ c/ score│ hoje ✓  │   │
│ └─────────┴─────────┴─────────┴─────────┘   │
├─────────────────────────────────────────────┤
│ PRIORIDADES CLÍNICAS (duas colunas mobile)  │
│ ┌ Problemas ────────┐ ┌ Objetivos ────────┐ │
│ │ • Ansiedade 8/10  │ │ • Regulação emo.  │ │
│ │ • Relacionamento  │ │ • Autocompaixão     │ │
│ └───────────────────┘ └───────────────────┘ │
├─────────────────────────────────────────────┤
│ DESTAQUES DOS INSTRUMENTOS                  │
│ ┌ YSQ top 3 ────────┐ ┌ YAMI top 3 ───────┐ │
│ │ Abandono    ████  │ │ Vulnerável  ███   │ │
│ │ Defectuos.  ███   │ │ Punitivo    ██    │ │
│ └───────────────────┘ └───────────────────┘ │
├─────────────────────────────────────────────┤
│ SINAIS RECENTES                             │
│ Check-in: humor 4 · ansiedade 7 · energia 3 │
│ Evento: Mudança de emprego (impacto 8)      │
├─────────────────────────────────────────────┤
│ INSTRUMENTOS (cards expansíveis → D2)       │
│ [YSQ ▼] [YAMI ▼] [Apego ▼] [Enfrent. ▼]    │
│ [Parentais ▼] [Personalidade — futuro]      │
├─────────────────────────────────────────────┤
│ HISTÓRICO RÁPIDO (staff) / oculto (paciente)│
│ YSQ 01/06 · YAMI 28/05 · Apego 15/05        │
└─────────────────────────────────────────────┘
```

### Componentes visuais

| Componente | Descrição |
|------------|-----------|
| `ClinicalDashboardDisclaimerBanner` | Mantido |
| `CaseOverviewHeader` | Nome + 4 KPI chips (problemas, objetivos, instrumentos, check-in) |
| `ClinicalPriorityPanel` | Duas listas ranqueadas (intensidade / data alvo) |
| `InstrumentHighlightsRow` | Mini-barras YSQ + YAMI lado a lado (top 3) |
| `RecentSignalsCard` | Check-in + 1 evento timeline |
| `InstrumentAccordion` | Card colapsável por instrumento; expande para D2 |
| `QuickHistoryStrip` | Staff: últimas 5 aplicações com link para resultados |

### Estados vazios

| Estado | Comportamento |
|--------|---------------|
| Caso sem dados | `CaseOverviewHeader` com zeros; mensagem central: *"Comece registrando problemas, objetivos ou aplicando instrumentos na trilha."* + CTA trilha |
| Sem YSQ/YAMI | Mini-painéis substituídos por chip *"Instrumento pendente"* + link questionários |
| Sem check-in hoje | Chip *"Sem check-in recente"* (não bloqueia) |
| Sem problemas/objetivos | Painéis com empty inline *"Nenhum registro ativo"* + link módulo |
| Erro de rede | `ErrorBanner` + retry (padrão existente) |
| Loading | Skeleton nos chips e barras |

### Navegação

| Origem | Destino |
|--------|---------|
| Trilha paciente | D1 |
| Detalhe paciente (staff) | D1 |
| Chip problema/objetivo | `/patient/problems`, `/patient/therapy-goals` (staff: prefixo admin/psychologist) |
| Instrumento pendente | `/patient/questionnaires` |
| Histórico item (staff) | `…/results/:responseId` |
| Accordion expand | Scroll para painel D2 na mesma página |

### Responsividade

| Breakpoint | Comportamento |
|------------|---------------|
| `< 360px` | KPI chips em 2×2; highlights empilhados |
| `360–599px` | Layout mobile padrão (coluna única) |
| `≥ 600px` (tablet/desktop) | Prioridades e highlights YSQ/YAMI em 2 colunas; accordion em grid 2 colunas |
| Pull-to-refresh | Mantido em todas as larguras |

### Critérios de aceite

- [x] D1 carrega agregando repositórios existentes sem nova migration ou Edge Function
- [x] KPI chips refletem contagens reais (problemas `active`, objetivos `active`, respostas com `hasResults`, check-in mais recente)
- [x] Top 3 esquemas/modos correspondem ao snapshot da **última** resposta concluída (mesma lógica v2)
- [x] Staff vê faixa histórica; paciente vê mesma visão executiva (scores nos mini-cards — DP-03 aberto para restrição futura)
- [x] Detalhes por instrumento permanecem em seção colapsável (D2 completo pendente)
- [x] Banner de validação clínica sempre visível
- [x] Empty states com CTA para trilha/módulo correto
- [x] `flutter test` — testes de domain para case summary, callouts e parental dashboard

---

## D2 — Painel de instrumento

### Objetivo clínico

Permitir **leitura profunda** de um instrumento específico: todos os scores do snapshot, agrupamento por domínio (quando presente no snapshot), severidade visual e metadados da aplicação (data, versão, período de referência).

### Dados utilizados

| Fonte | Uso |
|-------|-----|
| `questionnaire_results.snapshot` | `schemas[]`, `domains[]`, `questionnaire`, `version`, `scale_max` |
| `questionnaire_responses` | `completed_at`, `response_id`, `questionnaire_versions.reference_period` (via join existente) |
| `severity_ranges` | Já embutido no snapshot quando calculado (`severity_label`, `severity_color_key`) |

### Layout proposto

```
┌─────────────────────────────────────────────┐
│ YSQ — Inventário de Esquemas                │
│ Concluído em 01/06/2026 · Ref.: último ano  │
│ Versão snapshot: scoring-demo-1             │
├─────────────────────────────────────────────┤
│ [Staff] Ver comparativo (2 aplicações) → D4 │
├─────────────────────────────────────────────┤
│ POR DOMÍNIO (se domains[] no snapshot)      │
│ ▼ Domínio Desconexão/Rejeição               │
│   Abandono          ████████░░  4.2  Alta     │
│   Instabilidade     ██████░░░░  3.1  Média    │
│ ▼ Domínio Autonomia                         │
│   Dependência       ████░░░░░░  2.0           │
├─────────────────────────────────────────────┤
│ LISTA COMPLETA (rank decrescente)           │
│ 1. Abandono …                               │
│ … até 8 itens + "Ver todos" (staff)         │
├─────────────────────────────────────────────┤
│ [Staff] Abrir resultado completo → results  │
└─────────────────────────────────────────────┘
```

**Variantes por instrumento:**

| Código | Título card | Agrupamento |
|--------|-------------|-------------|
| `YSQ_FOUNDATION_V1` | YSQ | Por `domains[]` do snapshot → D5 |
| `YAMI_MODES_FOUNDATION_V1` | YAMI — Modos | Lista única ou por domínio se existir |
| `ATTACHMENT_STYLES_V1` | Estilos de apego | 3 estilos (Ansioso, Seguro, Evitante) |
| `YCI_FOUNDATION_V1` | YCI | Score geral + itens se múltiplos schemas |
| `YRAI_FOUNDATION_V1` | YRAI | Idem YCI |
| `PERSONALITY_*` | Personalidade | Placeholder v2 mantido até instrumento existir |

### Componentes visuais

| Componente | Descrição |
|------------|-----------|
| `InstrumentPanelHeader` | Nome, data, referência temporal, código |
| `DomainGroupSection` | `ExpansionTile` por domínio com barras internas |
| `HorizontalScoreBar` | Reutilizado v2; cor por `severity_color_key` |
| `SeverityBadge` | Chip quando `severity_label` presente |
| `CompareLinkButton` | Staff: visible se ≥ 2 respostas concluídas do mesmo código |
| `ViewFullResultButton` | Staff → `PatientResultDetailsPage` |

### Estados vazios

| Estado | UI |
|--------|-----|
| Instrumento nunca aplicado | Card colapsado com ícone + *"Ainda não aplicado"* + CTA questionários |
| Snapshot sem schemas | *"Sem scores estruturados nesta resposta"* (legado `mvp-1`) |
| Domínios ausentes no snapshot | Ocultar seção domínio; mostrar lista plana |
| Personalidade | *"Disponível em versão futura"* |

### Navegação

- Expansão a partir do accordion D1
- *Ver comparativo* → D4 (staff)
- *Abrir resultado completo* → `…/results/:responseId`
- YSQ domínio → expansão inline D5 (não nova rota)

### Responsividade

- Domínios: lista vertical mobile; tablet pode usar master-detail (lista domínios | barras)
- Barras: largura 100% com label truncado em 2 linhas

### Critérios de aceite

- [ ] Painel YSQ/YAMI/Apego/YCI/YRAI renderiza scores do snapshot sem recalcular
- [ ] Agrupamento por domínio só aparece se `domains[]` existir no snapshot
- [ ] Severidade exibida quando presente; omitida sem inventar faixas
- [ ] Link comparativo só para staff e só com ≥ 2 respostas `completed` do mesmo `questionnaire_code`
- [ ] Placeholder Personalidade inalterado
- [ ] Testes domain: parsing de agrupamento por domínio a partir de snapshot fixture

---

## D3 — Estilos parentais por figura

### Objetivo clínico

Visualizar resultados de `PARENTAL_STYLES_V1` **separados por figura parental** (Mãe, Pai, Outro), alinhado ao snapshot `parental-context-v1` já produzido por `finish-questionnaire`.

### Dados utilizados

| Fonte | Uso |
|-------|-----|
| `questionnaire_results.snapshot.contexts[]` | `context_label`, `context_key`, scores por contexto |
| `questionnaire_response_contexts` | Metadados da figura (via response_id) |
| Última resposta `PARENTAL_STYLES_V1` concluída | Base do painel |

### Layout proposto

```
┌─────────────────────────────────────────────┐
│ Estilos parentais                           │
│ Aplicação: 20/05/2026                       │
├─────────────────────────────────────────────┤
│ [ Mãe ] [ Pai ] [ Outro: Avó ]   ← tabs     │
├─────────────────────────────────────────────┤
│ Figura: Mãe                                 │
│ ┌ Autoritarismo    ████████░░  72%          │
│ │ Permissividade   ████░░░░░░  41%          │
│ │ Negligência      ██░░░░░░░░  18%          │
│ └ … estilos do snapshot por contexto        │
├─────────────────────────────────────────────┤
│ [Staff] Abrir resultado por figura          │
└─────────────────────────────────────────────┘
```

### Componentes visuais

| Componente | Descrição |
|------------|-----------|
| `ParentalContextTabBar` | Uma tab por entrada em `contexts[]` |
| `ParentalContextScorePanel` | Barras horizontais por estilo/categoria do snapshot |
| `ParentalEmptyState` | *"Selecione figuras parentais ao iniciar o instrumento"* |

### Estados vazios

- Instrumento não aplicado → card vazio padrão D2
- Snapshot sem `contexts[]` → fallback mensagem *"Resultado sem separação por figura"* + lista agregada se houver schemas
- Apenas uma figura → tabs ocultas, painel único

### Navegação

- Seção dentro de D1 (accordion *Estilos parentais*)
- Staff: link para `PatientResultDetailsPage` (já exibe seções por figura)

### Responsividade

- Tabs scrolláveis horizontalmente em telas estreitas
- Barras empilhadas (mesmo padrão D2)

### Critérios de aceite

- [x] Tabs geradas dinamicamente de `snapshot.contexts[]`
- [x] Scores por tab correspondem ao sub-snapshot da figura (sem merge incorreto)
- [x] Compatível com resposta de figura única
- [x] Sem alteração em `finish-questionnaire` ou schema parental
- [x] Teste domain com fixture `parental-context-v1`

---

## D4 — Comparativo longitudinal

### Objetivo clínico

Apoiar o psicólogo a **comparar duas aplicações** do mesmo instrumento (ex.: YSQ inicial vs. reavaliação), visualizando delta de scores nos esquemas/modos comuns — leitura clínica permanece humana.

### Dados utilizados

| Fonte | Uso |
|-------|-----|
| `questionnaire_responses` | Filtrar `completed` + mesmo `questionnaire_code`, ordenar por data |
| Dois snapshots mais recentes (ou par selecionado) | Interseção de `schema.code` ou `schema.name` |
| Cálculo client-side | `delta = score_b - score_a` — **não persiste** |

### Layout proposto

```
┌─────────────────────────────────────────────┐
│ ← Comparativo YSQ                           │
├─────────────────────────────────────────────┤
│ ⚠ Comparação visual; não indica significância│
│   estatística. Interpretação clínica manual. │
├─────────────────────────────────────────────┤
│ A: 01/03/2026          B: 01/06/2026        │
│ [dropdown trocar A]    [dropdown trocar B]  │
├─────────────────────────────────────────────┤
│ Esquema          A      B      Δ              │
│ Abandono        4.2    3.1   ▼ 1.1           │
│ Defectuosidade  3.8    4.0   ▲ 0.2           │
│ …                                           │
├─────────────────────────────────────────────┤
│ Gráfico barras agrupadas (opcional v3.1)    │
└─────────────────────────────────────────────┘
```

### Componentes visuais

| Componente | Descrição |
|------------|-----------|
| `ComparisonDisclaimer` | Aviso estatístico |
| `ApplicationSelector` | Dropdown de resposta A e B |
| `ComparisonTable` | Colunas score A, B, delta com setas ▲▼ |
| `DeltaChip` | Verde/vermelho/neutro por sinal do delta (sem julgamento clínico) |

### Estados vazios

- Menos de 2 aplicações → seção oculta em D2; se acesso direto, tela *"É necessário ao menos duas aplicações concluídas"*
- Snapshots incompatíveis (versões diferentes) → banner *"Versões de snapshot diferentes; comparar com cautela"*
- Sem schemas em comum → empty *"Nenhum constructo em comum entre as aplicações"*

### Navegação

- Staff only: link a partir de D2
- Rota sugerida: `…/clinical-dashboard/compare?code=YSQ_FOUNDATION_V1`
- Voltar → D1

### Responsividade

- Tabela vira cards empilhados (`Esquema X · A: 4.2 · B: 3.1 · Δ -1.1`) em `< 400px`

### Critérios de aceite

- [ ] Visível **apenas** para `admin` e `psychologist`
- [ ] Delta calculado no client; nada escrito no banco
- [ ] Dropdown lista só respostas `completed` com `hasResults` do mesmo código
- [ ] Default: duas mais recentes
- [ ] Testes domain: interseção de schemas e cálculo delta

---

## D5 — Domínios YSQ (drill-down)

### Objetivo clínico

Organizar esquemas YSQ pelos **domínios clínicos oficiais** (Desconexão/Rejeição, Autonomia, etc.) conforme já presentes em `snapshot.domains[]`, facilitando leitura alinhada à literatura de Terapia do Esquema.

### Dados utilizados

- `snapshot.domains[]` com `code`, `name`, `schemas[]` aninhados ou mapeamento schema→domain do payload
- Fallback: agrupar por `schema.domain_code` se domínios vierem flat em `schemas[]`

### Layout proposto

```
┌─────────────────────────────────────────────┐
│ ▼ Desconexão e Rejeição (4 esquemas)        │
│   [barras horizontais por esquema]            │
│ ▼ Limites Impostos (3 esquemas)             │
│   …                                           │
└─────────────────────────────────────────────┘
```

### Componentes visuais

- `DomainExpansionList` — reutiliza `HorizontalScoreBar` agrupado
- Contador de esquemas por domínio no título

### Estados vazios

- Snapshot sem domínios → seção oculta; D2 mostra lista plana

### Navegação

- Inline dentro do painel YSQ (D2); sem rota dedicada

### Responsividade

- Igual D2

### Critérios de aceite

- [ ] Domínios renderizados na ordem do snapshot
- [ ] Esquemas sem domínio aparecem em grupo *"Outros"*
- [ ] Teste fixture YSQ real (migration 014)

---

## Papéis: staff vs paciente (DP-03)

| Elemento | Staff | Paciente |
|----------|-------|----------|
| Scores numéricos | Visível | Oculto nos highlights; opcional mostrar severidade qualitativa |
| Comparativo D4 | Sim | Não |
| Histórico rápido | Sim | Não |
| Link resultados | Sim | Não |
| Problemas/objetivos/check-in | Sim | Sim (próprios dados) |
| Instrumentos pendentes CTA | Sim | Sim |

Implementação: flag `isStaffView` no builder, derivada de `profile.role`.

---

## Fora de escopo v3

- Novas tabelas, views materializadas ou caches server-side
- Alteração de `finish-questionnaire`, regras de scoring ou catálogo de perguntas
- Dashboard web, export PDF do dashboard (PDF clínico v1 permanece separado)
- Interpretação textual automática, IA, alertas clínicos
- Comparativo entre instrumentos diferentes (ex.: YSQ vs YAMI)
- Gráficos radar/spider (candidate v3.1)

---

## Dependências técnicas (implementação futura)

| Área | Ação |
|------|------|
| Domain | Novos builders: `ComparisonBuilder`, `ParentalDashboardBuilder`, `DomainGroupBuilder` |
| Data | Reutilizar `ClinicalDashboardRepository` + `ResultsRepository`; carregar N respostas para D4 |
| Presentation | Refatorar `DashboardHomePage` → composição D1; widgets em `clinical_dashboard_widgets.dart` |
| Testes | Fixtures JSON de snapshot em `test/fixtures/` |
| Docs | Atualizar `docs/mobile-app.md` após implementação |

---

## Rastreabilidade

| Artefato v2 | Evolução v3 |
|-------------|-------------|
| `ClinicalCaseSummary` | + KPI chips, prioridades ranqueadas |
| `InstrumentDashboardCard` | → `InstrumentAccordion` + D2 |
| `ClinicalDashboardFutureSectionCard` (Parentais) | → D3 real |
| `ClinicalDashboardHistoryCard` | → `QuickHistoryStrip` + D4 |
| Placeholder Personalidade | Mantido |

---

## Histórico

| Data | Alteração |
|------|-----------|
| 2026-06-07 | Fatia 1 implementada: D1 visão executiva + D3 estilos parentais |
| 2026-06-07 | Especificação v3 inicial |
