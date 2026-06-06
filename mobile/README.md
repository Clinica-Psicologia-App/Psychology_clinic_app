# Terapia do Esquema — Mobile (Flutter)

MVP mobile da Plataforma Terapia do Esquema.

## Demo

Siga na raiz do repositório:

- [docs/demo-checklist.md](../docs/demo-checklist.md)
- [docs/demo-script.md](../docs/demo-script.md)

## Pré-requisitos

- Flutter SDK 3.16+
- Supabase local (`supabase start`) ou projeto remoto com seed aplicada

## Configuração

```bash
cd mobile
cp env.example.json env.local.json
flutter pub get
```

Use `env.local.json` com URL e **anon key** do seu Supabase. A chave padrão embutida é só para `supabase start` local.

## Executar

```bash
# iOS Simulator
flutter run -d "iPhone 16 Pro" --dart-define-from-file=env.local.json

# Android emulador (127.0.0.1 → 10.0.2.2 automático)
flutter run -d android --dart-define-from-file=env.local.json
```

**Backend:** em outro terminal, `supabase functions serve` (questionários e cadastro de paciente).

## Contas demo (seed)

Senha: **`TesteMVP2025!`**

| Perfil | E-mail |
|--------|--------|
| Admin | `admin@clinicateste-mvp.example` |
| Psicólogo | `psicologo@clinicateste-mvp.example` |
| Paciente | `paciente.login@clinicateste-mvp.example` |

Chips na tela de login preenchem e-mail e senha.

## Build Android (APK debug)

| Campo | Valor |
|-------|--------|
| `applicationId` | `br.com.terapiaesquema.mvp` |
| Nome no launcher | Terapia do Esquema |
| Ícone | Padrão Flutter (`ic_launcher`) |

```bash
flutter build apk --debug --dart-define-from-file=env.local.json
```

Artefato: `build/app/outputs/flutter-apk/app-debug.apk`

Em **dispositivo físico**, troque `127.0.0.1` no `env.local.json` pelo IP da máquina na rede (Supabase acessível na LAN).

## Testes

```bash
flutter test
```

## Módulos

```text
lib/features/
  auth/                 login, sessão, homes
  patients/             staff — listagem, detalhe, create-patient (Edge)
  questionnaires/       Edge Functions
  results/              staff — leitura RLS + snapshot
  therapy_resources/    staff + paciente
  daily_monitors/       paciente + histórico staff
```

Documentação: [docs/mobile-app.md](../docs/mobile-app.md)
