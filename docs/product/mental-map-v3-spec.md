# Mapa Mental v3 — Especificação de produto

**Versão:** 3.0 (spec)  
**Data:** 2026-06-07  
**Status:** Implementado (M1–M5)  
**Escopo:** Somente Flutter (domain + presentation). **Sem** alteração de banco, scoring, Edge Functions ou questionários.

**Baseline:** Mapa mental v2 (`features/mental_map/`) — hub radial responsivo, centro clínico, camadas principal/contextual, síntese read-only, navegação por nós.

**Objetivo v3:** Elevar o mapa de **organizador visual** para **formulação clínica integrada de alto valor** — o profissional (e o paciente, em versão educativa) percebe conexões *explicitamente registradas* entre esquemas, modos, história de vida, vínculos e plano terapêutico, sem inferência automática.

---

## Princípios de produto

| Princípio | Regra |
|-----------|--------|
| **Read-only** | Nenhum CRUD na tela do mapa; edição nos módulos de origem |
| **Sem inferência** | Não desenhar setas causais automáticas entre esquema ↔ evento |
| **Conexões explícitas** | Agrupamentos visuais apenas por co-ocorrência de dados existentes (ex.: mesmo paciente, mesma sessão de registro) |
| **Camadas clínicas** | Espelhar modelo de formulação: Esquemas/Modos → Vínculo/História → Plano |
| **Degradável** | Nó vazio não colapsa layout; hub funciona com 0–8 nós preenchidos |

---

## Mapa de telas

| # | Tela | Rota (mantida) | Papel |
|---|------|----------------|-------|
| M1 | Formulação integrada | `/patient/mental-map` · `…/patients/:id/mental-map` | Paciente + Staff |
| M2 | Camada núcleo clínico | Scroll / tab na M1 | Ambos |
| M3 | Camada história e vínculos | Scroll / tab na M1 | Ambos |
| M4 | Camada plano terapêutico | Scroll / tab na M1 | Ambos |
| M5 | Detalhe do nó | Bottom sheet modal | Ambos |

Rotas existentes mantidas. M2–M4 são **seções** da M1 (tabs ou scroll vertical), não rotas novas obrigatórias.

---

## M1 — Formulação integrada (tela principal)

### Objetivo clínico

Oferecer **visão única da formulação do caso** para supervisão, preparo de sessão e psicoeducação: núcleo esquemático (YSQ/YAMI), contexto vital (timeline, genograma, parentais), plano atual (problemas, objetivos, check-in) e síntese textual existente — tudo navegável.

### Dados utilizados

| Fonte | Uso |
|-------|-----|
| `questionnaire_results` / snapshots | Top esquemas (YSQ), modos (YAMI), apego, YCI/YRAI |
| `patient_problems` | Ativos, intensidade |
| `therapy_goals` | Ativos, data alvo |
| `patient_check_ins` | Últimos 7 registros (tendência sparkline) |
| `patient_timeline_events` | Top 5 por impacto/data |
| `genogram_people` + `genogram_relationships` | Contagem, relações destacadas |
| `patients` / intake (`patient_intake_context` se populado) | Síntese textual em `MentalMapCaseSummary` |
| `PARENTAL_STYLES_V1` snapshot | Resumo por figura (labels only, top estilo) |

Repositório: estender `MentalMapRepository` + `mental_case_map_builder.dart` — mesmas queries RLS v2.

### Layout proposto

```
┌─────────────────────────────────────────────┐
│ ← Mapa mental                  [↻] [? info] │
├─────────────────────────────────────────────┤
│ ⚠ Mapa mental: organiza registros; não      │
│   substitui avaliação clínica.              │
├─────────────────────────────────────────────┤
│ [ Núcleo ] [ História ] [ Plano ]  ← tabs   │
├─────────────────────────────────────────────┤
│           ┌─────────────┐                   │
│    ┌──────│   MARIA     │──────┐            │
│    │Esquem│ 3 prob ·    │Modos │            │
│    │  ▲   │ 2 obj ·     │  ▲   │            │
│    └──────│ check-in ✓  │──────┘            │
│           └─────────────┘                   │
│     Apego    Parentais    Enfrent.          │
│     Eventos  Genograma    Objetivos         │
├─────────────────────────────────────────────┤
│ Legenda: ● preenchido  ○ pendente           │
├─────────────────────────────────────────────┤
│ SÍNTESE CLÍNICA (expandível)                │
│ Demandas · Contexto · Hipóteses · Focos     │
├─────────────────────────────────────────────┤
│ CARDS RESUMO POR MÓDULO (v2 mantidos)       │
└─────────────────────────────────────────────┘
```

### Componentes visuais

| Componente | Descrição |
|------------|-----------|
| `MentalMapDisclaimerBanner` | Mantido |
| `FormulationTabBar` | 3 tabs: Núcleo, História, Plano |
| `MentalMapClinicalCanvas` | Hub v3: centro + 8 nós posicionados em 3 anéis |
| `MentalMapCenterCapsule` | Nome + resumo compacto (problemas, objetivos, check-in) |
| `MentalMapNodeChip` | Nó clicável; borda sólida se preenchido, tracejada se vazio |
| `FormulationLegend` | Preenchido vs pendente |
| `MentalMapCaseSummaryCard` | Mantido v2 |
| `MentalMapModuleCards` | Cards resumo v2 abaixo do hub |

### Estados vazios

| Estado | Comportamento |
|--------|---------------|
| Mapa totalmente vazio | Centro com nome; todos nós tracejados; mensagem *"Registre dados na trilha para preencher o mapa"* + CTA `/patient/journey` |
| Nó individual vazio | Borda tracejada + label *"Pendente"*; toque abre M5 com CTA para módulo |
| Sem síntese textual | Card síntese colapsado com hint anamnese futura |
| Erro / loading | Padrão `AsyncStateBody` |

### Navegação

| Ação | Destino |
|------|---------|
| Toque nó preenchido | M5 bottom sheet |
| Toque nó vazio | M5 com empty + CTA módulo |
| Tab Núcleo/História/Plano | Scroll/foco na camada (M2–M4) |
| Ver detalhes (cards) | Rotas dos módulos (v2) |
| Info `?` | Dialog com explicação das camadas |

### Responsividade

| Breakpoint | Layout |
|------------|--------|
| `< 560px` | Hub → **grid 2 colunas** (fallback v2 aprimorado) + tabs |
| `560–900px` | Hub radial 8 nós em anéis |
| `≥ 900px` | Radial ampliado; cards resumo em 2 colunas |
| Tabs | Scroll horizontal se necessário |

### Critérios de aceite

- [ ] M1 agrega todos os módulos v2 sem nova migration
- [ ] 8 nós fixos com ids estáveis: `schemas`, `modes`, `problems`, `goals`, `attachment`, `coping`, `timeline`, `genogram` (+ `parental` como sub de História ou nó 9 rotulado compacto)
- [ ] Centro exibe nome real do paciente (staff: do contexto; paciente: próprio)
- [ ] Legenda e disclaimer sempre visíveis
- [ ] Fallback grid funcional abaixo de 560px
- [ ] Testes widget: hub renderiza com 0, 4 e 8 nós preenchidos

---

## M2 — Camada núcleo clínico

### Objetivo clínico

Destacar **esquemas mal-adaptativos e modos** predominantes — núcleo da Terapia do Esquema — com leitura rápida dos scores e severidade quando disponível.

### Dados utilizados

- Snapshot YSQ: top 5 schemas por score
- Snapshot YAMI: top 5 modos por score
- Severidade: do snapshot quando existir

### Layout proposto

```
┌─────────────────────────────────────────────┐
│ NÚCLEO CLÍNICO                              │
├─────────────────────────────────────────────┤
│ ESQUEMAS (YSQ) — última aplicação 01/06     │
│ ┌─────────────────────────────────────────┐ │
│ │ 1. Abandono        ████████  4.2  Alta   │ │
│ │ 2. Defectuosidade  ██████    3.8        │ │
│ │ … top 5                                  │ │
│ └─────────────────────────────────────────┘ │
│ [Ver dashboard YSQ]                         │
├─────────────────────────────────────────────┤
│ MODOS (YAMI) — última aplicação 28/05       │
│ ┌─────────────────────────────────────────┐ │
│ │ 1. Vulnerável      ███████   3.5        │ │
│ │ … top 5                                  │ │
│ └─────────────────────────────────────────┘ │
│ [Ver dashboard YAMI]                        │
├─────────────────────────────────────────────┤
│ PROBLEMAS ATIVOS (top 3 por intensidade)    │
│ • Ansiedade generalizada        8/10        │
│ • Conflitos familiares          6/10        │
└─────────────────────────────────────────────┘
```

### Componentes visuais

| Componente | Descrição |
|------------|-----------|
| `NucleusSchemaPanel` | Lista + mini barras (reuso `HorizontalScoreBar` compact) |
| `NucleusModePanel` | Idem modos |
| `ActiveProblemsStrip` | Lista compacta com intensidade |
| `CrossLinkHint` | Texto estático: *"Esquemas e modos provêm de instrumentos; problemas são registrados pelo paciente/equipe"* — **sem setas inferidas** |

### Estados vazios

- Sem YSQ → painel esquemas empty + CTA questionários
- Sem YAMI → idem
- Sem problemas → *"Nenhum problema ativo registrado"*

### Navegação

- *Ver dashboard* → `/clinical-dashboard` com scroll para instrumento
- Problema → `/patient/problems/:id`

### Responsividade

- Coluna única mobile; tablet: esquemas | modos lado a lado

### Critérios de aceite

- [ ] Top 5 coerente com builder v2 (`_nodeItemLimit` elevado para 5 nesta camada)
- [ ] Data da última aplicação exibida por instrumento
- [ ] Sem setas esquema→problema automáticas

---

## M3 — Camada história e vínculos

### Objetivo clínico

Contextualizar o núcleo esquemático com **história de vida, vínculos familiares e experiências parentais** já registradas — eixo biográfico da formulação.

### Dados utilizados

| Fonte | Uso |
|-------|-----|
| `patient_timeline_events` | Top 5 eventos (impacto, data, categoria) |
| `genogram_people` | Lista resumida (nome, gênero, falecido) |
| `genogram_relationships` | Top 3 relações (tipo, par) |
| `PARENTAL_STYLES_V1` snapshot | Por figura: estilo dominante (maior score) |
| `ATTACHMENT_STYLES_V1` | Estilo predominante |

### Layout proposto

```
┌─────────────────────────────────────────────┐
│ HISTÓRIA E VÍNCULOS                         │
├─────────────────────────────────────────────┤
│ LINHA DO TEMPO (top 5)                      │
│ ● 2018 — Divórcio dos pais        impacto 9 │
│ ● 2022 — Mudança de cidade        impacto 6 │
│ [Ver timeline completa]                     │
├─────────────────────────────────────────────┤
│ GENOGRAMA (resumo)                          │
│ 6 pessoas · 4 relações                      │
│ Mãe — conflituosa · Pai — distante          │
│ [Ver genograma]                             │
├─────────────────────────────────────────────┤
│ ESTILOS PARENTAIS (por figura)              │
│ Mãe: Autoritarismo · Pai: Permissividade    │
│ [Ver dashboard parentais]                   │
├─────────────────────────────────────────────┤
│ APEGO                                       │
│ Predominante: Ansioso (snapshot)            │
└─────────────────────────────────────────────┘
```

### Componentes visuais

| Componente | Descrição |
|------------|-----------|
| `TimelineHighlightList` | Lista cronológica compacta com chip impacto |
| `GenogramSummaryCard` | Contadores + 2 relações textuais |
| `ParentalStyleMiniChip` | Figura + estilo dominante |
| `AttachmentStyleBadge` | Estilo com score opcional (staff) |

### Estados vazios

- Timeline vazia → CTA *"Registrar eventos na linha do tempo"*
- Genograma vazio → CTA genograma
- Parentais não aplicado → chip *"Instrumento pendente"*
- Apego vazio → idem

### Navegação

- Links para `/timeline`, `/genogram`, `/clinical-dashboard` (parentais/apego)

### Responsividade

- Seções empilhadas; genograma summary trunca nomes longos

### Critérios de aceite

- [ ] Eventos sensíveis (`is_sensitive`) exibem ícone 🔒 sem revelar título completo ao paciente se policy futura exigir — **v3 mantém comportamento v2** (mostrar título; flag visual apenas)
- [ ] Estilo parental dominante = schema com maior score no contexto
- [ ] Genograma mostra contagem real de pessoas/relações

---

## M4 — Camada plano terapêutico

### Objetivo clínico

Conectar formulação ao **trabalho em curso**: objetivos, evolução subjetiva (check-in), monitor e recursos — eixo teleológico do tratamento.

### Dados utilizados

| Fonte | Uso |
|-------|-----|
| `therapy_goals` | Ativos, título, `target_date` |
| `patient_check_ins` | Últimos 7: humor, ansiedade, energia (sparkline) |
| `daily_monitors` | Último registro (opcional, 1 linha resumo) |
| `therapy_resources` + `patient_resource_access` | Contagem liberados / concluídos |

### Layout proposto

```
┌─────────────────────────────────────────────┐
│ PLANO TERAPÊUTICO                           │
├─────────────────────────────────────────────┤
│ OBJETIVOS ATIVOS                            │
│ ○ Regulação emocional      alvo: Ago/2026   │
│ ○ Autocompaixão            alvo: —          │
├─────────────────────────────────────────────┤
│ CHECK-IN — últimos 7 dias                   │
│ Humor      ·─·──·─·──  (sparkline)         │
│ Ansiedade  ──·──·──·─                       │
│ Energia    ·──·─·──·─                       │
│ Hoje: humor 4 · ansiedade 7 · energia 3     │
├─────────────────────────────────────────────┤
│ RECURSOS                                    │
│ 2 liberados · 1 concluído                  │
│ [Ver biblioteca]                            │
└─────────────────────────────────────────────┘
```

### Componentes visuais

| Componente | Descrição |
|------------|-----------|
| `ActiveGoalsList` | Checkbox visual (não interativo) + título + data |
| `CheckInSparklineRow` | Mini gráfico linha 7 pontos (CustomPainter simples) |
| `CheckInTodaySummary` | Valores numéricos atuais |
| `ResourcesProgressChip` | Liberados/concluídos |

### Estados vazios

- Sem objetivos → CTA objetivos
- Menos de 2 check-ins → sparkline oculto; mostrar só último
- Sem recursos → *"Nenhum material liberado"*

### Navegação

- Objetivos → `/therapy-goals`
- Check-in → `/check-ins`
- Recursos → `/resources`

### Responsividade

- Sparklines largura 100%; altura fixa 32px

### Critérios de aceite

- [ ] Sparkline usa no máximo 7 check-ins mais recentes
- [ ] Valores ausentes (`null`) interpolados como gap no gráfico
- [ ] Contagem de recursos via repositório existente
- [ ] Teste domain: série temporal check-in → pontos sparkline

---

## M5 — Detalhe do nó (bottom sheet)

### Objetivo clínico

Apresentar **detalhe acionável** ao tocar um nó do hub: lista completa (até 10 itens), metadados e atalho para o módulo de origem.

### Dados utilizados

- Payload do nó (`MentalCaseMapNode` + dados brutos do repositório para aquele id)

### Layout proposto

```
┌─────────────────────────────────────────────┐
│ ──── (drag handle)                          │
│ Principais Esquemas                    [✕]  │
│ 3 destaques · YSQ 01/06/2026                │
├─────────────────────────────────────────────┤
│ 1. Abandono              4.20               │
│ 2. Defectuosidade        3.80               │
│ 3. Insuficiência         3.10               │
├─────────────────────────────────────────────┤
│ [ Ir para dashboard clínico ]               │
└─────────────────────────────────────────────┘
```

**Nó vazio:**

```
┌─────────────────────────────────────────────┐
│ Estilos de Apego                       [✕]  │
│ Nenhum resultado ainda                      │
│ [ Aplicar instrumento na trilha ]           │
└─────────────────────────────────────────────┘
```

### Componentes visuais

| Componente | Descrição |
|------------|-----------|
| `NodeDetailSheet` | `showModalBottomSheet`, draggable |
| `NodeDetailHeader` | Título + subtítulo |
| `NodeDetailItemList` | Até 10 linhas |
| `NodeDetailCta` | Botão primário para módulo |

### Mapeamento nó → módulo

| `node.id` | CTA |
|-----------|-----|
| `schemas`, `modes`, `attachment`, `coping`, `parental` | Dashboard clínico (scroll instrumento) |
| `problems` | Problemas |
| `goals` | Objetivos |
| `timeline` | Timeline |
| `genogram` | Genograma |

### Estados vazios

- Lista vazia → mensagem + CTA (tabela acima)

### Navegação

- Fechar sheet → M1
- CTA → push módulo correspondente

### Responsividade

- Sheet 50–90% altura; scroll interno se > 10 itens

### Critérios de aceite

- [ ] Todo nó do hub abre sheet
- [ ] CTAs usam `mental_map_navigation_targets.dart` (estender mapa)
- [ ] Staff e paciente veem mesmo sheet (scores: aplicar regra DP-03 se paciente)

---

## Hub v3 — Geometria dos nós

Anéis propostos (radial ≥ 560px):

```
                    [ Esquemas ]
                         │
        [ Apego ] ── [ CENTRO ] ── [ Modos ]
                         │
                   [ Problemas ]

    [ Parentais ] [ Eventos ] [ Genograma ] [ Enfrent. ]
                         │
              [ Objetivos ] (plano — anel externo)
```

| Anel | Nós | Camada tab |
|------|-----|------------|
| Interno | Esquemas, Modos, Problemas | Núcleo |
| Médio | Apego, Parentais, Enfrent., Eventos, Genograma | História |
| Externo | Objetivos | Plano |

**Regra visual:** nó preenchido = `border: solid 2px primary`; vazio = `dashed 1px outline`.

---

## Papéis: staff vs paciente

| Elemento | Staff | Paciente |
|----------|-------|----------|
| Scores nos nós/sheets | Visível | Ocultar número; manter rank/nome |
| Sparkline check-in | Sim | Sim (próprios dados) |
| Síntese clínica intake | Sim | Sim se campos populados |
| Links módulos | Todos | Só rotas paciente |

---

## Fora de escopo v3

- Grafo interativo com arestas causais ou editáveis
- IA / inferência de relações esquema↔evento
- Novas tabelas (`mental_map_nodes`, anotações persistidas)
- Alteração de scoring ou snapshots
- Genograma gráfico (continua lista/resumo)
- Comparativo longitudinal no mapa (permanece no Dashboard D4)

---

## Dependências técnicas (implementação futura)

| Área | Ação |
|------|------|
| Domain | `mental_case_map_builder.dart`: nó `parental`, sparkline input, top 5 |
| Domain | `CheckInSparklineBuilder` (pure Dart) |
| Presentation | `MentalMapClinicalCanvas`, `FormulationTabBar`, `NodeDetailSheet` |
| Presentation | Refatorar `MentalMapRadialHub` → anéis v3 |
| Testes | `mental_map_domain_test.dart`, `mental_map_widgets_test.dart` ampliados |
| Navegação | Estender `mental_map_navigation_targets.dart` |

---

## Rastreabilidade v2 → v3

| v2 | v3 |
|----|-----|
| Hub radial 6+2 nós | 8 nós + anéis + legenda |
| Centro 3 labels | Centro + KPI compacto |
| Cards síntese abaixo | Mantidos + tabs camadas |
| Grid fallback | Fallback aprimorado com ordem clínica |
| Nó toque → navega direto | Nó → M5 sheet → CTA |
| Sem parentais no hub | Nó `parental` dedicado |
| Sem tendência check-in | Sparkline M4 |

---

## Critérios de aceite globais (v3)

- [x] Zero alteração em `supabase/migrations/`, Edge Functions e catálogo de questionários
- [x] Disclaimer clínico em M1
- [x] Hub funcional com dados parciais (demo seed)
- [x] Rotas `/patient/mental-map` e staff inalteradas
- [x] `flutter test` verde após implementação (197 testes)
- [x] Documentar em `docs/mobile-app.md` pós-implementação
- [x] Tabs M2–M4 e sparkline M4

---

## Histórico

| Data | Alteração |
|------|-----------|
| 2026-06-07 | Fatia 2 implementada: M2–M4 tabs + sparkline + recursos |
| 2026-06-07 | Fatia 1 implementada: M1 hub 8 nós + M5 bottom sheet |
| 2026-06-07 | Especificação v3 inicial |
