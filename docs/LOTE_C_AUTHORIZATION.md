# Lote C — autorização de métricas e contrato da jornada

Data: 2026-09-14. Ambiente: Supabase local, branch `audit/astra`.
Implementação somente C1/N14. C2/N20 é investigação e recomendação, sem patch.
Nenhum commit, push, merge, rebase ou mudança em staging foi feito.

## Estado inicial

- HEAD: `c3e7712a460905f98b0ec3834796ddd030a5cc1e`.
- Working tree limpo; nenhum arquivo staged/untracked.
- `git ls-remote origin refs/heads/audit/astra` confirmou o mesmo HEAD remoto.

## C1 — N14: contrato e causa raiz

`get_patient_counts_by_psychologist()` não recebe argumentos e retorna tabela:
`psychologist_id uuid`, `active_count bigint`, `pending_invites bigint`.
É PL/pgSQL, STABLE, SECURITY DEFINER, owner `postgres`.

Histórico:

1. `20260720120011_restrict_admin_patient_access.sql` introduziu a RPC para
   permitir métricas administrativas sem expor prontuários individuais via RLS.
   Usava o papel legado `admin` e filtro pela clínica do chamador.
2. `20260815130000_fix_patient_counts_rpc.sql` é a última definição anterior
   ao Lote C, confirmada no catálogo local. Ela troca o papel para
   `platform_admin` e remove expressamente o filtro de clínica: contrato global.
3. A condição `current_role()::text <> 'platform_admin'` é permissiva quando o
   helper retorna NULL. O helper retorna o papel somente de um profile ativo;
   UID/profile ausente ou perfil inativo produz NULL. O IF não entra no ramo de
   negação e a função SECURITY DEFINER devolve UUIDs e contagens administrativas.

Antes: `search_path=public`, sem teste de UID/contexto; consulta `profiles`,
`patients` e `patient_invitations`. Nenhum SQL dinâmico. O acesso por PUBLIC e
anon era efetivo, além dos grants de authenticated/service_role/owner. Todos os
roles locais herdavam acesso via PUBLIC, inclusive roles internos do Postgres.

Consumidor: `mobile/lib/features/user_management/data/user_management_repository.dart`,
`listClinicUsers()`, agrega as duas contagens por UUID ao modelo `ClinicUser`.
É consumido pelo provider e pela tela de gerenciamento em `/platform/users`.
O comentário do repositório explica o contrato de platform_admin e a necessidade
de não ler pacientes individualmente. Não foram encontrados consumidores dessa
RPC em Edge Functions ou scripts. Patient/psychologist não têm contrato de acesso.

## C1 — implementação

Nova migration: `20260914140000_harden_patient_counts_authorization.sql`.

- Preserva assinatura, STABLE, SECURITY DEFINER e owner por CREATE OR REPLACE.
- Define `search_path=pg_catalog`; relações e `auth.uid()` qualificadas.
- Exige `current_setting('role', true) = 'authenticated'` e UID não nulo.
- Exige existência de profile ativo com `role::text = 'platform_admin'`.
- Falha com SQLSTATE 42501 e mensagem `Administrative counts access denied`
  antes da consulta de métricas. Não usa `current_role()` para autorizar.
- Não filtra clínica do administrador nem modifica a lógica das contagens.
- Revoga somente EXECUTE de PUBLIC/anon nessa função e preserva authenticated.
- Não altera defaults globais, owner, frontend, Storage ou outras funções.

O contexto de banco vem do SET ROLE de PostgREST. `current_user` dentro de uma
SECURITY DEFINER seria o owner, e `session_user` seria a identidade da conexão;
nenhum deles é usado como identidade de aplicação. Claims de papel/metadados
não substituem o papel de banco nem a consulta ao profile. Isso não pretende
proteger contra um superusuário SQL capaz de alterar funções ou simular sessões.

### Grants efetivos após aplicação e reset

| Identidade | EXECUTE antes | EXECUTE depois | Comportamento do guard |
|---|---|---|---|
| PUBLIC | Sim | Não | Não é identidade de aplicação |
| anon | Sim | Não | Também nega se EXECUTE for reaberto num teste |
| authenticated | Sim | Sim | Apenas platform_admin ativo com UID |
| service_role | Sim | Sim | Chamada direta negada, mesmo com UID de admin |
| postgres | Sim | Sim | Contexto direto negado, mesmo com UID de admin |
| supabase_admin | Sim | Sim | Privilégio administrativo do banco preservado |
| Outros roles locais | Sim via PUBLIC | Não | Catálogo efetivo consultado |

ACL final: `postgres=X`, `authenticated=X`, `service_role=X`.
Os únicos roles locais com EXECUTE efetivo são authenticated, postgres,
service_role e supabase_admin. Não houve concessão por coluna ou alteração de view.

## C1 — testes e revisão adversarial

`lote-c-counts-authorization-tests.sql`: **27 verificações**, sem depender do seed,
com duas clínicas, dez identidades e contagens sintéticas conhecidas.

- ACLs efetivos, owner, STABLE, SECURITY DEFINER e search_path.
- Anon negado por ACL; grant temporário testa também o guard de anon e anon
  com UID de administrador. O grant é revertido integralmente.
- Authenticated sem UID/profile, inativos admin/psicólogo/paciente, pacientes,
  psicólogos de A/B e papel legado negados, com SQLSTATE/mensagem exatos.
- Claims simulados anunciam papel de administrador nos metadados, sem conceder
  acesso aos profiles não autorizados.
- Service_role sem UID, sem profile ou com UID de admin negado; owner direto
  com UID de admin também negado.
- Cada negação exige ausência de resultado: nenhum UUID, contagem ou linha parcial.
- Administradores A e B enxergam as mesmas contagens globais: psicólogo A tem
  2 pacientes ativos/1 convite pendente; B tem 1/2; psicólogo sem pacientes tem 0/0.
  Paciente inativo e convite revogado não contam. O psicólogo inativo de contagem
  zero permanece listado, preservando a lógica histórica da métrica.
- Role e ativação NULL são negados. Administrador com clínica NULL mantém acesso
  global. Esses estados são impossíveis pelas constraints NOT NULL atuais;
  somente nesses probes elas são relaxadas dentro de savepoint, restaurado
  imediatamente e verificado. Não se altera o schema persistente.

`lote-c-counts-mutation.ps1` executa a suíte verde, extrai a definição histórica
da migration de agosto e a injeta em memória, após os checks dos grants atuais.
Assim a falha não é apenas de ACL/search_path: o usuário sem profile consegue
chegar às métricas e a suíte falha com:

`FAIL: missing profile denied before any metrics` (psql exit 3).

O encerramento da conexão reverte a transação. O runner compara o fingerprint
de definição, owner e ACL antes/depois e repete todas as 27 verificações verdes.
Isso passou no banco existente e novamente após reset completo.

Prova HTTP adicional com sessões Auth reais locais: anon recebeu 401; sem
profile, paciente e psicólogo receberam 403; administrador recebeu 200 com dois
registros do seed. As quatro identidades sintéticas foram removidas ao final.
Nenhum token, senha ou conteúdo individual é registrado aqui.

## C2 — N20: investigação, sem correção

**DECISÃO B — AUTHENTICATED ONLY** para um próximo patch autorizado.

Definição final: `20260806120000_psychoeducation_modules.sql`, única definição
encontrada; confirmada no catálogo local. Sem argumentos, retorna JSONB, PL/pgSQL,
SECURITY DEFINER, owner postgres, search_path public. Não consulta auth.uid(),
profile ou outro contexto. Lê apenas `public.psychoeducation_modules`, filtrando
`is_published`, ordenando por `number` e projetando explicitamente os cards.

Grants atuais, NÃO alterados: PUBLIC, anon, authenticated, service_role e postgres
com EXECUTE; demais roles herdam PUBLIC. A tabela tem RLS habilitada, policy de
leitura publicada para staff authenticated e gerenciamento para admin. Não há
policy anon. A RPC como owner lê além da RLS do chamador, mas limita explicitamente
às publicações e à projeção sem texto do terapeuta.

### Estrutura retornada

- Módulo: `id` (UUID editorial), `number`, `stage`, `title`, `presentation`,
  `closing`, `accent_color`, `cover_url`, `cards`.
- Card: `title`, `image_url`, `patient_text`, `reflection`, `exercise`.
- Categorias: identidade/ordenação do catálogo, conteúdo educativo, apresentação
  visual e URLs de imagens. `patient_text` é texto genérico destinado ao paciente,
  não texto extraído de prontuário individual.
- Não retorna `therapist_text`, is_published, created_at/updated_at, IDs de
  paciente/clínica/profissional, vínculo clínico, progresso ou estado privado.
- Não há joins ou parâmetros que introduzam dados por pessoa/clínica.

| Identidade HTTP local | Status | Registros | Diferença de resposta |
|---|---|---|---|
| anon | 200 | 6 | Referência |
| authenticated sem profile | 200 | 6 | Nenhuma; JSON idêntico |
| patient ativo | 200 | 6 | Nenhuma; JSON idêntico |
| psychologist ativo | 200 | 6 | Nenhuma; JSON idêntico |
| platform_admin ativo | 200 | 6 | Nenhuma; JSON idêntico |

Probe adicional em transação: módulo publicado com chaves `therapist_text`,
`patient_id` e `progress` contendo sentinelas privadas; outro módulo não publicado.
Como anon, a RPC retornou o publicado sem as chaves/sentinelas extras, omitiu o
não publicado, e SELECT direto da tabela não mostrou nenhum dos dois. Rollback
completo. Não foi identificado vazamento contextual/privado na estrutura atual.

### Evidência de produto e Flutter

- O cabeçalho da migration diz que publicar libera para psicólogos e pacientes,
  descrevendo a RPC como acesso do paciente; não descreve publicação para internet.
- `PsychoeducationRepository.getJourney()` chama a RPC; o comentário diz acesso
  do paciente, sem texto do terapeuta.
- `psychoeducationJourneyProvider` alimenta `PsychoeducationJourneyPage` e
  `PsychoeducationModulePage`.
- `psychoeducation_routes.dart` insere essas telas sob `/patient/psychoeducation`
  e `/psychologist/psychoeducation`. `/platform/psychoeducation` usa o repositório
  administrativo sobre a tabela para curadoria.
- `app_router.dart` redireciona profile ausente para login/onboarding;
  `RouteAccess.publicPaths` não contém nenhuma rota de psicoeducação.
- Não foi encontrada tela pública/pré-login dependente da RPC, consumidor Edge
  ou script, nem conteúdo explicitamente destinado a marketing/site público.
- Os testes encontrados são de domínio da jornada e renderização com provider
  substituído; não estabelecem um contrato anônimo de backend.

Logo, os usos encontrados pertencem ao app autenticado. EXECUTE público é
exposição fora desse contrato, não evidência de intenção de produto público.
Próximo patch recomendado: remover PUBLIC/anon, exigir contexto autenticado,
UID/profile ativo e papéis legítimos (paciente/psicólogo; confirmar necessidade
de leitura dessa projeção por administrador, cuja curadoria usa outra via).
Manter a projeção publicada sem dados privados e adicionar matriz permanente
de autorização e projeção. **Nada disso foi implementado para N20 neste lote.**

## Regressões executadas

| Validação | Resultado |
|---|---|
| Migration no banco existente: `supabase migration up --local` | PASS |
| Reset completo: `supabase db reset --local` | PASS, migrations + seed |
| Lote C1 e mutação antes/depois do reset | 27 PASS; mutação detectada; rollback comprovado |
| Lote B | 438 PASS |
| Lote A | 378 PASS |
| F01/F02 | PASS, exit 0 |
| F03 SQL | 46 PASS |
| F03 HTTP com runtime local | 30 PASS; fixtures limpas |
| Patient lifecycle | PASS, exit 0 |
| Production governance | PASS, exit 0 |
| SQL lint local | Sem erros |
| Flutter analyze --no-fatal-infos | Exit 0, 99 infos, sem warnings/errors |
| Flutter test | 447 PASS |
| Smoke RLS antigo | Falha conhecida: fixture sem questionnaire_version_id |
| Deno CLI | Indisponível; nenhum código Edge alterado |

Reprodução das suítes: executar o runner de mutação com PowerShell 7 e enviar
cada SQL para `docker exec -i supabase_db_App_Clinica_Psicologia psql -U
supabase_admin -d postgres -X -v ON_ERROR_STOP=1`. Todos os fixtures SQL revertem.

## Limites, risco de regressão e entrega

- Validado apenas no ambiente local; migrations/grants/configuração remotos não
  foram aplicados nem validados. Staging não foi acessada.
- O chamador administrativo legítimo conserva assinatura e contagens globais.
  Scripts externos não presentes no repo que usassem N14 anon/service_role direto
  passarão a falhar: restrição intencional.
- N20 continua acessível anonimamente até um patch separado; conteúdo de campos
  editoriais livres e URLs depende da curadoria. A projeção não classifica nem
  anonimiza texto arbitrário inserido em campos públicos por um administrador.
- Identificação de conteúdo privado futuro requer bloquear publicação/corrigir
  antes de disponibilizar; não foi encontrado dado contextual na resposta atual.
- Outros findings, defaults EXECUTE, Storage, app_metadata e biblioteca não foram
  tratados. O smoke antigo não foi corrigido.
- Somente quatro arquivos novos: esta documentação, a migration C1, sua suíte
  SQL e o runner de mutação. Nenhum arquivo histórico/rastreado modificado.

Sugestão de commit, APENAS após revisão independente:
`fix(security): restrict global patient counts to active platform admins`

Incluir somente os quatro arquivos deste lote; N20 entra apenas como documentação
de investigação, nunca como correção implementada.
