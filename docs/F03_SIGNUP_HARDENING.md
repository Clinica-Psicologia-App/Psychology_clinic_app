# F03 — signup sem provisionamento por metadata

Data: 2026-09-13. Branch: `audit/astra`. Baseline/HEAD:
`9a611a387e35c0a6cebcb0cb40db5b2e9e8a6c3c`.
Working tree inicialmente limpo. Somente F03 implementado, sem commit ou push.

## Causa raiz e decisão

O trigger `on_auth_user_created` chamava `handle_new_user()` como SECURITY DEFINER.
A função copiava role, clinic_id e is_active de raw_user_meta_data para profiles,
inclusive com ON CONFLICT DO UPDATE. Esses metadados podem ser enviados no signup
e editados pelo usuário; não são fonte confiável de autorização.

O signup local está habilitado em `[auth]` e `[auth.email]`, com confirmação de
e-mail. `[auth.sms].enable_signup` está desabilitado. Essas configurações não
foram alteradas: a proteção não depende de fechar o endpoint público.

**Padrão seguro: conta Auth sem profile, clínica ou papel de aplicação.** Não foi
escolhida uma clínica padrão nem criado um paciente ativo automaticamente. O
schema de profiles exige clinic_id/role; inventar esse vínculo concederia acesso
indevido. Uma conta pode autenticar sem ter sido provisionada clinicamente.

A nova função é SECURITY INVOKER, com search_path pg_catalog, e somente retorna
NEW. Não lê user_metadata, app_metadata ou JWT claims; não escreve em profiles.
O trigger continua instalado por compatibilidade. EXECUTE foi revogado de PUBLIC,
anon, authenticated e service_role. Nenhuma RPC de provisionamento foi adicionada.

## Arquivos alterados

| Arquivo | Motivo |
|---|---|
| `supabase/migrations/20260913130000_remove_signup_metadata_authorization.sql` | Substitui a função vulnerável sem editar histórico |
| `supabase/functions/create-patient/index.ts` | Provisiona profile explicitamente com valores validados pelo servidor, antes de patients; remove privilégios de user_metadata |
| `supabase/functions/create-staff-user/index.ts` | Remove role/clinic_id de user_metadata; mantém upsert explícito autorizado |
| `supabase/functions/accept-patient-invitation/index.ts` | Remove role/clinic_id de user_metadata; mantém profile derivado do convite validado |
| `supabase/seed.sql` | Provisiona os três perfis demo explicitamente, necessário para instalação limpa |
| `supabase/tests/f03-signup-authorization-tests.sql` | Casos negativos SQL, identidade GoTrue, perfis existentes e reentrada do trigger |
| `supabase/tests/f03-auth-signup-tests.ps1` | Integração HTTP local com Auth, REST e os três handlers; cleanup das fixtures |
| `docs/F03_SIGNUP_HARDENING.md` | Este relatório |

Nenhuma alteração em frontend, UX/UI, F01/F02, F04 ou migrations históricas.

## Fluxos legítimos

- **Staff por administrador:** getCallerProfile valida usuário real, profile ativo
  e platform_admin; role é limitado a psychologist/platform_admin e clínica é
  validada no banco. Depois de admin.createUser, o service client grava profiles.
- **Paciente por profissional:** mantém validação do chamador, psicólogo responsável,
  clínica e quotas. Agora insere explicitamente profile com role patient e
  is_active true antes de patients. Valores extras de autorização no body são
  ignorados. Falha no novo passo tenta remover a identidade Auth criada e registra
  se a compensação falhou.
- **Paciente por convite:** token, validade e estado pending continuam sendo
  verificados; clínica vem do convite e role patient é fixado pelo servidor.
  Dados extras em body.profile não concedem privilégios.
- **Supabase Auth:** sincronização de e-mail permanece no trigger existente e foi
  testada após provisionamento. Atualizar metadata não cria nem altera profiles.
- **Contas existentes:** a migration não altera dados nem reclassifica perfis.
  Criação duplicada continua retornando conflito; não substitui o profile existente.
- **Intervalo entre Auth e profile:** contas autenticadas sem profile foram
  bloqueadas no INSERT direto de profiles e nos handlers create-patient/staff.
  Não se presume atomicidade entre chamadas HTTP diferentes.

Os três handlers continuam gravando somente full_name/phone em user_metadata.
Autorização reside em profiles e nos valores explicitamente validados no servidor.

## Validação realizada

| Verificação | Resultado |
|---|---|
| `supabase db reset --local` | PASS: histórico completo + nova migration + seed explícito; 116 migrations |
| SQL F03 | PASS: 46 verificações, com 17 payloads de metadata; ROLLBACK |
| Mutação com handle_new_user histórico | PASS da detecção: suíte falhou exatamente em `signup cannot provision platform_admin`; transação revertida |
| HTTP F03 completo | PASS: 30 verificações contra Auth/REST/Edge Functions reais locais; fixtures removidas |
| SQL F01/F02 | PASS: suíte de 84 verificações |
| Patient lifecycle | PASS |
| Production governance | PASS |
| `supabase db lint --local` | PASS: No schema errors found |
| `flutter analyze --no-fatal-infos` | PASS: 99 infos, zero warnings/errors |
| `flutter test` | PASS: 447 testes |
| `git diff --check` | PASS |
| `deno check` / suítes Deno de helpers | NÃO EXECUTADOS: Deno CLI ausente no host e no container existente; handlers executados via Supabase Edge Runtime não substituem typecheck |

A primeira execução HTTP foi parcial porque o runtime local anterior havia sido
encerrado. Após reiniciá-lo, a suíte completa terminou com exit 0. Nenhuma falha
parcial foi contada como aprovação final. Não foram instaladas dependências.

Comandos para repetir (somente ambiente local):

```powershell
Get-Content -Raw supabase/tests/f03-signup-authorization-tests.sql | docker exec -i supabase_db_App_Clinica_Psicologia psql -U supabase_admin -d postgres -X -v ON_ERROR_STOP=1
# Em outro terminal: supabase functions serve
./supabase/tests/f03-auth-signup-tests.ps1
```

O teste HTTP exige PowerShell 7, obtém URL/chaves de `supabase status` sem imprimi-las
e rejeita hosts não locais. Usa apenas contas sintéticas de prefixo UUID próprio,
com limpeza em finally. O convite de teste é inserido diretamente para não enviar
mensagem por provedor externo. `-AuthOnly` e `-SkipPublicSignup` permitem repetir
partes da suíte quando necessário; não equivalem a uma execução completa.

## Revisão adversarial

Testados: platform_admin, psychologist, admin legado, clínica arbitrária/inexistente,
ativação explícita, quotas e flags extras, objetos aninhados, ausência de metadata,
NULL, array/escalar JSON, tipos malformados e chaves incompletas. Nenhum desses
payloads criou profile. A restauração do comportamento histórico falhou já no
primeiro payload válido malicioso, antes dos casos malformados.

Pelo Auth real, app_metadata e role de serviço enviados no signup não alteraram
o papel Auth; edição de user_metadata não provisionou profile. Adulterar o role
no JWT sem assinar novamente foi rejeitado com 401. Uma conta sem profile recebeu
403 nas tentativas de criar staff/paciente e de se inserir diretamente em profiles.

O teste SQL também reanexou temporariamente handle_new_user a UPDATE de metadata:
a função continuou incapaz de sobrescrever um profile existente. Todos os objetos
adicionais desse teste foram revertidos. A função não possui auxiliares nem SQL
dinâmico que possam reabrir o caminho por metadata.

## Riscos residuais e publicação futura

- Configuração remota de signup, hooks, providers, JWT, grants e versões das Edge
  Functions não foi consultada nem alterada. Nenhuma validação em produção ocorreu.
- Perfis privilegiados criados indevidamente antes desta correção continuam
  existentes; precisam de revisão humana. Não houve saneamento automático.
- Auth e profiles são provisionados em chamadas separadas. Queda/falha de
  compensação pode deixar identidade sem profile; ela não se torna privilegiada
  pelo trigger. Não foi implementada saga, reconciliação ou teste de concorrência
  entre processos. As fragilidades de lifecycle/convites de outros findings permanecem.
- Em especial F04 continua fora do escopo: a segurança de todas as RPCs para
  usuários sem profile não é garantida por esta correção de signup.
- Integrações externas que esperem profile automático após admin.createUser
  precisarão provisioná-lo explicitamente por caminho de servidor autorizado.
- Para publicação futura, implantar primeiro os três handlers atualizados e depois
  a migration. Eles já omitem os metadados privilegiados e gravam profiles, sendo
  compatíveis também com o trigger antigo. Aplicar a migration mantendo o antigo
  create-patient quebraria a criação direta de paciente até atualizar o handler.
  Nenhuma implantação remota foi executada nesta tarefa.

## Git

`git diff --stat` dos arquivos já rastreados: 4 arquivos, 41 inserções e 15 remoções.
A migration, as duas suítes e este relatório são arquivos novos não rastreados e
não entram nessa contagem. Não foi feito staging.

Sugestão de commit: `fix(security): remove profile authorization from signup metadata`.
Sem commit ou push. Aguardando revisão de F03.
