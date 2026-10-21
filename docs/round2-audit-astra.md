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

## Próximas tarefas

- Visão staff dos exercícios respondidos.
- Link Modos → Biblioteca 9 (Transformar).
- Acesso ao Diário e cartões de enfrentamento na Biblioteca Praticar.
