# Plataforma Terapia do Esquema — MVP

Monorepo do MVP clínico: backend Supabase (Postgres + Auth + RLS + Edge Functions) e app mobile Flutter.

## Homologação e demo (cliente / psicólogas)

**Pacote principal:**

1. **[Homologação final MVP](docs/demo/final-mvp-homologation.md)** — guia completo do zero (roteiros, segurança, pendências clínicas)
2. **[Checklist demo](docs/demo-checklist.md)** — smoke rápido local
3. **[Roteiro de demo](docs/demo-script.md)** — roteiro falado (~25–40 min)

**Deploy e build:**

- [Checklist deploy Supabase](docs/deploy/supabase-deploy-checklist.md)
- [Checklist build mobile](docs/deploy/mobile-build-checklist.md)

Senha seed: **`TesteMVP2025!`** · contas `@clinicateste-mvp.example`

## Estrutura

| Pasta | Conteúdo |
|-------|----------|
| `mobile/` | App Flutter (iOS, Android, desktop, web) |
| `supabase/` | Migrations, seed demo, Edge Functions, testes SQL |
| `docs/` | Modelo, API, demo, deploy, RLS, motor clínico |
| `scripts/` | Validação do Supabase remoto |

## Início rápido (local)

```bash
supabase start
supabase db reset
supabase functions serve   # terminal separado (9 Edge Functions)

cd mobile
cp env.example.json env.local.json
flutter pub get
flutter run --dart-define-from-file=env.local.json
```

### APK debug (Android)

```bash
cd mobile
flutter build apk --debug --dart-define-from-file=env.local.json
# → build/app/outputs/flutter-apk/app-debug.apk
```

`applicationId`: `br.com.esquemacore.app` · Nome no launcher: **EsquemaCore**

## Segurança (MVP)

- App: apenas **anon key** + JWT (`env.local.json` / `env.production.json` — não commitar).
- **service_role** somente nas Edge Functions (nunca no Flutter).
- Cadastro de paciente, questionários e PDF via Edge Functions; demais módulos via API + RLS.

## Testes

```bash
cd mobile && flutter test && flutter analyze
supabase db reset
# Edge Functions: supabase/tests/edge-functions-flow.ps1
# Scoring (opcional): cd supabase/functions && deno task test:scoring
```

## Documentação

### Homologação e operação

- [Homologação final MVP](docs/demo/final-mvp-homologation.md)
- [Deploy Supabase](docs/deploy/supabase-deploy-checklist.md)
- [Build mobile](docs/deploy/mobile-build-checklist.md)
- [QA pós-roadmap](docs/qa/post-roadmap-stabilization.md)
- [Estado de implementação para produção](docs/production-implementation-status.md)
- [Homologação clínica YSQ/YAMI](docs/scoring-engine/clinical-homologation.md)

### Produto e roadmap

- [Master roadmap](docs/product/master-roadmap.md)
- [Gap analysis — wireframes](docs/product/gap-analysis-from-wireframes.md)

### Técnico

- [App mobile](docs/mobile-app.md)
- [API Edge Functions](docs/api.md)
- [Próximos passos](docs/next-steps.md)
- [Modelo de dados](docs/database-model.md)
- [Motor clínico](docs/scoring-engine/README.md)
