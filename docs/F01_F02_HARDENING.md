# F01/F02 — implementação para revisão

Data: 2026-09-13. Branch: `audit/astra`. HEAD inicial e final:
`e47a71b2380e2df02ad866f10824d885fc0939ca`. Escopo autorizado: somente F01/F02.
Sem commit, push, merge, alterações de frontend ou aplicação remota.

## Baseline e arquivos

Os arquivos versionados estavam limpos. O status inicial continha apenas
`?? .claude/settings.local.json`. O arquivo local foi preservado; a inclusão de
seu caminho no `.gitignore` é o housekeeping opcional autorizado, separado do SQL.
O working tree final contém as alterações abaixo, ainda sem staging.

| Arquivo | Alteração |
|---|---|
| `supabase/migrations/20260913120000_harden_profile_updates_and_patient_delete.sql` | Nova migration; substitui duas funções e restringe EXECUTE |
| `supabase/tests/f01-f02-authorization-tests.sql` | Suíte isolada, fixtures próprias, rollback integral |
| `docs/F01_F02_HARDENING.md` | Este relatório de implementação e validação |
| `.gitignore` | Housekeeping: ignora somente `.claude/settings.local.json` |

Nenhuma migration histórica, policy RLS, Edge Function ou fixture preexistente foi editada.

## Causas e correção

**F01:** `prevent_profile_privilege_escalation()` era SECURITY DEFINER e tratava
`current_user = postgres` como autorização do chamador. O catálogo local confirmou
que postgres é o proprietário da função, neutralizando a proteção.

A função continua SECURITY DEFINER para consultar o ator sem recursão de RLS,
mas exige papel de conexão `authenticated`, `auth.uid()` e profile ativo com role
não nulo. Consulta diretamente `public.profiles`; não delega a autorização a
`current_role()` nem usa metadados fornecidos pelo usuário.

Edição pessoal permitida: `full_name`, `phone`, `avatar_url`, `avatar_type`,
`avatar_path`, `avatar_config`, `avatar_updated_at` e `updated_at`. Este último
continua sujeito ao trigger existente. Identidade, e-mail, CRP, criação, clínica,
papel, status, quotas e novas colunas ficam protegidos por padrão.

Exceções explícitas preservadas:

- Administrador ativo da plataforma: operações administrativas existentes.
- Papel real de banco `service_role`: operações das Edge Functions existentes.
- Sessões diretas postgres/supabase_admin, sem SET ROLE de aplicação: manutenção.
- Conexão real `supabase_auth_admin`: somente sincronização de e-mail já registrado
  em `auth.users`, com atualização do timestamp.
- Psicólogo ativo responsável, na mesma clínica do paciente e do profile:
  somente `is_active` e `updated_at` no profile do paciente. A RLS continua
  impedindo a edição direta de outro perfil; a exceção serve ao lifecycle RPC.

`current_setting('role')` identifica o SET ROLE autorizado pelo PostgreSQL;
`session_user` identifica a conexão original. Nenhum deles é substituído pelo
proprietário da função SECURITY DEFINER. Claims de role isoladas não concedem
acesso de serviço.

**F02:** a comparação `NULL <> 'platform_admin'` não entrava no bloco de rejeição.
A RPC também tinha EXECUTE efetivo para anon, PUBLIC e service_role.

A RPC agora exige o papel de conexão authenticated, UID presente e existência de
profile ativo cujo role seja exatamente platform_admin, antes de consultar o alvo.
Ausência, inatividade e NULL falham com `42501`. Administrador válido recebe
`P0002` para ID inexistente ou NULL. O papel platform_admin permanece global:
exclusão entre clínicas por esse administrador é comportamento legítimo existente.
O alvo é bloqueado com FOR UPDATE; exclusão, cascatas e auditoria são atômicas.

## Funções, grants e search_path

Ambas mantêm o proprietário postgres e usam `search_path = pg_catalog`, com
referências explícitas a `public` e `auth`. Não há SQL dinâmico nas funções de produção.

| Função | EXECUTE efetivo confirmado no catálogo local |
|---|---|
| `prevent_profile_privilege_escalation()` | Proprietário; revogado de PUBLIC, anon, authenticated e service_role. O trigger continua executando |
| `delete_patient_as_admin(uuid)` | Proprietário e authenticated; revogado de PUBLIC, anon e service_role |

## Validação executada

| Verificação | Resultado |
|---|---|
| `supabase db reset --local` | PASS; histórico completo e seed, incluindo a migration nova |
| Reaplicação da migration durante revisão | PASS; CREATE OR REPLACE e ACLs reaplicáveis; versão final inclui compatibilidade com Auth |
| `f01-f02-authorization-tests.sql` | PASS; 84 verificações registradas, ROLLBACK |
| `patient-lifecycle-tests.sql` | PASS; inativação/reativação legítima e bloqueio da reativação pelo paciente |
| `production-governance-tests.sql` | PASS; ROLLBACK |
| `supabase db lint --local` | PASS; No schema errors found |
| `rls-smoke-tests.sql` | FAIL na fixture: questionnaire_version_id NULL; anterior às assertions, sem relação com a correção |
| `flutter analyze --no-pub --no-fatal-infos` | PASS; 99 infos, zero warnings/errors |
| `flutter test --no-pub --reporter expanded` | PASS; 447 testes |
| `git diff --check` | PASS |

O reset apagou e recriou somente o banco local deste projeto, com autorização da
ferramenta. O banco local terminou com 115 migrations, última `20260913120000`.
Catálogo conferido: role continua NOT NULL; nenhuma fixture da suíte permaneceu.

Para repetir a suíte no container local:

```powershell
Get-Content -Raw supabase/tests/f01-f02-authorization-tests.sql | docker exec -i supabase_db_App_Clinica_Psicologia psql -U supabase_admin -d postgres -X -v ON_ERROR_STOP=1
```

O superusuário local é necessário somente para preparar fixtures e simular a
identidade de conexão do Auth. Operações de aplicação rodam com SET ROLE
authenticated/anon/service_role. A simulação de role NULL relaxa NOT NULL apenas
dentro da transação de teste; a constraint é restaurada e tudo termina em ROLLBACK.

## Revisão adversarial e limites

Cobertura: alteração de cada campo protegido por paciente/psicólogo; perfil de
terceiro; perfil inativo e ausente; bypass de RLS via função privilegiada de teste;
role forjado em metadata/claim; manutenção administrativa e service_role; Auth;
lifecycle com ownership; anon com e sem grant temporário para alcançar o corpo da
RPC; NULL role/UID/alvo; alvo de outra clínica; objetos temporários tentando
sombrear profiles; grants PUBLIC; cascata; rollback quando a auditoria falha.
Nenhum bypass de F01/F02 foi observado nesses cenários.

As primeiras execuções expuseram dois problemas da nova fixture, corrigidos antes
do resultado final: expansão de registro composto e necessidade de superusuário
para SET SESSION AUTHORIZATION. Não foram tratados como passes.

Não houve teste HTTP autenticado via PostgREST, aplicação remota nem validação de
produção; os testes exercitam SQL/RPC com os papéis usados pelo PostgREST.
As Edge Functions não foram alteradas e os testes Deno não foram executados.

Outros findings permanecem fora do escopo. Em especial, F03 (signup confiando em
metadata) pode criar um perfil indevidamente administrativo; esta correção confia
no papel persistido do administrador e não saneia perfis já comprometidos. F04
também não foi corrigido: o novo trigger bloqueia o caso de reativação com profile
associado testado, mas não substitui a autorização do lifecycle para todos os casos.
Portanto, estes resultados não liberam o sistema para produção.

## Git e sugestão de commit

`git diff --stat` mostra somente `.gitignore | 3 +++`, pois a migration, a suíte e
este relatório são arquivos novos não rastreados. Não foi usado git add.

Status esperado para revisão:

```text
 M .gitignore
?? docs/F01_F02_HARDENING.md
?? supabase/migrations/20260913120000_harden_profile_updates_and_patient_delete.sql
?? supabase/tests/f01-f02-authorization-tests.sql
```

Sugestão de commit de segurança: `fix(security): bloqueia escalacao de perfil e exclusao anonima de pacientes`.
Housekeeping separado: `chore(git): ignora configuracao local do Claude`.
Nenhum commit foi executado. Aguardando revisão humana.
