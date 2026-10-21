# Homologação Android — recurso liberado da biblioteca

Data: 2026-10-21. Branch: `audit/astra`. Resultado: **aprovado no escopo abaixo**.

## Ambiente e preparação

APK debug da homologação do monitor, sem alteração posterior de código:
SHA-256 `1e95f63b925a36367eeb346829ccdb69d044804bd5d751f4ed5d1326bd619133`.
Não foi gerado novo build nesta etapa. Instância descartável Small_Phone,
captura 720 × 1280 px e viewport 360 × 640. Interação pelo Android SDK/ADB;
o CLI Maestri continuava indisponível.

Criados um paciente e login novos na clínica sintética previamente verificada.
Credenciais somente em arquivo local ignorado. Pela chave pública e JWT real
do psicólogo demo foram criados um recurso `exercise` e sua liberação para o
novo paciente. A criação/liberação usou o contrato REST normal, sem privilégios
administrativos. Antes da liberação, a leitura do paciente tinha zero acessos.
Após a liberação, a leitura autenticada retornou uma linha e o conteúdo esperado,
com `viewed_at` e `completed_at` nulos.

Recurso: `TESTE BIBLIOTECA 20261021`. Orientação textual totalmente sintética,
com marcador `TESTE_RECURSO_CONTEUDO`, sem URL. Não houve consulta ou alteração
de recursos clínicos preexistentes. O provisionamento da conta foi feito pela
Management API conforme os testes anteriores, sem alteração de schema/policies.

## Execução

O app entrou pelo formulário de login do paciente. Pela home → Biblioteca,
foi aberta a tela RECURSOS e o exercício esperado, sem deep link.

| Etapa | Evidência na interface | Conferência REST com JWT do paciente |
|---|---|---|
| Listar | Um exercício com título esperado e status Liberado | Um acesso ativo, recurso/conteúdo corretos, sem datas de progresso |
| Abrir | Detalhe Meu recurso, orientação completa e status Visualizado | `viewed_at` preenchido automaticamente e `completed_at` ainda nulo |
| Concluir | Toque em Marcar como concluído; status Concluído no detalhe e na lista | `completed_at` preenchido no mesmo acesso, uma única linha |
| Reiniciar | Processo encerrado/reaberto; sessão restaurada; home → Biblioteca → detalhe | Mesmo ID de acesso/recurso, uma linha e mesma data de conclusão |

A liberação não foi pré-marcada como visualizada/concluída: essas duas escritas
foram realizadas pelo próprio app. As sessões das leituras REST independentes
foram revogadas com escopo local, sem interromper a sessão do aplicativo.

Árvore de acessibilidade e capturas conferidas. Evidências locais no diretório
`post-test`: `library-released.png`, `library-viewed.png`,
`library-completed.png`, `library-reopened-list.png` e
`library-reopened-detail.png`. Nenhuma exceção Flutter ou overflow apareceu na
amostra final das últimas 350 linhas do processo; houve aviso HWUI sobre formato
do renderizador. Não equivale a monitoramento completo da sessão.

## Limpeza e limites

App encerrado e seus dados locais apagados apenas na instância descartável.
Recurso, acesso, paciente, perfil e usuário temporários removidos em transação
com validação de IDs, clínica, título/marcadores e contagem de um único acesso.
Consulta independente após o commit confirmou **zero recursos, acessos, pacientes,
perfis, usuários Auth, identidades e sessões** desse conjunto. Clínica e paciente
demo anterior preservados; arquivo de credenciais removido e emulador encerrado.

Os **seis testes existentes de domínio de recursos passaram**. A suíte completa
anterior de 495 aprovados não foi repetida, pois esta etapa não alterou código.

Escopo restrito a exercício textual, listagem, visualização, conclusão e
persistência após reiniciar. Não cobre UI de criação/liberação do psicólogo,
links externos, vídeos/PDFs, catálogo de filmes/séries, revogação, acesso entre
contas, falha de rede, concorrência, acessibilidade, iOS ou release. Não houve
alteração de aplicação, schema, policies ou grants.
`flutter analyze` executado antes do commit: exit 1, 144 ocorrências
(0 errors, 12 warnings e 132 infos), sem novas ocorrências ou supressões.
