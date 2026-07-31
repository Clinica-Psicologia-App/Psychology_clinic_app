# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

```
App_Clinica_Psicologia/
├── mobile/        Flutter app (iOS, Android, web, Windows)
├── supabase/      Backend — migrations, edge functions (Deno/TypeScript), seed
├── docs/          Product docs, deploy guides, demo scripts
└── scripts/       Validation shell/SQL scripts
```

---

## Commands

All Flutter commands run from `mobile/`. A `--dart-define-from-file` env file is always required.

### Local backend

```bash
supabase start                    # start local Supabase stack
supabase db reset                 # reset DB and re-apply all migrations + seed.sql
supabase functions serve          # serve all edge functions (separate terminal)
```

### Flutter

```bash
cd mobile
cp env.example.json env.local.json   # fill SUPABASE_URL + SUPABASE_ANON_KEY

flutter pub get
flutter run --dart-define-from-file=env.local.json
flutter run -d android --dart-define-from-file=env.local.json

flutter test                         # all unit tests
flutter test test/some_test.dart     # single test file
flutter analyze
```

### Edge function tests (Deno)

```bash
cd supabase/functions
deno task test:scoring
deno task test:clinical-report
```

### Build vars (`--dart-define-from-file`)

| Key | Purpose |
|---|---|
| `SUPABASE_URL` | PostgREST + Auth base URL |
| `SUPABASE_ANON_KEY` | Public anon key (only key in the Flutter app) |
| `SHOW_TEST_ACCOUNTS` | `true` shows seed login chips on the login screen |
| `PASSWORD_RESET_REDIRECT_URL` | Deep-link target for password reset emails |

`env.local.json` and `env.production.json` are gitignored — never commit them.

### Seed accounts (password: `TesteMVP2025!`)

| Role | Email |
|---|---|
| `platformAdmin` | `admin@clinicateste-mvp.example` |
| `psychologist` | `psicologo@clinicateste-mvp.example` |
| `patient` | `paciente.login@clinicateste-mvp.example` |

---

## Architecture

### Feature module structure

Every feature under `mobile/lib/features/<feature>/` is divided into four layers:

```
<feature>/
  data/         *_repository.dart  — Supabase client + edge function calls
  domain/       Pure Dart models (no Flutter/Supabase imports)
  presentation/ Pages + widgets (ConsumerWidget / ConsumerStatefulWidget)
  providers/    Riverpod providers wiring repository → UI
```

### State management (Riverpod)

- **`Provider<Repository>`** — singleton for data-layer objects.
- **`FutureProvider` / `FutureProvider.family`** — read-only async queries.
- **`AsyncNotifier` / `FamilyAsyncNotifier`** — mutation providers that expose a method (`submit`, `start`, …), flip `state` through loading/data/error, then call `ref.invalidate(...)` to bust caches.
- **`StateNotifier`** — used only for `AuthController` (auth lifecycle).
- **`StateProvider`** — simple boolean flags (`authRedirectMessageProvider`, `passwordRecoveryActiveProvider`).

Notifiers hold no constructor args — all dependencies come from `ref.read(...)` inside methods.

### Router and role gating

`GoRouter` lives in `appRouterProvider`. A `redirect` callback checks `authControllerProvider` on every navigation.

Three roles are defined in `mobile/lib/features/profile/domain/profile_role.dart`:

| `ProfileRole` | DB string | Allowed prefix |
|---|---|---|
| `platformAdmin` | `platform_admin` / `admin` | `/platform/**` |
| `psychologist` | `psychologist` | `/psychologist/**` |
| `patient` | `patient` | `/patient/**` |

`RouteAccess` (static class) encodes all rules. Public paths are: `/`, `/onboarding`, `/login`, `/accept-invitation`, `/forgot-password`, `/update-password`, `/terms`, `/privacy`.

Pages shared between roles (e.g., `PatientsPage`) receive a `ProfileRole role` constructor param, so a single widget handles both contexts.

### Auth and Supabase session

- `SupabaseBootstrap.initialize()` (called in `main()`) configures PKCE flow with auto-refresh.
- `AuthController` listens to `authStateChanges`. On sign-in it calls `ProfileRepository.fetchCurrentProfile()` which reads `profiles` (RLS-filtered to the caller's own row).
- `passwordRecoveryActiveProvider = true` locks the router to `/update-password` until the password is changed.
- The **anon key** is the only Supabase credential ever compiled into Flutter. The `service_role` key is exclusively used inside Deno edge functions.

### Calling edge functions from Flutter

`EdgeApiClient` (`mobile/lib/core/network/edge_api_client.dart`) wraps `supabase.functions.invoke()`. All responses follow the shape:

```json
{ "ok": true,  "data": { ... } }
{ "ok": false, "error": { "code": "...", "message": "...", "details": {} } }
```

Errors map to `AppException` via `mapEdgeErrorPayload`. Repositories call it as:

```dart
final data = await _edgeApi.invoke('function-name', body: { ... });
```

### Edge function internals (Deno)

Shared utilities live in `supabase/functions/_shared/`:

- `supabase.ts` — `createUserClient(authHeader)` forwards the Flutter JWT (inherits RLS); `createServiceClient()` bypasses RLS (service role only).
- `auth.ts` — `getCallerProfile`, `requireStaff`, `assertPatientAccess`, `assertPsychologistCanReceivePatient`.
- `http.ts` — `handleOptions` (CORS), `requirePost`, `parseJsonBody`, `handleError`.
- `errors.ts` — `AppError(code, status, details)`.

### Database conventions

- RLS is enforced on every table. Helper SQL functions (`current_clinic_id()`, `current_role()`, `user_can_access_patient(p_patient_id)`, `is_staff()`) centralize policy logic and are reused across migrations.
- Migrations are numbered chronologically in `supabase/migrations/`. The seed file is `supabase/seed.sql`.
- Key tables: `profiles`, `patients`, `questionnaires`, `questionnaire_versions`, `questionnaire_responses`, `questionnaire_professional_access`, `patient_invitations`, `therapy_goals`, `patient_problems`, `patient_check_ins`, `patient_timeline_events`.
- RPCs used from Flutter: `set_patient_active_status`, `delete_patient_as_admin`, `get_current_clinic_entitlements`.

### Clinic entitlements

`get_current_clinic_entitlements()` RPC returns a map of feature flags for the caller's clinic. `ClinicFeatureEntitlements.isEnabled(key)` defaults to `true` when a key is absent (permissive fallback). The `FutureModulesSection` widget gates feature cards on this.

### Clinical feature access flow (questionnaires example)

Admin configures which questionnaires a psychologist can use (`questionnaire_professional_access` table — INSERT/UPDATE/DELETE restricted to `platformAdmin` by RLS). The psychologist then sees only their granted questionnaires when opening a patient's detail page. The `start-questionnaire` edge function creates a `questionnaire_responses` row; access is validated at the DB level via `user_can_access_patient`.
