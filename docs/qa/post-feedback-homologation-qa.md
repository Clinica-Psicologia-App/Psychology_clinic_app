# QA pós-feedback — homologação FH-01 a FH-04

**Data:** 2026-06-06  
**Escopo:** onboarding de profissional (`FH-01`), convite de paciente (`FH-02`), catálogo de questionários com acesso por profissional (`FH-03`) e estilos parentais multi-referência (`FH-04`).  
**Objetivo:** executar uma rodada de regressão funcional e técnica antes da próxima versão de homologação, **sem alterar banco, Edge Functions ou novas features**.

---

## 1. Automação executada nesta rodada

| Comando | Resultado | Observação |
|---------|-----------|------------|
| `cd mobile && flutter test` | **OK** (`156` testes) | Suíte cobre convites, onboarding, catálogo/acesso, fluxos de questionário e parsing de resultados |
| `cd mobile && flutter analyze` | **OK com apontamentos** (`47 issues`) | Sem erro bloqueante novo; baseline atual é majoritariamente `info`/`warning` de qualidade e APIs depreciadas |
| `supabase db reset` | **Pendente execução manual** | Necessário validar migrations `022`–`025` + seed em ambiente com Docker/Supabase local ativo |
| `supabase functions serve` | **Pendente execução manual** | Validar `create-professional-account`, convites e fluxo de questionários localmente |
| `deno check` das functions alteradas | **Não executado nesta máquina** | Rodar apenas se `deno` estiver disponível no ambiente |

### Comandos recomendados para reprodução

```bash
supabase start
supabase db reset
supabase functions serve

cd mobile
flutter test
flutter analyze
```

### Checagem opcional das Edge Functions

```bash
cd supabase/functions
deno check create-professional-account/index.ts
deno check create-patient-invitation/index.ts
deno check accept-patient-invitation/index.ts
deno check start-questionnaire/index.ts
deno check submit-questionnaire-answer/index.ts
deno check finish-questionnaire/index.ts
```

---

## 2. Checklist técnico

### 2.1 Backend local

- [ ] `supabase start` sobe sem erro
- [ ] `supabase db reset` aplica migrations `001`–`025` e `seed.sql`
- [ ] `supabase status` mostra API, DB e Inbucket ativos
- [ ] `supabase functions serve` inicia sem falha de import ou secret
- [ ] `create-professional-account` responde localmente
- [ ] `create-patient-invitation` responde localmente
- [ ] `accept-patient-invitation` responde localmente
- [ ] `start-questionnaire`, `submit-questionnaire-answer` e `finish-questionnaire` respondem localmente
- [ ] `deno check` das functions alteradas passa, se Deno estiver instalado

### 2.2 Mobile

- [x] `flutter test` passa
- [x] `flutter analyze` roda sem erro bloqueante novo
- [ ] `flutter run --dart-define-from-file=env.local.json` abre no dispositivo/emulador
- [ ] Navegação pública libera `/professional-sign-up` e `/accept-invitation`
- [ ] Navegação autenticada mantém redirects por papel

---

## 3. Checklist funcional por fluxo

### 3.1 Profissional

#### FH-01 — criar conta profissional solo

- [ ] Abrir `/professional-sign-up`
- [ ] Selecionar `Sou profissional autônomo`
- [ ] Preencher nome, e-mail, senha, confirmação, telefone e CRP
- [ ] Submeter com sucesso
- [ ] Confirmar mensagem `Conta criada com sucesso`
- [ ] Validar no banco que a clínica foi criada automaticamente como clínica pessoal
- [ ] Validar que o profile entrou com papel `admin` da própria clínica

#### Login

- [ ] Fazer login com a conta criada
- [ ] Confirmar home do staff abre sem redirecionamento incorreto
- [ ] Confirmar sessão persiste após reinício do app

#### FH-02 — convidar paciente

- [ ] Abrir tela/lista de convites
- [ ] Criar convite com e-mail válido
- [ ] Se logado como psicólogo, validar que o responsável é ele mesmo
- [ ] Se logado como admin, validar seleção de psicólogo responsável
- [ ] Copiar `invite_url`
- [ ] Confirmar convite aparece com status `pending`
- [ ] Confirmar nenhum token puro aparece persistido na interface posterior ao create

#### FH-03 — gerenciar acesso a questionários

- [ ] Abrir `/admin/questionnaire-access`
- [ ] Selecionar um profissional
- [ ] Ativar/desativar questionários por switch
- [ ] Confirmar persistência ao recarregar a tela
- [ ] Confirmar psychologist não acessa essa tela de gerenciamento
- [ ] Confirmar psychologist vê apenas os instrumentos liberados

### 3.2 Paciente

#### FH-02 — aceitar convite

- [ ] Abrir `/accept-invitation?token=...`
- [ ] Confirmar token válido abre formulário sem pedir login prévio
- [ ] Confirmar token inválido/expirado mostra erro genérico, sem detalhe técnico

#### Criar senha e completar cadastro

- [ ] Definir senha e confirmação válidas
- [ ] Preencher dados cadastrais obrigatórios
- [ ] Submeter com sucesso
- [ ] Confirmar redirecionamento para login
- [ ] Fazer login com a nova conta
- [ ] Confirmar patient/profile/patient record foram vinculados corretamente

#### Acessar trilha

- [ ] Home do paciente abre
- [ ] Trilha do paciente abre
- [ ] Questionários disponíveis respeitam o psicólogo responsável e os acessos liberados
- [ ] Módulos clínicos do paciente continuam acessíveis sem regressão

### 3.3 Questionários

#### YSQ

- [ ] Continua aparecendo quando liberado ao profissional
- [ ] Intro abre com `reference_period`
- [ ] Resposta e finalização continuam funcionando
- [ ] Resultado abre no staff

#### YAMI

- [ ] Continua aparecendo quando liberado ao profissional
- [ ] Intro abre com `reference_period`
- [ ] Resposta e finalização continuam funcionando
- [ ] Resultado abre no staff

#### FH-04 — `PARENTAL_STYLES_V1`

- [ ] Seleção inicial permite `Mãe`
- [ ] Seleção inicial permite `Pai`
- [ ] Seleção inicial permite `Outro`
- [ ] `Outro` exige texto preenchido
- [ ] Seleção múltipla funciona (`Mãe` + `Pai`, `Mãe` + `Outro`, etc.)
- [ ] Cada figura parental abre o mesmo conjunto de perguntas
- [ ] Progresso aparece separado por figura
- [ ] Título da sessão indica a figura atual (`Respondendo sobre: ...`)
- [ ] Botão de finalizar só habilita após todos os contextos concluídos
- [ ] Resultado no detalhe staff aparece separado por figura parental

### 3.4 Staff

- [ ] Lista de resultados abre
- [ ] Detalhe de resultado abre
- [ ] Dashboard clínico abre
- [ ] Mapa mental abre
- [ ] Geração de PDF continua funcionando
- [ ] Nenhum desses fluxos quebra com respostas de estilos parentais multi-contexto

---

## 4. Matriz de risco pós-FH

| Risco | Módulo afetado | Severidade | Como validar |
|------|-----------------|------------|--------------|
| Clínica pessoal criada sem vínculo correto de owner/admin | FH-01 onboarding profissional | Alta | Criar conta `solo`, inspecionar `clinics`, `profiles` e login inicial |
| Convite pendente duplicado por e-mail ou responsável incorreto | FH-02 convites | Alta | Criar dois convites para o mesmo e-mail na mesma clínica e validar bloqueio/regra |
| Token aceito mais de uma vez ou erro técnico exposto ao paciente | FH-02 aceite público | Alta | Aceitar um convite e tentar reutilizar o mesmo link |
| Admin gerencia acessos, mas psychologist continua vendo instrumentos revogados | FH-03 catálogo/acesso | Alta | Revogar acesso, relogar como psychologist e conferir catálogo |
| Patient vê questionário não liberado para o psicólogo responsável | FH-03 catálogo/acesso + trilha paciente | Alta | Trocar liberação do profissional e comparar catálogo do paciente vinculado |
| Fallback sem migration `022` quebrar a demo em ambiente desatualizado | FH-03 repository/UI | Média | Validar catálogo em ambiente sem `questionnaire_professional_access` aplicado, se houver staging legado |
| Seleção de múltiplas figuras parentais perder progresso entre contextos | FH-04 resposta de questionário | Alta | Responder parcialmente `Mãe`, avançar, voltar e conferir persistência |
| `PARENTAL_STYLES_V1` finalizar sem todos os contextos completos | FH-04 finish-questionnaire | Alta | Tentar finalizar com uma figura incompleta |
| Resultado separado por figura não abrir no staff | FH-04 resultados | Alta | Concluir `PARENTAL_STYLES_V1` com 2+ figuras e abrir detalhe |
| Dashboard/mapa mental não tolerarem snapshots novos ou ausência de dados | Staff leitura clínica | Média | Abrir dashboard e mapa mental após nova resposta parental e após paciente sem resposta |
| PDF sofrer regressão com snapshots novos | Clinical report | Média | Gerar PDF de paciente com respostas recentes de múltiplos instrumentos |
| Warnings do `flutter analyze` esconderem regressão real futura | Base mobile | Baixa | Manter comparação com baseline atual de `47 issues` até rodada de limpeza |

---

## 5. Critérios de aceite da rodada

- [x] Checklist técnico consolidado
- [x] Fluxos críticos documentados por papel
- [x] Riscos pós-FH mapeados com severidade e forma de validação
- [ ] `supabase db reset` executado no ambiente de homologação
- [ ] `supabase functions serve` validado com os fluxos públicos
- [ ] Roteiro manual concluído em dispositivo real ou emulador

---

## 6. Observações desta preparação

- `flutter test` passou nesta rodada com `156` testes.
- `flutter analyze` permanece em `47 issues`, sem erro bloqueante novo identificado.
- `deno check` continua dependente de um ambiente com Deno instalado.
- A próxima homologação deve priorizar os fluxos públicos novos (`/professional-sign-up` e `/accept-invitation`) e o caso mais sensível do `PARENTAL_STYLES_V1` com múltiplas figuras.
