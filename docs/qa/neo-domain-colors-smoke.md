# Homologação das cores NEO — Infográfico e Mapa Mental

Data: 2026-10-20. Branch: `audit/astra`.

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
