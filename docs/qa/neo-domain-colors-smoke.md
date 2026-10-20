# Homologação das cores NEO — Infográfico e Mapa Mental

Data: 2026-10-20. Branch: `audit/astra`.

Este documento registra a conferência inicial e, na seção final, a correção
posterior autorizada para tornar o nó Personalidade acessível.

## Escopo e estado inicial

Antes de editar arquivos, foram conferidos o Git, a paleta compartilhada,
builders, providers, widgets e os relatórios anteriores. As 61 alterações
rastreadas e os seis caminhos não rastreados preexistentes foram preservados.
O APK debug gerado na homologação anterior foi reutilizado; não houve alteração
de código, dependências, schema, RLS, navegação ou layout nesta etapa.

O formulário e o perfil de personalidade já tinham sido homologados no Android.
Nesta continuação foram inspecionados Mapa Mental e Infográfico. O dashboard
clínico/Panorama não carrega nem exibe NEO atualmente: seu repositório e dados
tratam questionários e outros sinais, sem avaliações de personalidade. Portanto,
não existe apresentação de domínios NEO para conferir nessa tela. Não foi
adicionada uma nova integração ao Panorama.

## Dados e execução

Foi criada uma única avaliação NEO não compartilhada, com marcador exclusivo,
no paciente sintético já autorizado, usando a conta de psicólogo e a chave
pública. A preparação exigiu nome exato de teste, vínculo com o profissional e
ausência de outras avaliações de personalidade nesse paciente. Credenciais e
identificadores ficaram somente em arquivos locais ignorados pelo Git.

| Domínio | Escore T | Classificação | Cor esperada |
|---|---:|---|---|
| Neuroticismo | 29 | Muito Baixo | Vermelho (`AppColors.error`) |
| Extroversão | 44 | Baixo | Âmbar (`AppColors.warning`) |
| Abertura à experiência | 55 | Médio | Verde (`AppColors.success`) |
| Amabilidade | 65 | Alto | Lilás (`AppColors.purple`) |
| Conscienciosidade | 66 | Muito Alto | Azul (`AppColors.blue`) |

Execução no AVD Small_Phone descartável de 360 × 640 lógicos, com login real e
rotas normais autenticadas. A instância existente do usuário foi preservada.
Na primeira tentativa de instalação o dispositivo ainda estava offline durante
o boot; a instalação foi concluída depois de confirmar `sys.boot_completed=1`.

## Resultado

**Infográfico aprovado para esta amostra.** A página real carregou a avaliação
remota e exibiu os cinco nomes, escores, classificações, ícones e barras com as
cores esperadas. A captura `neo-colors-infographic-phone.png`, preservada no
diretório local de evidências da tarefa, registra todos os domínios. Não foi
necessário corrigir a paleta ou o renderer.

**Mapa Mental: apresentação de personalidade pendente.** O repositório carrega
a avaliação; `buildMentalCaseMap` prepara um nó `personality` com até três
resumos de domínio. Os helpers já resolvem as cores para os rótulos canônicos.
Porém, os dois layouts do diagrama renderizam somente IDs fixos:

- `_MentalMapMobileOrbit`, em `mental_map_widgets.dart`: seis posições para
  esquemas, modos, problemas, apego, objetivos e enfrentamento.
- `MentalMapRadialHub`, no mesmo arquivo: oito posições; inclui também
  parentais e história, mas não `personality`.

A página envia `data.caseMap.allNodes` ao hub, porém os IDs fora dessas posições
não são desenhados. A inspeção Android confirmou os seis módulos do diagrama
móvel sem acesso ao nó Personalidade. Assim, os pontos coloridos de seus
resumos/detalhes não puderam ser homologados pela tela real. A captura
`neo-colors-map-hub.png` registra o diagrama observado. A conclusão de ausência
na tela larga vem da inspeção dos IDs de posição no código, não de execução
visual em tablet.

Esse achado exige uma correção de exibição do nó, separada da paleta. Não foi
redesenhado o mapa nesta etapa de conferência. Como próximo ajuste, dar acesso
ao nó já preparado, reutilizando o detalhe existente, e então verificar os
três resumos e suas cores. O resumo de três itens é o limite atual do builder;
o perfil completo e o Infográfico apresentam os cinco domínios.

## Validação e limpeza

- **17 testes existentes aprovados:** personalidade, builder do Infográfico e
  widgets do Mapa Mental. Esses testes não comprovam, sozinhos, a exibição do
  nó Personalidade no diagrama; o achado visual permanece pendente.
- `flutter analyze`: **exit 1, mesmas 144 ocorrências** — 0 errors, 12 warnings,
  132 infos. Sem supressão de regras.
- Suíte completa não repetida nesta etapa sem alteração de código. A última
  execução continua com 481 aprovados e as mesmas 7 falhas documentadas.
- A amostra de logs do aplicativo após navegar nas telas não apresentou erro
  Flutter de layout; houve apenas aviso do renderizador Android. Leituras da
  hierarquia via auxiliar ADB falharam intermitentemente no mapa; a inspeção
  desse estado foi feita por capturas de tela, sem interpretar essas falhas
  como defeito do aplicativo.
- Leitura REST independente confirmou exatamente uma avaliação não
  compartilhada, com os cinco valores esperados. A avaliação foi excluída por
  ID, paciente e marcador exatos; ausência confirmada (`cleanup: passed`).
- Conta, clínica e paciente sintéticos foram mantidos. O aplicativo foi
  encerrado e somente a instância descartável do emulador foi fechada.

Não foram validados nesta passagem: exportação PNG/PDF, login do paciente,
isolamento entre clínicas, release, iOS ou aparelho físico.

## Correção posterior — acesso ao nó Personalidade

Após autorização para prosseguir com esse ajuste, foi acrescentado ao
`MentalMapVisualHub` um cartão de Personalidade abaixo do diagrama, reutilizando
`MentalMapHubNode` e o callback da página. Essa posição é comum aos layouts móvel
e largo, evitando redistribuir a órbita existente. O cartão mostra os três
resumos já preparados pelo builder e abre `MentalMapNodeDetailSheet`; a ação
principal do detalhe continua apontando para o módulo de personalidade da
sessão. Nenhum dado de paciente é buscado por um novo caminho.

O cartão usa apenas o nó real recebido da página, inclusive quando está
pendente/sem avaliação; o placeholder interno de “Versão futura” não é exibido
nesse cartão. Sua altura acompanha a escala de texto. Nenhum schema, permissão,
papel, provider ou cálculo clínico foi alterado.

Testes de regressão reproduziram a ausência do título Personalidade em larguras
360 e 900 antes do ajuste. Depois, quatro cenários novos validaram:

- Presença, toque e abertura do detalhe em ambas as larguras.
- Cores vermelho/âmbar/verde dos três resumos e dos pontos do detalhe.
- Novo cartão/detalhe com texto ampliado em 1,6, isolado da órbita antiga.
- Cartão pendente acessível, sem rótulo “Versão futura”.

Os testes de widgets e fluxo do mapa somaram **15 aprovados**. A suíte completa
final somou **485 aprovados e as mesmas 7 falhas anteriores**.

A primeira execução com texto 1,6 e toda a órbita encontrou overflow de 4 px nos
seis nós móveis antigos, cujas caixas continuam em 84 × 72. Essa limitação foi
registrada em `TECH_DEBT.md`. O teste ampliado foi delimitado ao novo cartão e
detalhe; não houve supressão de exceções nem alegação de acessibilidade completa
do mapa. A suíte completa foi reexecutada após essa delimitação.

Homologação final Android em 360 × 640, com novo APK debug e uma avaliação
sintética não compartilhada:

1. Abrir Mapa Mental do paciente de teste e rolar até abaixo do diagrama.
2. Conferir cartão Personalidade preenchido com Neuroticismo: Muito Baixo
   em vermelho, Extroversão: Baixo em âmbar e Abertura: Médio em verde.
3. Tocar no cartão: detalhe existente aberto com origem NEO PI-R e os três
   resumos com pontos nas mesmas cores.
4. Tocar em Abrir avaliação de personalidade: lista carregada para o mesmo
   paciente, com a única avaliação sintética esperada.

Capturas `neo-node-card-android.png` e `neo-node-detail-android.png` preservam
o resultado no diretório local de evidências. A consulta independente confirmou
os cinco escores originais sem alteração. A avaliação temporária foi removida
por ID/paciente/marcador e a ausência confirmada (`cleanup: passed`). Apenas a
instância descartável foi encerrada. O usuário, clínica e paciente de teste
foram mantidos.

`flutter analyze` manteve **144 ocorrências: 0 errors, 12 warnings, 132 infos**.
Build APK debug aprovado, com os mesmos avisos existentes do Kotlin Gradle
Plugin. Logs amostrados após a navegação não mostraram erro Flutter de layout;
apenas o aviso do renderizador Android. Tela larga e cartão sem avaliação foram
validados por widgets; não houve execução Android em tablet nem login de paciente.

A pendência de acesso ao nó está resolvida. O limite de três resumos e a
ausência de NEO no Panorama permanecem como comportamento atual. Exportação,
RLS entre contas e build de release continuam fora desta evidência.
