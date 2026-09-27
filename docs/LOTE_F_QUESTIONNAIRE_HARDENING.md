# Lote F — fronteiras de questionários e resultados

## Base e isolamento

Implementação baseada exclusivamente em `b4fdd4f5b0e575b5df702f937a0c8bc47931df74`,
da branch de origem `audit/astra`. Worktree detached:
`C:\Users\bruno\AppData\Local\Temp\lote-f-b4fdd4f-20260924\worktree`.
O workspace original não foi usado para testes nem editado. Seus arquivos locais
e as migrations reservadas `20260922120000` e `20260924150000` não foram copiados.
Nenhum commit, push, merge ou rebase foi realizado.

O harness local fica no diretório irmão `runtime`: project_id `lote_f_b4fdd4f`,
API `56321`, banco `56322`, inspector `8183`. As pastas de código são junctions
exclusivamente para este worktree; config e logs ficam fora do código versionado.
Postgres local `17.6.1.127` (imagem disponível); não foi alterada configuração remota.
A migration nova é `20260927130000_harden_questionnaire_patient_boundaries.sql`.

## Contratos reinspecionados

Foram lidos migrations, catálogo efetivo (policies, grants, triggers, helpers),
`start-questionnaire`, `submit-questionnaire-answer`, `finish-questionnaire`,
o fetch do relatório clínico, repositories/providers/modelos/telas de resultados,
dashboard/jornada e o fluxo de liberação.

- `current_role()` considera somente profile ativo. `is_staff()` significa
  psicólogo; platform_admin não tem acesso clínico incidental.
- `user_can_access_response()` exige clínica e usa `user_can_access_patient()`;
  para psicólogo este último exige responsabilidade pelo paciente.
- `current_patient_id()` exige identidade authenticated, profile patient ativo,
  vínculo único, clínica correspondente e paciente ativo.
- Atribuições controlam o início pelo paciente. O Edge fixa a versão ativa,
  cria draft, recebe respostas e conclui via client com JWT do usuário.
- A revisão escreve `reviewed_at`, `reviewed_by_profile_id`, `review_notes`,
  ajustes profissionais e ativações. Revisão não é liberação.
- A liberação canônica é `patients.results_released_at`, através da RPC existente
  `set_patient_results_released`, pelo psicólogo responsável.
- O Flutter usa gráficos agregados/esquemas e contextos parentais após release.
  `FinishQuestionnaireResult` aceita payload operacional sem `results`;
  `resultsCount` não é usado pela tela de sucesso.
- O relatório clínico usa service client depois de autorizar o profissional;
  continua com acesso profissional. Nenhuma view existente sobre estas tabelas
  foi encontrada. Os RPCs clínicos anteriores continuam cobertos pelo Lote B.

## Causas e correções

| Finding | Causa | Correção |
|---|---|---|
| N01 | `qsa_staff_all` verificava apenas staff/clínica | Mesma clínica + psicólogo ativo + `user_can_access_response`, tanto USING quanto WITH CHECK |
| F05 | RLS autorizava a linha inteira com `psi_observation`; Flutter apenas omitia a coluna | Removida leitura paciente da tabela bruta; RPC de ativação com allowlist. SELECT por coluna nas tabelas operacionais exclui campos profissionais; RPC de detalhe decide a projeção no servidor |
| F07 | Policies de escrita autorizavam linha, sem proteger colunas nem estado | Trigger de INSERT/UPDATE em responses, answers e contexts; campos profissionais protegidos, identidade imutável, respostas concluídas imutáveis para paciente |
| F08 | Ativação usava `reviewed_at`; finish devolvia resultados; resultado bruto expunha campos profissionais após release | Gate de release nas projeções; resultado bruto apenas para psicólogo autorizado; finish retorna apenas confirmação operacional nos dois ramos |

## Campos e transições

| Tabela / campos | Classe e contrato |
|---|---|
| responses: `id, clinic_id, patient_id, questionnaire_id, questionnaire_version_id` | Identidade de criação validada por RLS/FKs; imutável para paciente em UPDATE |
| responses: `started_at, created_at, updated_at` | Timestamps geridos no servidor; INSERT paciente normaliza; atualização de `updated_at` pelo trigger existente |
| responses: `status, completed_at` | Workflow: INSERT somente draft; paciente pode draft→completed, com completed_at normalizado no banco; nunca completed/cancelled→draft, nem editar resposta já finalizada |
| responses: `reviewed_at, reviewed_by_profile_id, review_notes` | Exclusivamente profissional; paciente não insere nem modifica; leitura profissional pela RPC |
| answers: `answer_value` | Patient-writable enquanto response é draft; lock do parent serializa edição com conclusão |
| answers: `id, response_id, question_id, response_context_id, created_at` | Identidade imutável em UPDATE; INSERT valida referências/versão por triggers existentes |
| answers: `professional_value, professional_note` | Professional-writable; não legíveis diretamente pelo papel authenticated; retornados somente na projeção profissional autorizada |
| answers: `created_at, updated_at` | Normalizados no INSERT paciente; updated_at mantido pelo trigger existente |
| contexts: identidade, clínica, resposta, paciente, instrumento, tipo/chave/label/ordem e created_at | INSERT de contexto draft, FKs e trigger de consistência; identidade imutável em UPDATE paciente |
| contexts: `status, completed_at, updated_at` | Server/workflow-only: mudança de status acompanha progresso real; timestamp gerado pelo banco na conclusão e preservado em updates completed→completed. Após finalizar o parent, não reabre. `updated_at` segue o trigger existente |
| results: identidade, scores, percentage, classification, snapshot, created_at | Cálculo pelo servidor; nenhuma escrita de paciente. Permissões profissionais existentes preservadas |
| results: `professional_average_score, professional_note` | Ajustes profissionais; nunca enviados na projeção paciente |
| activations: `psi_observation, activated_by_profile_id, clinic_id` | Dados profissionais/identidade interna, ausentes da projeção paciente |
| patients: `results_released_at, results_released_by` | Workflow profissional existente; teste negativo de escrita direta pelo paciente, sem alterar este domínio |

O trigger verifica o role efetivo da conexão (`current_setting('role')`), não
claims editáveis nem o `current_user` de uma chamada intermediária SECURITY DEFINER.
Escritores confiáveis: service_role e sessões diretas postgres/supabase_admin.
Uma função SECURITY DEFINER de teste não consegue contornar a proteção paciente.

A transição forward continua usando o JWT do paciente, como o Edge existente.
Ela não comprova que a requisição veio especificamente do Edge. A atomicidade,
idempotência e integridade transacional completa de finalização não são tratadas
neste lote. **F09 permanece aberto.**

## Projeções e grants

`get_questionnaire_response_detail(uuid)` e
`list_questionnaire_response_summaries(uuid)` autorizam usando identidade, profile,
clínica e vínculo. Não aceitam role/clinic enviados como argumentos. A mesma RPC
retorna detalhe profissional ao responsável e somente allowlist ao paciente.

Paciente recebe dados operacionais da resposta/questionário; respostas próprias
quando draft ou liberadas; resultados agregados somente após release. Os dados
liberados incluem `id`, `category_id`, `total_score`, `average_score`, categoria e
`patient_result`. Este último reconstrói explicitamente versionamento de exibição,
resumos, schemas/domains e contextos, inclusive allowlist em cada nível. Não retorna
snapshot bruto, itens internos do motor, notas, interpretação livre, severidade,
overrides profissionais nem chaves desconhecidas. Valores compostos em campos
declarados escalares são descartados. Métricas agregadas após release são
intencionais e mantêm os gráficos existentes; não são disponibilizadas antes dele.

`get_patient_schema_activations(uuid)` retorna exclusivamente:
`id, questionnaire_response_id, schema_code, schema_name, created_at`.
Requer patient ativo, vínculo único/ativo, clínica correspondente e release.

- Raw `questionnaire_results` / `questionnaire_schema_activations`: paciente não
  recebe linhas, inclusive após release e com `select=*` ou colunas explícitas.
- Raw responses/answers: SELECT apenas de colunas operacionais enumeradas;
  `select=*`, `review_notes`, `professional_note/value` falham por privilégio.
  Isso também afeta consultas profissionais diretas antigas; o repository foi
  migrado para RPC autorizada. Escrita profissional legítima continua via RLS.
- Novas RPCs: owner postgres, SECURITY DEFINER, search_path pg_catalog, relações
  qualificadas; EXECUTE removido de PUBLIC/anon e concedido a authenticated.
  O grant default service_role não é ampliado; a identidade de usuário é exigida
  nas RPCs de leitura. Helpers internos não têm EXECUTE para authenticated/anon/PUBLIC.
- Nenhum default privilege global foi alterado. Não há SQL dinâmico novo.

## Payload de finalização

Antes: `{ok:true,data:{response:{...},results:[{total_score,average_score,snapshot,...}]}}`.

Depois, nos ramos comum e parental:

```json
{"ok":true,"data":{"response":{"id":"uuid","status":"completed","completed_at":"timestamp","patient_id":"uuid","questionnaire_id":"uuid"}}}
```

Somente as duas expressões de resposta HTTP mudaram no handler. Cálculo, ordem de
escrita, uso dos clients e persistência foram preservados. O resultado é lido
posteriormente pela projeção autorizada. **F09 permanece aberto:** falhas após
marcar completed ainda podem deixar resultados incompletos e retries não idempotentes.

## Matriz de acesso

| Identidade | Dados profissionais | Projeção de resultado/ativação |
|---|---|---|
| Paciente próprio, antes de release | Negado | Sem resultado/ativação |
| Paciente próprio, reviewed preenchido mas release NULL | Negado | Sem resultado/ativação |
| Paciente próprio, liberado | Negado | Allowlist permitida |
| Paciente de outra clínica / profile inativo | Negado | Negado |
| Psicólogo responsável ativo | Permitido | Detalhe profissional permitido |
| Psicólogo mesma clínica sem vínculo / outra clínica / inativo | Negado | Negado |
| Platform admin / anon / authenticated sem profile | Negado | Negado |

## Testes e reprodução

Executar a partir do harness Supabase isolado (nunca do workspace original):

```powershell
supabase db reset --local
# Executar o SQL com psql ON_ERROR_STOP=1 no container do projeto isolado.
& ./supabase/tests/lote-f-questionnaire-http.ps1
& ./supabase/tests/lote-f-questionnaire-mutation.ps1
supabase db lint --local
```

SQL: fixtures transacionais com rollback; matriz de identidades, INSERT/UPDATE,
negação de campos privados, transições, escrita de resultado/release, guard contra
SECURITY DEFINER/claims, projeção recursiva e regressões positivas profissionais.
HTTP: Auth real, REST explícito/wildcard, payload com allowlist em cada nível,
início por atribuição, salvamento e finalização comum/parental, gate de release e
limpeza em finally. Flutter: seis testes de parsing e transporte dos repositories.

Mutações: N01 restaura acesso staff pela clínica; F05 restaura caminho de leitura
bruta paciente; F07 remove triggers; F08 recoloca results no payload real do Edge.
As três SQL são injetadas na transação da suíte e devem falhar na asserção específica;
fingerprint de policies, funções, owners/grants e triggers confirma rollback.
A mutação HTTP salva bytes do handler, reinicia apenas o Edge isolado, espera sua
prontidão, exige falha do contrato e restaura bytes/runtime em finally. As suítes
protegidas são repetidas após a restauração.

## Validação local inicial (anterior à revisão independente)

| Validação | Resultado local |
|---|---|
| Migration sobre baseline existente | Aplicou sem erro |
| Reset limpo com migration final | Passou; nenhuma migration reservada aplicada |
| Lote F SQL | 84 verificações, exit 0, rollback |
| Lote F HTTP | 128 verificações, fluxos comum e parental |
| Mutações N01/F05/F07/F08 | Todas detectadas; catálogo e bytes restaurados; suítes protegidas repetidas |
| Lote A SQL | 378 verificações |
| Lote B SQL | 438 verificações |
| Lote C SQL | 27 verificações |
| Lote D | SQL 31; HTTP 17 |
| Lote E | SQL 72; HTTP 198 |
| F01/F02 SQL | 84 verificações |
| F03 | SQL 46; HTTP 30 |
| Patient lifecycle / production governance | Ambos exit 0 |
| SQL lint final | No schema errors found, sem avisos |
| Flutter focal | 6 testes aprovados |
| Flutter completo | 480 testes aprovados, zero falhas |
| Flutter analyze --no-fatal-infos --no-pub | Exit 0; 106 infos, zero warnings/errors |
| git diff --check | Passou |
| Workspace original | 16 arquivos comparados por hash; zero diferenças; status idêntico |

Flutter completo: 474 testes baseline + 6 novos. A resolução offline não mudou o pubspec;
o baseline não versiona pubspec.lock, portanto não fixa integralmente dependências.
Os arquivos gerados pelo Flutter foram retirados do diff isolado.
Deno não está instalado no PATH local: `deno check` e as tasks Deno não foram
executados. Os dois ramos alterados do handler foram executados pelo runtime Edge
local via HTTP; isso não substitui a checagem estática Deno.


## Correção após revisão independente — CHANGES REQUIRED

A revisão independente reprovou a primeira versão: depois da finalização parental,
o paciente conseguia gravar `completed_at=2099-01-01T00:00:00Z` no contexto.
Também identificou asserts baseados somente em erro HTTP/contagem de linhas.
A correção é focal na migration F ainda não commitada e nas três suítes F;
não foi criada migration adicional nem alterado Flutter/Edge nesta rodada.

### Causa e contrato de workflow

O guard excluía `completed_at` da comparação de campos imutáveis, e o validator
histórico mantinha timestamps não nulos fornecidos pelo cliente. O guard agora
normaliza antes desse validator: draft mantém NULL; na transição autorizada para
completed usa `now()`; completed→completed preserva exatamente `OLD.completed_at`,
inclusive quando o cliente envia NULL ou outra data. HTTP 200 nessa normalização
significa que o valor arbitrário foi ignorado; a prova é a releitura persistida.

O fluxo oficial usa JWT do paciente, inclusive para a sincronização das respostas
e o UPDATE de contextos na Edge de finalização. Não foi necessário promovê-lo a
service_role: a data criada pelo sync é preservada no UPDATE posterior do Edge.
Os caminhos privilegiados existentes de service_role/sessão administrativa ficam
inalterados. Claims de JWT não selecionam o role efetivo do banco.

Para impedir apagar/recriar a data com uma troca direta de status, mudanças de
status do contexto devem corresponder aos mesmos critérios do sync existente:
quantidade de perguntas M_ ativas e respostas não nulas. Enquanto o parent é draft,
limpar legitimamente uma resposta ainda pode tornar o progresso incompleto e
limpar o timestamp; responder novamente gera uma nova conclusão pelo servidor.
Um PATCH isolado para draft, mantendo todas as respostas completas, é negado.
Após finalizar o parent, a reabertura continua proibida.

### Testes de estado e mutações

- HTTP: fixture existente, vínculo/response/instrumento conferidos antes dos probes;
  releitura via service após tentativas de falsificar reviewed_at, review_notes,
  professional_note/value, identidade, status e completed_at.
- Datas testadas: 2099-01-01, 2001-02-03, NULL e status=completed com data arbitrária;
  todos os campos originais devem permanecer iguais (exceto updated_at do servidor).
- Progresso parental: conclusão automática antes do finish, negativa de ciclo direto
  de status, edição legítima para incompleto, resave oficial e finish preservando
  exatamente o timestamp da nova conclusão automática.
- SQL: helper temporário de leitura privilegiada compara o estado persistido antes
  e depois; cobre responses, answers, contexts, patients, results e activations.
  Os helpers/fixtures existem somente dentro da transação com rollback.
- F05: fixture contém `PRIVATE_PSI_OBSERVATION_LOTE_F`; o mutante deve ler exatamente
  esse valor como patient antes de a suíte protegida detectar sua exposição.
- F07: o mutante deve gravar `PATIENT_FORGED_LOTE_F` em professional_note e a leitura
  privilegiada deve confirmar exatamente o sentinel. A suíte protegida exige que
  o estado original seja preservado. Uma variante adicional remove a normalização
  de timestamp e deve falhar especificamente pela mudança persistida da data.
- N01/F08 continuam com as mutações existentes. Catálogo e bytes da Edge são
  restaurados; as suítes protegidas são repetidas depois.
- Removidas consultas a coluna `score` inexistente e RPC sem argumento obrigatório.
  Negativas REST agora exigem 403/42501 nas colunas protegidas, 200/[] por RLS,
  ou 401/42501 para EXECUTE anônimo; administrador recebe 200/null na RPC.
- Ambos os ramos verificam envelope/data e a allowlist interna exata de response:
  `id,status,completed_at,patient_id,questionnaire_id`.

A validação desta correção usa cópia exata do worktree no harness `lote_f_review`
(API 57321 / banco 57322), sem migrations ou arquivos locais do workspace original.
Logs ficam em `C:\Users\bruno\AppData\Local\Temp\lote-f-correction-20260925`.
**F09 CONTINUA ABERTO**: esta correção não implementa atomicidade nem idempotência.

### Resultado da revalidação da correção

| Validação | Resultado |
|---|---|
| Reset limpo com a migration F corrigida | Passou |
| Lote F SQL | 92 checks; rollback |
| Lote F HTTP | 241 checks; Auth/REST/Edge reais locais |
| Mutações | N01/F05/F07/F08 detectadas, mais variante F07 completed_at; restauração verificada |
| A / B / C SQL | 378 / 438 / 27 checks |
| D SQL / HTTP | 31 / 17 checks |
| E SQL / HTTP | 72 / 198 checks |
| F01/F02 SQL | 84 checks |
| F03 SQL / HTTP | 46 / 30 checks |
| Lifecycle / governance | Ambos passaram |
| SQL lint | Sem erros de schema |
| Flutter completo | 480 aprovados; nenhuma alteração Flutter nesta correção |
| Analyze | Exit 0; 106 infos; zero warnings/errors |

Prova HTTP armazenada em `f-http-final.log`:

```text
original = 2026-09-25T21:09:35.487347-03:00
PATCH    = 2099-01-01T00:00:00Z
HTTP     = 200 (normalização; a data arbitrária não foi gravada)
releitura= 2026-09-25T21:09:35.487347-03:00
```

O mesmo valor original foi preservado para 2001-02-03, NULL e status=completed.
A tentativa de ciclo direto para draft retornou 403/42501 e manteve o estado.
A sincronização legítima de progresso e a finalização parental passaram.
`f-mutations-final.log` registra leitura exata dos sentinels nos mutantes,
falha específica das suítes protegidas e restauração do catálogo/Edge.

Os seis arquivos do lote fora desta correção mantiveram seus hashes. Os 16 arquivos
locais do workspace original mantiveram hashes e status. Nenhum stage, commit,
push, merge ou rebase foi realizado. A correção aguarda NOVA revisão independente.

## Arquivos e estado Git

Modificados, exclusivamente no worktree isolado:

- `mobile/lib/features/patient_journey/data/patient_journey_repository.dart`
- `mobile/lib/features/results/data/results_repository.dart`
- `mobile/lib/features/results/domain/category_result.dart`
- `mobile/lib/features/results/domain/schema_activation.dart`
- `supabase/functions/finish-questionnaire/index.ts`

Novos, ainda untracked:

- `docs/LOTE_F_QUESTIONNAIRE_HARDENING.md`
- `mobile/test/lote_f_results_contract_test.dart`
- `supabase/migrations/20260927130000_harden_questionnaire_patient_boundaries.sql`
- `supabase/tests/lote-f-questionnaire-authorization-tests.sql`
- `supabase/tests/lote-f-questionnaire-http.ps1`
- `supabase/tests/lote-f-questionnaire-mutation.ps1`

`git diff --stat` (não inclui os seis arquivos untracked):

```text
 .../data/patient_journey_repository.dart           |  18 ++--
 .../features/results/data/results_repository.dart  | 109 +++++----------------
 .../features/results/domain/category_result.dart   |   3 +-
 .../features/results/domain/schema_activation.dart |   2 +-
 supabase/functions/finish-questionnaire/index.ts   |   3 +-
 5 files changed, 35 insertions(+), 100 deletions(-)
```

HEAD isolado permanece detached em `b4fdd4f5b0e575b5df702f937a0c8bc47931df74`.
Nada staged. Worktree e runtime isolado mantidos para revisão independente.

Status original preservado, branch `audit/astra`, mesmo HEAD:

```text
 M mobile/android/app/build.gradle.kts
 M mobile/lib/features/auth/presentation/update_password_page.dart
 M mobile/lib/features/initial_assessment/domain/genogram_enums.dart
 M mobile/lib/features/initial_assessment/presentation/initial_assessment_family_page.dart
 M mobile/lib/features/initial_assessment/presentation/widgets/genogram_person_editor.dart
 M mobile/lib/features/patient_check_ins/data/patient_check_ins_repository.dart
 M mobile/lib/features/patient_check_ins/domain/patient_check_in.dart
 M mobile/lib/features/patient_check_ins/domain/patient_check_in_input.dart
 M mobile/lib/features/patient_check_ins/presentation/patient_check_in_form_page.dart
 M mobile/lib/features/patient_journey/domain/journey_step.dart
 M mobile/lib/features/patient_journey/presentation/patient_journey_page.dart
 M mobile/lib/features/patient_journey/presentation/widgets/journey_ambience.dart
?? mobile/env.web.json
?? mobile/lib/features/patient_check_ins/domain/check_in_mode.dart
?? supabase/migrations/20260922120000_check_in_emotions_and_modes.sql
?? supabase/migrations/20260924150000_caregiver_need_add_guidance_stability.sql
```

## Riscos e limites

- Validação exclusivamente local; nada foi implantado ou validado em produção.
- Integradores que selecionavam campos profissionais diretamente de responses ou
  answers precisam usar a RPC autorizada. Service-role autorizado continua com
  leitura completa. Publicar banco/Edge e Flutter compatíveis coordenadamente.
- A liberação continua por paciente, não por resposta; novos resultados desse
  paciente seguem a semântica de liberação global existente.
- A projeção não retorna campos livres/profissionais nem snapshot bruto; o Dart
  adapta `patient_result` para o modelo de gráfico já existente, sem mudança de UI.
- O bloqueio protege canais de dados do servidor; não promete impedir que alguém
  calcule manualmente algo a partir das próprias respostas e de um instrumento conhecido.
- F06, F09, F10, F11/DP01, N02/F12 continuam fora do escopo. Nenhuma alteração em
  signup, lifecycle, profile admin hardening, biblioteca, psicoeducação ou buckets.
- O smoke antigo mantém expectativas obsoletas e não foi alterado nem usado como
  contrato deste lote.

Sugestão de commit, somente após revisão independente:
`fix(security): enforce questionnaire patient boundaries and result release`

## Correção de fixtures após a segunda revisão — CHANGES REQUIRED

A segunda revisão independente confirmou as proteções do Lote F, mas exigiu
correção dos três probes HTTP de identidade: `patient_id` apontava para paciente
inexistente; `questionnaire_id`, para UUID sem questionário; a troca de `id` usava
resposta com dependências. Esses controles falhavam inclusive como service_role,
por consistência de clínica/FK, e não demonstravam a validade estrutural da operação.
O histórico da primeira revisão e de suas correções acima permanece preservado.

Nesta rodada mudou somente a suíte HTTP e esta documentação. Não houve alteração
na migration, Edge Function, Flutter ou implementação de segurança.

A suíte agora valida Patient A/JWT/clínica, cria Auth/profile/Patient B sintéticos
na mesma clínica e usa Q1/Q2 reais com versões coerentes (Q2: PARENTAL_STYLES_V1,
versão active). Para cada campo cria uma response draft descartável com IDs
identificáveis por `fbf10000`; Auth/profile/Patient B usam também o nome/email
`lote-f-identity-*`. Confirma ID2 livre e ausência de dependências nas cinco tabelas:
answers, results, contexts, assignments e schema activations.

Cada controle usa a mesma fixture restaurada e o mesmo payload: service_role PATCH
retorna 200 e a releitura confirma a alteração; após restaurar o estado original,
patient recebe estritamente 403/42501. A releitura completa deve ser idêntica à
realizada imediatamente antes da tentativa do paciente, inclusive timestamps.

| Campo | Controle privilegiado persistido | Paciente | Estado final |
|---|---|---|---|
| patient_id | A → B, 200 | 403/42501 | A preservado |
| questionnaire_id | Q1/v1 → Q2/v2, 200 | 403/42501 | Q1/v1 preservados |
| response id | ID1 → ID2, 200; ID1 ausente | 403/42501 | ID1 preservado; ID2 ausente |

O finally remove responses, Patient B, Auth/profile B e seus audit_events; releituras
confirmam zero linhas residuais. Falhas de FK, UUID, clínica, 404 ou coluna não são
aceitas como bloqueio de autorização. Os demais checks aprovados foram preservados.

Validação repetida em 25/09/2026 no ambiente isolado:

- HTTP focal: **277 checks** (antes: 241); repetição e pós-mutation: 277.
- F SQL: **92**; mutations N01/F05/F07/F08 detectadas, mais variante F07 completed_at;
  sentinels F05/F07 comprovados, catálogo restaurado e bytes de Edge restaurados.
- A/B/C SQL: **378/438/27**; D SQL/HTTP: **31/17**; E SQL/HTTP: **72/198**.
- F01/F02 SQL: **84**; F03 SQL/HTTP: **46/30**; lifecycle e governance: exit 0.
- SQL lint: exit 0, sem erros de schema; Flutter: **480 pass, 0 fail**;
  analyze --no-fatal-infos: exit 0, zero warnings/errors, 106 infos.

F09 permanece aberto. Nenhuma correção de atomicidade/idempotência foi incluída.
Sem stage, commit, push, merge ou rebase. Aguardando TERCEIRA revisão independente.

## Reordenação temporal antes da integração — 27/09/2026

A migration F ainda não commitada usava originalmente o timestamp
`20260924160000`. A consulta `supabase migration list --linked` confirmou que
`20260926100000` e `20260926140000` já estavam aplicadas remotamente. A integração
foi interrompida antes de stage/commit. O arquivo foi renomeado para
`20260927130000_harden_questionnaire_patient_boundaries.sql`, posterior ao maior
timestamp remoto, sem colisão. As referências operacionais acima foram atualizadas.
O timestamp antigo neste parágrafo é somente registro histórico.

O SQL permaneceu byte a byte idêntico. SHA-256 antes e depois:
`A7B3D1A18A9C5AEC28E8E1F1BA7388E7C261E5A0271DD4BC757290DA153CD83E`.
A mudança foi exclusivamente de identificação/ordenação da migration, sem alteração
de segurança, Flutter ou Edge Function; não constitui uma vulnerabilidade.

Reset local limpo pré-commit na cópia isolada do worktree corrigido: aprovado.
F SQL: 92; F HTTP: 277. Mutations N01/F05/F07/F08 e variante completed_at:
detectadas, rollback/restauração comprovados e suites protegidas aprovadas.
As migrations paralelas da branch serão validadas juntas no reset do HEAD integrado.
