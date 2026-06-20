# Production readiness

> Atualizacao de 2026-06-19: o procedimento atual e os bloqueios de lancamento
> estao consolidados em [production-go-live-runbook.md](production-go-live-runbook.md).
> Os numeros abaixo representam a rodada de 2026-06-15 e foram preservados como
> historico.

Estado técnico validado em 2026-06-15.

## Automatizado e validado

- Flutter: 208 testes passando.
- Edge Functions: criação de paciente, início, respostas e finalização de
  questionário passando no fluxo integrado local.
- RLS: smoke test completo passando.
- Banco: `supabase db lint --local` sem erros.
- Builds: APK debug e web release compilando.
- Android: HTTP sem criptografia permitido apenas em debug/profile.
- Android release: exige keystore externo e nunca usa assinatura debug.
- Release Flutter: exige `SUPABASE_URL` e `SUPABASE_ANON_KEY` explícitos;
  a URL precisa usar HTTPS.
- CI: Flutter, Deno, banco e RLS configurados em `.github/workflows/quality.yml`.
- Recuperação de senha, documentos legais versionados e aceite persistido.
- Auditoria de alterações sensíveis sem replicar conteúdo clínico.
- Instrumentos não homologados bloqueados no backend hospedado.
- Busca de pacientes e identificadores mobile definitivos.

Detalhamento: [production-implementation-status.md](production-implementation-status.md).

## Obrigatório antes de produção

- Criar projeto Supabase de produção separado de desenvolvimento/homologação.
- Configurar redirects de autenticação no painel Supabase (Authentication → URL
  Configuration) adicionando `esquemacore://auth/update-password` à lista de
  Redirect URLs; sem isso o link de "Esqueceu senha" é bloqueado pelo Supabase.
- Configurar `PATIENT_INVITATION_BASE_URL=esquemacore://app` como secret das
  Edge Functions no painel Supabase; garante que o link de convite abra
  diretamente no app Android/iOS via deep link.
- Configurar SMTP transacional, templates e testes de entrega.
- Configurar CAPTCHA e revisar rate limits públicos.
- Criar e proteger keystore Android; configurar assinatura iOS.
- Confirmar disponibilidade do `applicationId`/bundle ID
  `br.com.esquemacore.app` nas lojas.
- Configurar backups, restauração testada, logs, alertas e monitoramento.
- Definir política LGPD: consentimento, retenção, exportação e exclusão.
- Executar pentest e revisão de acesso com usuários de clínicas distintas.
- Homologar instrumentos, regras de scoring, textos e relatórios com a equipe
  clínica responsável.
- Publicar política de privacidade, termos de uso e canal de suporte.

## Critério de liberação

Produção só deve ser liberada quando o workflow `Quality` estiver verde, os
itens externos acima tiverem evidência registrada e os fluxos críticos forem
testados no binário assinado contra o projeto Supabase de produção.
