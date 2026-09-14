# Lote B — autorização clínica fail-closed

Data: 2026-09-14. Branch audit/astra.
HEAD inicial confirmado: 682f4a140a2df19d1cd0ed58de0590c9a0e6ccff, igual ao
origin/audit/astra consultado com git ls-remote. Working tree inicialmente limpo.
Sem commit, push, merge, rebase ou alteração em staging.

## Escopo e causa raiz

| Finding | Causa confirmada | Contrato aplicado |
|---|---|---|
| N01 set_patient_active_status | current_role NULL não dispara NOT IN; SELECT/retorno e escrita podiam ser alcançados | authenticated com profile ativo; platform_admin global ou psychologist responsável na mesma clínica |
| N15 get_patients_data_completion | filtro por UID do responsável sem validar atividade/papel do profile | somente psychologist ativo, pacientes sob sua responsabilidade e mesma clínica |
| N16 get_patients_with_pending_results_release | mesma ausência de validação explícita | mesmo contrato de psicólogo |
| N17 get_psychologist_alerts | vínculos sobrevivem à inativação do profissional | mesmo contrato, inclusive convites da sua clínica |
| N18 get_my_library | busca paciente pelo UID sem validar profile ativo/papel | patient ativo, vínculo próprio único, paciente ativo e mesma clínica |
| N19 current_patient_id/view | helper devolvia vínculo de profile inativo, com LIMIT 1 arbitrário | vínculo válido retorna UUID; contexto inválido retorna NULL; view não expõe avaliação |

A migration única é
`supabase/migrations/20260914130000_harden_clinical_authorization.sql`.
Não modifica migrations históricas nem introduz helper genérico de autorização.
Seis funções mantêm assinaturas e retornos. Nenhuma policy foi modificada.
`personality_results_public` permaneceu intacta.

## Inspeção final do histórico e desenho

| Função/assinatura | Última definição anterior |
|---|---|
| set_patient_active_status(uuid,boolean) → patients | 20250620170035_platform_admin_patient_access.sql |
| get_patients_data_completion() → TABLE | 20260901120000_patients_data_completion_rpc.sql |
| get_patients_with_pending_results_release() → TABLE(patient_id uuid) | 20260816130000_patients_pending_results_release_rpc.sql |
| get_psychologist_alerts() → jsonb | 20260816120000_pending_results_release_alert.sql |
| get_my_library() → jsonb | 20260805120000_library_indications.sql |
| current_patient_id() → uuid | 20250525120009_auth_and_rls.sql |

Todas eram e continuam SECURITY DEFINER, owner postgres.
search_path passou de public para pg_catalog, com relações qualificadas.
As três consultas e current_patient_id passaram de SQL a PL/pgSQL para expressar
a rejeição/retorno NULL; STABLE foi preservado. Lifecycle e biblioteca continuam
PL/pgSQL com volatilidade histórica. Não existe SQL dinâmico na migration.

A identidade vem de auth.uid(), acompanhada do papel PostgreSQL estabelecido
pelo PostgREST via current_setting('role'). current_user dentro de SECURITY
DEFINER é o owner, não o usuário da aplicação; session_user tampouco é usado
como atalho. app_metadata e claims de papel não concedem acesso sem profile.

N01 valida identidade antes da busca do paciente. Responsabilidade/clínica fazem
parte do WHERE da busca bloqueada com FOR UPDATE; um alvo inexistente ou
incompatível recebe o mesmo 42501. O caminho sem mudança de status não pula o
guard. Profile vinculado, quando existente, deve ser patient da clínica do
registro. Não exige que esse profile esteja ativo para permitir reativação.
Mantidos atualização do paciente, sincronização de atividade do profile e
auditoria. Status NULL recebe 22023 após a autorização.

As três consultas levantam 42501 para contexto/identidade/papel inválido.
Psicólogo ativo sem pacientes elegíveis recebe coleção vazia legitimamente.
Não há parâmetro de paciente nessas coleções: ausência de vínculo exclui linhas,
enquanto identidade inválida gera exceção. Admin não recebe acesso incidental.
Filtros de clínica também cobrem convites e relações com coluna clinic_id.
patient_intake/patient_life_areas não possuem essa coluna; são filtradas pelo
patient_id do conjunto de pacientes autorizado.

get_my_library chama o current_patient_id endurecido antes da leitura.
Vínculo inválido gera 42501; paciente válido sem indicações publicadas recebe [].
Indicações de clínica incompatível são excluídas. Campos e projeção da obra
permanecem iguais, sem camada privada do psicólogo.

current_patient_id valida profile, papel, atividade, clínica e atividade do
paciente. Como patients.profile_id tem índice NÃO único, exige exatamente um
vínculo, em vez de escolher o primeiro. Vínculo ausente, duplicado ou de clínica
divergente retorna NULL. Não desativa constraints nem cria índice neste lote.

## Tabelas, helpers e consumidores relacionados

- Lifecycle: profiles, patients e audit_events; auth.uid e triggers existentes,
  incluindo prevent_profile_privilege_escalation de F01.
- Consultas: profiles, patients, patient_intake, patient_life_areas,
  patient_timeline_events, genogram_people, questionnaire_responses,
  patient_check_ins e patient_invitations.
- Biblioteca: current_patient_id, current_clinic_id, library_indications,
  library_works, profiles e patients.
- View: personality_assessments, current_patient_id, current_clinic_id,
  personality_results_public.
- Policies existentes que usam current_patient_id incluem respostas,
  recursos, metas, problemas, check-ins, timeline, genograma e assignments.
  O helper permanece STABLE/uuid; nenhuma dessas policies foi reescrita.

Chamadas legítimas foram localizadas nos repositórios Flutter de pacientes,
biblioteca do paciente e personalidade. Não houve mudança no Flutter.
A busca em Edge Functions/scripts não identificou contrato service_role
necessário para estas RPCs.

## View e grants efetivos

A view patient_shared_personality era e permanece security_invoker=false,
owner postgres. É uma projeção necessária porque a tabela base é protegida
para staff. Mantém as colunas e a sanitização original; acrescenta igualdade
de clinic_id e usa o helper endurecido.

O catálogo mostrou que a view é automaticamente atualizável e recebia grants
de escrita via defaults, embora o fluxo paciente seja somente leitura.
Por isso a migration revoga os privilégios de PUBLIC/anon e todos os de
authenticated, concedendo novamente apenas SELECT. Essa alteração pertence
ao acesso efetivo da view N19. Não altera o editor clínico da tabela base.

| Objeto | PUBLIC antes/depois | anon antes/depois | authenticated |
|---|---|---|---|
| current_patient_id | EXECUTE / não | EXECUTE / não | EXECUTE preservado |
| Outras cinco funções | não / não | não / não | EXECUTE preservado |
| patient_shared_personality | sem grant / sem grant | privilégios amplos / nenhum | privilégios amplos / somente SELECT |

Nas seis funções, service_role, postgres e supabase_admin mantêm EXECUTE efetivo.
service_role direto recebe 42501 nas cinco RPCs; o helper retorna NULL.
Na view, service_role/owner preservam os grants administrativos anteriores.
Execução permitida por ACL não equivale a autorização clínica.
O helper/view aninhado mantém o contexto authenticated nas chamadas legítimas.

## Testes e mutações

Arquivos:
- `supabase/tests/lote-b-clinical-authorization-tests.sql`
- `supabase/tests/lote-b-authorization-mutations.ps1`

A suíte final contém **438 verificações aprovadas**. Fixtures próprias: duas
clínicas, 15 identidades Auth, 14 profiles, pacientes com/sem login, responsáveis,
questionários, respostas concluídas/pendentes, convites, biblioteca e avaliações.
Todas as alterações são transacionais e revertidas.

Cobertura: anon, UID ausente, profile ausente/excluído/inativo, paciente ativo,
psicólogo responsável/não responsável/inativo, admin ativo/inativo, outra clínica,
papel legado, papel incorreto com vínculo, vínculo removido/duplicado, registro
de paciente inativo, service_role e claims de papel simulados.

N01 é chamado com status igual e diferente do atual, com/sem profile vinculado.
A rejeição exige 42501 e mensagem específica, antes de qualquer DML.
Triggers de statement levantam erro diferente se houver escrita precoce;
snapshots completos de patients/profiles/audit_events verificam ausência de
efeitos. Há prova de rollback após falha tardia da auditoria.

Controles positivos verificam inativação/reativação, profile de login, autor e
ações da auditoria, ausência de auditoria falsa de status no no-op, admin global
e paciente sem responsável. Consultas retornam os pacientes esperados; biblioteca
e view entregam somente conteúdo próprio. View bloqueia INSERT/UPDATE/DELETE.
Incluídos sanitização de scores, avaliação não compartilhada, biblioteca vazia,
obra não publicada e indicação de clínica inconsistente.

Nas quatro mutações históricas, o runner extrai a definição do arquivo versionado
e a injeta em memória após BEGIN. A quinta remove somente os três predicados de
clínica das duas funções corrigidas. ON_ERROR_STOP encerra a conexão em falha e
reverte tudo.

| Família | Corpo restaurado | Falha histórica exigida |
|---|---|---|
| Lifecycle | set_patient_active_status | no-op de paciente sem login permitido a caller sem profile |
| Psicólogo | get_patients_data_completion | psicólogo inativo ultrapassa guard |
| Biblioteca | get_my_library | paciente inativo recebe retorno |
| Helper/view | current_patient_id | helper não retorna NULL para profile inativo |
| Isolamento entre clínicas | N16/N17 sem os três predicados de clínica | pendência da clínica A exposta ao profissional B após transferência |

As cinco mutações saíram com código 3 pela falha esperada, não por FK/fixture.
Após cada uma, as 438 verificações protegidas passaram novamente, inclusive ACLs.
Nenhuma mutação foi persistida.

Comandos na raiz:
```powershell
Get-Content -Raw supabase/tests/lote-b-clinical-authorization-tests.sql |
  docker exec -i supabase_db_App_Clinica_Psicologia psql -U supabase_admin -d postgres -X -v ON_ERROR_STOP=1
pwsh -NoProfile -File supabase/tests/lote-b-authorization-mutations.ps1
```

## Bloqueador encontrado pela revisão independente

A primeira versão do Lote B tinha 404 verificações, mas cobertura insuficiente
para uma transferência de paciente entre clínicas. A revisão reproduziu respostas
válidas na clínica A, seguidas da transferência do paciente para B. O psicólogo
B não via as respostas por RLS, porém N16/N17 revelavam sua existência, estado e
antiguidade. Validar somente a clínica atual do paciente não isolava as respostas.

Foi corrigida a própria migration ainda não commitada, sem criar outra migration.
Os três joins agora exigem explicitamente `qr.clinic_id = p.clinic_id`:

| Função | Consulta/CTE | Response | Patient | Predicado |
|---|---|---|---|---|
| get_patients_with_pending_results_release | SELECT DISTINCT p.id | qr | p | qr.clinic_id = p.clinic_id |
| get_psychologist_alerts | stale_questionnaires | qr | p | qr.clinic_id = p.clinic_id |
| get_psychologist_alerts | pending_results_release | qr | p | qr.clinic_id = p.clinic_id |

Esses são todos os usos de questionnaire_responses nas duas funções. A igualdade
é aplicada antes da agregação/MIN e do LIMIT; não muda a lógica de pendência nem
usa a clínica do profissional como substituto da clínica do paciente.

A regressão acrescenta 34 verificações (total 438), sem desativar constraints ou
triggers. Usa o paciente sem profile vinculado, inicialmente na clínica A, cria
respostas válidas e depois transfere clinic_id/responsável para B. Verifica RLS,
N15, N16, os dois alertas N17 e a perda de acesso do antigo responsável A.
Em seguida cria respostas válidas B e confirma o retorno legítimo das pendências
e dos alertas, com dias calculados exclusivamente a partir das respostas B.

Matriz adversarial A–H:

- A: responses A/paciente A retornam pendências e idades legítimas ao responsável A.
- B: após transferência, responses A não aparecem por RLS, não contam em N15
  e não geram linha/alerta ou informação derivada em N16/N17 para B.
- C: responses B/paciente B restauram pendências e alertas legítimos.
- D: responses A e B coexistem; apenas B influencia a visão do responsável B.
- E: responses A com 40 dias não alteram a idade B de 12 dias (draft) e 9 dias
  (resultado concluído).
- F: responses A com 8 dias, mais recentes que B, também não substituem nem
  mascaram o estado/idade legítimos de B.
- G: o psicólogo A não recebe o paciente transferido em N15/N16/N17.
- H: o psicólogo B recebe somente o domínio clínico atual permitido.

A quinta mutação extrai as duas funções protegidas, confere exatamente três
ocorrências do predicado e remove somente essas condições, em memória e dentro
da transação da suíte. Falha esperada: `FAIL: cross-clinic B pending ignores A / A age=40`,
exit 3. Após o rollback, todas as 438 verificações passam novamente. As quatro
mutações históricas continuam válidas. Nenhuma mutação persiste no banco.

## Validações

- Aplicação sobre banco existente: passou.
- Reset local completo com migrations e seed: passou.
- Lote B: 438 verificações; cinco mutações detectadas e revertidas.
- Lote A: 378 verificações passaram.
- F01/F02 e F03 SQL: passaram; F03 SQL tem 46 verificações.
- F03 Auth/signup/Edge Functions HTTP: 30 verificações passaram; fixtures limpas.
  A primeira tentativa encontrou o runtime Edge local parado; após iniciar
  `supabase functions serve`, a suíte completa passou, sem alterar Edge Functions.
- patient-lifecycle-tests.sql e production-governance-tests.sql: OK.
- supabase db lint --local: sem erros de schema.
- flutter analyze --no-fatal-infos: exit 0, 99 infos, sem errors/warnings.
- flutter test: 447 passaram.
- Deno: não disponível; não executado.
- Smoke RLS antigo: falha conhecida no INSERT de questionnaire_responses sem
  questionnaire_version_id NOT NULL. Fixture revertida; teste não alterado.

## Revisão adversarial, limites e riscos residuais

Negação independe de FK, UI, Edge Function ou RLS de outra tabela.
Caller inativo com claims presentes, papel errado, service_role e contexto anon
não passam. NULL no helper não revela a view; identidade inválida nas RPCs
recebe erro. Chamadas SECURITY DEFINER aninhadas foram exercitadas por biblioteca
e view. Nenhum contexto owner/superusuário foi tratado como usuário clínico.

A suíte SQL simula claims e papel de banco; não valida configurações remotas
do gateway. Produção não foi acessada/aplicada. Revogação concorrente após a
leitura autorizadora segue visibilidade transacional; não cancela retroativamente
uma operação já autorizada. Credenciais privilegiadas do banco permanecem fora
da fronteira de proteção do guard.

Riscos de regressão intencionais: vínculos duplicados, clínica divergente,
profiles inativos ou papéis incorretos deixam de obter resultados.
O consumo de current_patient_id em outras policies passa a exigir vínculo
único e paciente ativo. Registros inconsistentes não são corrigidos neste lote.
Clientes desconhecidos que escreviam pela view ou chamavam estas RPCs com
service_role deverão usar os caminhos legítimos autorizados.

Descobertas relacionadas: vínculo de paciente não único e view atualizável;
tratados estritamente no helper/acesso N19, sem refatorar o schema.
A tabela library_indications permite clinic_id divergente do paciente; a RPC
agora filtra essa inconsistência, mas um hardening geral da integridade fica fora
do lote. Defaults de futuras funções/views permanecem permissivos.
Nenhuma correção em contagens, jornada, Storage, is_library_cover_admin,
app_metadata ou outros findings fora do escopo.

## Entrega

Quatro arquivos novos: esta documentação, uma migration, uma suíte SQL e o runner
de mutações. Nenhum arquivo histórico/Flutter/Edge foi alterado ou staged.
git diff --stat não inclui estes arquivos enquanto forem untracked.

Sugestão de commit (não executada):
`fix(security): fail closed on clinical RPC and patient view authorization`

Aguardando revisão humana; sem commit/push.
