# Roteiro de demo — MVP Terapia do Esquema

**Duração estimada:** 25–40 minutos (demo completa) · 15–20 min (versão curta)  
**Público:** cliente / psicólogas / stakeholders  
**Ambiente:** local ou remoto (Supabase + Flutter)

**Antes de começar:** [demo-checklist.md](./demo-checklist.md)  
**Homologação formal:** [demo/final-mvp-homologation.md](./demo/final-mvp-homologation.md)

---

## Mensagem de abertura (30 s)

> “Esta é a versão MVP da Plataforma Terapia do Esquema: app mobile com login por perfil, dados isolados por clínica (RLS), questionários com motor de apuração YSQ/YAMI, trilha do paciente, módulos clínicos, dashboard e relatório PDF para a equipe. Os dados são fictícios; scores estruturados estão em **validação clínica** — não substituem laudo.”

---

## Parte 1 — Visão da clínica (Admin) · ~8 min

### 1.1 Login admin

1. App → login.
2. Chip **Admin** ou:
   - `admin@clinicateste-mvp.example`
   - `TesteMVP2025!`
3. Home **Admin** — “Ricardo Mendes (admin demo)”.

### 1.2 Pacientes

1. **Pacientes** → **Maria Silva (paciente demo)**.
2. Detalhe → psicóloga **Dra. Ana Costa**; card **Gerar relatório** visível.

### 1.3 Resultados e dashboard

1. **Resultados** → resposta `MVP_DEMO` concluída (seed).
2. Detalhe → snapshot; banner de validação (não diagnóstico automático).
3. **Dashboard clínico** → barras ou empty YSQ/YAMI; aviso de validação clínica.

### 1.4 Recursos

1. **Recursos terapêuticos** → liberar *Exercício: Registro emocional guiado*.
2. Confirmar em **Liberados**.

### 1.5 Relatório PDF (opcional na demo curta)

1. **Gerar relatório** → seções default → **Gerar relatório PDF**.
2. Validar abertura do PDF + aviso clínico no documento.

### 1.6 Logout admin

---

## Parte 2 — Experiência do paciente · ~12 min

### 2.1 Login paciente

- `paciente.login@clinicateste-mvp.example` / `TesteMVP2025!`
- Home **Maria Silva**.

### 2.2 Trilha do paciente

1. Abrir **Trilha** — 10 passos (questionários, monitor, biblioteca, dashboard, objetivos, problemas, check-in, timeline, genograma, mapa mental).
2. Mencionar status **Disponível / Em andamento / Concluído**.

### 2.3 Módulos clínicos (amostra)

1. **Objetivos** → criar 1 objetivo.
2. **Problemas** → registrar 1 problema.
3. **Check-in** → registro de hoje.
4. **Linha do tempo** → 1 evento.
5. **Genograma** → 2 pessoas + 1 relação (lista v1).

### 2.4 Questionário

1. **Questionários** → *Inventário Demo — 5 itens* (rápido) **ou** mencionar YSQ/YAMI completos na homologação clínica separada.
2. Responder → **Finalizar** → sucesso (`functions serve` ativo).

### 2.5 Recursos e monitor

1. **Meus recursos** → item liberado.
2. **Monitor diário** → registro de hoje.

### 2.6 Mapa mental e dashboard (paciente)

1. **Mapa mental** → seções + disclaimer.
2. **Dashboard clínico** (via trilha) → barras ou empty; **somente leitura**.

### 2.7 Logout paciente

---

## Parte 3 — Acompanhamento (Psicólogo) · ~8 min

### 3.1 Login psicólogo

- `psicologo@clinicateste-mvp.example` / `TesteMVP2025!`

### 3.2 Paciente Maria Silva

1. **Objetivos / Problemas / Check-ins / Timeline / Genograma** — dados do paciente.
2. **Check-ins** — confirmar **somente leitura** para staff.
3. **Monitor diário** — histórico.
4. **Resultados** + **Mapa mental** + **Dashboard clínico**.

### 3.3 PDF (se não feito na Parte 1)

**Gerar relatório** → PDF com seções selecionadas.

### 3.4 Logout

---

## Parte 4 — Fechamento (2 min)

Reforçar:

- **RLS** + rotas por perfil (`RouteAccess`).
- **Edge Functions:** cadastro, questionários, **PDF**; demais módulos via API + JWT.
- **Validação clínica YSQ/YAMI:** sessão dedicada — [clinical-homologation.md](./scoring-engine/clinical-homologation.md).
- **Fora do MVP:** IA, dashboard web, comparativo longitudinal avançado, e-mail/Storage PDF, loja (release).

---

## Versão curta (~15 min)

1. Admin: paciente → resultados → liberar recurso.  
2. Paciente: trilha → demo questionário → monitor.  
3. Psicólogo: resultados + check-ins leitura.  
4. Opcional: PDF em 1 min.

---

## Demo remota (Supabase cloud)

1. [deploy/supabase-deploy-checklist.md](./deploy/supabase-deploy-checklist.md)
2. `env.production.json` com URL/anon do projeto
3. Mesmo roteiro; pausa após “Finalizar questionário” se latência alta

---

## Troubleshooting ao vivo

| Se falhar… | Faça |
|------------|------|
| Login 500 | `supabase db reset` |
| Questionário / PDF trava | Ver `functions serve` ou deploy |
| Lista vazia | Hot restart; conferir env |
| Admin não vê paciente | Seed + login correto |

Checklists: [demo-checklist.md](./demo-checklist.md) · [final-mvp-homologation.md](./demo/final-mvp-homologation.md)
