# Lote D — N20: autorização da jornada de psicoeducação

Implementado e validado somente no Supabase local em 2026-09-14.
Nenhum commit, push, merge, rebase, cherry-pick ou acesso à staging/produção.

## Estado inicial e escopo

Branch `audit/astra`, HEAD `31a0491d0bd44eebade0b9a7230d177442996d59`, working
tree limpo. `git ls-remote origin refs/heads/audit/astra` confirmou o mesmo HEAD.
Somente N20 / `get_psychoeducation_journey()` foi alterada, por nova migration
`20260914150000_harden_psychoeducation_journey.sql`. Nenhuma migration histórica,
tabela persistente, frontend ou outra RPC foi alterada.

## Contrato anterior e evidências de consumo

A definição final histórica estava em `20260806120000_psychoeducation_modules.sql`:
PL/pgSQL, sem argumentos, retorno JSONB, SECURITY DEFINER, owner postgres,
search_path public, sem guard de identidade/profile. PUBLIC e anon tinham
EXECUTE efetivo. Assim, publicar um módulo também o tornava acessível via RPC
sem login, embora o produto descrevesse publicação para pacientes/profissionais.

A investigação foi reconfirmada antes de editar:

- `mobile/lib/features/psychoeducation/data/psychoeducation_repository.dart`:
  `getJourney()` chama esta RPC e documenta acesso sem texto do terapeuta.
- `psychoeducationJourneyProvider` alimenta `PsychoeducationJourneyPage` e
  `PsychoeducationModulePage`.
- `psychoeducation_routes.dart`: leitura em `/patient/psychoeducation` e
  `/psychologist/psychoeducation`, incluindo detalhes dos módulos.
- `app_router.dart` exige profile para essas rotas; `RouteAccess.publicPaths`
  não as inclui. Deep links não dispensam o guard.
- A curadoria `/platform/psychoeducation` usa o repositório administrativo e a
  tabela diretamente, não esta RPC.
- Não foi encontrado consumidor público, de platform_admin ou service_role
  desta RPC em Edge Functions/scripts. Testes de renderização substituem o
  provider; não estabelecem contrato público.

## Contrato final e implementação

Permitido somente contexto PostgreSQL `authenticated`, UID presente, profile
existente/ativo e papel exatamente `patient` ou `psychologist`.
O catálogo continua global: sem filtro/requisito de clínica ou vínculo patient.

Negados: anon, ausência de UID/profile, profile removido/inativo, role NULL,
platform_admin, legacy admin, outros papéis, claims sem profile válido,
service_role direto e owner usado como caller de aplicação.

O guard usa `current_setting('role', true) IS DISTINCT FROM 'authenticated'`,
`auth.uid()` e `NOT EXISTS` sobre `public.profiles`, com `is_active IS TRUE` e
lista positiva de papéis. Nega com SQLSTATE 42501 / `Psychoeducation access denied`
antes da consulta de conteúdo. Não usa `current_user`/`session_user` como usuário
de aplicação e não confia em papéis de app_metadata/user_metadata.

Assinatura, JSONB, owner, linguagem e volatilidade histórica foram preservados.
SECURITY DEFINER continua necessário para o paciente ler somente a projeção
sanitizada, sem receber acesso direto à tabela que contém texto do terapeuta.
Search_path agora é pg_catalog, relações qualificadas, sem SQL dinâmico.

## Projeção preservada

A comparação do trecho de consulta/retorno com a definição histórica confirmou
igualdade exata. Mantidos filtro `is_published`, ordem dos módulos por `number`,
estrutura, campos nulos, cards vazios e semântica de agregação existentes.

- Módulo: id, number, stage, title, presentation, closing, accent_color, cover_url,
  cards.
- Card: title, image_url, patient_text, reflection, exercise.
- Não retorna therapist_text, is_published, timestamps, IDs clínicos, progresso,
  vínculo, notas ou chaves privadas extras. `id` identifica o módulo editorial.

## Grants efetivos antes/depois

| Role | Antes | Depois |
|---|---|---|
| PUBLIC | EXECUTE | Sem EXECUTE |
| anon | EXECUTE | Sem EXECUTE |
| authenticated | EXECUTE | EXECUTE com guard |
| service_role | EXECUTE | Sem EXECUTE |
| postgres | EXECUTE | Preservado |
| supabase_admin | EXECUTE efetivo | Preservado |

Decisão: remover também EXECUTE explícito de service_role por ausência de
consumidor legítimo. O guard o nega mesmo com um grant temporário e UID de
paciente válido. Não foram removidos poderes inerentes do owner/superuser.
ACL final consultada: `{postgres=X/postgres,authenticated=X/postgres}`.
Somente authenticated, postgres e supabase_admin têm EXECUTE efetivo no catálogo
local. Defaults globais não foram alterados; não reabrem esta função existente.

## Testes SQL e adversariais

`lote-d-psychoeducation-tests.sql`: **31 verificações** com rollback integral.

- ACL real de PUBLIC/anon/service/authenticated, owner e search_path.
- Negações por ACL e pelo corpo: grants temporários exercitam o guard mesmo se
  alguma concessão futura reabrir EXECUTE.
- Sem UID, UUID inexistente, profile ausente/removido/inativo, platform_admin,
  legacy admin, role NULL, claims falsos de patient/psychologist, service e owner.
- Patient de A e psychologist de B recebem a mesma resposta global completa.
- Fixtures publicadas inseridas fora de ordem, campos legítimos completos,
  campos nulos, cards vazios e módulo não publicado.
- Igualdade com JSON literal esperado valida campos, valores e ordenação.
- Sentinelas em therapist_text, patient_id, clinic_id, progress, private_note e
  arbitrary_extra não aparecem. Módulo não publicado também não aparece.
- Role/clinic NULL são estados impossíveis no schema atual; constraints são
  relaxadas apenas dentro de savepoint revertido. Role NULL nega, clinic NULL
  não bloqueia paciente legítimo. Não há alteração persistente de constraints.
- Conteúdo propositalmente malformado prova que usuário sem profile recebe
  negação de autorização antes de alcançar a consulta JSON.

`lote-d-psychoeducation-mutation.ps1` extrai o corpo histórico, restaura grants
PUBLIC/anon em memória dentro da transação e executa a suíte. Ela falha com:
`FAIL: anon historical bypass denied before content` (psql exit 3).
Existem fixtures publicadas; a falha é o retorno anônimo indevido, não sintaxe,
FK, fixture ou falta de conteúdo. Ao desconectar, rollback integral. O runner
compara fingerprint de definição/owner/ACL e repete as 31 verificações verdes.
Passou tanto no banco existente quanto após reset completo.

## HTTP / PostgREST

`lote-d-psychoeducation-http.ps1`: **17 verificações** com sessões Auth reais
locais e limpeza das seis identidades sintéticas em finally.

| Identidade | HTTP | Resultado |
|---|---|---|
| anon | 401 | Sem conteúdo |
| sem profile | 403 | Sem conteúdo |
| patient inativo | 403 | Sem conteúdo |
| psychologist inativo | 403 | Sem conteúdo |
| platform_admin | 403 | Sem conteúdo |
| patient ativo | 200 | 6 módulos do seed |
| psychologist ativo | 200 | 6 módulos do seed |

Respostas negativas têm SQLSTATE 42501 e nenhum campo de conteúdo parcial.
As positivas têm allowlist exata de campos de módulo/card e JSON idêntico.
O teste HTTP usa a mesma clínica de seed; a prova de clínicas diferentes está
na suíte SQL. Nenhuma credencial é escrita nos arquivos ou neste relatório.

## Regressões executadas

| Verificação | Resultado |
|---|---|
| Migration sobre banco existente | PASS |
| Reset completo com migrations e seed | PASS |
| SQL D / mutação D | 31 PASS, bypass detectado e restauração validada |
| HTTP D | 17 PASS |
| Lote C | 27 PASS |
| Lote B | 438 PASS |
| Lote A | 378 PASS |
| F01/F02 | PASS, exit 0 |
| F03 SQL / HTTP | 46 / 30 PASS |
| Lifecycle / governance | PASS |
| SQL lint local | Sem erros |
| Flutter analyze --no-fatal-infos | Exit 0; 99 infos, sem warnings/errors |
| Flutter test | 447 PASS |
| Smoke RLS antigo | Somente falha conhecida da fixture sem questionnaire_version_id |
| Deno CLI | Indisponível; nenhum código Edge alterado |

## Limitações e entrega

Validação apenas local; produção e configuração remota não foram validadas.
Integrações externas desconhecidas que usem anon/admin/service nesta RPC serão
negadas intencionalmente. Campos editoriais livres continuam dependentes de
curadoria: a projeção remove chaves privadas, não anonimiza texto arbitrário.
Conteúdo malformado pode continuar falhando para chamadores legítimos, como
antes. Não se pretende restringir superusuários capazes de alterar o próprio SQL.

Fora do escopo e intocados: Storage, app_metadata, defaults globais,
is_library_cover_admin, library_indications, outras RPCs, frontend e UX.

Cinco arquivos novos: esta documentação, uma migration, suíte SQL, runner de
mutação e suíte HTTP. Nenhum arquivo rastreado/histórico alterado.

Sugestão de commit após revisão independente, sem execução nesta tarefa:
`fix(security): restrict psychoeducation journey to active patients and psychologists`
