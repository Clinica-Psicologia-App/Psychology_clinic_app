# Homologação remota do registro NEO PI-R

O script `scripts/validate-personality-remote.mjs` verifica persistência pelo
contrato REST do Supabase. Ele não executa o formulário Flutter nem substitui
a homologação visual em dispositivo.

## Preparação

Use uma conta de **psicólogo ativa** e um paciente **sintético**, vinculado à
conta e à mesma clínica. O nome deve identificar teste, demo, homologação ou E2E.
Não use dados reais de pacientes. O script não cria contas nem pacientes.

Preencha localmente `.env.personality-smoke.local.json`, na raiz do repositório:

```json
{
  "email": "",
  "password": "",
  "patientId": "",
  "expectedPatientName": ""
}
```

O arquivo já é ignorado pela regra `.env.*`; nunca o adicione à força ao Git.
Não envie a senha pelo chat nem a coloque em argumentos do terminal.
`expectedPatientName` deve ser o nome exato do paciente sintético cadastrado.

O destino padrão é `mobile/env.production.json`. Use apenas URL HTTPS e chave
anon/publicável. Chaves `service_role` são rejeitadas.

## Execução

Na raiz do repositório, com Node.js disponível:

```powershell
node scripts/validate-personality-remote.mjs
```

Para escolher explicitamente outros arquivos locais:

```powershell
node scripts/validate-personality-remote.mjs mobile/env.production.json .env.personality-smoke.local.json
```

## O que é verificado

1. Login, papel, conta ativa e clínica do profissional.
2. ID, nome exato e vínculo do paciente sintético antes de qualquer gravação.
3. Criação de uma avaliação não compartilhada, com UUID exclusivo do teste.
4. Cinco atualizações no mesmo registro, uma por domínio, com resultados
   sintéticos nos limites das classificações do pedido: 29, 44, 55, 65 e 66.
5. Releitura por nova requisição após cada atualização, conferindo os resultados
   cumulativos, ID, paciente, clínica e ausência de compartilhamento.
6. Ausência de leitura anônima do registro recém-criado.
7. Exclusão restrita a UUID, paciente e marcador deste teste, confirmação da
   remoção e encerramento somente da sessão criada pelo script.

O UUID é definido antes do INSERT, permitindo tentar a limpeza se a resposta
da criação se perder. O script não repete INSERTs nem altera avaliações existentes.
Havendo falha de limpeza, o resultado é `failed` e inclui `cleanupAssessmentId`,
que identifica exclusivamente o registro sintético para remoção manual.

O relatório não inclui senha, chave, JWT, nome ou ID do paciente, nem respostas
de erro brutas. `passed` exige todas as etapas, inclusive limpeza e logout.
Isso não comprova isolamento entre clínicas ou acesso do paciente à view;
esses cenários exigem contas adicionais e validação própria.

## Validação local do script

```powershell
node --check scripts/validate-personality-remote.mjs
node --test scripts/validate-personality-remote.test.mjs
```

Oito testes locais com HTTP simulado passaram: ciclo completo; bloqueio antes
da gravação por perfil/paciente incompatíveis; rejeição de credenciais ausentes
e chave privilegiada; falha de atualização; resposta do INSERT perdida;
vazamento anônimo; falha de limpeza; ocultação de mensagens externas.
Esses resultados não são evidência de execução autenticada em produção.

## Execução de 2026-10-20

- Saúde de autenticação do Supabase configurado em produção: **HTTP 200**,
  usando apenas chave pública.
- Uma tentativa com a conta demo de psicólogo documentada no seed/script:
  **HTTP 400 / `invalid_credentials`**.
- Nenhuma leitura de dados clínicos ou gravação foi feita nessa tentativa.
- Arquivo de credenciais criado inicialmente vazio e confirmado como ignorado pelo Git.
- A primeira execução do novo script sem credenciais parou antes da primeira requisição,
  com `TEST_CREDENTIALS_REQUIRED`.

Após autorização explícita para criar um novo usuário de teste:

- O Supabase CLI já estava autenticado e vinculado ao mesmo projeto configurado
  em `mobile/env.production.json`; a correspondência foi confirmada antes de gravar.
- Foi criado um psicólogo ativo, uma clínica pessoal isolada e um paciente
  sintético vinculado a esse profissional. O provisionamento seguiu o padrão de
  dados do seed confiável, em transação única pela Management API, com inspeção
  prévia dos campos e triggers. Nenhum schema, RLS ou conta existente foi alterado.
- A senha foi gerada aleatoriamente no banco e o retorno foi capturado diretamente
  no arquivo local ignorado, sem impressão de chave, senha ou JWT.
- **Homologação REST autenticada aprovada:** login 200; criação 201; cinco
  atualizações 200, cada uma seguida de releitura 200 com igualdade dos resultados
  cumulativos; leitura anônima retornou lista vazia (HTTP 200); exclusão 204 e
  confirmação de ausência 200; encerramento da sessão de teste 204.
- A avaliação temporária foi removida. O usuário, a clínica e o paciente
  sintéticos foram mantidos para próximas homologações, como solicitado.
- As credenciais e os identificadores do ambiente sintético estão somente em
  `.env.personality-smoke.local.json`, ignorado pelo Git. Não foram incluídos neste
  relatório nem nos scripts versionados.
- O smoke REST não cobre o formulário Flutter nem isolamento autenticado entre
  clínicas/pacientes. A execução Android posterior está descrita abaixo;
  isolamento autenticado continua pendente.

## Formulário Android — 2026-10-20

Build debug concluído com `flutter build apk --debug
--dart-define-from-file=env.production.json`. Execução no AVD Small_Phone em
instância descartável, 720 × 1280 físicos, densidade 320 (360 × 640 lógicos),
com login real do psicólogo sintético. O emulador que já estava aberto foi
preservado. Não houve alteração de código, dependências ou configuração do AVD.
As duas tentativas iniciais com o executável headless do emulador encerraram
com falha do processo no Windows. A execução concluída usou o emulador normal
com janela oculta, sem alterar o aplicativo para contornar esse problema.

Fluxo executado pela interface, com conferência independente via REST autenticado:

1. Criar metadados e salvar Neuroticismo 29 e faceta Ansiedade 30. A interface
   exibiu Muito Baixo e Baixo, respectivamente; banco com um único registro.
2. Encerrar o processo do aplicativo e abrir novamente. Sessão restaurada;
   avaliação parcial acessível e os dois valores recuperados ao editar.
3. Informar Extroversão 44, desligar rede do emulador (modo avião e Wi-Fi
   desativado) e salvar. Mensagem de ausência de internet, permanência na etapa
   2 de 5 e valor 44 preservado. Consulta pelo host confirmou que o banco ainda
   continha somente o domínio anterior, sem atualização parcial de Extroversão.
4. Restaurar rede e repetir o salvamento, sem redigitar. Avanço para etapa 3.
5. Salvar Abertura 55, Amabilidade 65 e Conscienciosidade 66. Classificações
   visíveis Médio, Alto e Muito Alto; cabeçalhos verde, lilás e azul.
6. Concluir pelo botão Salvar avaliação. Retorno ao perfil com confirmação.
   Releitura independente confirmou **um único registro não compartilhado**, com
   os cinco domínios cumulativos e a faceta preservada, sem duplicação.
7. Encerrar e abrir o aplicativo novamente; lista e perfil recarregados com os
   cinco escores/classificações. Excluir somente a avaliação deste teste pelo
   marcador e identificadores exatos; ausência confirmada (`cleanup: passed`).

Capturas locais preservam os estados de reabertura, erro de rede, etapas 3–5 e
perfil final. As telas inspecionadas não apresentaram overflow; a consulta dos
últimos logs do processo após o segundo reinício não encontrou erro Flutter de
layout (apenas aviso do renderizador Android). Isso não substitui teste visual
completo ou acessibilidade. A rede foi restaurada e o emulador descartável foi
encerrado; conta, clínica e paciente sintéticos continuam disponíveis.

Antes do commit desta evidência, `flutter analyze` foi reexecutado: exit 1,
as mesmas 144 ocorrências (0 errors, 12 warnings e 132 infos). Nenhuma regra
foi suprimida. A suíte completa não foi repetida nesta etapa sem alteração de
código; a última execução continua com 481 aprovados e 7 falhas documentadas.

Limites: APK debug, um tamanho de tela e um paciente sem login próprio. Não foram
validados build de release, iOS, aparelho físico, isolamento entre contas
autenticadas, visão do paciente ou perda da resposta do primeiro INSERT.
