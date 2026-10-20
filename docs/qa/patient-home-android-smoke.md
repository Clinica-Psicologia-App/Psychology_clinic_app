# Homologação Android — atalhos da home do paciente

Data: 2026-10-20. Branch: `audit/astra`. Resultado: **quatro atalhos e quatro
retornos à home aprovados**.

## Ambiente e preparação

APK debug atual instalado em uma instância descartável do AVD Small_Phone,
com captura de 720 × 1280 px (viewport 360 × 640). O APK já incluía as mudanças
de UI existentes e a correção do cartão Personalidade; os commits seguintes
alteraram somente testes e documentação. Não houve alteração de aplicação
nesta homologação.

SHA-256 do APK instalado:
`240e2e4766f80b2aa15532cafd8e83ccda594f36952791a160732003e873ed5d`.

O CLI Maestri não estava disponível; a interação foi feita pelo Android SDK/ADB.
A instância do usuário em `emulator-5554` foi preservada. A instância temporária
`emulator-5556` foi mantida em processo separado e encerrada no final.

Foi criado um novo login de paciente e um novo cadastro `Paciente TESTE HOME`
na clínica sintética previamente verificada. O responsável era o psicólogo
demo existente. O provisionamento seguiu o padrão de seed pela Management API;
o aplicativo entrou pela tela de login com e-mail e senha reais dessa conta,
usando a configuração pública existente. Credenciais ficaram apenas em arquivo
local ignorado e não foram impressas.

## Execução

O onboarding e o tour inicial foram dispensados. Todos os caminhos foram
abertos por toque nos cards da home, sem deep links.

| Atalho | Destino observado | Estado | Voltar do Android |
|---|---|---|---|
| Meu plano terapêutico | MEU PLANO | Mesmo paciente/responsável, fase Conhecer, progresso 0/12 | Home preservada |
| Mapa mental | MAPA MENTAL | Mesmo paciente/responsável, Em construção, zero questionários/metas | Home preservada |
| Biblioteca | RECURSOS | Mesmo paciente/responsável, Nenhum recurso liberado para você ainda | Home preservada |
| Monitor diário | MONITOR DIÁRIO | Mesmo paciente/responsável, sem acompanhamentos, Novo registro disponível | Home preservada |

O card Biblioteca usa atualmente a rota `/patient/resources`, conforme
`TherapyResourceRoutes.patientList`. A tela RECURSOS é o destino configurado;
não foi feita mudança de nomenclatura ou fluxo nesta etapa.

A árvore de acessibilidade foi lida na home, plano, recursos e monitor. No
mapa, duas leituras falharam no auxiliar ADB; a captura visual mostrou a tela
carregada e o retorno à home funcionou. Não foi atribuído esse erro à aplicação.
As capturas foram inspecionadas visualmente, sem tela de erro ou overflow
visível no trecho conferido. A amostra das últimas 350 linhas do processo
ao final não encontrou mensagens com erro/exceção/overflow; isso não equivale
a monitoramento completo da sessão.

Evidências locais no diretório `post-test` desta tarefa:
`home-shortcuts.png`, `home-plan.png`, `home-map.png`, `home-library.png` e
`home-monitor.png`. Capturas contêm somente identificação sintética.

## Limpeza e limites

O aplicativo foi encerrado e seus dados locais apagados somente na instância
temporária. O paciente, perfil e usuário Auth foram removidos em transação,
com validação de IDs, nome sintético, clínica e e-mail de teste. Uma consulta
independente após o commit confirmou **zero pacientes, perfis, usuários Auth,
identidades e sessões** desse conjunto. A clínica e o paciente demo anterior
continuaram presentes. O arquivo de credenciais temporário foi removido.

Esta homologação valida login, quatro aberturas, estados vazios e quatro
retornos com a conta real de paciente. Não cobre gravação de monitor,
conteúdo liberado da biblioteca, mapa preenchido, ações internas da jornada,
texto ampliado, tablet, iOS, acessibilidade completa ou build de release.
Não houve alteração de schema, policies, grants, permissões ou dados clínicos
fora do conjunto sintético criado para o teste.

`flutter analyze` reexecutado antes do commit da documentação: exit 1,
144 ocorrências (0 errors, 12 warnings, 132 infos), mantendo a baseline.
A suíte anterior de 492 testes aprovados não foi repetida nesta etapa, que
alterou somente documentação e executou a homologação Android descrita acima.
