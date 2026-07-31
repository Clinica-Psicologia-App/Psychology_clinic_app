# EsquemaCore — Detalhamento completo da UI

App Flutter (Material 3, somente tema claro, pt-BR) para clínicas de Terapia do Esquema.
Três perfis: **Admin da plataforma**, **Psicólogo** e **Paciente**, cada um com área isolada por rotas (`/platform`, `/psychologist`, `/patient`).

---

## 1. Design System (fundação de todas as telas)

### Paleta (guia de marca oficial)
| Cor | Hex | Uso |
|---|---|---|
| Turquesa | `#00B2A9` | Primária, acentos, FAB, progresso |
| Ciano | `#0096D6` | Secundária, botões de texto, módulo timeline/monitor |
| Azul | `#3B82F6` | Módulo questionários/genograma |
| Roxo | `#7B5CF6` | Terciária, módulo mapa mental/recursos |
| Navy | `#0D1B3D` | Texto principal, botões preenchidos, AppBar |
| Fundo | `#F4F7FB` | Scaffold |
| Sucesso | `#059669` | Status concluído |
| Alerta | `#D97706` | Status pendente |
| Erro | `#DC2626` | Erros |

### Tipografia
- **Poppins** (via google_fonts) em todo o app
- Títulos w700, corpo w400, labels w600–w800

### Gradientes de marca
- `brand`: turquesa → azul → roxo (diagonal) — heros, painel do login
- `brandHorizontal`: turquesa → ciano → azul — detalhes (handle de bottom sheet)

### Formas e sombras
- Raios: 8/12/16/20/24px (cards usam 16, heros 20)
- Sombras suaves tingidas de navy (5–8% alpha, blur 12–24)

### Sistema de animação (100% custom, sem Lottie/Rive)
- `MotionReveal` — entrada fade + slide sutil de cada bloco
- `MotionStaggered` / `staggerDelay` — cascata em listas (55ms de intervalo)
- `MotionSurface` — micro-escala em hover (1.008) e pressão (0.992)
- Transição de página global: fade + slide diagonal sutil
- **Tudo respeita "remover animações" do sistema (acessibilidade)** — cai para renderização instantânea

---

## 2. Ícone do app (launcher)

Gerado programaticamente via Canvas (1024×1024):
- Fundo full-bleed com gradiente diagonal turquesa → ciano → azul → roxo
- Cérebro branco estilizado: dois hemisférios com contorno de "bumps", fissura central vazada revelando o gradiente
- Rede neural: hub central em anel + 6 conectores radiais vazados com nós
- 3 nós externos em anel ultrapassando a silhueta (assinatura da marca)
- **Adaptive icon Android**: camadas separadas de foreground (cérebro, safe zone 62%) e background (gradiente) — adapta-se a máscara redonda/squircle
- Cauda inferior direita estilo balão de fala (flick da marca)

---

## 3. Fluxo de entrada

### Splash
- Fundo gradiente branco → azul-claro
- Logo com animação de entrada (scale 0.82→1 com easeOutBack + fade)
- Halos turquesa "respirando" atrás da marca (loop 2.6s)
- Três pontos pulsantes em sequência + "Preparando seu espaço..."
- Restaura sessão automaticamente

### Onboarding (4 slides)
- PageView com parallax; cada slide tem arte central: círculo gradiente 116px com ícone branco + 2 ícones satélites posicionados por trigonometria + halos translúcidos
- Slides: Boas-vindas (turquesa) / Jornada (roxo) / Questionários (azul) / Evolução (ciano)
- Indicador de pontos animado (largura 8→26px, cor interpolada)
- Botões "Pular" (some no último) e "Continuar/Começar" com AnimatedSwitcher

### Login
- **Telas largas**: split layout — metade esquerda com painel gradiente da marca + logo monocromático + headline; metade direita formulário (max 420px) com slide-in
- **Mobile**: formulário centralizado com logo no topo
- Campos e-mail/senha (toggle de visibilidade), "Esqueci minha senha", card informativo "Novo acesso?", links Termos/Privacidade
- Chips de contas de teste (somente em builds com flag habilitada)
- LoadingOverlay "Entrando..." durante autenticação

---

## 4. Homes por perfil (todas usam o BrandHeroCard)

### BrandHeroCard (hero compartilhado — o elemento central do redesign)
- Card com gradiente da marca (turquesa → azul → roxo) em **animação de respiração**: loop de 4,2s onde as cores e a direção do gradiente se deslocam suavemente (turquesa↔ciano, azul se aquece)
- **Saudação automática por horário**: "Bom dia" / "Boa tarde" / "Boa noite"
- Avatar circular branco 64px com inicial do nome e **halo pulsante** sincronizado com a respiração
- Nome do usuário em branco w700 (headlineSmall)
- Marca d'água: logo monocromático 150px a 12% de opacidade no canto superior direito
- Chips translúcidos (branco 16% + borda branca 28%): role do usuário + e-mail
- Sombra azul difusa (28% alpha, blur 26) projetando o card
- Entrada com MotionReveal

### Home do Psicólogo (`/psychologist`)
- AppBar "EsquemaCore / Área do profissional" + botão sair
- BrandHeroCard
- Seção "Módulos de trabalho" (título com barra vertical turquesa)
- Card "Pacientes" (acento azul, ícone em box gradiente) — gated pelo plano da clínica, mostra pill "Liberado"/"Bloqueado"

### Home do Paciente (`/patient`)
- AppBar "EsquemaCore / Minha jornada terapêutica"
- BrandHeroCard
- Seção "Jornada terapêutica"
- Card "Meu plano terapêutico" (acento roxo, pill "Continuar") → trilha guiada

### Home do Admin (`/platform`)
- BrandHeroCard com chip "Administrador da plataforma"
- Seção "Operação principal": tiles Pacientes (turquesa), Clínicas (azul), Usuários (roxo)
- Seção "Governança clínica": Catálogo de questionários (roxo), Acesso a questionários (ciano)
- Tiles: ícone 46px em **box gradiente do acento com sombra colorida** + título w700 + subtítulo 2 linhas + **chevron em chip circular tingido** — hover/press com micro-escala

---

## 5. Detalhes do paciente (visão do psicólogo)

- Header com dados do paciente, psicólogo responsável, contexto de vida e demandas
- **Grid de módulos 2 colunas** (12 módulos) — cada card:
  - Ícone branco em box 42px com gradiente do acento do módulo + sombra colorida
  - Título w700 + subtítulo 11.5px (2 linhas)
  - Cadeado + dessaturação quando bloqueado pelo plano da clínica
  - Reveal em cascata linha por linha (45ms)
- Módulos e acentos: Questionários (azul), Resultados (ciano), Dashboard clínico (navy), Personalidade (roxo), Recursos terapêuticos (roxo), Problemas (âmbar), Objetivos (turquesa), Check-ins (turquesa), Mapa mental (roxo), Genograma (azul), Linha do tempo (ciano), Monitor diário (ciano)
- Gating por entitlements: subtítulo troca para "Validando permissões..." (carregando) ou "Bloqueado pelo plano da clínica."

---

## 6. Fluxo de questionários (novo — atribuição por paciente)

### Página de questionários — visão do Psicólogo
- Nome do paciente no topo
- **Seção "Atribuições"** com botão FilledButton "Atribuir" (navy, ícone +)
- Tiles de atribuição com chip de status colorido:
  - **Pendente** = âmbar (`#D97706` sobre `#FEF3C7`) com ícone ampulheta
  - **Em andamento** = ciano com ícone de edição
  - **Concluído** = verde (`#059669` sobre `#D1FAE5`) com check
- Cada tile: avatar tingido do status, nome do questionário, mensagem do psicólogo em itálico, "Atribuído por [nome] em [data]", botão cancelar (X vermelho) em pendentes
- **Bottom sheet de atribuição** (DraggableScrollableSheet 70%):
  - Handle com gradiente da marca (48×4px)
  - RadioList do catálogo do psicólogo (nome + código)
  - Campo de mensagem opcional (500 chars) com hint amigável
  - Botão "Atribuir questionário" com spinner durante envio
- **Seção "Iniciar na sessão"** (divider + subtítulo explicativo): catálogo completo para aplicar na hora — tiles com código, autor, período de referência, chips de status clínico e "Já respondido"/"Em andamento"

### Página de questionários — visão do Paciente
- Subtítulo "Questionários atribuídos pelo seu psicólogo."
- **Somente as atribuições** (não vê o catálogo completo)
- Mesmos chips de status; concluídos ficam visíveis não-clicáveis
- Estado vazio acolhedor: "Nenhum questionário atribuído ainda. Aguarde seu psicólogo."

### Intro do questionário
- Nome, descrição, banner de homologação (se instrumento não validado)
- Card de orientação do período de referência
- Para estilos parentais: até 3 cards de cuidador com switch, radio de papel (Mãe/Pai/Tia/Avó/Avô/Outro) e campos de texto
- Botão "Iniciar questionário"

### Resposta (answer)
- Uma pergunta por vez com barra de progresso
- Fluxo parental: progresso por contexto (por cuidador)
- Escala Likert com inputs adaptados ao tipo de resposta
- PopScope com diálogo de confirmação ao sair com respostas pendentes
- Banner de modo preview (admin testando o instrumento)

### Sucesso
- Confirmação com resultado resumido e navegação de volta

---

## 7. Resultados

### Lista (psicólogo e paciente)
- Tiles com nome do questionário, status, datas, contagem de respostas
- Paciente vê **apenas resultados revisados/liberados** pelo psicólogo

### Detalhe do resultado
- Card da resposta: instrumento, código, status, datas, contagem
- **Card de validação do terapeuta** (staff): campo de notas + botões "Marcar como revisado"/"Remover revisão" — é o gate de liberação para o paciente
- Card "aguardando revisão clínica" quando pendente
- Seção de scoring estruturado com disclaimers
- Fluxo parental: cards por contexto (cuidador) com esquemas agregados
- Cards de categoria: classificação, score total/médio, cores por severidade
- Lista de respostas: código, texto da pergunta, figura parental, label da resposta

---

## 8. Telas administrativas

- **Catálogo de questionários**: CRUD completo — criar, editar versões, publicar, arquivar
- **Acesso a questionários**: seleção de psicólogo + switches por instrumento (é o que libera o catálogo de cada profissional)
- **Clínicas**: gestão de clínicas, planos e entitlements por feature
- **Usuários**: administradores/psicólogos, ativação, limites de pacientes por psicólogo
- **Pacientes (global)**: visualizar, inativar, reativar, excluir

---

## 9. Componentes compartilhados (biblioteca interna)

| Componente | Função |
|---|---|
| `AppScaffold` | Shell com AppBar 2 linhas + glow radial turquesa decorativo no topo |
| `BrandHeroCard` | Hero gradiente animado (descrito acima) |
| `ClinicalModuleCard` | Card horizontal de módulo com acento, pill de status e seta |
| `ModuleGridCard` | Card vertical compacto para grid 2 colunas |
| `EsquemaCoreLogo` | Logo em 4 variantes (stacked/horizontal/icon/monochrome) com fallback |
| `AsyncStateBody` | Loading skeleton → erro com retry → vazio → conteúdo revelado |
| `LoadingOverlay` | Overlay de carregamento com mensagem |
| `StatusChip` / pills | Chips de estado coloridos |
| `GradientProgressIndicator` | Barra de progresso com gradiente turquesa→azul |
| `ResponsiveContent/Grid` | Largura máxima 1200px + colunas adaptativas por breakpoint |

### Breakpoints
compact <600 / medium ≥768 / expanded ≥1024 / wide ≥1440 — grids e paddings adaptam automaticamente; telas largas ganham logo horizontal no topo das homes.
