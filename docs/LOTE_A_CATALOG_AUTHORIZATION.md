# Lote A — N02: autorização administrativa do catálogo

Data: 2026-09-14. Branch: `audit/astra`.
Base conferida antes de editar: `94a8a4c3b4c1939986dd4c7c53edc94f6355796d`,
igual ao HEAD publicado de `origin/audit/astra`; working tree inicialmente limpo.
Não houve commit, push, merge ou alteração de staging.

## Causa e estratégia

A lógica anterior usava `current_role() NOT IN ('platform_admin','admin')`.
Sem profile ou com profile inativo, o helper de papel retorna NULL:
a condição PL/pgSQL não fica verdadeira e a exceção não é levantada.
Aceitar o papel legado `admin` também contrariava o contrato solicitado.

Uma única migration, `supabase/migrations/20260914120000_harden_catalog_admin_authorization.sql`,
substitui apenas o corpo de `assert_platform_admin()`, com assinatura void preservada.
Exige contexto de banco authenticated, UID presente e profile ativo com papel
exatamente platform_admin. NOT EXISTS rejeita ausência e valores NULL.
O catálogo continua global: não exige igualdade de clínica.

## Definição final

```sql
CREATE OR REPLACE FUNCTION public.assert_platform_admin()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor_id uuid := auth.uid();
BEGIN
  IF current_setting('role', true) IS DISTINCT FROM 'authenticated'
    OR v_actor_id IS NULL
    OR NOT EXISTS (
      SELECT 1
      FROM public.profiles AS actor
      WHERE actor.id = v_actor_id
        AND actor.is_active IS TRUE
        AND actor.role::text = 'platform_admin'
    ) THEN
    RAISE EXCEPTION USING ERRCODE = '42501',
      MESSAGE = 'Active platform administrator required';
  END IF;
END;
$$;
```

Owner efetivo: postgres. O helper usa search_path=pg_catalog, auth.uid() e
public.profiles qualificados; sem SQL dinâmico e sem current_user/session_user
como identidade de aplicação. current_user seria postgres durante SECURITY DEFINER.
current_setting('role') preserva o papel selecionado pelo PostgREST durante chamadas
aninhadas; claims JSON e metadata editável não substituem esse contexto nem o profile.

## Consumidores e grants efetivos

As 11 funções finais abaixo chamam o helper e são SECURITY DEFINER, owner postgres,
search_path=public. A comparação de prosrc antes/depois confirmou que **nenhum dos
11 corpos mudou**. Somente suas ACLs foram endurecidas.

| Consumidor | Corpo | PUBLIC antes/depois | anon antes/depois |
|---|---|---|---|
| admin_archive_questionnaire | preservado | sim/não | sim/não |
| admin_create_draft_version | preservado | sim/não | sim/não |
| admin_delete_question | preservado | sim/não | sim/não |
| admin_delete_questionnaire_draft | preservado | sim/não | sim/não |
| admin_discard_draft_version | preservado | sim/não | sim/não |
| admin_duplicate_questionnaire_as_draft | preservado | sim/não | sim/não |
| admin_get_questionnaire | preservado | sim/não | sim/não |
| admin_list_questionnaires | preservado | sim/não | sim/não |
| admin_publish_questionnaire | preservado | sim/não | sim/não |
| admin_save_question | preservado | sim/não | sim/não |
| admin_save_questionnaire_draft | preservado | sim/não | sim/não |

No próprio assert_platform_admin, PUBLIC era não e permanece não; anon passou de
sim para não. Em todas as 12 funções, authenticated, service_role, postgres e
supabase_admin tinham e mantêm EXECUTE efetivo. Verificado via catálogo real,
aclexplode e has_function_privilege, inclusive superusuário, após instalação limpa.

EXECUTE não é autorização: service_role é rejeitado pelo guard, inclusive com UID
de administrador ativo; owner/superusuário mantêm poderes administrativos de banco.
Não existe bypass automático para manutenção sem contexto authenticated.
A busca dos consumidores encontrou chamadas no repositório Flutter
questionnaire_catalog_admin_repository.dart via cliente autenticado; não encontrou
uso destas RPCs por Edge Functions ou scripts de provisionamento que exigisse anon.

## Suíte específica e reprodução

Arquivo: `supabase/tests/lote-a-catalog-authorization-tests.sql`.
Fixtures sintéticas independentes do seed, duas clínicas, nove identidades Auth,
questionários ativo/draft, versões, perguntas, regras e acesso profissional.
Tudo roda em BEGIN/ROLLBACK, inclusive grants temporários e triggers de prova.

Executar na raiz, somente no ambiente local:

```powershell
Get-Content -Raw supabase/tests/lote-a-catalog-authorization-tests.sql |
  docker exec -i supabase_db_App_Clinica_Psicologia psql -U supabase_admin -d postgres -X -v ON_ERROR_STOP=1
```

**378 verificações passaram**, antes e depois do reset completo:

- 1 verifica a quantidade final de consumidores.
- 12 verificam grants efetivos das funções.
- 168 negações: 12 identidades/contextos por 14 caminhos.
- 168 verificam ausência de efeitos nas nove tabelas monitoradas.
- 28 controles positivos: 14 caminhos para cada um de dois administradores globais.
- 1 verifica atomicidade após erro deliberado posterior ao guard.

Os 14 caminhos incluem helper, 11 consumidores e variantes de criação/edição
de pergunta e de draft. Identidades negadas: sem profile, três papéis inativos,
paciente/psicólogo ativos, papel legado admin, authenticated sem UID,
anon com/sem UID e service_role com/sem UID. Inclui metadata/claims simulados
alegando platform_admin. Role NULL persistida não é permitida pelo schema;
o retorno NULL histórico é reproduzido pelo profile ausente/inativo.

Cada negação exige SQLSTATE 42501 e mensagem exata do guard.
Antes das operações, triggers temporários em nível de statement interrompem
qualquer INSERT/UPDATE/DELETE/TRUNCATE com SQLSTATE diferente: assim uma FK
ou rollback posterior não pode mascarar autorização tardia.
Snapshots completos cobrem questionnaires, questionnaire_versions, questions,
question_categories, question_category_items, question_scoring_rules,
severity_ranges, questionnaire_professional_access e audit_events.
As leituras precisam lançar a mesma exceção antes de retornar dados.
Um GRANT anon temporário, após validar as ACLs reais, testa o guard mesmo se
esse EXECUTE for acidentalmente restaurado; é revertido no fim.

Controles positivos verificam dados efetivamente criados, copiados, editados,
excluídos, publicados/arquivados e auditoria correspondente. Os dois admins,
de clínicas distintas, operam o mesmo catálogo global. Um trigger de auditoria
provoca erro após a alteração de arquivamento; o snapshot prova rollback integral.

## Mutação histórica

A definição anterior foi lida do catálogo antes da migration e reinserida
**somente em memória** no marcador MUTATION_INJECTION_POINT, após BEGIN.
A mesma suíte falhou como esperado com:
`FAIL: assert_platform_admin allowed no_profile` (processo não zero).
ON_ERROR_STOP encerrou a conexão e reverteu a transação.
Conferência posterior confirmou helper corrigido, search_path=pg_catalog,
ACLs restauradas e nenhuma identidade sintética remanescente.
O reset posterior e a repetição das 378 verificações também passaram.
A mutação não foi gravada em migration histórica nem persistida no banco.

## Validações executadas

| Validação | Resultado |
|---|---|
| supabase migration up --local | passou em banco existente |
| supabase db reset --local | passou com todas as migrations e seed |
| Nova suíte Lote A | 378 verificações, exit 0, incluindo instalação limpa |
| F01/F02 SQL | 84 verificações, exit 0 |
| F03 SQL | 46 verificações, exit 0 |
| F03 Auth/signup HTTP + Edge Functions | 30 verificações, exit 0; fixtures limpas |
| patient-lifecycle-tests.sql | OK, exit 0 |
| production-governance-tests.sql | OK, exit 0 |
| rls-smoke-tests.sql | falhou na fixture, exit 3; ver abaixo |
| supabase db lint --local | No schema errors found, exit 0 |
| flutter analyze --no-fatal-infos | exit 0; 99 infos, sem errors/warnings |
| flutter test | 447 testes passaram, exit 0 |
| Deno | executável não disponível; não executado |

O smoke RLS insere questionnaire_responses sem questionnaire_version_id
(linha 143). A coluna é NOT NULL desde a migration histórica
20260711120000_questionnaire_true_versioning.sql. Falhou antes de exercitar
as políticas, com violação NOT NULL; suas fixtures foram revertidas.
Este lote não altera essa tabela/constraint nem a suíte antiga.

## Revisão adversarial e riscos residuais

Sem UID/profile, inativos, papéis incorretos/NULL, chamadas diretas e aninhadas,
anon e service_role foram negados antes de efeitos. Grants PUBLIC/anon estão
revogados apenas nas 12 funções; authenticated continua dependendo do guard.
Os fixtures válidos e triggers sentinelas impedem falsas conclusões por FK.
O teste de falha tardia demonstrou ausência de efeitos parciais.

O modelo depende do PostgREST escolher o papel de banco a partir de JWT validado;
esta suíte SQL simula esse contexto, não valida a configuração remota do gateway.
F03 HTTP validou localmente Auth/Edge Functions e rejeição de JWT forjado.
Produção não foi acessada, migrada ou validada. Owners/superusuários e credenciais
de servidor comprometidas continuam fora da fronteira de segurança do guard.

Risco de regressão focal: clientes desconhecidos usando anon, service_role ou
papel legado admin para administrar catálogo passam a ser negados; isso é
intencional pelo contrato exclusivo de platform_admin ativo autenticado.
Os fluxos conhecidos do Flutter e os 11 controles positivos foram preservados.
Search_path e auxiliares dos consumidores permanecem históricos; não houve
hardening generalizado. Outros findings N01/F04, N14–N20, Storage/app_metadata
e F05/F06/F07 não foram corrigidos. O smoke RLS antigo permanece pendente.

## Arquivos e sugestão de commit

Somente três arquivos novos: esta documentação, a migration e a suíte específica.
Nenhum arquivo existente foi modificado; nenhum arquivo foi staged.
git diff --stat fica vazio porque os arquivos ainda são untracked.

Sugestão (não executada):
`fix(security): fail closed on catalog administrator authorization`

Entrega aguardando revisão humana. Sem commit/push.
