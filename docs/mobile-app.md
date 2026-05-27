# App mobile Flutter — MVP Terapia do Esquema

Cliente iOS/Android com autenticação Supabase e navegação por `role` do profile.

## Localização no repositório

```text
mobile/
  lib/
    core/                 # config, erros, router, Supabase, rede (Edge Functions)
    shared/               # widgets compartilhados
    features/
      auth/               # login, sessão, telas home
      profile/            # leitura do próprio profile (RLS)
      patients/           # listagem, detalhe e cadastro (staff)
  env.example.json        # modelo de variáveis
  env.local.json          # gitignored — cópia local (não commitar produção)
```

## Configuração Supabase

| Variável | Origem |
|----------|--------|
| `SUPABASE_URL` | `--dart-define-from-file=env.local.json` |
| `SUPABASE_ANON_KEY` | idem |

Classe: `lib/core/config/env_config.dart`

- **iOS Simulator / desktop:** `http://127.0.0.1:54321`
- **Android Emulator:** `http://10.0.2.2:54321` (automático se não houver define)
- **Dispositivo físico:** IP da máquina na rede (ex.: `http://192.168.x.x:54321`)

Obter chaves locais:

```bash
supabase status -o json
```

## Autenticação e sessão

- `supabase_flutter` com **PKCE** e persistência nativa de sessão.
- Login: `signInWithPassword`.
- Ao abrir o app: `restoreSession()` → se JWT válido, busca `profiles`.
- Logout: `signOut()` + redirect para login.

## Profile e RLS

Após login, o app consulta o próprio profile:

```sql
SELECT id, clinic_id, role, full_name, email, is_active
FROM profiles WHERE id = auth.uid()
```

Demais tabelas respeitam RLS com o JWT do usuário (sem `service_role` no app).

## Navegação por role

| `profiles.role` | Home | Módulo pacientes |
|-----------------|------|------------------|
| `admin` | `/admin` | `/admin/patients`, `/admin/patients/new`, `/admin/patients/:id` |
| `psychologist` | `/psychologist` | `/psychologist/patients`, … |
| `patient` | `/patient` | **sem acesso** (redirect para home do paciente) |

Router: `go_router` + `authControllerProvider` (`lib/core/router/app_router.dart`).

Sub-rotas do staff ficam sob o prefixo da home (`/admin/...`, `/psychologist/...`).

## Módulo de pacientes (staff)

Feature: `lib/features/patients/` (`data` / `domain` / `presentation`).

| Tela | Função |
|------|--------|
| `PatientsPage` | Lista via `patients` + join em `profiles` (psicólogo e status de acesso) |
| `PatientDetailsPage` | Dados básicos + placeholders (questionários, recursos, monitores) |
| `CreatePatientPage` | Formulário → Edge Function `create-patient` |

**Listagem:** `PatientsRepository.listPatients()` — RLS filtra por clínica e, para psychologist, só pacientes com `responsible_psychologist_id = auth.uid()`.

**Cadastro:** `EdgeApiClient.invoke('create-patient')` — não insere direto em `patients`/`profiles`. Admin escolhe psicólogo; psychologist envia o próprio `id` como responsável.

**Status exibido:** derivado de `profile_id` + `profiles.is_active` (`Ativo`, `Inativo`, `Sem acesso ao app`).

**UX:** loading, empty, error com retry, pull-to-refresh, FAB “Novo paciente”, diálogo de confirmação após criação.

## Tratamento de erros

- `AppException` + `error_mapper.dart` traduz `AuthException` / `PostgrestException`.
- Edge Functions: `edge_api_client.dart` mapeia `{ ok: false, error: { code, message } }` para mensagens em português.
- UI: `ErrorBanner`, `AsyncStateBody`.

## Como rodar

```bash
cd mobile
flutter pub get
supabase start                                     # backend local
supabase functions serve                           # create-patient etc.

flutter run --dart-define-from-file=env.local.json
```

### Android — HTTP local

Em `android/app/src/main/AndroidManifest.xml`, no `<application>`:

```xml
android:usesCleartextTraffic="true"
```

### Testes

```bash
flutter test
```

Teste manual: login admin/psychologist → **Pacientes** na home → listar, cadastrar, abrir detalhe. Usuários seed: `docs/rls-test-plan.md`.

## Próximas integrações (fora desta etapa)

- Questionários via Edge Functions (`start-questionnaire`, …).
- Deep links / recuperação de senha.
- Tema clínico e acessibilidade.
