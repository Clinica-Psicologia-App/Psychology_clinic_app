# EsquemaCore — Design System

Identidade visual oficial do aplicativo clínico **EsquemaCore** (*seu raciocínio clínico em mapa*).

## Marca

| Item | Valor |
|------|--------|
| Nome | EsquemaCore |
| Slogan | seu raciocínio clínico em mapa |
| Tipografia | Poppins (Regular, Medium, SemiBold, Bold) |
| Material | Material 3 (`useMaterial3: true`) |

## Paleta oficial

```dart
turquoise  #00B2A9
cyan       #0096D6
blue       #3B82F6
purple     #7B5CF6
navy       #0D1B3D
```

Implementação: `mobile/lib/core/theme/app_colors.dart`

### Cores semânticas

Não usar cores de marca para estados críticos quando prejudicar leitura:

| Token | Uso |
|-------|-----|
| `success` / `successContainer` | Concluído, confirmação |
| `warning` / `warningContainer` | Atenção, problemas |
| `error` / `errorContainer` | Erro, bloqueio |
| `info` / `infoContainer` | Banners informativos clínicos |

## Gradientes

`mobile/lib/core/theme/app_gradients.dart`

| Token | Uso |
|-------|-----|
| `brand` | Destaques institucionais (turquesa → azul → roxo) |
| `brandHorizontal` | Login desktop, headers |
| `splashBackground` | Splash |
| `progress` | Barras de progresso (questionários) |

**Regra:** gradiente com moderação — splash, login, progresso, marca. Não em todos os cards.

## Espaçamento

Escala: **4 · 8 · 12 · 16 · 20 · 24 · 32 · 40** (`AppSpacing`)

| Token | Valor |
|-------|-------|
| `contentMaxWidth` | 1200 px |
| `formMaxWidth` | 560 px |
| `minTouchTarget` | 48 px |

## Bordas

| Token | Valor | Uso |
|-------|-------|-----|
| `sm` | 8 | Chips, elementos pequenos |
| `md` | 12 | Inputs, botões |
| `lg` | 16 | Cards |
| `xl` / `xxl` | 20 / 24 | Painéis, dialogs, bottom sheets |

## Sombras

`AppShadows.soft` · `AppShadows.card` · `AppShadows.elevated` — discretas, sem elevação pesada.

## Tipografia

Centralizada em `AppTypography.textTheme()` via Google Fonts Poppins.

## Tema Material 3

Arquivo principal: `mobile/lib/core/theme/app_theme.dart`

Configura: `colorScheme`, `textTheme`, `appBarTheme`, `cardTheme`, `inputDecorationTheme`, botões, FAB, chips, navigation bar, dialog, bottom sheet, snackbar, divider, progress, slider, switch, list tile, banner.

**Dark mode:** não implementado nesta fase. Cores semânticas em tokens para facilitar evolução futura.

## Breakpoints

`mobile/lib/core/theme/app_breakpoints.dart`

| Largura | Layout |
|---------|--------|
| < 600 | compact (mobile) |
| 600–767 | medium |
| 768–1023 | expanded (tablet) |
| 1024–1439 | expanded |
| ≥ 1440 | wide (desktop) |

## Animações

`AppAnimations`: fast 150ms · standard 250ms · emphasis 400ms · curvas `easeOutCubic` / `easeInOut`.

Respeitar `MediaQuery.disableAnimationsOf(context)`.

## Componentes compartilhados

| Componente | Arquivo |
|------------|---------|
| `EsquemaCoreLogo` | `shared/widgets/esquema_core_logo.dart` |
| `AppScaffold` / `AppFormScaffold` | `shared/widgets/app_scaffold.dart` |
| `AsyncStateBody` / `EmptyStatePanel` / `ErrorStatePanel` | `shared/widgets/async_state_body.dart` |
| `HomologationInfoBanner` / `EmptyPanel` / `SectionHeader` | `shared/widgets/homologation_ui.dart` |
| `ClinicalModuleCard` | `shared/widgets/clinical_module_card.dart` |
| `StatusChip` | `shared/widgets/status_chip.dart` |
| `GradientProgressIndicator` | `shared/widgets/gradient_progress_indicator.dart` |
| `ResponsiveContent` / `ResponsiveGrid` | `shared/widgets/responsive_content.dart` |
| `LoadingSkeleton` | `shared/widgets/loading_skeleton.dart` |

## Acentos por módulo clínico

Uso pontual em ícones/cards — não como fundo saturado:

| Módulo | Cor |
|--------|-----|
| Questionários | blue |
| Mapa mental | purple |
| Check-in | turquoise |
| Linha do tempo | cyan |
| Objetivos | turquoise |
| Problemas | warning (âmbar) |
| Recursos | purple |
| Dashboard | navy |
| Monitor | cyan |
| Genograma | blue |

## Logo e assets

Caminhos esperados (`mobile/assets/branding/`):

- `esquema_core_logo.png`
- `esquema_core_logo_horizontal.png`
- `esquema_core_icon.png`
- `esquema_core_logo_monochrome.png`

**Fallback:** gradiente institucional + ícone `hub_outlined` quando PNG ausente.

Ver `mobile/assets/branding/README.md`.

### Ícone do launcher

Configurar `flutter_launcher_icons` com `esquema_core_icon.png` e executar:

```bash
dart run flutter_launcher_icons
```

## Regras de uso do logo

| Tela | Variante |
|------|----------|
| Splash | stacked + slogan |
| Login mobile | stacked |
| Login desktop | área institucional + gradiente |
| Cadastro / convite | horizontal discreto no topo |
| Home staff (wide) | horizontal no header |

Não repetir logo grande em todas as páginas internas.

## Status da trilha terapêutica

| Status | Tom |
|--------|-----|
| Disponível | available |
| Em andamento | inProgress |
| Concluído | completed |
| Em desenvolvimento | development |
| Bloqueado | blocked |

Implementado via `StatusChip` + `JourneyStepCard`.
