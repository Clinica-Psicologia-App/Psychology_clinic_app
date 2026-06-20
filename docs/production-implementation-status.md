# Estado de implementação para produção

Revisão técnica: 2026-06-15.

## Implementado no repositório

- Recuperação e redefinição de senha por Supabase Auth.
- Deep link `esquemacore://auth/update-password` para Android e iOS.
- Termos de Uso e Política de Privacidade versionados no aplicativo.
- Cadastro profissional restrito a administradores e primeiro acesso do
  paciente realizado por convite.
- Persistência do aceite em `legal_consents`.
- Auditoria de alterações sensíveis em `audit_events`, sem copiar conteúdo
  clínico para o log.
- Status de governança dos instrumentos em `questionnaires.clinical_status`.
- Bloqueio de instrumentos não homologados em builds de produção e nas Edge
  Functions hospedadas.
- Busca de pacientes por nome, e-mail ou psicólogo responsável.
- Identificadores definitivos `br.com.esquemacore.app`.
- Versão inicial de produção `1.0.0+1`.
- RLS, lint do banco, testes Flutter e fluxo integrado de Edge Functions.

## Bloqueado por evidência externa

Estes itens não podem ser declarados concluídos apenas com alteração de código:

- Parecer jurídico e texto definitivo de Termos/Privacidade.
- Definição formal de retenção, descarte, portabilidade e atendimento ao titular.
- Licença e homologação clínica dos instrumentos.
- Projeto Supabase de produção, domínio HTTPS e redirects autorizados.
- SMTP transacional e validação de entrega.
- CAPTCHA, MFA e políticas comerciais de rate limit do projeto hospedado.
- Keystore Android, certificados Apple e contas das lojas.
- Backup, restauração testada, observabilidade e alertas do ambiente contratado.
- Pentest independente e teste cruzado entre clínicas no ambiente de produção.

## Regra de liberação

Um instrumento somente deve receber `clinical_status = 'approved'` após registro
da licença, responsável clínico, data de aprovação e evidências do checklist de
homologação. Não use `ALLOW_UNVALIDATED_INSTRUMENTS=true` em produção.

O lançamento comercial depende de todos os itens externos acima possuírem
responsável, data e evidência anexada.
