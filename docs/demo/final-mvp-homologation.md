# Homologação final — MVP Terapia do Esquema

**Versão:** MVP homologação · **Data doc:** 2026-06-04  
**Público:** cliente, psicólogas, equipe técnica  
**Objetivo:** permitir que uma pessoa suba o ambiente do zero, execute os roteiros clínicos e registre aprovação ou pendências — **sem implementar novas features**.

---

## Visão do que está no MVP

| Área | Status |
|------|--------|
| Auth + RLS por clínica e perfil | Implementado |
| Pacientes (staff) | Implementado |
| Questionários clínicos (`YSQ_FOUNDATION_V1`, `YAMI_MODES_FOUNDATION_V1`, `PARENTAL_STYLES_V1`, `ATTACHMENT_STYLES_V1`, `YCI_FOUNDATION_V1`, `YRAI_FOUNDATION_V1`) | Implementado |
| Motor de apuração + snapshot JSON | Implementado |
| Resultados (staff) | Implementado |
| Recursos terapêuticos + monitor diário | Implementado |
| Trilha do paciente + 7 módulos clínicos do paciente | Implementado |
| Mapa mental v3 + dashboard v3 (mobile) | Implementado — homologação UX/clínica pendente |
| Relatório PDF v1 (staff) | Implementado |
| IA, dashboard web, assinatura digital, e-mail automático | **Fora do escopo** |

---

## 1. Pré-requisitos

| Ferramenta | Uso |
|------------|-----|
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | Supabase local |
| [Supabase CLI](https://supabase.com/docs/guides/cli) 2.x | Migrations, deploy, functions |
| [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.16 | App mobile |
| Android SDK ou Xcode | Emulador/dispositivo |
| Deno (opcional) | `deno task test:scoring` / `test:clinical-report` |

**Documentos auxiliares:**

- [Checklist demo](../demo-checklist.md) — smoke rápido
- [Deploy Supabase](../deploy/supabase-deploy-checklist.md)
- [Build mobile](../deploy/mobile-build-checklist.md)
- [QA pós-roadmap](../qa/post-roadmap-stabilization.md)
- [QA pós-feedback FH-01 a FH-04](../qa/post-feedback-homologation-qa.md)
- [QA Dashboard v3 + Mapa Mental v3](../qa/dashboard-v3-mental-map-v3-homologation.md)
- [Homologação clínica YSQ/YAMI](../scoring-engine/clinical-homologation.md)
- [Checklist validação clínica catálogo](../scoring-engine/clinical-validation-checklist.md)

### Gate adicional para homologação v3 (Dashboard + Mapa Mental)

Antes da sessão com cliente/psicólogas após entrega v3, executar:

- [qa/dashboard-v3-mental-map-v3-homologation.md](../qa/dashboard-v3-mental-map-v3-homologation.md) — checklists §1–§5
- Cenários: paciente sem dados · com cada instrumento · caso completo seed
- Validar hub 8 nós, tabs Núcleo/História/Plano, bottom sheets e responsividade
- Preencher tabela de feedbacks §6 e registro §7

**Escopo v3 entregue (Flutter only):**

| Módulo | Entregue | Pendente homologação / roadmap |
|--------|----------|--------------------------------|
| Dashboard v3 | D1 visão executiva + D3 parentais + detalhes colapsáveis | D2/D4/D5; sessão clínica |
| Mapa Mental v3 | M1 hub + M2–M4 tabs + M5 bottom sheet | Sessão UX/clínica; grafo/IA fora de escopo |

### Gate adicional para a próxima versão de homologação (FH-01 a FH-04)

Antes da próxima sessão com cliente, executar também o roteiro pós-feedback de:

- onboarding público do profissional (`FH-01`)
- convite e primeiro acesso do paciente (`FH-02`)
- catálogo/liberação de questionários por profissional (`FH-03`)
- `PARENTAL_STYLES_V1` com múltiplas figuras parentais (`FH-04`)

---

## 2. Ambiente local (homologação do zero)

### 2.1 Backend

```bash
cd /caminho/para/Aplicativo-Clinica-Psicologia

supabase start
supabase db reset          # migrations 001–025 + seed demo
supabase functions serve   # manter em terminal separado
```

Conferir:

```bash
supabase status
cd mobile && flutter test
```

### 2.2 App mobile

```bash
cd mobile
cp env.example.json env.local.json   # local: 127.0.0.1:54321
flutter pub get
flutter run --dart-define-from-file=env.local.json
```

**Android emulador:** `127.0.0.1` no JSON (app converte para `10.0.2.2`).  
**Dispositivo físico na LAN:** substituir URL pelo IP da máquina que roda o Supabase.

### 2.3 Build APK debug (entrega de demo)

```bash
cd mobile
flutter build apk --debug --dart-define-from-file=env.local.json
# → build/app/outputs/flutter-apk/app-debug.apk
```

Detalhes: [mobile-build-checklist.md](../deploy/mobile-build-checklist.md).

---

## 3. Deploy Supabase (staging / homologação remota)

Ordem recomendada:

```bash
supabase link --project-ref <PROJECT_REF>
supabase db push
supabase db query --linked -f supabase/seed.sql

supabase functions deploy create-professional-account
supabase functions deploy create-patient
supabase functions deploy create-patient-invitation
supabase functions deploy accept-patient-invitation
supabase functions deploy start-questionnaire
supabase functions deploy submit-questionnaire-answer
supabase functions deploy finish-questionnaire
supabase functions deploy generate-clinical-report
```

Configurar `mobile/env.local.json` (ou `env.production.json` — ver checklist mobile) com **URL** e **anon key** do projeto remoto.

Checklist completo: [supabase-deploy-checklist.md](../deploy/supabase-deploy-checklist.md).

---

## 4. Contas de teste (seed)

Senha para todas: **`TesteMVP2025!`**

| Perfil | E-mail | Nome na UI | Uso na homologação |
|--------|--------|------------|-------------------|
| Admin | `admin@clinicateste-mvp.example` | Ricardo Mendes (admin demo) | Visão clínica, liberar recursos, PDF |
| Psicólogo | `psicologo@clinicateste-mvp.example` | Dra. Ana Costa (psicóloga demo) | Paciente Maria Silva; resultados; homologação YSQ/YAMI |
| Paciente | `paciente.login@clinicateste-mvp.example` | Maria Silva (paciente demo) | Trilha, questionários, módulos clínicos |

**Paciente:** `patients.id` = `11111111-1111-1111-1111-111111111201`  
Dados fictícios: domínio `@clinicateste-mvp.example`, CPF `00000000191`.

**Instrumentos no banco (migrations 014–015, 022–025 e seed atual):**

- `YSQ_FOUNDATION_V1` — 90 itens, esquemas iniciais
- `YAMI_MODES_FOUNDATION_V1` — modos esquemáticos
- `PARENTAL_STYLES_V1` — estilos parentais com suporte a múltiplas figuras
- `ATTACHMENT_STYLES_V1` — estilos de apego
- `YCI_FOUNDATION_V1` — coping/inventário complementar
- `YRAI_FOUNDATION_V1` — inventário complementar

---

## 5. Roteiro — Paciente (~20–30 min)

Login: `paciente.login@…` / `TesteMVP2025!`

| # | Passo | Validar |
|---|--------|---------|
| 1 | Home paciente — nome Maria Silva | Perfil correto |
| 2 | **Trilha do paciente** — 10 passos visíveis | Status Disponível / Em andamento / Concluído coerentes |
| 3 | **Objetivos** — criar 1 objetivo | Lista atualiza; refresh OK |
| 4 | **Problemas** — registrar 1 problema | Intensidade 0–10; lista OK |
| 5 | **Check-in** — registro de hoje | Trilha pode marcar concluído |
| 6 | **Linha do tempo** — 1 evento | Título + data/período |
| 7 | **Genograma** — 2 pessoas + 1 relação | Aviso gráfico v1; lista OK |
| 8 | **Questionários** — iniciar YSQ/YAMI ou responder um instrumento curto disponível | Finalizar sem erro (functions ativas) |
| 9 | **Monitor diário** — registro de hoje | SnackBar sucesso |
| 10 | **Meus recursos** — item liberado pelo staff | Sem recursos não liberados |
| 11 | **Mapa mental** | Hub 8 nós + tabs Núcleo/História/Plano + bottom sheets; banner disclaimer; cards resumo v2 mantidos |
| 12 | **Dashboard clínico** | Visão executiva v3; prioridades YSQ/YAMI/apego/enfrentamento; parentais por figura; detalhes colapsáveis |
| 13 | Logout | Retorno ao login |

\* YSQ (90) e YAMI (~124) são longos — para sessão de homologação clínica dedicada, usar [clinical-homologation.md](../scoring-engine/clinical-homologation.md).

---

## 6. Roteiro — Psicólogo / Admin (~25–35 min)

Login admin **ou** psicólogo (mesmo paciente Maria Silva).

| # | Passo | Validar |
|---|--------|---------|
| 1 | **Pacientes** → Maria Silva | Psicóloga responsável visível |
| 2 | **Questionários** (staff) | Iniciar aplicação se necessário |
| 3 | **Resultados** | Resposta concluída; snapshot legível; **sem interpretação automática** |
| 4 | **Dashboard clínico** | Visão executiva v3; parentais por figura; callouts |
| 5 | **Mapa mental** | Hub + tabs + bottom sheet; agregado read-only |
| 6 | **Objetivos / Problemas / Timeline / Genograma** | Dados criados pelo paciente |
| 7 | **Check-ins** | **Somente leitura** (staff não cria) |
| 8 | **Monitor diário** (histórico) | Leitura; registros do paciente |
| 9 | **Recursos terapêuticos** | Liberar item da biblioteca |
| 10 | **Gerar relatório** → PDF | Ver §7 abaixo |
| 11 | Logout | — |

**Admin adicional:** lista de pacientes; cadastro via app (Edge `create-patient`) se quiser demonstrar onboarding.

Roteiro falado resumido: [demo-script.md](../demo-script.md).

---

## 7. Roteiro — Geração de PDF (staff)

Pré-requisito: `generate-clinical-report` deployada / `functions serve` ativo.

1. Login **admin** ou **psicólogo**.
2. **Pacientes** → Maria Silva.
3. Card **Gerar relatório** (ou rota `…/clinical-report`).
4. Manter seções marcadas (default: todas) ou desmarcar para teste parcial.
5. **Gerar relatório PDF** — aguardar loading.
6. Validar:
   - PDF abre no dispositivo ou caminho exibido no SnackBar
   - Capa: clínica, paciente, psicólogo, data
   - Aviso: *apoio clínico; interpretação do profissional*
   - Seções conforme `include`
   - Rodapé: `CLINICAL_REPORT_V1`
7. **Não esperar:** assinatura digital, envio e-mail, Storage permanente.

Erro comum: functions paradas → HTTP 500 / timeout.

---

## 8. Checklist clínico YSQ / YAMI

Usar em sessão **dedicada** com psicóloga homologadora (não substituir demo funcional de 25 min).

| Documento | Conteúdo |
|-----------|----------|
| [clinical-homologation.md](../scoring-engine/clinical-homologation.md) | Roteiro responder + revisar snapshot + registrar aprovação |
| [clinical-validation-checklist.md](../scoring-engine/clinical-validation-checklist.md) | Catálogo, licença, textos, severidades |
| [ysq-import-report.md](../scoring-engine/ysq-import-report.md) | Importação YSQ |
| [yami-import-report.md](../scoring-engine/yami-import-report.md) | Importação YAMI |

### Resumo executivo (homologação)

- [ ] Paciente completa `YSQ_FOUNDATION_V1` (ou amostra acordada)
- [ ] Staff abre resultado → esquemas/domínios/itens + severidades visíveis
- [ ] Banner de validação clínica presente (não diagnóstico)
- [ ] Mesmo fluxo para `YAMI_MODES_FOUNDATION_V1`
- [ ] Psicóloga registra OK / pendências na tabela do doc de homologação
- [ ] Faixas de severidade e licença de uso revisadas ([severity-ranges.md](../scoring-engine/severity-ranges.md))

**Até homologação formal:** dashboard e mapa mental são **apoio visual**, não laudo. Rodada UX/clínica v3: [dashboard-v3-mental-map-v3-homologation.md](../qa/dashboard-v3-mental-map-v3-homologation.md).

---

## 9. Checklist de segurança

| # | Verificação | Como testar | Esperado |
|---|-------------|-------------|----------|
| S1 | Paciente não acessa rotas staff | Logado como paciente, tentar URL mental `/admin/patients` | Redirect `/patient` |
| S2 | Staff não acessa rotas paciente | Logado como psicólogo, `/patient/journey` | Redirect `/psychologist` |
| S3 | Admin ≠ psychologist prefix | `/psychologist` como admin | Redirect `/admin` |
| S4 | Paciente não gera PDF | Sem rota/card de relatório no fluxo paciente | — |
| S5 | Paciente não vê pacientes de outra clínica | RLS (seed single-clinic) | Listas vazias ou 403 |
| S6 | Check-in: staff só leitura | Psicólogo tenta criar check-in via app | Sem UI de criação; RLS bloqueia insert staff |
| S7 | Anon key no app | Inspecionar `env.local.json` | Sem `service_role` |
| S8 | service_role só Edge Functions | Dashboard Supabase → secrets | Não embutido no Flutter |
| S9 | JWT expirado | Logout + token inválido | Mensagem sessão expirada |
| S10 | Dados fictícios | Seed | Domínio `@clinicateste-mvp.example` |

Detalhe RLS módulos 017–021: [post-roadmap-stabilization.md](../qa/post-roadmap-stabilization.md) §3.

Automação: `cd mobile && flutter test` (inclui `route_access_test`).

---

## 10. Pendências conhecidas (explícitas para o cliente)

| ID | Área | Pendência | Impacto |
|----|------|-----------|---------|
| P1 | Clínico | Homologação formal YSQ/YAMI (licença, cortes, textos) | Não usar scores como laudo até aprovação |
| P2 | Clínico | Outros instrumentos da planilha (Personalidade, Apego, etc.) | Não no MVP |
| P3 | Produto | Dashboard web, comparativo longitudinal | Roadmap pós-MVP |
| P4 | Produto | IA / sugestão terapêutica | Fora do MVP |
| P5 | PDF | Acentuação PT-BR limitada (Helvetica/sanitize) | Texto legível; sem ç/ã em alguns PDFs |
| P6 | PDF | Sem Storage, e-mail, versão paciente | Staff gera e abre localmente |
| P7 | Genograma | Sem gráfico interativo | Lista + relações |
| P8 | QA | `deno task test:scoring` requer Deno instalado | Opcional em CI |
| P9 | Release | APK/AAB release + Play Store / App Store | Checklist mobile § release |
| P10 | Demo | URLs de recursos fictícias | Fluxo de liberação OK; link externo pode falhar |

---

## 11. Critérios de aceite da homologação MVP

- [ ] `supabase db reset` (local) ou `db push` + seed (remoto) sem erro
- [ ] Cinco Edge Functions respondem (incl. PDF)
- [ ] `flutter test` verde
- [ ] Roteiro paciente (§5) executado ou amostra registrada
- [ ] Roteiro staff (§6) + PDF (§7) executados
- [ ] QA Dashboard v3 + Mapa Mental v3 — [dashboard-v3-mental-map-v3-homologation.md](../qa/dashboard-v3-mental-map-v3-homologation.md) §5 aprovado ou com ressalvas documentadas
- [ ] Checklist segurança (§9) — smoke OK
- [ ] YSQ/YAMI: sessão clínica agendada ou tabela [clinical-homologation.md](../scoring-engine/clinical-homologation.md) preenchida
- [ ] Pendências (§10) comunicadas ao cliente

---

## 12. Referências rápidas

| Tópico | Documento |
|--------|-----------|
| API Edge Functions | [api.md](../api.md) |
| QA v3 Dashboard + Mapa | [qa/dashboard-v3-mental-map-v3-homologation.md](../qa/dashboard-v3-mental-map-v3-homologation.md) |
| Spec Dashboard v3 | [product/dashboard-v3-spec.md](../product/dashboard-v3-spec.md) |
| Spec Mapa Mental v3 | [product/mental-map-v3-spec.md](../product/mental-map-v3-spec.md) |
| App mobile / rotas | [mobile-app.md](../mobile-app.md) |
| Roteiro demo 15–25 min | [demo-script.md](../demo-script.md) |
| Deploy Supabase | [deploy/supabase-deploy-checklist.md](../deploy/supabase-deploy-checklist.md) |
| Build mobile | [deploy/mobile-build-checklist.md](../deploy/mobile-build-checklist.md) |
