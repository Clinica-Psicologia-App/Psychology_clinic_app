# API — Edge Functions (MVP)

Base URL local: `http://127.0.0.1:54321/functions/v1`  
Base URL remota: `https://<PROJECT_REF>.supabase.co/functions/v1`

## Autenticação

Todas as funções exigem JWT do Supabase Auth:

```http
Authorization: Bearer <access_token>
apikey: <SUPABASE_ANON_KEY>
Content-Type: application/json
```

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

---

## 1. `POST /create-patient`

Cria usuário Auth + profile (`patient`) + registro em `patients`.

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

### Resposta `data`

```json
{
  "response": { "id", "status": "draft", "started_at", "..." },
  "questionnaire": { "id", "code", "name", "..." },
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

Valida escala (`scale_min` / `scale_max`) e se a pergunta pertence ao questionário da sessão.

### Resposta `data`

```json
{
  "answer": { "id", "response_id", "question_id", "answer_value", "..." }
}
```

---

## 4. `POST /finish-questionnaire`

Finaliza sessão e grava `questionnaire_results` com `snapshot` JSONB (agregação simples, sem motor clínico).

**Permissão:** quem tem acesso à response (RLS).  
**Nota:** insert em `questionnaire_results` usa service role **após** validação de acesso no servidor.

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
        "version": "mvp-1",
        "category_code": "DEMO_GERAL",
        "answer_count": 5,
        "total_weighted_score": 18,
        "items": [ ],
        "note": "Placeholder aggregation — clinical engine not applied"
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
2. POST create-patient (staff)
3. POST start-questionnaire → guardar response.id + questions
4. Para cada pergunta: POST submit-questionnaire-answer
5. POST finish-questionnaire → exibir snapshot / aguardar motor futuro
```

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
supabase functions deploy start-questionnaire
supabase functions deploy submit-questionnaire-answer
supabase functions deploy finish-questionnaire
supabase db push   # inclui migration 010 (snapshot JSONB)
```

Reaplicar seed atualizada se necessário.
