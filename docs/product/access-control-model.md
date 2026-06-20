# Modelo de acessos

Atualizado em 2026-06-20.

O produto possui tres papeis ativos:

| Papel | Responsabilidade | Acesso clinico |
| --- | --- | --- |
| Administrador (`platform_admin`) | Clinicas, psicologos, status, limites, auditoria e acesso a questionarios | Nao acessa prontuarios ou pacientes |
| Psicologo (`psychologist`) | Seus pacientes, convites e modulos clinicos | Somente pacientes sob sua responsabilidade |
| Paciente (`patient`) | Sua jornada, respostas e materiais liberados | Somente o proprio cadastro |

## Regras operacionais

- Nao existe administrador por clinica.
- Somente administradores globais criam, inativam e excluem psicologos.
- Administradores definem limite de pacientes e instrumentos liberados por
  psicologo.
- Psicologos nao gerenciam outros usuarios.
- Psicologos convidam e acompanham apenas os proprios pacientes.
- Pacientes entram somente por convite.
- O valor `admin` permanece no enum do banco apenas para compatibilidade de
  migrations antigas; nenhum perfil ativo deve utilizar esse valor.

## Controles de seguranca

- RLS retorna zero pacientes para administradores globais.
- Alteracoes de papel, clinica, status e limites sao protegidas contra
  autoelevacao pelo proprio usuario.
- A conta de demonstracao administrativa fica inativa no ambiente hospedado.
- Alteracoes sensiveis continuam registradas em `audit_events`.

