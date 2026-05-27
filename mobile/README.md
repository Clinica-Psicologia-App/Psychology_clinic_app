# Terapia do Esquema — Mobile (Flutter)

## Pré-requisitos

- Flutter SDK 3.16+
- Supabase local (`supabase start`) ou projeto remoto

## Configuração

1. Copie `env.example.json` → `env.local.json` e ajuste URL/anon key.
2. Instale dependências e gere pastas de plataforma (primeira vez):

```bash
cd mobile
flutter pub get
flutter create . --project-name terapia_esquema
```

> `flutter create .` preserva `lib/` e adiciona `android/`, `ios/`, etc.

## Executar

O projeto suporta **Android, iOS, Windows e Web**. Sem emulador, use Windows ou Chrome:

```powershell
cd mobile
supabase start

# Windows (recomendado no PC)
flutter run -d windows --dart-define-from-file=env.local.json

# Ou Chrome
flutter run -d chrome --dart-define-from-file=env.local.json

# Android (emulador: URL 10.0.2.2 automática no EnvConfig)
flutter run -d android --dart-define-from-file=env.local.json
```

Listar dispositivos: `flutter devices`

## Contas seed (local)

| Perfil | E-mail | Senha |
|--------|--------|-------|
| Admin | `admin@clinicateste-mvp.example` | `TesteMVP2025!` |
| Psicólogo | `psicologo@clinicateste-mvp.example` | `TesteMVP2025!` |
| Paciente | `paciente.login@clinicateste-mvp.example` | `TesteMVP2025!` |

Na tela de login, use os chips **Admin / Psicólogo / Paciente** para preencher.

## Estrutura

```text
lib/
  core/          config, errors, router, supabase, theme
  shared/        widgets reutilizáveis
  features/
    auth/        login, sessão, homes placeholder
    profile/     leitura do profile (RLS)
```
