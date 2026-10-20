# Homologação do Panorama — YSQ/YAMI

Data: 2026-10-20. Branch: `audit/astra`.

## Escopo e preparação

Antes de editar, foram conferidos o status do Git, as implementações anteriores,
os testes e os relatórios pós-teste. As 61 alterações rastreadas preexistentes e
os seis caminhos não rastreados foram preservados. Não houve reimplementação dos
rankings ou da ocultação do bloco duplicado.

Usados o psicólogo, a clínica isolada e o paciente sintéticos da homologação
anterior. O paciente não tem login próprio e estava sem respostas de
questionários antes do teste. Credenciais e IDs ficaram em arquivos locais
ignorados, sem inclusão neste documento ou no código versionado.

Foram geradas duas aplicações pelos endpoints normais `start-questionnaire`,
`submit-questionnaire-answer` e `finish-questionnaire`, autenticados como o
psicólogo de teste com chave pública. Todas as perguntas foram respondidas com
valores sintéticos válidos. Não foram fabricados snapshots por SQL:

- YSQ `v2-oficial`: 90 respostas, 18 esquemas, escala 1–6.
- YAMI `v1-foundation`: 186 respostas, 10 modos, escala 1–6.

O processamento remoto foi confrontado com as somas e médias esperadas a partir
das respostas sintéticas, inclusive regras de inversão. O auxiliar local teve
uma falha inicial de leitura do nome do campo de resultados da RPC; a leitura
foi corrigida e retomada usando a resposta YSQ já concluída, sem duplicá-la.
Isso foi uma falha do auxiliar de homologação, não do aplicativo.

## Resultado observado no Android

APK debug com `env.production.json`; AVD Small_Phone descartável, 360 × 640
lógicos. Login real e abertura do Panorama pela rota normal autenticada.

| Rank | Top YSQ | Média | Pontos secundários |
|---|---|---:|---:|
| 1 | Abandono/Instabilidade | 6,0 | 30 |
| 2 | Desconfiança/Abuso | 5,4 | 27 |
| 3 | Privação emocional | 4,8 | 24 |
| 4 | Defectividade/Vergonha | 4,2 | 21 |
| 5 | Isolamento social/Alienação | 3,6 | 18 |

| Rank | Top YAMI | Média na tela | Pontos secundários |
|---|---|---:|---:|
| 1 | Criança Impulsiva | 6,0 | 60 |
| 2 | Criança Zangada | 5,4 | 65 |
| 3 | Supercontrolador | 4,8 | 58 |
| 4 | Vencido Submisso | 4,2 | 63 |
| 5 | Criança Satisfeita | 3,6 | 58 |

Conferências aprovadas:

- Exatamente cinco linhas por ranking, com nomes legíveis e sem códigos técnicos.
- Média como valor principal e pontos brutos em texto secundário. A interface
  usa uma casa decimal; o snapshot conserva mais precisão.
- A ordem YAMI difere da soma bruta: 60 pontos/média 6,0 vêm antes de
  65 pontos/média 5,4167. O sexto modo não entra no Top 5.
- YAMI somente nas prioridades; nenhum bloco de modos no consolidado ou nos
  detalhes expandidos. A entrada YAMI no histórico permanece como acesso à resposta.
- Consolidado YSQ com quatro esquemas ativados automaticamente em lilás e demais
  barras cinza, incluindo Isolamento social com média 3,6. Domínios continuam na
  ordem clínica. Não foram feitas ativações manuais.
- Detalhes técnicos YSQ preservados: o painel expandido ainda mostra códigos,
  pontos e oito resultados. O limite de cinco e a média principal se referem
  aos cartões de prioridades do Panorama.

Capturas locais registram começo/fim dos dois rankings, barras do consolidado,
orientação e detalhes expandidos. Não houve overflow visual nas áreas
inspecionadas. A amostra dos logs do aplicativo só apresentou aviso do
renderizador Android, sem erro Flutter de layout.

## Ajuste encontrado

A orientação do consolidado ainda dizia “em vermelho”, embora as barras já
fossem lilás. Foram corrigidos somente essa expressão, a cor do marcador da
orientação e a cor padrão do símbolo da legenda do paciente, reutilizando
`AppColors.purple`. Nenhum cálculo, navegação, schema ou permissão foi alterado.
A correção foi reconstruída em APK debug, instalada preservando a sessão de
teste e conferida no Android: texto “em lilás” e marcador lilás visíveis.
A legenda da visão do paciente foi verificada no código e pela suíte existente;
não foi aberta uma sessão de paciente nesta homologação.

## Testes e limites

- Antes da correção visual: **31 testes direcionados aprovados** nos arquivos
  `clinical_dashboard_domain_test.dart`, `consolidated_schema_card_test.dart`
  e `question_scale_labels_test.dart`.
- Após a correção: **481 testes aprovados e as mesmas 7 falhas** da suíte
  completa, descritas no relatório pós-teste. Sem nova falha.
- `flutter analyze`: **exit 1, 144 ocorrências: 0 errors, 12 warnings e
  132 infos**, sem supressão de regras e sem aumento em relação à passagem anterior.
- Build APK debug atualizado concluído. O Gradle manteve os avisos de
  compatibilidade futura do Kotlin Gradle Plugin; nenhuma versão foi alterada.
- As legendas completas das escalas 1–6 foram revalidadas por testes de widget
  em tela estreita; não houve preenchimento manual dos 276 itens no Android.

## Limpeza

As duas aplicações foram removidas após a inspeção. Como a exclusão de respostas
não é exposta ao psicólogo, a limpeza usou a Management API já autenticada,
em transação limitada aos dois IDs registrados localmente, paciente e clínica
sintéticos. A transação exigiu exatamente duas remoções e não alterou políticas.
Respostas individuais e resultados vinculados foram removidos por cascade.
Nova consulta pelas RPCs normais do psicólogo confirmou lista vazia e ausência
dos dois detalhes (`cleanup: passed`). Conta, clínica e paciente foram mantidos.
O aplicativo de teste foi encerrado e apenas o emulador descartável foi fechado.

Um toque para expandir detalhes foi inicialmente recusado pela revisão automática
por possível ativação de esquema. Uma nova leitura confirmou que o ponto estava
dentro do controle de expansão, abaixo das linhas de esquemas, e a ação de
leitura foi aprovada. A conferência remota confirmou zero ativações manuais.

Esta evidência cobre a visão do psicólogo no Panorama com dados sintéticos
processados remotamente. Não valida o conteúdo clínico do motor, a visão do
paciente, isolamento entre clínicas, release, iOS ou aparelhos físicos.
