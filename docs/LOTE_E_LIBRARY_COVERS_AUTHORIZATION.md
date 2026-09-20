# Lote E — profiles como autoridade de library-covers

Data: 2026-09-15. Implementação e testes somente no Supabase local.
Branch inicial `audit/astra`, HEAD `2af9b035adc4bce2818bbed0e37fb7741374d824`.
Working tree inicialmente limpo e HEAD remoto confirmado por `git ls-remote`.
Sem commit, push, merge, rebase ou alteração/acesso à staging e produção.

## Causa raiz e decisão arquitetural A

A última definição anterior, `20260810120000_fix_library_cover_admin_metadata.sql`,
usava `COALESCE(current_role() IN ('platform_admin','admin'),
auth.jwt()->'app_metadata'->>'role' IN ('platform_admin','admin'), false)`.
Profile ausente/inativo fazia current_role() retornar NULL e ativava o fallback.
JWTs antigos continuavam permitindo INSERT; refresh e novo login renovavam
esse acesso enquanto o Auth mantivesse app_metadata administrativo. Rebaixar
para paciente ativo negava, mas inativá-lo depois reabria o fallback.

O claim não é livremente forjável pelo usuário comum: a prova usa JWTs reais
emitidos pelo Auth Admin API para identidades descartáveis. O patch não tenta
sincronizar metadados nem limpa claims de usuários reais.

Outra falha era funcional: não havia SELECT administrativo para esse bucket.
Mesmo admin ativo falhava em UPDATE/upsert; DELETE retornava 200 sem remover.
Adicionar SELECT mantendo o fallback ampliaria o impacto. Ambos foram tratados
atomicamente na migration `20260915120000_harden_library_cover_authorization.sql`.

## Helper final

`public.is_library_cover_admin()` preserva assinatura, boolean, owner postgres,
SQL, STABLE e SECURITY DEFINER. Search_path passa a pg_catalog.

Retorna true somente com contexto PostgreSQL authenticated, auth.uid() presente
e registro em public.profiles com `is_active IS TRUE` e papel exatamente
platform_admin. Qualquer outro estado válido retorna false. O estado PostgreSQL
do caller não é obtido de um claim JSON de papel. Não usa current_role(),
auth.jwt(), app_metadata, user_metadata, current_user ou session_user.
Não filtra clínica nem ownership. Não há SQL dinâmico.

SECURITY DEFINER foi mantido para a consulta por PK ao profile ser consistente
nas policies de Storage, sem depender das policies de leitura do profile nem
conceder novas permissões de leitura na tabela. A função só expõe um boolean;
identidade/relações qualificadas e search_path seguro limitam a resolução.
STABLE é apropriado à leitura do profile no snapshot da instrução. A revogação
vale nas requisições seguintes ao commit, sem esperar refresh do token.

ACL preservada: postgres, authenticated e service_role têm EXECUTE; PUBLIC/anon
não têm. O helper retorna false no contexto direto de serviço, mas service_role
mantém seu bypass administrativo de RLS e não depende do helper para operar.
Defaults globais não foram alterados.

## Policies efetivas antes/depois

Todas as expressões abaixo usam `bucket_id = 'library-covers' AND
public.is_library_cover_admin()` e aplicam-se a authenticated:

| Policy | Antes | Depois | Expressão |
|---|---|---|---|
| library_covers_admin_select | Ausente | Adicionada | USING |
| library_covers_admin_insert | Presente | Preservada | WITH CHECK |
| library_covers_admin_update | Presente | Preservada | USING e WITH CHECK |
| library_covers_admin_delete | Presente | Preservada | USING |

A migration não reescreve as três policies já corretas. O novo helper muda sua
autoridade e a nova SELECT habilita as operações sobre objetos existentes.
O bucket permanece público; URLs públicas não mudam. Download público de bytes
não equivale a SELECT/listagem de metadados. Outros buckets/policies não mudaram.

## Consumidores preservados

- AdminLibraryRepository.uploadCover: upload com upsert em `$baseName.$ext`.
- AdminPsychoeducationRepository.uploadCover: prefixo `psychoeducation/`.
- Telas usam cover_url pública.
- `scripts/upload_library_covers.sh`: service_role e upload com sobrescrita.

Nenhum frontend, Edge Function, fluxo Auth ou script de publicação foi alterado.
Service_role continua com SELECT/upload/UPDATE/upsert/DELETE reais funcionando.

## Matriz e efeitos verificados

| Cenário em library-covers | SELECT metadata | INSERT | UPDATE/upsert | DELETE efetivo |
|---|---|---|---|---|
| anon | Vazio | Nega | Nega | Não remove |
| authenticated sem profile/sem claim | Vazio | Nega | Nega | Não remove |
| sem profile com claim administrativo | Vazio | Nega | Nega | Não remove |
| patient ativo (inclusive com claim) | Vazio | Nega | Nega | Não remove |
| psychologist ativo | Vazio | Nega | Nega | Não remove |
| admin ativo sem claim | Permite | Permite | Permite | Remove |
| admin ativo com claim | Permite | Permite | Permite | Remove |
| admin inativo com JWT antigo | Vazio | Nega | Nega | Não remove |
| admin inativo após refresh/novo login | Vazio | Nega | Nega | Não remove |
| profile removido com JWT antigo | Vazio | Nega | Nega | Não remove |
| removido após refresh/novo login | Vazio | Nega | Nega | Não remove |
| rebaixado para patient ativo | Vazio | Nega | Nega | Não remove |
| rebaixado e depois inativado | Vazio | Nega | Nega | Não remove |
| admin reativado com token sem claim | Permite | Permite | Permite | Remove |
| service_role | Permite | Permite | Permite | Remove |

Download pela URL pública continua retornando os bytes esperados em todos os
cenários. DELETE negado pode continuar respondendo HTTP 200 com resultado vazio:
o teste exige que o objeto e seus bytes permaneçam intactos.
Legacy admin, role NULL, UID ausente e anon com UID administrativo também são
negados nos testes SQL. Outros roles fora da lista positiva não ganham acesso.

## Suítes específicas

`lote-e-library-covers-tests.sql`: **72 checks**, transação revertida, incluindo
16 cenários com INSERT real em storage.objects, retorno do helper, SELECT e
UPDATE com contagem de linhas. Fixtures de admins em duas clínicas comprovam
administração global. Testa grants, configuração, bucket público e quatro policies.
Role NULL é construído apenas em savepoint que relaxa NOT NULL e reverte.
Testa também INSERT/UPDATE indevidos em avatar alheio e tentativa de mover objeto
de library-covers para avatars, bloqueada pelo WITH CHECK.

Não se desativa `storage.protect_delete`: DELETE e arquivos físicos são testados
pela API Storage, não por remoção SQL direta de metadados. Todas as fixtures SQL
somem no rollback.

`lote-e-library-covers-http.ps1`: **198 checks**, Auth/Storage locais reais:

- Em cada cenário: URL pública, listagem, INSERT e existência, UPDATE e bytes,
  upsert e bytes, DELETE e existência; negações verificam bytes originais intactos.
- Os objetos existentes são criados por serviço: admin legítimo consegue
  administrá-los sem exigência de ownership.
- Emite claim administrativo por Auth Admin API somente para fixtures.
- Confirma claim ainda administrativo após refresh em profile inativo/removido;
  mesmo assim nenhuma operação administrativa é permitida.
- Recria/reativa profile admin; limpa claim apenas da fixture e confirma acesso
  com token sem papel administrativo. Nenhuma sincronização de produção é criada.
- Avatar de caminho alheio preserva leitura pública já existente, mas nenhuma
  escrita nova é permitida ao administrador de capas.
- Finally limpa seis identidades e objetos dos dois buckets, verificando que
  não há objetos restantes. Consulta final ao banco confirmou zero fixtures E.

## Mutação

`lote-e-library-covers-mutation.ps1` restaura em memória somente o corpo histórico
do helper dentro da transação, mantendo a nova SELECT. A suíte falha com:
`FAIL: inactive claim INSERT denied` (exit 3), porque o INSERT indevido volta a
passar. Não é falha de sintaxe/FK/fixture. A conexão reverte tudo ao terminar.
Fingerprint cobre definição, owner, ACL e todas as policies de storage.objects;
depois da mutação coincide com o estado protegido e a suíte passa novamente.
DELETE histórico não é simulado desativando guard do Storage.

## Validações executadas

| Validação | Resultado |
|---|---|
| Migration no banco existente | PASS |
| Reset completo, migrations + seed | PASS |
| SQL E / mutação | 72 PASS, bypass detectado, fingerprint restaurado |
| Storage HTTP E | 198 PASS, antes e depois do reset |
| Lote D | 31 PASS |
| Lote C | 27 PASS |
| Lote B | 438 PASS |
| Lote A | 378 PASS |
| F01/F02 | PASS |
| F03 SQL / HTTP | 46 / 30 PASS |
| Lifecycle / governance | PASS |
| SQL lint local | Sem erros |
| Flutter analyze --no-fatal-infos | Exit 0, 99 infos, sem warnings/errors |
| Flutter test | 447 PASS |
| Smoke RLS antigo | Apenas fixture conhecida sem questionnaire_version_id |
| Deno CLI | Indisponível; nenhum código Edge alterado |

O runtime de Edge Functions foi iniciado localmente para repetir F03 HTTP.
Os scripts PowerShell exigem versão 7 e recusam API fora de localhost.
Mutation/SQL usam explicitamente o container local do projeto.

## Riscos residuais e revisão

Validação somente local. Configurações remotas e integrações externas não foram
auditadas nem modificadas. Clientes antigos que dependam exclusivamente de claim
ou role legado serão negados intencionalmente. Não há revogação retroativa de
instruções já em execução; o guard consulta o estado atual por requisição.
Os grants inerentes de serviço/owner continuam administrativos e devem permanecer
fora do cliente. O bucket público continua publicando seus bytes por contrato.

Cinco arquivos novos: migration, SQL, runner de mutação, HTTP e esta documentação.
Nenhuma migration histórica, policy de outro bucket, frontend, app_metadata de
usuário real, default privilege ou outro finding foi alterado.

Sugestão de commit, somente após revisão independente:
`fix(security): authorize library cover administration from active profiles`
