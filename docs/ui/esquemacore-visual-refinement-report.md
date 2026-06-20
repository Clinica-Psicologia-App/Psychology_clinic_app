# EsquemaCore — Relatório de refinamento visual

Data: 2026-06-15 · **Fase 4 concluída** (módulos clínicos + marca)

## Resumo

Refinamento incremental da identidade **EsquemaCore** sobre o MVP Flutter existente, sem alteração de regras de negócio, RLS, Edge Functions, rotas ou scoring.

## Fase 4 — entregas

### 1. Assets oficiais

| Arquivo esperado | Constante |
|------------------|-----------|
| `esquema_core_logo_principal.png` | `AppBrandingAssets.logoPrincipal` |
| `esquema_core_logo_horizontal.png` | `AppBrandingAssets.logoHorizontal` |
| `esquema_core_icon.png` | `AppBrandingAssets.icon` |
| `esquema_core_logo_monochrome.png` | `AppBrandingAssets.logoMonochrome` |

**Pendência operacional:** copiar os PNGs oficiais para `mobile/assets/branding/`. Não estavam no workspace durante a implementação; o fallback permanece ativo até a cópia.

`flutter_launcher_icons` documentado no `pubspec.yaml` (comentado) — executar somente após validar `esquema_core_icon.png` (≥1024px, sem texto, margens).

### 2. Dashboard clínico

- KPIs animados (`ClinicalKpiChip`, 320ms)
- Barras com animação de preenchimento (`AnimatedClinicalScoreBar`, 420ms)
- Seção expansível por instrumento (`ExpandableDashboardSection`, 220ms)
- Disclaimer clínico no topo (`CustomScrollView`)
- Layout responsivo via `ResponsiveContent`
- Instrumentos organizados: YSQ, YAMI, parentais, apego, YCI, YRAI + placeholder Personalidade
- **Sem alteração** de percentuais, scoring ou interpretação

### 3. Mapa mental

- Hub radial ≥600px; lista conectada scrollável &lt;600px (360px validado em teste)
- Camadas visuais: Núcleo clínico / Contexto terapêutico
- Estados: preenchido, parcial, pendente, bloqueado (ícone + borda + texto)
- Centro com ícone EsquemaCore + paciente
- Placeholder **Personalidade** (bloqueado, sem dados inventados)
- Bottom sheet existente mantido

### 4. Aceite de convite

- Header de marca EsquemaCore
- Seções de formulário (`FormSection`)
- Loading no botão
- Painéis de erro amigáveis (inválido, expirado, revogado, já utilizado)
- Token **não** exposto em mensagens

### 5. Formulários longos

- `FormSection`, `FormFieldGrid`, `FormPageBody`
- Cadastro de paciente reorganizado em seções
- Aceite de convite com mesma estrutura

### 6. Listas e cards

- `ClinicalRecordListTile` para padronização leve
- Dashboard e mapa mental usam componentes shared existentes

## Componentes novos (Fase 4)

| Componente | Caminho |
|------------|---------|
| `ClinicalKpiChip` | `shared/widgets/clinical_kpi_chip.dart` |
| `ClinicalRecordListTile` | `shared/widgets/clinical_record_list_tile.dart` |
| `FormSection` / `FormFieldGrid` / `FormPageBody` | `shared/widgets/form_section.dart` |
| `ExpandableDashboardSection` | `clinical_dashboard/.../clinical_dashboard_shared_widgets.dart` |
| `AnimatedClinicalScoreBar` | idem |
| `MentalMapNodeVisualState` | `mental_map/presentation/mental_map_node_state.dart` |

## Telas alteradas (Fase 4)

- Splash, Login (logo principal / monocromático)
- Dashboard clínico (paciente e staff)
- Mapa mental (hub visual)
- Aceite de convite (`accept_patient_invitation_page.dart`)
- Cadastro de paciente (`create_patient_page.dart`)
- `EsquemaCoreLogo` (variantes icon, monochrome, nomes oficiais)

## Decisões responsivas

| Largura | Comportamento |
|---------|---------------|
| &lt;600px | Mapa mental: lista conectada scrollável, sem sobreposição |
| ≥600px | Mapa mental: hub radial |
| Desktop | Formulários: `FormFieldGrid` 2 colunas; `ResponsiveContent` max 560–640px |

## Riscos / validação clínica

- **Cores de severidade** nas barras seguem mapeamento existente (verde/âmbar/laranja/vermelho) — validar com equipe se tons são adequados para contexto clínico brasileiro.
- **Placeholder Personalidade** é visual apenas; instrumento real depende de roadmap clínico.
- **Assets PNG** precisam ser copiados pelo time de marca antes do piloto visual final.

## QA (2026-06-15)

```text
dart format .        ✓
flutter analyze      ✓ 0 errors
flutter test         ✓ 202 passed
```

Testes novos/atualizados:

- `test/esquema_core_branding_test.dart` — fallback, filenames, estados do mapa
- `test/mental_map_widgets_test.dart` — lista conectada 360px, radial 760px

## Pendências pós-Fase 4

- [ ] Copiar PNGs oficiais para `mobile/assets/branding/`
- [ ] Validar ícone e rodar `dart run flutter_launcher_icons`
- [ ] Validação visual manual nas larguras 360 / 390 / 600 / 768 / 1024 / 1440
- [ ] Adotar `ClinicalRecordListTile` em mais listas (objetivos, problemas, timeline) se desejado na Fase 5

## Histórico — Fases 2–3

Ver seções anteriores neste arquivo e `docs/ui/esquemacore-design-system.md`.
