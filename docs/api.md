# API — Edge Functions (MVP)

> Regra vigente desde 2026-06-20: não existe autocadastro público de
> profissionais. A função `create-professional-account` foi removida. Contas
> profissionais são criadas por administradores autorizados.

Base URL local: `http://127.0.0.1:54321/functions/v1`  
Base URL remota: `https://<PROJECT_REF>.supabase.co/functions/v1`

## Autenticação

Por padrão, as Edge Functions exigem JWT do Supabase Auth:

```http
Authorization: Bearer <access_token>
apikey: <SUPABASE_ANON_KEY>
Content-Type: application/json
```

Exceções públicas atuais:

- `POST /accept-patient-invitation`

Obter token (local):

```http
POST http://127.0.0.1:54321/auth/v1/token?grant_type=password
apikey: <anon_key>
Content-Type: application/json

{
  "email": "paciente.login@clinicateste-mvp.example",
  "password": "TesteMVP2025!"
}
```

## Formato de resposta

**Sucesso**

```json
{
  "ok": true,
  "data": { }
}
```

**Erro**

```json
{
  "ok": false,
  "error": {
    "code": "FORBIDDEN",
    "message": "Human readable message",
    "details": { }
  }
}
```

| HTTP | code típico |
|------|-------------|
| 400 | `VALIDATION_ERROR`, `INVALID_STATE` |
| 401 | `UNAUTHORIZED` |
| 403 | `FORBIDDEN` |
| 404 | `NOT_FOUND` |
| 409 | `CONFLICT` |
| 500 | `INTERNAL_ERROR` |

### Cliente Flutter

O app usa `EdgeApiClient` + `error_mapper.dart` (`mapEdgeErrorPayload`). Códigos `UNAUTHORIZED` viram mensagem de sessão expirada; `FORBIDDEN` / RLS alinhados ao HTTP 403. Ver `docs/mobile-app.md` (Tratamento de erros).

## Catálogo de questionários e acesso por profissional

O FH-03 não adiciona Edge Functions novas. O catálogo e a liberação por profissional usam PostgREST com RLS sobre:

- `questionnaires`
- `questionnaire_versions`
- `questionnaire_professional_access`

No Flutter, o repositório de questionários mantém fallback compatível para ambientes sem a migration `022_questionnaire_catalog_access.sql`, evitando quebrar a demo.

---

## 1. `POST /create-patient`

Cria usuário Auth + profile (`patient`) + registro em `patients`.

**Status do fluxo:** legado, mantido por compatibilidade enquanto o onboarding por convite é adotado gradualmente.

**Permissão:** `admin`, `psychologist`  
**RLS:** validações com JWT do caller (clínica, e-mail, psicólogo); criação Auth + insert em `patients` via service role **após** checagens (mesmo padrão de `finish-questionnaire`).

### Body

```json
{
  "email": "novo.paciente@clinicateste-mvp.example",
  "password": "SenhaSegura1!",
  "full_name": "Novo Paciente Teste",
  "phone": "+5511999990099",
  "responsible_psychologist_id": "11111111-1111-1111-1111-111111111103",
  "cpf": "00000000999",
  "birth_date": "1995-01-01",
  "gender": "nao_informado",
  "email_patient": "contato.paciente@clinicateste-mvp.example",
  "phone_patient": "+5511999990088"
}
```

| Campo | Obrigatório | Regras |
|-------|-------------|--------|
| `email` | sim | Login Auth; único na clínica |
| `password` | sim | mín. 8 caracteres |
| `full_name` | sim | |
| `responsible_psychologist_id` | sim | psychologist da mesma clínica; psych só pode ser ele mesmo |
| demais | não | gravados em `patients` |

### Resposta `data`

```json
{
  "patient": { "id", "clinic_id", "profile_id", "full_name", "email", "..." },
  "profile_id": "uuid-auth"
}
```

---

## Endpoint removido: `POST /create-professional-account`

Este endpoint não está mais disponível. O conteúdo abaixo descreve apenas o
fluxo histórico e não deve ser utilizado em clientes ou automações.

Cria uma conta de profissional sem exigir cadastro manual prévio de clínica.

**Permissão:** pública  
**JWT:** não exigido  
**Regra de produto:** o profissional criado entra como `admin` da clínica criada neste primeiro acesso.

### Body

```json
{
  "email": "psicologa@clinicateste-mvp.example",
  "password": "SenhaSegura1!",
  "full_name": "Ana Souza",
  "phone": "+5511999990099",
  "crp": "06/12345",
  "mode": "solo",
  "clinic": {
    "name": "Clínica Horizonte",
    "phone": "+551133334444",
    "email": "contato@horizonte.example"
  }
}
```

### Regras

- `mode = solo`: cria `clinics` com nome `Clínica pessoal — {full_name}` e `clinic_type = personal`
- `mode = clinic`: exige `clinic.name` e cria `clinics` com `clinic_type = clinic`
- cria `auth.users` via service role
- cria/atualiza `profiles` com `role = admin`, `clinic_id`, `full_name`, `phone`, `crp`
- define `clinics.owner_profile_id` para o profissional recém-criado
- não permite criar paciente por esse fluxo
- se o e-mail já existir, retorna erro genérico de conflito

### Resposta `data`

```json
{
  "profile_id": "uuid-auth",
  "clinic_id": "uuid-clinic"
}
```

---

## 1b. `POST /create-patient-invitation`

Cria um convite mínimo para o paciente concluir o primeiro acesso.

**Permissão:** `admin`, `psychologist`  
**JWT:** obrigatório  
**Observação:** não envia e-mail ainda; retorna `invite_url` para cópia manual.

### Body

```json
{
  "email": "paciente.convite@clinicateste-mvp.example",
  "full_name": "Bruno Costa",
  "phone": "+5511999990099",
  "responsible_psychologist_id": "11111111-1111-1111-1111-111111111103"
}
```

### Resposta `data`

```json
{
  "invitation": { "id", "email", "status", "expires_at", "..." },
  "invite_url": "/accept-invitation?token=...",
  "expires_at": "2026-06-13T12:00:00.000Z"
}
```

---

## 1c. `POST /accept-patient-invitation`

Aceita um convite pendente sem JWT prévio, cria a conta do paciente e completa o cadastro inicial.

**Permissão:** pública  
**JWT:** não exigido  
**Segurança:** token inválido, expirado, aceito ou revogado retorna mensagem genérica.

### Body

```json
{
  "token": "token-seguro",
  "password": "SenhaSegura1!",
  "profile": {
    "full_name": "Bruno Costa",
    "phone": "+5511999990099",
    "cpf": "00000000999",
    "birth_date": "1995-01-01",
    "gender": "Masculino",
    "relationship_status": "Solteiro(a)",
    "education_level": "Ensino superior completo",
    "occupation": "Designer",
    "birth_country_state": "Porto Alegre / Brasil",
    "religious_orientation": "Sem religião",
    "ethnic_group": "Branco",
    "sexual_orientation": "Heterossexual",
    "has_children": true
  }
}
```

### Resposta `data`

```json
{
  "patient_id": "uuid-patient",
  "profile_id": "uuid-auth"
}
```

---

## 2. `POST /start-questionnaire`

Inicia sessão (`questionnaire_responses` em `draft`) e retorna perguntas ativas.

**Permissão:** staff com acesso ao paciente **ou** paciente (apenas si).

### Body

```json
{
  "patient_id": "11111111-1111-1111-1111-111111111201",
  "questionnaire_id": "11111111-1111-1111-1111-111111111301"
}
```

Para `PARENTAL_STYLES_V1`, aceita também:

```json
{
  "patient_id": "uuid",
  "questionnaire_id": "uuid-parental",
  "contexts": [
    { "key": "mother", "label": "Mãe" },
    { "key": "father", "label": "Pai" },
    { "key": "other", "label": "Avó" }
  ]
}
```

### Resposta `data`

```json
{
  "response": { "id", "status": "draft", "started_at", "..." },
  "questionnaire": { "id", "code", "name", "..." },
  "contexts": [
    { "id", "context_key", "context_label", "status", "sort_order" }
  ],
  "questions": [
    { "id", "code", "text", "order_index", "answer_type", "scale_min", "scale_max" }
  ]
}
```

---

## 3. `POST /submit-questionnaire-answer`

Grava ou atualiza uma resposta (upsert por `response_id` + `question_id`).

**Bloqueio:** response `completed` ou `cancelled`.

### Body

```json
{
  "response_id": "uuid",
  "question_id": "uuid",
  "answer_value": 4
}
```

Para `PARENTAL_STYLES_V1`, `response_context_id` passa a ser obrigatório:

```json
{
  "response_id": "uuid",
  "question_id": "uuid",
  "response_context_id": "uuid-context",
  "answer_value": 4
}
```

Valida escala (`scale_min` / `scale_max`) e se a pergunta pertence ao questionário da sessão.

### Resposta `data`

```json
{
  "answer": { "id", "response_id", "question_id", "answer_value", "..." }
}
```

---

## 4. `POST /finish-questionnaire`

Finaliza sessão e grava `questionnaire_results` com `snapshot` JSONB.

Quando existe versão **active** em `questionnaire_versions` e regras em `question_scoring_rules`, aplica o **motor DEMO** (`_shared/scoring/`: peso, reverse, faixas `severity_ranges`, agrupamento por esquema/domínio). Caso contrário, mantém agregação legado por `question_category_items`.

**Permissão:** quem tem acesso à response (RLS).  
**Nota:** insert em `questionnaire_results` usa service role **após** validação de acesso no servidor.  
**Aviso:** snapshot com `version: "scoring-demo-1"` é DEMO — não é interpretação clínica validada.

**FH-04:** para `PARENTAL_STYLES_V1`, a finalização exige todos os contexts completos e retorna `snapshot.version = "parental-context-v1"` com seções separadas por figura parental.

### Body

```json
{
  "response_id": "uuid"
}
```

### Resposta `data`

```json
{
  "response": { "id", "status": "completed", "completed_at", "..." },
  "results": [
    {
      "id",
      "category_id",
      "total_score",
      "average_score",
      "snapshot": {
        "version": "scoring-demo-1",
        "category_code": "DEMO_GERAL",
        "category_name": "Categoria demonstração",
        "answer_count": 5,
        "total_weighted_score": 18,
        "average_score": 3.6,
        "items": [
          {
            "question_id": "uuid",
            "answer_value": 4,
            "weight": 1,
            "weighted_score": 4,
            "adjusted_score": 4,
            "schema_code": "DEMO_SCHEMA_ABANDONMENT"
          }
        ],
        "note": "Motor DEMO (scoring engine) — agregação estruturada; não é interpretação clínica validada.",
        "questionnaire": { "id": "uuid", "code": "MVP_DEMO", "name": "..." },
        "questionnaire_version": {
          "id": "uuid",
          "version": "v1-demo",
          "scoring_method": "weighted_sum_demo",
          "scale_min": 1,
          "scale_max": 6
        },
        "completed_at": "2025-05-31T12:00:00.000Z",
        "summary": {
          "raw_score": 18,
          "weighted_score": 18,
          "average_score": 3.6,
          "answered_items": 5,
          "max_possible_score": 30
        },
        "domains": [ ],
        "schemas": [
          {
            "id": "uuid",
            "code": "DEMO_SCHEMA_ABANDONMENT",
            "average_score": 4,
            "severity": { "label": "Demo — Moderado", "color_key": "severity_moderate" }
          }
        ]
      },
      "classification": "pending_review"
    }
  ]
}
```

---

## Fluxo Flutter recomendado

```text
1. Login Supabase Auth
2. POST create-patient **ou** create-patient-invitation (staff)
3. Se convite: POST accept-patient-invitation (paciente)
4. POST start-questionnaire → guardar response.id + questions
5. Para cada pergunta: POST submit-questionnaire-answer
6. POST finish-questionnaire → exibir snapshot / aguardar motor futuro
```

---

## 5. `POST /generate-clinical-report`

Gera PDF clínico supervisionado para um paciente (somente equipe).

**Permissão:** `admin`, `psychologist`  
**RLS:** valida acesso ao paciente com JWT do caller; leitura agregada via service role após checagem.  
**Resposta:** `application/pdf` (binário), não JSON.

### Body

```json
{
  "patient_id": "11111111-1111-1111-1111-111111111201",
  "include": {
    "questionnaires": true,
    "mental_map": true,
    "goals": true,
    "problems": true,
    "check_ins": true,
    "daily_monitors": true,
    "timeline": true,
    "genogram": true
  }
}
```

Campos omitidos em `include` são tratados como `true`. Pelo menos uma seção deve estar habilitada.

### Conteúdo do PDF

1. Capa (clínica, paciente, psicólogo, data)
2. Aviso clínico (não diagnóstico automático)
3. Resumo do paciente (dados básicos)
4. Questionários — último YSQ/YAMI, top esquemas/modos e severidades
5. Mapa mental resumido (contagens e últimos registros)
6. Anexos textuais conforme `include` (problemas, objetivos, check-ins, monitor, timeline, genograma)
7. Rodapé com versão `CLINICAL_REPORT_V1` (sem assinatura digital)

### Erros

Erros continuam no formato JSON `{ ok: false, error: { code, message } }` com HTTP 4xx/5xx.

| code | Situação |
|------|----------|
| `UNAUTHORIZED` | JWT ausente ou inválido |
| `FORBIDDEN` | Perfil paciente ou sem acesso ao `patient_id` |
| `VALIDATION_ERROR` | `patient_id` inválido ou nenhuma seção em `include` |

### Flutter

`ClinicalReportRepository` invoca a função e trata bytes PDF (`parseClinicalReportPdfBytes`). Rota staff: `…/patients/:patientId/clinical-report`.

---

## Desenvolvimento local

```bash
supabase db reset
supabase functions serve
```

Script de teste: `supabase/tests/edge-functions-flow.ps1`

---

## Deploy remoto

```bash
supabase functions deploy create-patient
supabase functions deploy create-patient-invitation
supabase functions deploy accept-patient-invitation
supabase functions deploy start-questionnaire
supabase functions deploy submit-questionnaire-answer
supabase functions deploy finish-questionnaire
supabase functions deploy generate-clinical-report
supabase db push   # inclui migration 010 (snapshot JSONB)
```

Reaplicar seed atualizada se necessário.
