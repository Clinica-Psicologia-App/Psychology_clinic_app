# Sprint de Polimento para Homologação

Documento de referência da sprint de **polimento visual e UX** do MVP, sem alteração de banco, Edge Functions, motor clínico ou regras de negócio.

**Data:** jun/2025  
**Escopo:** Trilha do paciente · Dashboard clínico · Mapa mental · PDF clínico (tela Flutter)

---

## 1. Melhorias realizadas

### Componentes compartilhados

Novo módulo `mobile/lib/shared/widgets/homologation_ui.dart`:

| Widget | Uso |
|--------|-----|
| `HomologationInfoBanner` | Banners de validação / disclaimer com ícone, título e texto |
| `HomologationEmptyPanel` | Estados vazios com ícone grande, título, mensagem e dica opcional |
| `HomologationSectionHeader` | Cabeçalhos de seção (ícone + título + subtítulo) |

Padroniza hierarquia visual entre as quatro telas da sprint.

---

### Trilha do paciente

**Arquivos:** `patient_journey_page.dart`, `journey_step_card.dart`, `journey_trail.dart`

- Cabeçalho reformulado com `HomologationSectionHeader`, saudação separada e legenda com rótulo explícito (“Legenda de status”).
- Label de seção **“Passos da trilha”** acima da lista vertical.
- Cards de passo:
  - Ícone em avatar circular.
  - Título e subtítulo com hierarquia mais clara.
  - Chip de status mantido.
  - Chevron à direita quando o passo não está bloqueado.
  - Dica de progresso em container destacado com ícone de orientação.
- Estado vazio da lista com ícone `route_outlined`.
- Espaçamento entre passos aumentado (8 px).

---

### Dashboard clínico

**Arquivos:** `clinical_dashboard_widgets.dart`, `patient_clinical_dashboard_page.dart`

- Banner de validação clínica unificado (`HomologationInfoBanner`).
- Seção **“Últimos resultados”** com subtítulo explicativo.
- Cards YSQ/YAMI:
  - Cabeçalho com ícone específico (`psychology` / `self_improvement`).
  - Código do questionário como subtítulo.
  - Data de conclusão com ícone de calendário.
  - Barras horizontais com ranking numerado, código do item e severidade quando disponível.
- Estados vazios por instrumento com `HomologationEmptyPanel` e dica para concluir na trilha.
- Histórico em card dedicado com cabeçalho e ícones por entrada (com/sem resultados).
- Mensagens de empty state global e AsyncStateBody revisadas.

---

### Mapa mental

**Arquivos:** `mental_map_widgets.dart`, `patient_mental_map_page.dart`

- Banner “Visão integrada” padronizado.
- Seção **“Resumo por módulo”** antes dos cards.
- Cada card de módulo:
  - Cabeçalho com `HomologationSectionHeader`.
  - Empty state rico (`HomologationEmptyPanel`) com dica de ação na trilha.
  - Botão “Ver detalhes” com ícone `open_in_new`.
- Destaques de questionário com layout customizado (`MentalMapScoreHighlightTile`) em vez de `ListTile` genérico.
- Estado global vazio com painel centralizado e orientação clara.

---

### PDF clínico (tela de opções)

**Arquivo:** `clinical_report_options_page.dart`

- Disclaimer em banner padronizado com ícone PDF.
- Cabeçalho **“Conteúdo do PDF”** com subtítulo orientando a seleção.
- Switches agrupados em um único `Card` com divisores.
- Cada switch com ícone temático e subtítulo nas seções principais (questionários e mapa mental).
- Contador **“X de 8 seções selecionadas”** antes do botão de geração.
- Botão primário mantido com feedback de loading.

> **Nota:** O layout do PDF gerado (Edge Function) não foi alterado nesta sprint — apenas a tela Flutter de configuração.

---

## 2. Prints esperados

Capturar manualmente no simulador/dispositivo com Supabase local + `functions serve` ativos. Usuário sugerido: `psicologo@…` (staff) e `paciente.login@…` (paciente).

| # | Tela | Rota / acesso | O que validar no print |
|---|------|---------------|------------------------|
| 1 | Trilha | Paciente → Meu plano terapêutico | Cabeçalho com legenda; trilha vertical numerada; cards com chevron e dicas de progresso |
| 2 | Trilha (detalhe card) | Passo “Questionários” ou “Dashboard clínico” | Avatar do ícone, chip de status, hint em caixa azul clara |
| 3 | Dashboard clínico | Trilha → Dashboard clínico **ou** staff → paciente → dashboard | Banner validação; barras com ranking; histórico com ícones |
| 4 | Dashboard vazio | Paciente sem YSQ/YAMI concluído | Empty panel central “Sem gráficos disponíveis” + dica da trilha |
| 5 | Mapa mental | Trilha → Mapa mental | Banner + seção “Resumo por módulo”; cards com empty states ou dados |
| 6 | Mapa mental vazio | Paciente sem dados | Painel “Mapa ainda vazio” com hint |
| 7 | Gerar relatório | Staff → detalhe paciente → Gerar relatório | Banner, card de switches com ícones, contador de seções |
| 8 | Gerar relatório (loading) | Após tocar “Gerar relatório PDF” | Botão desabilitado com spinner |

**Sugestão de pasta:** `docs/ui/screenshots/homologation-polish/` (criar ao capturar).

---

## 3. Itens deixados para versão futura

| Item | Motivo |
|------|--------|
| Layout visual do PDF (tipografia, gráficos, capa) | Fora do escopo Flutter; exige alteração na Edge Function |
| Gráficos interativos no dashboard (zoom, filtros, comparação temporal) | Nova funcionalidade |
| Mapa mental gráfico / diagrama relacional | Wireframe original prevê visualização avançada |
| Animações na trilha (transição entre passos) | Polish adicional, não crítico para homologação |
| Modo escuro calibrado por tela | Tema global Material 3 já aplica; revisão fina pendente |
| Localização / acessibilidade (Semantics, contraste WCAG audit) | Sprint dedicada de a11y |
| Empty states ilustrados (SVG/Lottie) | Assets ainda não definidos no MVP |
| Preview do PDF in-app antes de abrir | Nova funcionalidade |
| Sincronização pull-to-refresh na trilha com feedback por passo | Melhoria incremental |

---

## 4. Arquivos alterados (referência)

```
mobile/lib/shared/widgets/homologation_ui.dart                          (novo)
mobile/lib/features/patient_journey/presentation/patient_journey_page.dart
mobile/lib/features/patient_journey/presentation/widgets/journey_step_card.dart
mobile/lib/features/patient_journey/presentation/widgets/journey_trail.dart
mobile/lib/features/clinical_dashboard/presentation/patient_clinical_dashboard_page.dart
mobile/lib/features/clinical_dashboard/presentation/widgets/clinical_dashboard_widgets.dart
mobile/lib/features/mental_map/presentation/patient_mental_map_page.dart
mobile/lib/features/mental_map/presentation/widgets/mental_map_widgets.dart
mobile/lib/features/clinical_reports/presentation/clinical_report_options_page.dart
docs/ui/homologation-polish.md                                          (este arquivo)
```

---

## 5. Como validar

```bash
cd mobile
flutter analyze
flutter test
flutter run --dart-define-from-file=env.local.json
```

Checklist rápido:

- [ ] Trilha lista 10 passos com conectores e legenda legível
- [ ] Dashboard exibe banner + barras quando há YSQ/YAMI
- [ ] Mapa mental mostra empty states com dicas quando módulo vazio
- [ ] Tela de PDF permite selecionar seções e gera arquivo sem erro
- [ ] Nenhuma migration ou Edge Function foi modificada
