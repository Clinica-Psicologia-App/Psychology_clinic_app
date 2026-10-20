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
- Permanecem pendentes a execução do formulário Flutter em dispositivo,
  interrupção real de rede e isolamento autenticado entre clínicas/pacientes.
  O smoke REST aprovado não cobre esses cenários.
