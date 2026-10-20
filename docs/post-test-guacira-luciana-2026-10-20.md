# Ajustes pós-teste — Guacira e Luciana

Data: 2026-10-20. Branch: `audit/astra`.

O pedido anuncia dez pontos, mas detalha sete. Foram implementados os sete
descritos. Alterações locais anteriores foram preservadas e excluídas do commit
deste trabalho, inclusive nos dois arquivos com mudanças sobrepostas.

## Diagnóstico e implementação

1. **NEO PI-R / persistência:** o botão intermediário só incrementava `_step`.
   Agora cada etapa aguarda a gravação; o ID retornado no primeiro INSERT é
   reutilizado nos UPDATEs. A tela só avança após sucesso. Falhas mantêm os
   campos e exibem o banner de erro. Campos ficam bloqueados durante a gravação.
   O UPDATE exige uma linha retornada, evitando sucesso aparente quando nenhuma
   linha foi atualizada. O fluxo usa PostgREST/RLS diretamente, sem Edge Function.
2. **YAMI / Panorama:** cinco maiores médias, selecionadas a partir de todos os
   modos; nomes sem código interno. Os modos foram retirados do consolidado e
   dos detalhes técnicos somente no Panorama, permanecendo nas outras telas.
   A contagem de esquemas desse consolidado também exclui os modos ocultados.
3. **YSQ / Panorama:** cinco maiores médias, com soma bruta secundária quando
   disponível. A média pode ser reconstruída por soma/itens respondidos em
   snapshots antigos. Resultados sem dados suficientes para calcular média
   ficam fora do ranking, preservados nos detalhes. Na ausência de médias,
   o card informa que não há médias disponíveis.
4. **Escalas:** extremos descritivos de YSQ e YAMI na escala 1–6, no componente
   compartilhado entre paciente e profissional, com quebra de linha.
5. **Esquemas:** barras individuais ativadas em lilás e não ativadas em cinza.
   Cores dos cabeçalhos ainda identificam os domínios.
6. **Escore T:** classificação automática pelas faixas fornecidas no pedido:
   até 29 / 30–44 / 45–55 / 56–65 / a partir de 66. O formulário aceita valores
   inteiros não negativos; rejeita texto inválido, frações, NaN e infinito.
   Campos vazios continuam opcionais. A classificação é calculada em leitura
   para registros com score e serializada ao salvar. Registros da view do
   paciente, sem score, preservam a classificação recebida.
7. **Cores NEO PI-R:** mapa de tons no domínio, sem dependência de Flutter, com
   resolução para tokens existentes: vermelho, âmbar, verde, lilás, azul.
   Aplicado no registro, perfil compartilhado, mapa mental e infográfico.

## Evidência e validação

Lidos: `AGENTS.md`, `CLAUDE.md`, arquitetura/estado/dívida técnica; formulário,
repositório e providers de personalidade; migration e políticas existentes;
builders/widgets do Panorama, questionários, mapa mental e infográfico.

- Bugs prioritários: **21 testes direcionados passaram**, antes das melhorias.
- Validação final direcionada: **43 testes passaram** nos arquivos
  `personality_assessment_form_test.dart`, `personality_assessment_domain_test.dart`,
  `clinical_dashboard_domain_test.dart`, `consolidated_schema_card_test.dart`,
  `question_scale_labels_test.dart` e `patient_infographic_builder_test.dart`.
- Cobertura adicionada: gravação por etapa no mesmo ID, tentativa após erro,
  entrada inválida sem envio, classificação exibida/persistida, limites do T,
  ranking por média com ordem bruta inversa, ocultação do bloco duplicado e
  legendas em viewport de 360 px.
- `flutter analyze`: **exit 1, 144 ocorrências: 0 errors, 12 warnings, 132 infos**.
  Os warnings estão em trechos preexistentes, fora das alterações deste patch.
  Não houve supressão de regras ou uso de flags para torná-los não fatais.
- `flutter test`: **478 passaram, 7 falharam**, reproduzido em segunda execução.
  Falhas:
  - `mental_map_domain_test.dart`: espera 4 nós de contexto; código retorna 5.
  - `patient_journey_domain_test.dart`: expectativa de disponibilidade 5; retorna 4.
  - `patient_library/staff_library_catalog_indicate_test.dart`: espera duas
    ocorrências de “Biblioteca clínica”; encontra zero.
  - Quatro testes em `patient_home_test.dart`: `pumpAndSettle timed out`.
  Esses módulos já tinham mudanças locais antes deste trabalho. As falhas
  não foram corrigidas nem foi executada uma suíte em checkout isolado da baseline.
- Uma execução de análise com saída redirecionada e uma tentativa de coletar
  testes via subprocesso ficaram sem progresso observável e foram interrompidas.
  Os resultados acima vêm das execuções diretas concluídas.

## Continuação — ranking com dados legados

Antes de editar, foram conferidos o status do Git, os 24 arquivos preparados,
os sete ajustes no código e as validações registradas. Não havia commit desses
ajustes. A próxima pendência identificada foi uma lacuna do Top 5: o fallback
`averageScore ?? score` ainda misturava pontos brutos e médias.

O teste de regressão reproduziu o problema: 95 pontos sem média eram ordenados
antes de uma média 5,4. O ranking agora considera apenas médias disponíveis ou
reconstruídas pela soma/itens respondidos. Os detalhes técnicos não são filtrados.
Nenhuma outra funcionalidade foi refeita nesta continuação.

- Testes direcionados: **46 aprovados**, incluindo três novos cenários de
  dados legados, preservação da média explícita e ausência de médias.
- Suíte completa após a correção: **481 aprovados e as mesmas 7 falhas**
  relacionadas acima. Não houve nova falha na suíte.
- A homologação REST remota foi posteriormente concluída, conforme a seção
  seguinte. RLS entre contas autenticadas e homologação visual dos demais módulos
  continuam pendentes; o formulário Android foi validado posteriormente.

## Limites e próxima homologação

Homologação remota em 2026-10-20: saúde de autenticação HTTP 200. Após a recusa
do login demo antigo, o responsável autorizou criar novo usuário de teste.
Foram provisionados um psicólogo, uma clínica isolada e um paciente sintético.
O smoke REST específico passou por criação, cinco atualizações e releituras,
bloqueio de leitura anônima, limpeza da avaliação e logout da sessão criada.
Os 8 testes locais do script também passaram. A conta e o paciente sintéticos
foram mantidos; credenciais somente no arquivo local ignorado pelo Git.
Veja [procedimento e evidência remota](qa/personality-remote-smoke.md).

O teste automatizado de persistência usa repositório simulado; separadamente,
o smoke REST confirmou a escrita remota e a homologação Android executou o
formulário real com a nova conta de teste. Em emulador de 360 × 640, a avaliação
parcial persistiu após encerrar e reabrir o processo. Com a rede desligada,
o salvamento manteve o valor e a etapa, exibiu erro e não alterou o banco.
Após reconectar, a nova tentativa funcionou sem redigitar. Os cinco domínios
e a faceta de teste ficaram no mesmo registro não compartilhado, com as
classificações corretas, e o perfil completo reabriu após novo reinício.
A avaliação temporária foi excluída e a ausência confirmada. Build APK debug
concluído, sem mudança de código nesta homologação. Não foram executados
isolamento RLS entre contas autenticadas, build de release ou validação visual
completa dos demais módulos.
Nenhum schema, migration ou Edge Function foi alterado; nenhum deploy ou push foi
realizado.

Antes de liberar: validar build de release e ampliar a cobertura dos demais
módulos. As cores NEO e o isolamento autenticado do escopo clínico foram
posteriormente conferidos, conforme as continuações abaixo. YAMI/YSQ no Panorama foram posteriormente
conferidos com snapshots remotos sintéticos, conforme a seção seguinte.
O fluxo de formulário,
reabertura e falha de rede foi aprovado no emulador Android; aparelho físico e
outras plataformas continuam fora desta evidência.
Salvar por etapa aumenta as escritas (um INSERT seguido de UPDATEs), mantendo
um único registro por preenchimento. Não foi adicionada recuperação automática
de INSERT cujo resultado se perca na rede; esse caso exige consulta antes de
repetir uma criação para evitar possível duplicata.

Perfis antigos compartilhados com pacientes expõem só classificação pela view.
Para alinhar uma classificação antiga divergente com o Escore T, o profissional
precisa salvar novamente a avaliação; não houve regravação em massa.

## Continuação — homologação YSQ/YAMI no Panorama

Foram executadas duas aplicações no paciente sintético pelos endpoints normais:
YSQ com 90 respostas/18 esquemas e YAMI com 186 respostas/10 modos. As médias
calculadas remotamente corresponderam às esperadas. No Android, os rankings
exibiram cinco nomes, médias principais e pontos secundários. A amostra YAMI
comprovou ordem diferente da soma bruta. Não houve bloco de modos repetido no
consolidado nem nos detalhes expandidos; o histórico foi preservado.

As barras do consolidado estavam corretamente lilás/cinza. A orientação ainda
dizia “em vermelho” e os símbolos auxiliares permaneciam vermelhos. Foram
ajustados somente esses três trechos no widget existente. A suíte completa foi
reexecutada: 481 aprovados e as mesmas 7 falhas, sem nova falha. Antes da correção,
31 testes direcionados de dashboard, consolidado e legendas passaram.
O APK atualizado foi conferido no Android; analyzer manteve 144 ocorrências,
sem errors, com 12 warnings e 132 infos. As duas aplicações de teste foram
removidas e a ausência foi confirmada pelas RPCs normais do psicólogo.

Procedimento, resultados e limites em
[homologação do Panorama](qa/panorama-ysq-yami-smoke.md).

## Continuação — cores NEO nas telas integradas

O Infográfico foi aprovado no Android com uma avaliação remota sintética:
cinco domínios, escores/classificações esperados e cores vermelho, âmbar, verde,
lilás e azul. A avaliação temporária foi removida e a ausência confirmada.
O Panorama atual não carrega nem exibe NEO, portanto essa integração não foi
considerada homologada nem adicionada nesta conferência.

No Mapa Mental foi encontrado um limite de exibição: o nó `personality` é
preparado pelos dados, mas os slots fixos do diagrama móvel e largo não o
renderizam. A tela Android confirmou sua ausência. A paleta e o resolver de
rótulos estão implementados, mas suas cores no mapa permanecem pendentes até
o nó ficar acessível. Nenhum layout foi alterado nesta etapa.

Passaram 17 testes existentes dos módulos envolvidos; analyzer manteve
144 ocorrências (0 errors, 12 warnings, 132 infos). A suíte completa não foi
repetida nesta etapa sem mudanças de código.
Veja [evidências e próximo ajuste](qa/neo-domain-colors-smoke.md).

## Continuação — nó Personalidade acessível no Mapa Mental

O hub agora exibe o nó real de Personalidade em cartão abaixo do diagrama,
reutilizando `MentalMapHubNode` e a abertura de detalhe já ligada à sessão e ao
paciente. As posições e animações da órbita foram preservadas. O cartão também
fica disponível sem avaliação, mantendo o encaminhamento existente ao módulo.

Quatro cenários de regressão cobrem larguras 360/900, três cores do resumo e
detalhe, toque e cartão pendente. Texto ampliado foi conferido no novo cartão e
detalhe isolados. O hub completo em texto 1,6 revelou overflow nos nós antigos
de altura fixa, registrado na dívida técnica e mantido fora desta correção.

Quinze testes direcionados passaram; suíte final com **485 aprovados e as mesmas
7 falhas**; analyzer com **0 errors, 12 warnings e 132 infos**. APK debug gerado
e homologado no Android: cartão, detalhe colorido e atalho para a lista correta
de avaliações. Registro sintético removido, ausência confirmada; conta mantida.
Nenhum schema, permissão, cálculo clínico ou rota foi alterado.

Veja [procedimento e limites](qa/neo-domain-colors-smoke.md).

## Continuação — isolamento remoto entre contas autenticadas

Homologação com duas clínicas, três psicólogos, dois logins de paciente e três
pacientes, todos novos e descartáveis. Três NEO e dois YSQ completos foram
preparados somente nesses pacientes. **101 verificações aprovadas** usando a
chave pública e JWTs reais; dados do ambiente fora desse conjunto não foram
consultados nem alterados.

Passaram o isolamento entre clínicas e entre responsáveis da mesma clínica,
as tentativas de leitura/alteração sem vínculo, a proibição de autoliberação
pelo paciente e os ciclos de liberação/revogação YSQ e compartilhamento NEO.
Classificações compartilhadas não expuseram escores ou síntese/integração;
marcadores privados de questionário não chegaram à projeção do paciente.
Dois INSERTs negados retornaram 400/P0001 pelo trigger de vínculo, confirmados
por repetição e controles positivos 201, sem aceitar erro genérico como prova.

Todas as contas e clínicas desta matriz foram removidas, com contagens zero
confirmadas após o commit da limpeza; a conta demo anterior foi mantida.
Não houve alteração de schema, policies, grants ou aplicação. O resultado não
se estende a módulos/atores não testados nem substitui a navegação por papel.
Veja [procedimento, matriz e limites](qa/clinical-access-remote-smoke.md).

## Continuação — primeira falha conhecida da suíte

A falha `buildMentalCaseMap returns empty nodes for patient without data` foi
reproduzida isoladamente: o teste esperava quatro nós de contexto, mas o builder
atual retorna cinco, incluindo Personalidade. Esse quinto nó já faz parte do
comportamento autorizado e homologado; removê-lo para satisfazer a expectativa
antiga seria uma regressão.

Foi alterado somente o teste: agora exige os cinco IDs de contexto, sem depender
da ordem, e preserva a verificação de que todos ficam vazios quando não há dados.
O nó Personalidade também deve continuar pendente e sem data de atualização
fictícia. Não houve mudança no builder, na UI, no banco ou nos trabalhos locais
anteriores. Os 47 testes direcionados de domínio, widgets e fluxo do mapa passaram.

A suíte completa final teve **486 aprovados e 6 falhas**, uma falha a menos e
nenhuma falha nova. Permanecem a expectativa de disponibilidade na jornada,
o título da biblioteca e os quatro timeouts da home do paciente. Essas falhas
ficaram fora desta correção, conforme a sequência de uma tarefa por vez.
`flutter analyze` foi reexecutado antes do commit: **exit 1, 144 ocorrências —
0 errors, 12 warnings e 132 infos**, sem novas ocorrências ou supressões.

## Continuação — expectativa de ordenação da jornada

A falha do primeiro teste de `patient_journey_domain_test.dart` foi reproduzida:
esperava ordem 5 para Problemas e demandas, mas recebeu 4. Apesar do nome do
teste mencionar disponibilidade, a falha era de ordenação. A alteração local
existente em `journey_step.dart` já coloca esse módulo no final da fase Conhecer,
antes dos questionários na posição 5.

Somente a expectativa do teste foi corrigida para 4 e foi acrescentada a
verificação da posição 5 dos questionários. A implementação, a UI e as mudanças
locais anteriores foram preservadas. Os **19 testes de domínio e popup da
jornada passaram**. A suíte completa teve **487 aprovados e 5 falhas**, sem
falhas novas: permanecem o título da biblioteca e os quatro timeouts da home.
`flutter analyze` executado antes do commit: **exit 1, 144 ocorrências —
0 errors, 12 warnings e 132 infos**, sem novas ocorrências ou supressões.

## Continuação — teste de indicação na biblioteca

A falha de `staff_library_catalog_indicate_test.dart` foi reproduzida no teste
de confirmação: a indicação para o paciente e a obra corretos já passava, mas
a expectativa ainda procurava dois títulos `Biblioteca clínica`. A tela atual
usa um cabeçalho único com `BIBLIOTECA CLÍNICA`.

Foi alterado somente o teste, preservando as mudanças locais na tela. Além do
título atual, ele exige o fechamento do formulário, a permanência da mesma
instância de estado do catálogo e a obra ainda visível após confirmar.
Os **três testes da biblioteca passaram**. A suíte completa teve **488 aprovados
e 4 falhas**, todas os timeouts já conhecidos em `patient_home_test.dart`.
Não houve mudança na aplicação, navegação, persistência ou permissões. A
verificação usa um notifier de teste; não representa indicação no backend real.
`flutter analyze` executado antes do commit: **exit 1, 144 ocorrências —
0 errors, 12 warnings e 132 infos**, sem novas ocorrências ou supressões.

## Continuação — timeouts dos testes da home do paciente

Os quatro testes de `patient_home_test.dart` foram reproduzidos isoladamente,
todos falhando na preparação com `pumpAndSettle timed out`. O card existente
Meu plano terapêutico usa `AnimationController.repeat(reverse: true)` no
gradiente, que agenda frames continuamente e impede essa espera de terminar.

Foi alterada somente a preparação do teste: 20 chamadas de `pump` de 100 ms
renderizam dois segundos, permitindo resolver os providers simulados e as
entradas em cascata sem esperar que a animação contínua pare. Não foram
removidas verificações, suprimidas exceções ou desativadas animações; nenhuma
mudança foi feita na home ou nas alterações locais anteriores.

Os **oito testes das homes do paciente e psicólogo passaram**. A suíte completa
teve **492 aprovados e nenhuma falha**. As sete falhas conhecidas da validação
inicial estão resolvidas. Esta etapa valida widgets com dados simulados; não
substitui navegação real pelos atalhos, backend ou homologação em dispositivo.
`flutter analyze` executado antes do commit: **exit 1, 144 ocorrências —
0 errors, 12 warnings e 132 infos**, sem novas ocorrências ou supressões.

## Continuação — navegação real da home do paciente no Android

Homologação com um novo paciente e login temporários na clínica sintética
existente, pelo formulário real de autenticação. No AVD Small_Phone, os cards
de plano terapêutico, mapa mental, biblioteca/recursos e monitor diário abriram
os destinos esperados com o mesmo contexto de paciente. Os quatro retornos
pelo Voltar do Android preservaram a home.

Estados vazios foram conferidos por árvore de acessibilidade e capturas visuais;
no mapa, a leitura da árvore falhou e a captura confirmou o estado carregado.
A amostra final de logs não mostrou exceções Flutter. Não houve mudança de
aplicação nem teste de gravação clínica nesta etapa.

O paciente, perfil e usuário temporários foram removidos; consulta independente
confirmou zero registros, identidades e sessões desse conjunto. Credenciais
locais removidas, instância descartável encerrada e demo anterior preservada.
Veja [procedimento, evidências e limites](qa/patient-home-android-smoke.md).
Análise reexecutada antes do commit documental: **exit 1, 0 errors, 12 warnings
e 132 infos**, sem mudança da baseline. A suíte de 492 aprovados da etapa
anterior não foi repetida, pois não houve alteração de código nesta etapa.
