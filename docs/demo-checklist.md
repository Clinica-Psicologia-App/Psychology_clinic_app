# Checklist de demo — MVP Terapia do Esquema

Use este documento para subir o ambiente **do zero** antes de uma demonstração técnica ou homologação com cliente.

**Homologação formal (pacote completo):** [demo/final-mvp-homologation.md](./demo/final-mvp-homologation.md)  
**Deploy remoto:** [deploy/supabase-deploy-checklist.md](./deploy/supabase-deploy-checklist.md) · [deploy/mobile-build-checklist.md](./deploy/mobile-build-checklist.md)

---

## Pré-requisitos

| Ferramenta | Versão sugerida |
|------------|-----------------|
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | Em execução |
| [Supabase CLI](https://supabase.com/docs/guides/cli) | 2.x |
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | 3.16+ |
| Xcode (iOS) ou Android SDK | Para dispositivo/emulador |

Opcional: Deno (`deno task test:scoring`), PowerShell (`edge-functions-flow.ps1`).

---

## 1. Backend local

Na raiz do repositório:

```bash
cd /caminho/para/Aplicativo-Clinica-Psicologia

supabase start
supabase db reset
supabase functions serve
```

Deixe `supabase functions serve` em um terminal separado (5 funções, incl. `generate-clinical-report`).

### Conferir Supabase

```bash
supabase status
```

| Variável | Valor local típico |
|----------|-------------------|
| URL | `http://127.0.0.1:54321` |
| Anon key | (saída de `supabase status`) |

### Teste rápido

```bash
cd mobile && flutter test
# Opcional: ./supabase/tests/edge-functions-flow.ps1
```

---

## 2. App mobile

```bash
cd mobile
cp env.example.json env.local.json
flutter pub get
flutter run --dart-define-from-file=env.local.json
```

**Android emulador:** `127.0.0.1` no JSON (app usa `10.0.2.2` internamente).  
**Dispositivo físico:** IP LAN ou Supabase cloud — ver [mobile-build-checklist.md](./deploy/mobile-build-checklist.md).

### APK debug

```bash
cd mobile
flutter build apk --debug --dart-define-from-file=env.local.json
# → build/app/outputs/flutter-apk/app-debug.apk
```

---

## 3. Usuários de teste (seed)

Senha para todos: **`TesteMVP2025!`**

| Perfil | E-mail | Nome na UI |
|--------|--------|------------|
| Admin | `admin@clinicateste-mvp.example` | Ricardo Mendes (admin demo) |
| Psicólogo | `psicologo@clinicateste-mvp.example` | Dra. Ana Costa (psicóloga demo) |
| Paciente | `paciente.login@clinicateste-mvp.example` | Maria Silva (paciente demo) |

Paciente: `patients.id` `11111111-1111-1111-1111-111111111201`.

> Dados fictícios (`@clinicateste-mvp.example`, CPF `00000000191`).

---

## 4. Dados pré-carregados na seed

| Módulo | O que existe antes da demo ao vivo |
|--------|-------------------------------------|
| Pacientes | 1 paciente (Maria Silva) |
| Questionários | `MVP_DEMO` (5 itens); **YSQ** + **YAMI** (migrations 014–015) |
| Resultados | 1 resposta `MVP_DEMO` concluída + snapshot |
| Recursos | 3 na biblioteca; 1 já liberado |
| Monitor diário | 1 registro de ontem |
| Trilha / módulos clínicos | Vazios até o paciente criar na demo |

---

## 5. Fluxo por perfil (validação rápida)

### Admin / Psicólogo

- [ ] Login → home staff
- [ ] **Pacientes** → Maria Silva
- [ ] **Resultados** → snapshot legível + disclaimer
- [ ] **Dashboard clínico** / **Mapa mental** (se YSQ/YAMI concluídos)
- [ ] **Objetivos, problemas, check-ins, timeline, genograma** (após paciente criar)
- [ ] **Recursos** → liberar item da biblioteca
- [ ] **Gerar relatório** → PDF abre ou salva
- [ ] Logout

### Paciente

- [ ] Login → home `/patient`
- [ ] **Trilha** → navegar 2+ módulos (ex.: objetivo, check-in)
- [ ] **Questionários** → `MVP_DEMO` ou amostra YSQ/YAMI
- [ ] **Meus recursos** + **Monitor diário**
- [ ] **Mapa mental** + **Dashboard clínico** (banners de validação)
- [ ] Logout

### Segurança (smoke)

- [ ] Paciente → URL `/admin/patients` redireciona para `/patient`
- [ ] Staff → URL `/patient/journey` redireciona para home staff
- [ ] Paciente **não** vê “Gerar relatório”

---

## 6. Demo com Supabase remoto

1. [supabase-deploy-checklist.md](./deploy/supabase-deploy-checklist.md): `link`, `db push`, seed, `functions deploy`
2. `mobile/env.production.json` (ou `env.local.json`) com URL + anon do projeto
3. `flutter run --dart-define-from-file=env.production.json`

---

## 7. Erros conhecidos

| Sintoma | Causa provável | Ação |
|---------|----------------|------|
| HTTP 500 no login | Seed auth desatualizada | `supabase db reset` |
| Questionário não inicia | Functions paradas | `supabase functions serve` ou deploy |
| PDF falha | Idem | Deploy `generate-clinical-report` |
| Lista vazia | RLS / env errado | `db reset`; conferir anon key |
| APK não alcança API | `127.0.0.1` no device físico | IP LAN ou cloud |

---

## 8. Critério de aceite da demo

- [ ] `supabase db reset` sem erro
- [ ] `flutter test` verde
- [ ] Roteiro [demo-script.md](./demo-script.md) ou [final-mvp-homologation.md](./demo/final-mvp-homologation.md) executável
- [ ] APK debug gerado (se demo Android)

---

Roteiro falado: [demo-script.md](./demo-script.md)
