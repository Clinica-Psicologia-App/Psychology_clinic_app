# QA — Estabilização pós-roadmap MVP

**Data:** 2026-05-31  
**Escopo:** Trilha, objetivos, problemas, check-in, timeline, genograma, mapa mental v1, dashboard clínico v1.  
**Sem alteração de modelo clínico, motor de apuração ou novas features.**

---

## 1. Automação executada

| Comando | Resultado | Observação |
|---------|-----------|------------|
| `cd mobile && flutter test` | **OK** (100 testes) | Inclui `route_access_test`, domínio dos módulos novos, trilha |
| `supabase db reset` | **OK** | Migrations 001–021 + `seed.sql` |
| `cd supabase/functions && deno task test:scoring` | **Não executado** | Deno não instalado no ambiente (`command not found`) |

### Reproduzir scoring (quando Deno estiver disponível)

```bash
cd supabase/functions
deno task test:scoring
```

---

## 2. Auditoria de rotas (`RouteAccess` + `app_router`)

**Mecanismo:** cada perfil só navega sob o prefixo do papel (`/patient`, `/admin`, `/psychologist`). Redirect envia para home do papel se a rota for inválida.

### 2.1 Paciente

| Rota | Permitida |
|------|-----------|
| `/patient/journey`, `/patient/therapy-goals`, `/patient/problems`, `/patient/check-ins`, `/patient/timeline`, `/patient/genogram`, `/patient/mental-map`, `/patient/clinical-dashboard` | Sim |
| `/patient/journey/upcoming/:stepId` (placeholder) | Sim |
| `/admin/*`, `/psychologist/*` | Não |

### 2.2 Staff (admin / psychologist)

| Rota | Admin | Psychologist |
|------|-------|--------------|
| `/{role}/patients/:id/therapy-goals` | Sim | Sim |
| `/{role}/patients/:id/problems` | Sim | Sim |
| `/{role}/patients/:id/check-ins` | Sim | Sim |
| `/{role}/patients/:id/timeline` | Sim | Sim |
| `/{role}/patients/:id/genogram` | Sim | Sim |
| `/{role}/patients/:id/mental-map` | Sim | Sim |
| `/{role}/patients/:id/clinical-dashboard` | Sim | Sim |
| `/{role}/patients/:id/results` | Sim | Sim |
| `/patient/*` | Não | Não |
| Rotas do outro papel (`/psychologist` vs `/admin`) | Não | Não |

**Cobertura automatizada:** `mobile/test/route_access_test.dart` (ampliado nesta rodada).

### 2.3 Placeholders da trilha

- Passos com `inDevelopment` ou `blocked` abrem `/patient/journey/upcoming/:stepId`.
- Página: `JourneyPlaceholderPage` — mensagem fixa *"Funcionalidade prevista para próxima versão."*
- Hoje **nenhum** passo do catálogo usa `blocked`/`inDevelopment`; todos os 10 passos são navegáveis ao módulo real.

---

## 3. Auditoria RLS (migrations 017–021)

Políticas comuns: `clinic_id = current_clinic_id()` + `user_can_access_patient(patient_id)`.

### 3.1 `therapy_goals`

| Operação | Paciente | Staff |
|----------|----------|-------|
| SELECT | Próprio paciente | Paciente da clínica com acesso |
| INSERT | `patient_id = current_patient_id()` | `is_staff()` + acesso ao paciente |
| UPDATE | Com acesso ao paciente | Idem |

### 3.2 `patient_problems`

Igual a `therapy_goals` (paciente ou staff com acesso).

### 3.3 `patient_check_ins`

| Operação | Paciente | Staff |
|----------|----------|-------|
| SELECT | Sim (com acesso) | Sim (leitura) |
| INSERT / UPDATE | **Somente paciente** (`current_role() = 'patient'`) | **Não** |

> Staff vê check-ins no app, mas não cria/edita via RLS — alinhado ao produto.

### 3.4 `patient_timeline_events`

Igual a problemas/objetivos (paciente ou staff).

### 3.5 `genogram_people` / `genogram_relationships`

Igual a problemas/objetivos (paciente ou staff).

### 3.6 Queries manuais (SQL Editor local)

Substituir `:patient_id` pelo UUID do paciente demo (`11111111-1111-1111-1111-111111111201`).

**Como paciente** (JWT do `paciente.login@clinicateste-mvp.example`):

```sql
-- Deve retornar só registros do próprio paciente
SELECT id, title FROM therapy_goals WHERE patient_id = :patient_id;
SELECT id, title FROM patient_problems WHERE patient_id = :patient_id;
SELECT id, recorded_at FROM patient_check_ins WHERE patient_id = :patient_id;
SELECT id, title FROM patient_timeline_events WHERE patient_id = :patient_id;
SELECT id, display_name FROM genogram_people WHERE patient_id = :patient_id;
```

**Como psicóloga** (paciente vinculado):

```sql
-- Mesmas queries — deve ver dados de Maria Silva
-- INSERT em check-in deve falhar (RLS)
INSERT INTO patient_check_ins (patient_id, clinic_id, mood_score)
VALUES (:patient_id, current_clinic_id(), 5);
```

**Como paciente em outro paciente** (deve retornar vazio / erro RLS):

```sql
SELECT * FROM therapy_goals WHERE patient_id != current_patient_id();
```

**Cross-clínica:** usuário de outra clínica não deve ver linhas (política `clinic_id`).

---

## 4. Estados de UI (loading / empty / error / refresh)

Padrão principal: `AsyncStateBody` + `RefreshIndicator` + botão/atualizar no `AppScaffold`.

| Módulo | Loading | Empty | Error + retry | Pull / refresh |
|--------|---------|-------|---------------|----------------|
| Objetivos | Sim | Lista vazia | Sim | Sim (paciente + staff) |
| Problemas | Sim | Sim | Sim | Sim |
| Check-ins | Sim | Sim | Sim | Sim |
| Timeline | Sim | Sim | Sim | Sim |
| Genograma | Sim | Mensagem custom (corpo interno se não for `List`) | Sim | Sim |
| Mapa mental | Sim | Global via `_MentalMapBody` se `!hasRelevantData` | Sim | Sim |
| Dashboard clínico | Sim | Inline em `_DashboardBody` + cards vazios por instrumento | Sim | Sim |

### Limitação conhecida (sem bug funcional)

`AsyncStateBody` só usa `emptyMessage` quando `T` é `List` vazio. Para `GenogramData`, `MentalMapData` e `ClinicalDashboardData`, o vazio é tratado **dentro** do `dataBuilder`. Comportamento correto na UI; mensagem do parâmetro `emptyMessage` pode não aparecer nesses três módulos.

---

## 5. Roteiro manual — fluxo paciente

**Pré-requisitos:** `supabase start`, `supabase db reset`, `supabase functions serve`, Flutter com `env.local.json`.

| # | Passo | Conta | Validar |
|---|--------|-------|---------|
| 1 | Login | `paciente.login@clinicateste-mvp.example` / `TesteMVP2025!` | Home paciente |
| 2 | Trilha | Trilha do paciente | 10 passos; status coerente |
| 3 | Objetivo | Trilha → Objetivos → criar | Lista atualiza; refresh |
| 4 | Problema | Trilha → Problemas → criar | Idem |
| 5 | Check-in | Trilha → Check-in → criar | Trilha pode marcar concluído hoje |
| 6 | Timeline | Trilha → Linha do tempo → evento | Lista cronológica |
| 7 | Genograma | Trilha → Genograma → pessoa (+ relação se 2+) | Aviso gráfico v1 |
| 8 | YSQ/YAMI | Questionários → concluir (se disponível na seed) | Snapshot em resultados |
| 9 | Mapa mental | Trilha → Mapa mental | Seções vazias com hints; disclaimer |
| 10 | Dashboard | Trilha → Dashboard clínico | Banner validação; barras ou empty YSQ/YAMI |

---

## 6. Roteiro manual — fluxo staff

| # | Passo | Conta | Validar |
|---|--------|-------|---------|
| 1 | Login admin ou psicóloga | `admin@…` ou psicóloga na seed | Lista pacientes |
| 2 | Detalhe Maria Silva | Módulos | Tiles habilitados |
| 3 | Objetivos / Problemas / Timeline / Genograma | Abrir cada módulo | Leitura + dados do paciente |
| 4 | Check-ins | Abrir | Somente leitura (sem FAB criar) |
| 5 | Mapa mental / Dashboard | Abrir | Mesmo conteúdo agregado; staff pode linkar a resultados no dashboard |
| 6 | Resultados | Lista + detalhe | Snapshot legível; sem interpretação automática |

---

## 7. Bugs encontrados

| ID | Severidade | Descrição | Ação |
|----|------------|-----------|------|
| — | — | Nenhum bug bloqueante identificado na automação | — |
| QA-01 | Baixa | `AsyncStateBody.emptyMessage` ignorado para tipos não-`List` | Documentado (§4); unificar em refactor futuro se desejado |
| QA-02 | Info | `deno task test:scoring` não rodou — Deno ausente no CI local | Instalar Deno ou rodar em CI com Deno |

---

## 8. Critérios de aceite

| Critério | Status |
|----------|--------|
| `flutter test` passando | Sim |
| `supabase db reset` passando | Sim |
| Fluxo paciente (roteiro §5) | Pendente validação manual no dispositivo |
| Fluxo staff (roteiro §6) | Pendente validação manual |
| RLS documentada + queries §3.6 | Sim |
| Rotas auditadas + testes | Sim |
| Bugs documentados | Sim (§7) |

---

## Referências

- Rotas mobile: [mobile-app.md](../mobile-app.md)
- Demo: [demo-script.md](../demo-script.md)
- Migrations RLS: `20250531170017` … `20250531210021`
