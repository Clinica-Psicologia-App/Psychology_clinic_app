# Runbook de entrada em producao

> Modelo de acesso vigente: consulte
> [product/access-control-model.md](product/access-control-model.md). Existem
> apenas administrador global, psicologo e paciente.

Atualizado em 2026-06-19.

Este documento separa o que pode ser comprovado pelo repositorio do que depende
de configuracao, contrato ou validacao externa. Nenhum ambiente deve ser
declarado pronto para uso clinico enquanto os bloqueios abaixo estiverem abertos.

## Estado tecnico comprovado

- As 36 migracoes locais e remotas estao sincronizadas.
- Os testes de RLS e de governanca passam usando fixtures transacionais.
- As 13 Edge Functions do repositorio foram publicadas no projeto Supabase.
- O fluxo de revisao clinica de respostas esta habilitado no aplicativo.
- O pipeline Android gera AAB assinado com simbolos nativos de depuracao.
- O build web release, os testes Flutter e o analisador fazem parte do gate de CI.
- Segredos de assinatura e o arquivo de ambiente de producao nao entram no Git.

O AAB gerado durante a validacao usa uma chave publica ficticia e serve apenas
para comprovar o pipeline. Ele nao deve ser enviado para a Play Store.

## Configuracao obrigatoria

1. Copie `mobile/env.production.example.json` para
   `mobile/env.production.json`.
2. Preencha `SUPABASE_URL` e `SUPABASE_ANON_KEY` com os valores publicos do
   projeto hospedado. Nunca use a chave `service_role` no aplicativo.
3. Configure o endereco HTTPS que recebe convites de pacientes:

   ```powershell
   supabase secrets set PATIENT_INVITATION_BASE_URL=https://app.exemplo.com
   ```

4. No Supabase Auth, configure o dominio principal, redirects autorizados,
   templates e SMTP transacional. Teste cadastro, convite, recuperacao de senha
   e troca de e-mail em aparelhos reais.
5. Ative CAPTCHA, limites de requisicao e MFA para administradores.
6. Guarde `mobile/android/keystore/esquemacore-upload.jks` e suas senhas em um
   cofre corporativo com copia de seguranca. A perda dessa chave pode impedir
   atualizacoes futuras do aplicativo.

## Geracao do Android

Depois de preencher o ambiente real:

```powershell
cd mobile
.\scripts\build-android-release.ps1
```

O artefato sera criado em
`mobile/build/app/outputs/bundle/release/app-release.aab`. Antes do envio,
confirme o Play App Signing, execute o teste interno da Play Store e valide
login, convites, pacientes, questionarios, resultados, mapa mental e recursos
terapeuticos em Android fisico.

## Bloqueios externos para lancamento

| Area | Evidencia exigida | Responsavel |
| --- | --- | --- |
| Juridico e LGPD | Termos, Privacidade, controlador, encarregado, retencao, exportacao e exclusao aprovados | Juridico/DPO |
| Instrumentos clinicos | Licenca, parecer tecnico e registro de homologacao de cada questionario | Responsavel clinico |
| E-mail | SMTP autenticado, reputacao de dominio e testes de entrega | Operacoes |
| Continuidade | Backup/PITR contratado e restauracao ensaiada | Infraestrutura |
| Monitoramento | Erros, disponibilidade e alertas com escala de atendimento | Engenharia |
| Seguranca | Pentest e teste de isolamento entre clinicas no ambiente hospedado | Seguranca |
| Lojas | Contas, politicas, classificacao etaria e testes internos aprovados | Produto |

Os sete questionarios permanecem em `clinical_status = 'validation'`. Nao altere
para `approved` sem as evidencias clinicas correspondentes e nunca habilite
`ALLOW_UNVALIDATED_INSTRUMENTS` em producao.

## Gate de liberacao

Uma versao somente pode ser promovida quando:

- `flutter analyze --no-fatal-infos` nao apresenta erros nem avisos;
- `flutter test` passa integralmente;
- os testes SQL de RLS e governanca passam;
- web release e Android AAB compilam com o ambiente real;
- todos os itens da tabela acima possuem responsavel, data e evidencia;
- o smoke test de producao foi executado sem dados clinicos reais.
