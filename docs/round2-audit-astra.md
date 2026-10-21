# Rodada 2 — ajustes pendentes

Branch: `audit/astra`. Uma tarefa por commit; sem push/publicação.

## BUG 1 — contagem de Metas (concluído)

O cabeçalho usava a quantidade de metas não arquivadas e incluía concluídas
como em andamento. Agora conta somente `isActive`, mantendo concluídas e
arquivadas acessíveis na listagem. Não altera status, banco ou permissões.

Quatro regressões reproduziram a falha antes da correção: paciente/terapeuta,
com e sem meta ativa, sempre com concluída e arquivada. Os nove testes de
Metas passaram; suíte completa com **499 aprovados, sem falhas**.
Análise: exit 1, 0 errors, 12 warnings e 132 infos, sem novas ocorrências.
As mudanças locais anteriores na mesma página foram preservadas e não fazem
parte do patch deste bug.

## FEATURE 2 — respostas dos exercícios (implementado localmente)

Acesso pelo cadastro do paciente, em Acompanhar → Exercícios e Tarefas.
Página somente leitura com nome, última data salva, perguntas, respostas,
seleções múltiplas, campo Outro, dificuldade e pedido para conversar na sessão.
A tabela mantém uma resposta por módulo/paciente, sem histórico de versões.
O repositório resolve `patients.id` para `profiles.id` antes de buscar respostas.
Não foi acrescentado acesso clínico ao administrador da plataforma.

Foi confirmado por leitura de metadados no Supabase remoto que a policy staff
passava `profiles.id` para `user_can_access_patient`, que recebe `patients.id`.
Com autorização explícita, a migration `20261021100000` resolve o vínculo e
preserva a checagem canônica do responsável/clínica. Não aplicada remotamente;
**a leitura real pelo terapeuta depende da aplicação e revisão humana dessa policy**.
Nenhuma credencial ou configuração de ambiente faz parte do commit.

Validação: suíte Flutter com **504 aprovados, zero falhas** e análise com
0 errors, 12 warnings e 132 infos, sem novas ocorrências. Cinco testes novos
cobrem vínculo entre IDs, cadastro ausente/sem perfil, apresentação e lista vazia.
`supabase db reset --local` passou no projeto descartável `esquemacore_round2`,
com cópia das migrations atuais (incluindo a migration local preexistente de
recursos saudáveis). Nenhum ambiente Docker existente foi reiniciado/resetado.
O SQL `round2-exercise-responses-rls.sql` passou com rollback: responsável,
outro psicólogo da mesma clínica, outra clínica, dois pacientes e administrador;
escritas staff negadas e confirmação da linha de outra clínica invisível.
O mesmo teste falhou com a policy antiga: responsável esperava 1 linha, recebeu 0.
Não foi realizado teste de navegação em dispositivo para esta funcionalidade.

## FEATURE 3 — Modos → Transformar (concluído)

O cabeçalho de Modos (YAMI) no núcleo clínico do mapa oferece o link
“Ver Biblioteca Transformar” para o psicólogo. O catálogo publicado resolve
o número 9 para o UUID do ambiente; a navegação usa a rota existente.
Não aparece para o paciente nem quando o módulo 9 não está disponível.
O cabeçalho permite quebra de linha em telas estreitas.

Três testes novos verificam o destino correto mesmo com outro módulo na mesma
etapa, a ausência para paciente e o módulo ausente. Suíte completa com
**507 aprovados, zero falhas**; análise com 0 errors, 12 warnings e 132 infos.
Sem alteração de banco. Sem nova homologação em dispositivo.

## FEATURE 4 — Diário e cartões em Praticar (MVP concluído)

A seção Praticar agora inclui Diários (atalho para lista/criação já existentes)
e Cartões de enfrentamento. Os atalhos são exclusivos da visão do paciente e
continuam acessíveis mesmo se o catálogo publicado estiver vazio.

Não havia entidade de cartões de enfrentamento. Foi criado um modelo de domínio
somente leitura com tema, origem (YCI/YRAI), resposta e data. A listagem monta
cartões de reflexão usando os temas da última aplicação concluída com resultados
de cada instrumento, pela extração existente. O texto convida a observar a
situação e construir uma resposta com o terapeuta; não gera diagnóstico ou
prescrição individual. As reflexões são registradas pelo Diário existente.
Personalização/persistência independente do texto do cartão fica fora deste MVP.

A leitura verifica `resultsReleased` e usa as RPCs existentes de resumo/detalhe,
que mantêm as restrições de liberação, vínculo e projeção do paciente no servidor.
São no máximo três chamadas de resultados (lista + dois detalhes), sem novas
tabelas, migrations, permissões ou dependências. Nenhuma nota profissional é
incluída no modelo/apresentação dos cartões. A nova tentativa atualiza também
o cadastro do paciente para reconsultar a liberação, evitando um bloqueio antigo
em cache. Revogação atualiza a lista quando o estado do paciente é recarregado;
esta tela não introduz assinaturas realtime.

Nove testes novos: tipos/status aceitos, última aplicação por instrumento,
ausência de consulta sem liberação, revogação após atualização, vínculo do
paciente, erro/nova tentativa/vazio, rotas e retorno de Diário/cartões e ausência
dos atalhos no catálogo staff. Suíte completa: **516 aprovados, zero falhas**.
Análise final: exit 1, **0 errors, 12 warnings e 132 infos** preexistentes,
sem novas ocorrências.

## Limites de entrega

As quatro tarefas têm implementação local e commits separados. Sem push,
publicação ou aplicação de migration remota. Os testes foram executados na
árvore de trabalho atual, preservando as alterações preexistentes sem incluí-las
nos commits desta rodada. Não se afirma validação de um checkout limpo.

A tela staff de exercícios exige revisão humana e aplicação posterior da
migration autorizada. A rodada não realizou homologação em Android/iOS/web nem
fluxo remoto autenticado dos novos recursos. Os testes de cartões usam dados
sintéticos locais e contratos existentes; não substituem homologação clínica.

Ao encerrar o ambiente descartável, `supabase stop` não encontrou o pipe
`dockerDesktopLinuxEngine`: o engine Docker estava indisponível. O reset e os
testes RLS haviam concluído antes disso; não foi possível confirmar a parada
do container `supabase_db_esquemacore_round2`. Não se reiniciou o Docker nem
se interferiu nos ambientes existentes para tentar a limpeza.
