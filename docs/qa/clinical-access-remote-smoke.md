# Homologação remota de acesso clínico

Data: 2026-10-20. Branch: `audit/astra`. Resultado: **101 verificações aprovadas**.
[Evidência sanitizada por caso](clinical-access-remote-2026-10-20.json).

## Escopo e preparação

Foram revisados os documentos atuais, migrations, policies e funções de acesso.
A definição implantada de `user_can_access_patient`, `user_can_access_response`,
`set_patient_results_released`, `personality_results_public` e da view
`patient_shared_personality` foi lida pela Management API antes dos testes.
O projeto vinculado ao CLI foi comparado com a URL de `env.production.json`.

Foi criado um conjunto **inteiramente descartável**, separado da conta demo
usada nas homologações anteriores:

- Duas clínicas novas, A e B.
- Três psicólogos: A e A2 na mesma clínica; B em outra clínica.
- Dois logins de paciente: um em A e outro em B.
- Três cadastros de paciente, um por psicólogo; o paciente A2 não tem login.
- Três avaliações NEO não compartilhadas, com escores e textos privados
  sintéticos nas colunas de síntese/integração.
- Dois YSQ concluídos pelos endpoints normais de início, resposta e conclusão,
  cada um com as 90 perguntas preenchidas com valores sintéticos válidos.

O provisionamento seguiu o padrão de seed já inspecionado, em transação pela
Management API. Senhas foram geradas no banco e capturadas diretamente em
arquivo local ignorado, sem impressão. **Os testes de acesso usaram a chave
pública e os JWTs reais de cada uma das cinco contas**, não `service_role`,
`SET ROLE` ou sessão administrativa. Consultas clínicas foram limitadas aos IDs
do conjunto recém-criado; nenhum registro clínico real foi lido ou alterado.

## Matriz executada

| Grupo | Verificações | Resultado |
|---|---:|---|
| Psicólogos leem seus próprios pacientes | 3 | Aprovado |
| Leitura/alteração de pacientes e NEO de outro responsável/clínica | 28 | Bloqueado |
| Inserções NEO sem vínculo ou pelo paciente | 3 | Bloqueado |
| Início de questionário de paciente alheio | 3 | Bloqueado (403) |
| Paciente próprio, tabela NEO privada, autoliberação e resultados brutos | 12 | Conforme o papel |
| Liberação de resultados por psicólogo alheio | 3 | Bloqueado (403) |
| RPC de detalhe/listagem de questionário alheio | 8 | Sem dados |
| Ciclo de compartilhamento NEO e liberação/revogação YSQ | 18 | Aprovado |
| Integridade dos registros após tentativas indevidas | 6 | Sem alteração |
| Leitura anônima de NEO | 1 | Sem dados |
| Controles positivos de inserção e confirmação do trigger | 4 | Aprovado |
| Isolamento/projeção repetidos com resultados liberados | 12 | Aprovado |
| **Total** | **101** | **Aprovado no escopo** |

HTTP 200 com lista vazia ou `null` é um bloqueio válido para consultas filtradas
por RLS. Nas tentativas de UPDATE, também foi conferido pelo proprietário que
os campos permaneciam inalterados. Não foi considerado sucesso apenas o status
HTTP. Erros genéricos de configuração não foram aceitos como prova de negação.

### Particularidade dos INSERTs NEO

Dois casos inicialmente esperavam 401/403, mas receberam **400/P0001**. A
análise do trigger mostrou que ele consulta o paciente sob o contexto do ator;
um paciente invisível pela RLS não fornece clínica e dispara a proteção de
vínculo. Os casos foram repetidos exigindo exatamente esse código e essa
mensagem conhecida. O mesmo payload, para o próprio paciente, criou uma linha
com **201**, removida em seguida. Assim, os 400 foram confirmados como bloqueios
reais, não erros de payload. A evidência conserva `initialStatus`, a expectativa
inicial e `verifiedBlock` nesses dois casos; o relatório inicial local também
foi preservado.

## Liberação e dados privados

**Questionários:** antes da liberação, o próprio paciente recebeu a estrutura da
resposta concluída com listas vazias de respostas/resultados. Após a ação do
psicólogo responsável, recebeu os resultados e as 90 respostas pelo RPC. Após
revogar, as listas voltaram a ficar vazias. Contas de outra clínica e psicólogo
sem vínculo continuaram sem dados mesmo durante a liberação.

Foram acrescentados marcadores privados sintéticos ao snapshot de um resultado
de cada YSQ para testar sua projeção. Os marcadores não apareceram no RPC do
paciente; a leitura direta de `questionnaire_results` permaneceu vazia mesmo
após a liberação. A projeção também não expôs `review_notes` ou
`professional_note` na amostra verificada.

**Personalidade:** o gate é independente, por `shared_with_patient`. Antes do
compartilhamento a view ficou vazia; depois mostrou apenas o perfil do paciente
autenticado, com classificações de domínio/faceta e sem escores, síntese ou
integração. A tabela base permaneceu invisível ao paciente mesmo após compartilhar.
A tentativa de UPDATE pela view retornou 403. Ao retirar o compartilhamento,
a view voltou a ficar vazia. O outro paciente nunca recebeu a linha.

Os pacientes não conseguiram liberar seus próprios resultados pela RPC ou
alterando diretamente `patients.results_released_at`; tampouco conseguiram
compartilhar a própria avaliação NEO. Nenhuma policy precisou ser afrouxada.

## Limpeza e verificações locais

Cada execução encerrou somente as sessões criadas por ela, com logout local.
Após os testes, uma transação de limpeza exigiu os IDs, nomes com marcador e
contagens exatas das duas clínicas, cinco perfis e três pacientes. Removeu
apenas esse conjunto, seus questionários/avaliações e eventos de auditoria de
teste. A conta demo anterior, sua clínica e seu paciente foram preservados.

Uma consulta independente após o commit confirmou **zero** clínicas, pacientes,
perfis, usuários Auth, identidades, sessões, respostas de questionário, avaliações
de personalidade e eventos de auditoria remanescentes do conjunto descartável.
O arquivo local com as credenciais dessas contas removidas foi excluído.

O auxiliar e SQLs operacionais ficaram no diretório local de evidências da tarefa;
o JSON versionado contém somente rótulos de casos/atores, status HTTP e vereditos,
sem IDs, e-mails, senhas, JWTs ou respostas clínicas. Uma consulta adicional de
contagens teve um erro de parêntese no auxiliar e foi corrigida/repetida; a
transação de limpeza não foi repetida. A revisão automática de autorização
também teve uma falha inicial por limite de uso; a consulta não executada foi
retomada pelo fluxo normal após o pedido do responsável.

Nenhum código de aplicação, schema, migration, grant ou policy foi alterado.
O teste é remoto autenticado; não substitui teste de navegação por papel no
aplicativo. A suíte Flutter completa não foi repetida nesta etapa documental;
a última execução continua com 485 aprovados e 7 falhas conhecidas.
Antes do commit da evidência, `flutter analyze` foi reexecutado: exit 1,
**144 ocorrências — 0 errors, 12 warnings e 132 infos**, sem aumento em relação
à passagem anterior e sem supressão de regras.

## Limites

Resultado restrito aos casos de pacientes, NEO e questionários acima. Não é uma
auditoria completa de todas as tabelas ou funções: não abrange administrador,
contas/pacientes inativos, vínculos ambíguos, Storage, biblioteca, genograma,
monitoramento, billing, todas as Edge Functions ou alterações de sessão tardias.
Não foram feitas consultas genéricas para tentar descobrir dados de terceiros.
Nenhuma conclusão de segurança dos demais módulos é inferida destes 101 casos.
