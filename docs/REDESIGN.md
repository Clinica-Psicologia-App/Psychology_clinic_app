# EsquemaCore — Redesign "Living Clinical Map"

Documentação da intervenção de UI/UX/motion executada em 2026-07-10.
Nenhuma regra de negócio, rota, chamada de API ou permissão foi alterada.

---

## 1. Auditoria inicial

**O que existia (e era bom):** paleta oficial já correta em `app_colors.dart`, Poppins no tema, sistema de motion consolidado (`MotionReveal`/`MotionStaggered`/`MotionSurface` + `AppAnimations`, tudo com fallback de reduce-motion), splash e onboarding animados, login split-screen, componentes responsivos (`ResponsiveContent`/`ResponsiveGrid`), estados assíncronos padronizados (`AsyncStateBody`).

**Problemas encontrados:**
1. A linguagem da marca (nodos/conexões/mapa) não existia na interface — só no logo.
2. Onboarding: os 4 slides eram o mesmo template (círculo + ícone + 2 satélites).
3. Painel de login em telas largas: parede de gradiente vazia.
4. `BrandHeroCard` era um card com LinearGradient — sem camadas.
5. Admin usava a mesma composição emocional do paciente.
6. 12 módulos do paciente sem agrupamento conceitual.
7. Resposta de questionário sem transição direcional e sem largura de leitura.
8. Gate de revisão clínica visualmente igual a qualquer card — não deixava clara a consequência (liberação ao paciente).
9. Estados vazios genéricos (ícone em caixa cinza).
10. Tokens de motion sem classificação por propósito.

---

## 2. Direção visual aplicada

**"Living Clinical Map"** — a linguagem da interface nasce da marca: nodos, conexões, caminhos e núcleos aparecem de forma abstrata e discreta nos momentos certos (formação do mapa na splash, constelações no hero e no login, caminho de etapas no onboarding, nodos se conectando na conclusão de questionário, órbita nos estados vazios).

Diferenciação por perfil:
- **Psicólogo** — hero completo + `ActionSurface` azul ("Pacientes") + workspace agrupado por conceito clínico.
- **Paciente** — hero acolhedor + `ActionSurface` roxo como jornada ("Meu plano terapêutico"), textos orientadores, focus mode nos questionários.
- **Admin** — hero `dense` (sem marca d'água/constelação, avatar menor, padding reduzido) + tiles operacionais com identificação imediata.

---

## 3. Design System

**Tokens adicionados** (`core/theme/`):
- `AppColors.surfaceTintTurquoise/Blue/Purple` — fundos tonais por acento.
- `AppAnimations.micro/hover/block/page/sheet/celebration/ambient` — durações classificadas por propósito (feedback 140ms, hover 180ms, entrada 300ms, página 320ms, sheet 360ms, celebração 900ms, ambiental 6s).

**Componentes novos** (`shared/widgets/`):
- `BrandConstellation` — a linguagem de nodos. CustomPainter com 3 presets (`scatter`, `path`, `orbit`), parâmetro `progress` para formação gradual, `RepaintBoundary` + `ExcludeSemantics`. Estático quando `progress: 1` (custo zero).
- `ActionSurface` — família para A ação principal de uma seção: fundo tonal do acento, ícone gradiente 56px, caminho de nodos decorativo, seta circular proeminente, pill de status, estado bloqueado legível.
- `ModuleGridCard` — cards compactos verticais do grid de módulos (criado na fase anterior, mantido).

**Componentes refinados:**
- `BrandHeroCard` — agora em camadas: gradiente respirando (4,2s) → glow radial que deriva → constelação estática → marca d'água → conteúdo. Variante `dense` para admin.
- `HomologationEmptyPanel` — estados vazios com constelação orbital + ícone turquesa em card elevado (upgrade automático em todas as telas via `AsyncStateBody`).

---

## 4. Motion System

| Classe | Uso | Duração |
|---|---|---|
| Feedback | seleção, press, chips | `micro` 140ms |
| Hover | superfícies interativas | `hover` 180ms |
| Structural | entrada de blocos, troca de pergunta | `block` 300ms |
| Progress | barras, formação de constelação | dirigido por controller |
| Ambient | respiração do hero, glow | 4–6s loop, máx. 1–2 por tela |
| Celebration | conclusão de questionário | 900ms, não bloqueia navegação |

Regras: stagger 45–55ms limitado (`maxStaggered` 4–10); loops ambientais só no hero (1 controller) e desligados sob reduce-motion; constelações estáticas fora de animações de entrada; transições direcionais coerentes (próxima pergunta entra da direita, anterior da esquerda).

---

## 5. Bibliotecas

**Nenhuma dependência adicionada.** O sistema `MotionReveal`/`MotionSurface` existente estava consolidado; refatorá-lo com `flutter_animate` criaria arquitetura duplicada sem ganho. Rive/Lottie descartados por não existirem assets próprios aprovados. Tudo foi feito com primitivas Flutter (CustomPainter, AnimationController, AnimatedSwitcher).

---

## 6. Telas alteradas

| Tela | Mudança |
|---|---|
| Splash | Constelação orbital se forma junto do halo de entrada (mapa nascendo) |
| Onboarding | 4 composições distintas: marca+órbita / caminho de etapas / cartões→núcleo de insight / linha ascendente com halo de chegada |
| Login (wide) | Painel de marca com 2 constelações (scatter + path) |
| Home psicólogo | `ActionSurface` azul para Pacientes |
| Home paciente | `ActionSurface` roxo como jornada |
| Home admin | Hero `dense` operacional |
| Detalhe do paciente | Módulos agrupados: Avaliação / Acompanhamento / Compreensão clínica, com headers de seção e stagger limitado por grupo |
| Resposta de questionário | Focus mode: largura de leitura 560px, pergunta em `titleLarge`, transição direcional, durações do motion system |
| Sucesso do questionário | Nodos se conectando na celebração (progress = ring) |
| Detalhe de resultado | Gate de revisão com estado explícito: borda/ícone/pill âmbar "Não liberado" ↔ verde "Liberado ao paciente" + texto de consequência |
| Estados vazios (global) | Constelação orbital + ícone em card elevado |

## 7. Arquivos alterados

**Novos:** `shared/widgets/brand_constellation.dart`, `shared/widgets/action_surface.dart`
**Modificados:** `core/theme/app_animations.dart`, `core/theme/app_colors.dart`, `shared/widgets/brand_hero_card.dart`, `shared/widgets/homologation_ui.dart`, `features/auth/presentation/splash_page.dart`, `features/auth/presentation/login_page.dart`, `features/auth/presentation/role_home_shell.dart`, `features/onboarding/presentation/onboarding_page.dart`, `features/platform_admin/presentation/platform_admin_home_page.dart`, `features/patients/presentation/widgets/future_modules_section.dart`, `features/questionnaires/presentation/questionnaire_answer_page.dart`, `features/questionnaires/presentation/questionnaire_success_page.dart`, `features/results/presentation/patient_result_details_page.dart`

## 8. Riscos ou pendências

- O onboarding usa posições fixas calculadas para canvas 232px — validar visualmente em telas muito pequenas (320px de largura) para conferir que o artwork não domina a viewport.
- O gate de revisão manteve toda a lógica (`_setReviewed`, providers, invalidações); apenas a apresentação mudou — sem risco funcional identificado.

## 9. Comandos executados

- `flutter analyze` — **No issues found**
- `flutter test` — **225/225 passando**
- `flutter build apk --debug --dart-define-from-file=env.production.json` — OK

## 10. Segunda rodada — módulos clínicos (mesma sessão)

**Mapa mental (experiência assinatura)** — adicionada a camada de conexões que faltava: `_HubConnectionsPainter` desenha linhas do núcleo até cada nodo, parando nas bordas dos círculos (nunca atravessando componentes). Nodos preenchidos ganham conexão mais presente (1.4px, alpha 0.18) com micro-nodo no ponto médio; vazios ficam tênues (1px, alpha 0.08). Aplicado nos dois layouts: radial desktop (posições refatoradas em `slotPositions` compartilhadas entre painter e Positioned) e órbita mobile (posições derivadas dos alignments). O hub, os detail sheets e toda a lógica de severidade foram preservados.

**Linha do tempo** — tile reescrito na linguagem da marca: nodo em anel com ponto central e halo suave (turquesa; vermelho quando sensível), segmentos de linha conectando eventos, card com data em pill tonal, chip "Sensível" com ícone+texto (não só cor), borda tingida pelo acento.

**Recursos terapêuticos (biblioteca editorial)** — novo `ResourceCover`: capa abstrata 72px gerada pela interface (tint do acento + constelação + ícone do tipo em círculo elevado). Acento por tipo real do domínio: artigo=ciano, vídeo=roxo, exercício=turquesa, documento=azul, link=ciano, outro=navy. `TherapyResourceTile` virou card editorial (pill do tipo, título w700, status). `PatientAccessTile` e `TherapyRecommendationTile` herdam automaticamente.

**Dashboard clínico** — a hierarquia visão geral → sinais → aprofundamento já existia (commit "dashboard v3"); adicionada apenas entrada escalonada dos blocos (`MotionReveal` + `staggerDelay`). Reestruturar seria retrabalho sem ganho.

Verificação da segunda rodada: `flutter analyze` sem issues, `flutter test` 225/225.

## 11. Terceira rodada — varredura das telas restantes

Auditoria de todas as telas de apresentação restantes. As já alinhadas ao sistema (jornada do paciente, lista de pacientes, clínicas, usuários, convites — construídas/refinadas em commits recentes) foram deixadas intactas. As defasadas receberam o facelift consistente:

| Tela/Widget | Mudança |
|---|---|
| Problemas (`PatientProblemListTile` + chip) | Box de ícone gradiente âmbar, borda de acento, chip de status com ícone+texto por estado (ativo/melhorou/resolvido/arquivado) |
| Objetivos (`TherapyGoalListTile` + chip) | Mesmo padrão em turquesa; chips com ícone por estado |
| Check-ins (`PatientCheckInListTile`) | Box gradiente turquesa; destaque "hoje" com `surfaceTintTurquoise` |
| Monitor diário (`DailyMonitorListTile`) | Nodo em anel com intensidade no centro (linguagem da marca) |
| Resultados (`ResponseSummaryTile`) | Reescrito: fim das linhas "label: valor"; pills de status + estado de liberação visível (Liberado ✓ verde / Aguardando revisão âmbar) |
| Genograma (`GenogramSummaryCard`) | Stats com boxes gradientes |

Verificação: `flutter analyze` sem issues, `flutter test` 225/225.

## 12. Quarta rodada — ícone v2, entrada e telas secundárias

**Ícone v2 (alinhado ao guia oficial):** invertido o esquema — fundo branco com o cérebro em gradiente turquesa→ciano→azul→roxo, centralizado. A caixa do shader cobre apenas a massa do cérebro para o gradiente atravessar a área visível; os nós externos herdam as cores das extremidades (anel esquerdo turquesa, direitos roxos), como no guia. Adaptive: foreground = cérebro gradiente, background = branco.

**Login (redesign completo):**
- Mobile: hero de marca no topo (296px, cantos inferiores 36px) com gradiente em respiração (5,2s), constelação se formando na entrada, halo pulsante atrás do logo monocromático; formulário revelado com slide-up.
- Wide: painel com respiração de gradiente + constelações em formação.
- Botão de entrar com estados reais: idle → spinner inline (54px fixos, sem mudança de layout). Removido o LoadingOverlay de tela cheia.

**Splash:** constelações ambientais nos cantos (ciano/roxo, reveladas com a entrada) + deriva rotacional quase imperceptível na constelação orbital do mark.

**Onboarding:** flutuação ambiente nos artworks (±6px, 3,8s) respondendo ao mesmo controller; parallax preservado.

**Telas secundárias:** Aceitar convite ganhou constelação no hero (consistência com o login); Esqueci/Atualizar senha auditadas (já estavam na linguagem — AuthBrandBadge + AnimatedSwitcher); Personalidade ganhou identidade do módulo (header com tint roxo + box gradiente, factor cards com barra de acento).

Verificação: `flutter analyze` sem issues, `flutter test` 225/225.

## 13. Oportunidades futuras (fora desta entrega)

1. **Tabelas administrativas desktop** — page header + search + filtros + data table padronizados (catálogo, clínicas, usuários, pacientes globais).
2. **Navegação lateral (NavigationRail) para admin em desktop** — quando o número de destinos justificar.
3. **Container transform (package `animations`)** nas transições módulo→detalhe.
4. **Check-ins/Monitor com calendário e tendências** — visualização temporal quando houver série de dados relevante.
5. **Genograma** — refinamento de canvas (zoom/pan/seleção) mantendo fundo limpo.
6. **Relação visual Problema → Objetivo → Progresso** — exige modelagem de vínculo entre entidades no backend.
