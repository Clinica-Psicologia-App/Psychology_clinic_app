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

Validação: suíte Flutter com **504 aprovados, zero falhas**. Cinco testes novos
e análise com 0 errors, 12 warnings e 132 infos, sem novas ocorrências. Os testes
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

## Próxima tarefa

- Acesso ao Diário e cartões de enfrentamento na Biblioteca Praticar.
