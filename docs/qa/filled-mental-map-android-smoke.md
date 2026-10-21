# Homologação Android — mapa mental preenchido do paciente

Data: 2026-10-21. Branch: `audit/astra`. Resultado: **mapa aprovado no escopo
abaixo; pendência de contagem no módulo Metas registrada separadamente**.

## Preparação

APK debug já validado nas homologações anteriores, sem mudança de código desde
o build. SHA-256:
`1e95f63b925a36367eeb346829ccdb69d044804bd5d751f4ed5d1326bd619133`.
Small_Phone descartável, captura 720 × 1280 px e viewport 360 × 640; Android
SDK/ADB. Não foi gerado outro APK nem alterada a aplicação nesta etapa.

Um paciente/login novo foi provisionado na clínica sintética previamente
conferida, com responsável demo existente. Credenciais em arquivo local ignorado.
Os registros clínicos foram preparados pelo REST com chave pública e JWTs reais:
problemas/metas pelo psicólogo e check-in/monitor pelo paciente.

| Registros sintéticos | Valores relevantes |
|---|---|
| Problema ativo | `TESTE MAPA ATIVO`, intensidade 8 |
| Problema melhorado | `TESTE MAPA MELHOROU`, intensidade 3 |
| Problema resolvido | `TESTE MAPA RESOLVIDO`, intensidade 1, resolução preenchida |
| Meta ativa | `TESTE MAPA META ATIVA`, progresso 40 |
| Meta concluída | `TESTE MAPA META CONCLUIDA`, progresso 100, conclusão preenchida |
| Check-in | Humor 6, ansiedade 4, energia 8 |
| Monitor | `TESTE MAPA MONITOR` |

Antes da preparação, as quatro tabelas estavam vazias para esse novo paciente.
Uma tentativa de inserção em lote retornou 400/PGRST102 (`All object keys must
match`), pois os itens tinham campos opcionais diferentes. O auxiliar local
passou a inserir cada linha individualmente; não houve mudança no contrato,
nas policies ou no schema. A leitura autenticada do paciente confirmou os sete
registros, seus IDs e valores antes de iniciar a navegação.

## Execução e resultados

Login pelo formulário real e home → Mapa mental, sem deep link. Conferidos:

- Mesmo paciente/responsável e cabeçalho com uma meta ativa.
- Órbita com Problemas e Objetivos preenchidos; demais nós sem questionários
  permaneceram pendentes. Personalidade também permaneceu pendente.
- Núcleo/resumo: `2 problemas ativos · 1 objetivo ativo · Humor 6 · Ans. 4`.
- Detalhe Problemas com os dois itens em acompanhamento; resolvido excluído.
- Detalhe Objetivos somente com a meta ativa; concluída excluída.
- Abrir problemas e Abrir objetivos chegaram aos módulos do mesmo paciente;
  Voltar do Android retornou ao mapa na posição preservada.
- Resumo por módulo: somente a meta ativa, check-in com 6/4/8 e o monitor
  sintético com sua data esperada.

Após encerrar/reabrir o processo, a sessão foi restaurada sem novo login. Pela
home, o mapa recarregou os mesmos nós, contagens e resumo. Duas releituras
independentes com JWT do paciente compararam o snapshot integral das sete
linhas com a preparação: **mesmos IDs/valores, sem alteração pela navegação**.

A árvore de acessibilidade falhou ao ser lida no mapa. Os resultados nessa
tela foram conferidos visualmente por capturas, incluindo detalhes e destinos
dos atalhos. A amostra final das últimas 350 linhas do processo não mostrou
exceções Flutter/overflow; houve aviso HWUI do renderizador. Isso não equivale
a monitoramento completo ou validação de leitor de tela.

Evidências locais no diretório `post-test`: `map-filled-top.png`,
`map-filled-orbit.png`, `map-filled-problems-detail.png`,
`map-filled-problems-target.png`, `map-filled-goals-detail.png`,
`map-filled-goals-target.png`, `map-filled-module-goals.png`,
`map-filled-checkin.png` e `map-filled-reopened.png`.

## Achado no destino Metas

Ao abrir Objetivos pelo mapa, o módulo METAS mostrou `2 em andamento`, embora
uma das duas metas estivesse concluída. A inspeção atual de `_GoalsList`, em
`patient_therapy_goals_page.dart`, confirmou que `visible` exclui somente metas
arquivadas e que o chip usa `visible.length`. A contagem mistura ativas e
concluídas sob o rótulo em andamento. O mapa e a home contaram corretamente
uma meta ativa. Nenhuma meta teve seu status alterado.

O achado foi registrado em `TECH_DEBT.md`; não foi corrigido nesta homologação
de uma funcionalidade por vez. A lista é compartilhada no código, mas a execução
real aqui foi somente como paciente.

## Limpeza e limites

App encerrado e dados locais apagados somente na instância temporária. Limpeza
em transação validou paciente/perfil/clínica e os sete IDs/marcadores, exigindo
contagens exatas 3/2/1/1. Consulta independente após o commit confirmou zero
problemas, metas, check-ins, monitores, pacientes, perfis, usuários Auth,
identidades e sessões desse conjunto. Clínica e paciente demo anteriores
preservados. Credenciais e snapshot locais removidos; emulador encerrado.

Os **50 testes existentes de domínio, widgets e fluxo do mapa passaram**.
A suíte completa anterior de 495 aprovados não foi repetida, pois esta etapa
alterou somente documentação e executou a homologação descrita acima.

O escopo não inclui preencher instrumentos, NEO, genograma ou linha da vida,
alterações clínicas pela UI, atualização dinâmica sem reabrir, exportação,
IA/sugestões, papéis adicionais, rede instável, texto ampliado, tablet, iOS ou
release. Não substitui as homologações específicas anteriores nem valida todo
o mapa ou todo o sistema. Nenhum código, schema, policy ou grant foi alterado.
`flutter analyze` executado antes do commit: exit 1, 144 ocorrências
(0 errors, 12 warnings e 132 infos), sem novas ocorrências ou supressões.
