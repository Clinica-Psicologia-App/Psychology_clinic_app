# Homologação Android — gravação e reabertura do monitor diário

Data: 2026-10-21. Branch: `audit/astra`. Resultado: **aprovado no escopo abaixo**.

## Ambiente e preparação

APK debug novo, gerado com `flutter build apk --debug
--dart-define-from-file=env.production.json`, sem alteração de código nesta etapa.
O build passou e manteve avisos de compatibilidade dos plugins com Kotlin.
SHA-256 do APK instalado:
`1e95f63b925a36367eeb346829ccdb69d044804bd5d751f4ed5d1326bd619133`.

Instância descartável do AVD Small_Phone, captura 720 × 1280 px, viewport
360 × 640. Interação pelo Android SDK/ADB, seguindo o mesmo procedimento da
[homologação dos atalhos](patient-home-android-smoke.md). Nenhum emulador
alheio à tarefa foi alterado.

Foi criado um paciente e login novos na clínica sintética previamente conferida,
com nome `Paciente TESTE HOME` e responsável demo existente. Provisionamento
pela Management API, sem alterar schema ou policies. Credenciais somente em
arquivo local ignorado. O aplicativo entrou pelo formulário real de login;
a leitura independente usou chave pública e JWT do próprio paciente.

## Execução e conferência

Uma leitura autenticada inicial confirmou **zero registros**. Pela home, foi
aberto Monitor diário → Novo registro e preenchidos:

| Entrada na interface | Valor sintético | Persistência esperada |
|---|---|---|
| Humor / estado emocional | `TESTE_MONITOR_HUMOR_20261021` | `mood_notes` |
| Intensidade | 7/10 | Primeira linha de `emotion_notes` |
| Gatilhos | `TESTE_MONITOR_GATILHOS` | Segunda linha de `emotion_notes` |
| Comportamentos | `TESTE_MONITOR_COMPORTAMENTOS` | `activity_notes` |
| Observações | `TESTE_MONITOR_OBSERVACOES` | `sleep_notes` |

Após um único toque em Salvar registro, o aplicativo retornou à lista com um
registro e intensidade 7. A leitura REST independente confirmou exatamente
uma linha, paciente/clínica esperados e igualdade dos cinco valores. O campo
combinado correspondeu exatamente a
`Intensidade: 7/10\nGatilhos: TESTE_MONITOR_GATILHOS`, com uma quebra de linha.

O processo do app foi encerrado e reaberto. A sessão foi restaurada sem novo
login; pela home e pelo card da lista, o detalhe exibiu humor, intensidade,
gatilhos, comportamentos e observações. Capturas foram inspecionadas e os
conteúdos conferidos também pela árvore de acessibilidade. Uma segunda leitura
REST confirmou **o mesmo ID, os mesmos valores e somente um registro**.
As sessões criadas pelas leituras independentes foram revogadas com escopo
local, preservando a sessão usada no app até a limpeza.

Evidências locais no diretório `post-test` desta tarefa:
`monitor-saved-list.png`, `monitor-reopened-top.png`,
`monitor-reopened-fields.png` e `monitor-reopened-observations.png`.
A amostra final das últimas 350 linhas do processo não mostrou exceções Flutter
ou overflow; houve aviso HWUI de formato de renderização Android. Não é
monitoramento completo da execução.

## Limpeza e limites

App encerrado e dados locais apagados somente na instância descartável.
Limpeza remota em transação exigiu o paciente/perfil exatos e um único monitor
com o ID e marcador sintéticos esperados. Foram removidos monitor, paciente,
perfil e usuário Auth. Consulta independente após o commit confirmou **zero
monitores, pacientes, perfis, usuários, identidades e sessões** desse conjunto.
A clínica e o paciente demo anterior permaneceram presentes. Arquivo de
credenciais removido e emulador temporário encerrado.

Esta evidência cobre criação pela interface, gravação remota, lista e detalhe
após reiniciar o processo. Não cobre edição, registros antigos, validações de
formulário vazio, falha de rede/retry, concorrência, acesso do psicólogo,
isolamento entre contas, texto ampliado, iOS ou build de release. Nenhum código,
schema, policy, grant ou dado clínico externo ao conjunto de teste foi alterado.
Os 495 testes aprovados da etapa anterior não foram repetidos nesta etapa
documental; o build e a homologação Android acima foram executados agora.
`flutter analyze` reexecutado antes do commit: exit 1, 144 ocorrências
(0 errors, 12 warnings e 132 infos), sem novas ocorrências ou supressões.
