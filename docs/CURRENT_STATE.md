# Estado atual — EsquemaCore

> Baseline pré-auditoria. Diagnóstico executado em **2026-09-11**, branch `staging`.
> Nada foi corrigido — apenas medido a partir do código real (ver `AGENTS.md`).
> Legenda: ✅ funcionando · ⚠️ parcial · ❌ com problema · 🧪 não validado · 📌 pendente/externo.

## Validações executadas

| Verificação | Comando | Resultado |
|---|---|---|
| Dependências | `flutter pub get` | ✅ PASS |
| Lint / análise estática | `flutter analyze` | ✅ PASS — exit 0, **99 issues nível `info`**, 0 warnings, 0 errors (~82s) |
| Testes (unit + widget) | `flutter test` | ✅ PASS — **447 testes, todos passaram** |
| Typecheck | — | ✅ Implícito no `analyze` (Dart é tipado; sem erros de tipo) |
| Build web release | `flutter build web --release` | 🧪 NÃO VALIDADO nesta passagem (coberto no CI `quality.yml`) |
| Build Android appbundle | `flutter build appbundle --release` | 🧪 NÃO VALIDADO nesta passagem (coberto no CI) |
| Testes Edge Functions | `deno task test:scoring` / `test:clinical-report` | 🧪 NÃO VALIDADO — **Deno não instalado** nesta máquina |
| Lint/testes de banco (RLS) | `supabase db lint` + `tests/*.sql` | 🧪 NÃO VALIDADO — exige `supabase start` (Docker); não iniciado nesta passagem |

> Não há TypeScript no frontend (o app é Flutter/Dart). TS existe apenas nas Edge
> Functions (Deno); o CI roda `deno check */index.ts`.

### Detalhe do lint (99 `info`, não bloqueiam)

Sugestões cosméticas, a maioria em testes: `prefer_const_constructors` (~30+, ex.
`test/tools/render_infographic.dart`), `depend_on_referenced_packages`
(`mobile/lib/features/user_management/domain/clinic_user.dart:1`),
`curly_braces_in_flow_control_structures` (`mobile/lib/shared/widgets/icon_optics.dart`),
`unnecessary_import` e `sized_box_for_whitespace` em testes. CI usa
`--no-fatal-infos`, então passam. Ver `TECH_DEBT.md`.

## Áreas do sistema

| Área | Estado | Observação (evidência) |
|---|---|---|
| App compila e testa | ✅ | 447 testes verdes; analyzer sem erros |
| Autenticação (Supabase Auth, PKCE) | ✅ | `mobile/lib/core/supabase/supabase_bootstrap.dart`, `features/auth/` |
| Autorização por papel (RLS + router) | ✅ | `core/router/route_access.dart` + funções SQL RLS; testado em `test/route_access_test.dart` |
| Gerência de estado (Riverpod) | ✅ | Padrão consistente nos 33 módulos |
| Navegação (GoRouter) | ✅ | `core/router/app_router.dart` |
| Edge Functions (15) | 🧪 | Código presente; handlers HTTP **não têm teste automatizado** (só scoring + clinical-report do `_shared`) |
| Banco / migrations (114) | 🧪 | Não aplicado nesta passagem; validado no CI |
| Tratamento de erros | ✅ | `core/errors/app_exception.dart` + `error_mapper.dart` + `AsyncStateBody`/`ErrorBanner` |
| Logging / observabilidade | ❌ | **Zero** `print`/`debugPrint`/telemetria no runtime — sem rastro de diagnóstico em produção |
| Design system | ✅ | Tokens em `core/theme/` + `shared/widgets/` reutilizados |
| Responsividade | 🧪 | Breakpoints existem (`app_breakpoints.dart`); não verificada em dispositivo nesta passagem |
| Acessibilidade | 🧪 | Não auditada (sem verificação de semantics/contraste/foco) |
| Integrações externas | ✅ | Supabase (dados/auth/storage/edge); `url_launcher`, `image_picker`, `pdf`/`printing`, `video_player` |
| Deploy / CD | 📌 | Sem workflow de deploy automatizado; processo **manual** documentado em `docs/deploy/` |
| Itens de produção (jurídico, licença clínica, SMTP, MFA, pentest…) | 📌 | Bloqueados por evidência externa — ver `docs/production-implementation-status.md` |

## Como completar a validação de backend

```bash
# Edge Functions (instalar Deno v2.x)
cd supabase/functions && deno check */index.ts && deno task test:scoring && deno task test:clinical-report
# Banco / RLS (Docker + supabase CLI já presentes)
supabase start && supabase db lint --local
# depois: supabase/tests/rls-smoke-tests.sql e production-governance-tests.sql
```

## Estado do repositório

- Branch: **`staging`** (up to date com `origin/staging`).
- **14 arquivos de código modificados não commitados** (trabalho visual em telas/
  `shared/widgets` de sessões anteriores). **Não foram tocados** neste diagnóstico.
- Dumps de produção (`backup_prod_*.sql`) presentes localmente mas **corretamente
  ignorados** pelo `.gitignore` e nunca commitados.

## Não coberto por esta baseline

Execução em dispositivo/emulador real; testes E2E contra Supabase remoto;
performance; acessibilidade; segurança das políticas RLS em produção. Ficam para
a auditoria.
