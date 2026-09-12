# AGENTS.md — Regras para agentes de IA

> Este arquivo é lido por agentes de IA (Codex, Claude, Cursor etc.) antes de
> trabalhar neste repositório. Vale para **todo** o monorepo. `CLAUDE.md`
> complementa este arquivo com comandos e detalhes de arquitetura.

---

## 0. Regra central — CONGELAMENTO (leia primeiro)

Este repositório está em **modo diagnóstico/auditoria**. Enquanto esta regra
estiver aqui:

- **NÃO refatorar.** Não reorganizar pastas, não renomear símbolos em massa, não
  "limpar" código que funciona.
- **NÃO redesenhar.** Não alterar UI, layout, tema, textos ou fluxos sem pedido
  explícito.
- **NÃO trocar bibliotecas** nem versões (nada de trocar Riverpod, GoRouter,
  Supabase, pdf, etc.; não subir/descer versões no `pubspec.yaml`).
- **NÃO migrar** padrões de estado, navegação ou arquitetura.
- **NÃO alterar o schema** do banco nem criar migrations sem pedido explícito.

O que é permitido por padrão: **ler, medir, diagnosticar e documentar**. Qualquer
mudança de código exige um pedido explícito e específico do responsável humano,
descrevendo o escopo. Na dúvida, pergunte antes de editar.

---

## 1. O que é o projeto

Monorepo do MVP clínico **EsquemaCore** — plataforma de Terapia do Esquema.

| Pasta | Conteúdo |
|---|---|
| `mobile/` | App Flutter (Android, iOS, web, desktop) — Riverpod + GoRouter + Supabase |
| `supabase/` | Migrations, seed, Edge Functions (Deno/TypeScript), testes SQL |
| `docs/` | Documentação de produto, arquitetura, deploy, QA, motor clínico |
| `scripts/` | Scripts de validação do Supabase remoto |

Três papéis de usuário: `platformAdmin`, `psychologist`, `patient`
(ver `mobile/lib/features/profile/domain/profile_role.dart`).

Docs de diagnóstico (leia antes de auditar):
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — como o código está organizado hoje
- [`docs/CURRENT_STATE.md`](docs/CURRENT_STATE.md) — build, testes e o que funciona
- [`docs/TECH_DEBT.md`](docs/TECH_DEBT.md) — dívida técnica observada

---

## 2. Comandos (todos a partir de `mobile/`, salvo indicado)

```bash
cd mobile
flutter pub get
flutter analyze
flutter test
flutter run --dart-define-from-file=env.local.json
```

Backend (a partir da raiz):

```bash
supabase start
supabase db reset            # aplica migrations + seed.sql
supabase functions serve     # terminal separado
cd supabase/functions && deno task test:scoring
cd supabase/functions && deno task test:clinical-report
```

Um arquivo `--dart-define-from-file` é **sempre** obrigatório para rodar o app.

---

## 3. Segurança — inegociável

- O app Flutter usa **apenas** a `SUPABASE_ANON_KEY` (+ JWT do usuário).
- A `service_role` key existe **somente** dentro das Edge Functions (Deno).
- **Nunca** commitar `env.local.json`, `env.production.json`, chaves, senhas ou
  tokens. Estão no `.gitignore` — mantenha assim.
- **Nunca** colar credenciais reais em código, testes, docs ou mensagens.
- RLS é aplicada em todas as tabelas; não desative RLS para "facilitar" nada.

---

## 4. Convenções que já existem (respeite, não reinvente)

- **Estrutura de feature:** cada `mobile/lib/features/<feature>/` tem
  `data/` · `domain/` · `presentation/` · `providers/`.
- **Estado:** Riverpod (`Provider`, `FutureProvider(.family)`,
  `AsyncNotifier`/`FamilyAsyncNotifier`, `StateNotifier` só no `AuthController`).
- **Navegação:** GoRouter em `appRouterProvider`; regras de acesso em
  `RouteAccess` (`mobile/lib/core/router/route_access.dart`).
- **Edge Functions:** respostas no formato `{ok, data}` / `{ok, error}`;
  chamadas via `EdgeApiClient`.
- **Migrations:** numeradas cronologicamente em `supabase/migrations/`.

Detalhes completos em `CLAUDE.md` e `docs/ARCHITECTURE.md`.

---

## 5. Git

- Branch de trabalho/produção: **`staging`** (não `main`).
- Não faça commit sem pedido explícito. Não faça push/force-push por conta própria.
- Nunca use `--no-verify` nem pule hooks/CI.
- Ao commitar mudanças pedidas, prefira commits pequenos e descritivos.

---

## 6. Como validar alterações (quando autorizadas)

Antes de considerar uma mudança pronta, a partir de `mobile/`:

```bash
flutter analyze   # deve continuar sem errors/warnings novos
flutter test      # baseline atual: 447 testes verdes
```

Mudanças em Edge Functions: `deno check */index.ts` + `deno task test:*`.
Mudanças em banco: nova migration numerada + `supabase db reset` + testes SQL em
`supabase/tests/`. Nunca edite migrations já aplicadas.

## 7. Design system

Não crie estilos avulsos. Reutilize os tokens de `mobile/lib/core/theme/`
(`app_colors`, `app_spacing`, `app_radius`, `app_shadows`, `app_typography`,
`app_gradients`, `app_breakpoints`) e os componentes de `mobile/lib/shared/widgets/`
(`AppCanopyScaffold`, `AppNavShell`, `ClayCard`, `ClinicalModuleCard`,
`AsyncStateBody`, `UserAvatar`, etc.).

## 8. Áreas sensíveis (cuidado redobrado)

- **RLS e Edge Functions com `service_role`** — qualquer mudança pode abrir acesso
  indevido entre clínicas/pacientes. Exige revisão humana.
- **`core/router/route_access.dart`** — gating por papel; erro aqui vaza telas.
- **`core/config/env_config.dart`** e validação de release — não afrouxar.
- **Migrations** — irreversíveis em produção; nunca reescrever histórico.
- **`results_released_at`** (paciente) — controla o que o paciente enxerga.

## 9. Ao terminar um trabalho de diagnóstico

Entregue um **relatório** (o que foi lido, o que rodou, o que falhou) e
**atualize os docs** relevantes em `docs/`. Não "conserte" o que encontrou a não
ser que tenha sido pedido — anote em `docs/TECH_DEBT.md`.
