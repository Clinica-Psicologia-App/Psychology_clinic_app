# Rodada 2 — migration e homologação remota

Data: 2026-10-22. Branch: `audit/astra`. Código: HEAD `6b1d340` mais alterações
locais preexistentes, preservadas. Resultado: **87 verificações HTTP aprovadas**,
com conferência Android dos novos fluxos.
[Evidência sanitizada por caso](round2-remote-2026-10-22.json).

## Aplicação autorizada

O responsável autorizou explicitamente somente a migration
`20261021100000_exercise_responses_staff_profile_link.sql` no Supabase vinculado
e testes com dados sintéticos. Não houve push ou aplicação de outras migrations.

Antes da aplicação foram conferidos novamente projeto vinculado versus URL do
ambiente, hash do arquivo revisado, RLS, policy antiga, histórico e funções de
acesso. O SQL autorizado e o registro de sua versão no histórico foram executados
na mesma transação, com limites de espera/execução e guardas contra divergência.
Uma consulta posterior confirmou a policy nova e a versão `20261021100000`.

A policy resolve `profiles.id` para `patients.id` antes de consultar a regra
canônica de acesso. A RLS continua habilitada; a policy de escrita própria e as
funções `is_staff`, `current_role`, `current_clinic_id` e
`user_can_access_patient` não foram alteradas. A alteração não concede acesso
clínico individual ao administrador da plataforma nem escrita staff nas
respostas dos pacientes.

## Conjunto descartável e testes HTTP

Foram criadas duas clínicas, três psicólogos (dois na mesma clínica), dois
pacientes com login, um administrador de plataforma e três cadastros de paciente
(um sem login). Tudo com IDs novos e nomes marcados TESTE. A conta demo anterior
foi preservada. Senhas aleatórias ficaram somente no arquivo local ignorado,
sem impressão. Testes usaram a chave pública e JWTs reais, sem `service_role`
ou simulação de papéis SQL como prova de acesso.

| Grupo | Verificações | Resultado |
|---|---:|---|
| Exercícios: autenticação, vínculo entre IDs, gravação, leitura, isolamento e integridade | 54 | Aprovado |
| YCI/YRAI: processamento, liberação/revogação, acesso e projeção sem notas privadas | 33 | Aprovado |
| **Total HTTP** | **87** | **Aprovado no escopo** |

**Exercícios:** paciente grava a própria resposta; responsável lê perguntas e
valores persistidos. Outro psicólogo da mesma clínica, profissional de outra
clínica, outro paciente, administrador e anônimo não leem a resposta alheia.
Tentativas de inserção, alteração e exclusão por essas contas foram bloqueadas;
inclusive o responsável não consegue escrever na resposta do paciente. Após
tentativas de alteração/exclusão, a leitura pelo paciente confirmou integridade.
O paciente atualizou a resposta mantendo o mesmo ID; o responsável leu os novos
valores. Consultas contendo os dois pacientes retornaram somente a linha própria
para cada responsável/paciente.

HTTP 200 com lista vazia foi considerado bloqueio por RLS, acompanhado das
verificações positivas e de integridade; não se inferiu acesso apenas pelo status.

**YCI/YRAI:** os dois instrumentos foram iniciados, respondidos e concluídos pelos
endpoints normais, com respostas sintéticas válidas. Antes da liberação, o
paciente não recebeu respostas/resultados. O responsável liberou, o paciente
recebeu os resultados e os demais atores continuaram sem acesso. Marcadores
privados sintéticos adicionados aos snapshots não apareceram na projeção do
paciente; a tabela bruta de resultados continuou oculta. Revogar removeu
respostas/resultados dessa projeção. Tentativas de liberação pelas demais
contas foram bloqueadas.

## Android

APK debug novo gerado com `--dart-define-from-file=env.production.json` e instalado
em `Small_Phone`, disco temporário `-read-only -no-snapshot`, 360 × 640 lógicos.
Nenhuma dependência ou código do aplicativo foi alterado nesta continuação.

1. Login do psicólogo sintético → cadastro do próprio paciente → Exercícios e
   Tarefas: título, data, perguntas, respostas atualizadas, dificuldade e pedido
   para conversar na sessão conferidos na tela real.
2. Mapa do mesmo paciente, com dados YCI/YRAI: na seção Modos (YAMI), o link
   “Ver Biblioteca Transformar” abriu “Conhecendo os Modos Esquemáticos”, módulo
   9. O conjunto não tinha aplicação YAMI; não se afirma homologação de seus
   gráficos nesta rodada.
3. Login do paciente → plano terapêutico → nó de apoio da Biblioteca → Praticar →
   Cartões de enfrentamento: cartões YCI e YRAI, origem e data conferidos.
4. “Registrar no Diário” abriu o formulário existente. Foi preenchido e salvo um
   registro sintético. Leitura REST autenticada confirmou **uma única linha**,
   com texto e clínica corretos. O atalho Diários em Praticar exibiu esse registro.
5. O responsável revogou os resultados pelo endpoint normal. Ao sair e reabrir
   os cartões, nenhum conteúdo de resultado apareceu. Liberar novamente e
   reabrir restaurou os cartões. Não há assinatura realtime de revogação.
6. Não foram encontrados marcadores de exceção de renderização, overflow ou
   exceção não tratada nos logs Flutter capturados. As telas preenchidas foram
   inspecionadas visualmente. Isso não equivale a QA completo de acessibilidade.

A leitura automática de elementos encontrou dificuldades nas animações do mapa;
a conferência desse trecho foi concluída por capturas de tela e gestos sobre os
controles observados. Falhas da automação não foram contabilizadas como falhas
do app nem substituídas por suposições de navegação.

## Limpeza e limites

Sessões dos scripts e do emulador foram encerradas com escopo local, preservando
outros logins. O emulador temporário foi encerrado. A limpeza remota exigiu IDs,
marcadores de nome/e-mail e contagens exatas antes de remover o conjunto criado.
Uma consulta independente após o commit da limpeza confirmou **zero** clínicas,
pacientes, perfis, usuários, identidades, sessões, exercícios, aplicações,
monitores e eventos de auditoria restantes desse conjunto. A demo anterior
continua presente, e a migration aplicada permanece no histórico. O arquivo de
credenciais descartáveis foi removido.

Os cartões são o MVP de modelos de reflexão somente leitura. Com os snapshots
sintéticos atuais, os temas foram **YCI Geral** e **YRAI Geral**, não perfis por
fator. Não houve criação de interpretação clínica, estratégia personalizada ou
armazenamento independente de cartões. Revisão do conteúdo com as terapeutas
continua sendo a próxima evolução de produto.

Não houve homologação iOS, web ou build release. O baseline anterior da suíte
Flutter permanece em 516 testes aprovados, 0 errors, 12 warnings e 132 infos;
não foi repetido nesta continuação sem alterações de código. O build debug e
os testes acima validam a árvore atual, sem afirmar validação de checkout limpo.
Relatórios desta continuação permanecem locais, sem novos commits ou publicação.
