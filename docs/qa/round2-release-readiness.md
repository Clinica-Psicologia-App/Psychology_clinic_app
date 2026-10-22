# Rodada 2 — revisão prévia e conferência Android

Data: 2026-10-21. Branch: `audit/astra`. HEAD: `6b1d340`.
[Evidência sanitizada](round2-preflight-2026-10-21.json).

**Registro histórico anterior à aplicação.** Em 2026-10-22 o responsável
autorizou a migration específica e os testes sintéticos. A aplicação e a
homologação foram concluídas; veja [resultado atualizado](round2-remote-smoke.md).

## Estado da migration remota

A URL usada no build foi comparada com o projeto vinculado ao CLI. A leitura
remota foi limitada a metadados de políticas, funções, índices, histórico e
publicação do módulo 9. Nenhum prontuário real foi consultado.

- `psychoeducation_exercise_responses.patient_id` referencia `profiles.id`.
- A policy staff implantada ainda usa
  `is_staff() AND user_can_access_patient(patient_id)`.
- `user_can_access_patient` recebe `patients.id` e exige responsável e clínica.
- `is_staff` restringe a psicólogo ativo; administrador permanece sem acesso.
- A policy de leitura de `patients` também exige `user_can_access_patient(id)`.
- RLS permanece habilitada. Existe índice em `patients.profile_id`.
- `20261021100000` não consta no histórico remoto; última versão: `20261001100000`.

A migration proposta continua sendo somente
[`20261021100000_exercise_responses_staff_profile_link.sql`](../../supabase/migrations/20261021100000_exercise_responses_staff_profile_link.sql),
do commit `96827d8`. Ela resolve o perfil para o cadastro antes de verificar
o vínculo existente. Não modifica as funções de acesso, a policy de escrita
própria preexistente, papéis, grants ou a configuração de RLS.

O arquivo e os metadados foram identificados por hash na evidência. A análise
não é medição de desempenho em produção nem nova execução dos testes SQL.
Os testes locais anteriores, incluindo a falha com a policy antiga, estão
registrados no [relatório de implementação](../round2-audit-astra.md).

**Na data deste registro (2026-10-21), a aplicação remota ainda não estava autorizada.** A autorização
anterior foi explicitamente “migration local e testes, sem aplicação remota”.
A pergunta para autorizar apenas este arquivo está pendente. O `AGENTS.md`
também exige revisão humana de mudanças em RLS. Não executar um push geral de
migrations: a autorização solicitada abrange somente a versão `20261021100000`.
Após autorização, revalidar os metadados, aplicar somente esse arquivo, registrar
a versão e conferir a policy antes de testar respostas com dados descartáveis.

## Conferência Android realizada

Foi gerado e instalado um APK debug novo da árvore de trabalho atual, usando
`--dart-define-from-file=env.production.json`. O build passou; houve aviso
preexistente de compatibilidade futura com Built-in Kotlin. Nenhuma dependência
foi alterada. O hash do APK está registrado na evidência.

Emulador `Small_Phone`, 720 × 1280 físicos, densidade 320, equivalente a
360 × 640. Iniciado com `-read-only -no-snapshot` para preservar o disco original.

1. Introdução, renderização do login e autenticação real pela conta demo
   sintética já existente aprovadas. Credenciais lidas do arquivo local ignorado.
2. A carteira tinha somente o paciente identificado como TESTE, confirmado antes
   da navegação. Esse cadastro não tem perfil/login de paciente vinculado.
3. Cadastro → Acompanhar → Exercícios e Tarefas abriu a nova tela
   “Exercícios respondidos”. Mensagem vazia correta e retorno ao cadastro aprovados.
4. O catálogo staff carregou 19 módulos em quatro etapas. O módulo de número 9,
   “Conhecendo os Modos Esquemáticos”, está publicado em Transformar; abertura
   e renderização da capa aprovadas.
5. Não foram encontrados marcadores de exceção de renderização, overflow ou
   exceção não tratada no log Flutter desta execução. Isso não substitui uma
   homologação completa de layout ou acessibilidade.
6. A sessão deste teste foi encerrada com `scope=local`; outros logins da conta
   demo foram preservados. O emulador temporário foi encerrado.

O estado vazio demonstra a rota e sua apresentação; **não comprova leitura de
respostas preenchidas**. A abertura do catálogo não comprova o clique no atalho
a partir de um mapa com núcleo clínico preenchido. Nenhuma resposta, resultado,
cadastro clínico ou conteúdo de biblioteca foi criado/alterado nesta continuação.
As operações de autenticação criaram e encerraram somente a sessão usada no teste.

## Pendências e limites

- Autorizar especificamente a aplicação remota da migration revisada.
- Depois, criar conjunto sintético descartável e verificar preenchimento pelo
  paciente, leitura pelo responsável e bloqueio para outro responsável/clínica.
- Conferir o atalho Modos → Transformar a partir de mapa preenchido.
- Homologar Diário e cartões YCI/YRAI no Android, incluindo liberação/revogação.
- Docker continua indisponível; nenhum banco local foi resetado nesta continuação.

A validação anterior da implementação permanece em 516 testes aprovados e
análise com 0 errors, 12 warnings e 132 infos. Não foram repetidas essas suítes
nesta etapa sem mudanças de código. O build e a conferência acima usam a árvore
atual com as alterações locais preexistentes; não representam checkout limpo.
Sem novos commits, push ou publicação nesta continuação.
