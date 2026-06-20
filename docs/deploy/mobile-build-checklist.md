# Checklist de build — App mobile (MVP)

Use antes de entregar APK de homologação, demo presencial ou preparação de release.

**Homologação completa:** [final-mvp-homologation.md](../demo/final-mvp-homologation.md)

---

## Identidade do app (MVP)

| Item | Valor |
|------|--------|
| Nome no launcher | **Terapia do Esquema** |
| `applicationId` (Android) | `br.com.terapiaesquema.mvp` |
| Versão pubspec | `0.1.0+1` (`mobile/pubspec.yaml`) |
| Pacote Dart | `terapia_esquema` |

- [ ] AndroidManifest `android:label` = Terapia do Esquema
- [ ] iOS: conferir `CFBundleDisplayName` em `ios/Runner/Info.plist` se build iOS

Ícone: padrão Flutter MVP (substituir antes de loja — fora deste checklist).

---

## 1. Qualidade de código

Na pasta `mobile/`:

```bash
flutter pub get
flutter analyze
flutter test
```

- [ ] `flutter analyze` sem erros bloqueantes
- [ ] `flutter test` verde (suite completa; ~110 testes)
- [ ] Sem secrets em arquivos commitados (`env.local.json` gitignored)

---

## 2. Configuração de ambiente

### Arquivos

| Arquivo | Uso | Commitar? |
|---------|-----|-----------|
| `env.example.json` | Modelo local (127.0.0.1 + anon demo) | Sim |
| `env.local.json` | Dev / demo na máquina | **Não** |
| `env.android.json` | Emulador Android (`10.0.2.2`) | Opcional (template) |
| `env.production.json` | Homologação/staging remoto | **Não** (criar localmente) |

### Criar config local

```bash
cd mobile
cp env.example.json env.local.json
# Editar SUPABASE_URL e SUPABASE_ANON_KEY
```

### Criar config homologação remota

```bash
cp env.example.json env.production.json
```

Preencher com valores do Dashboard Supabase (Project URL + anon public):

```json
{
  "SUPABASE_URL": "https://<PROJECT_REF>.supabase.co",
  "SUPABASE_ANON_KEY": "<anon_public_key>"
}
```

- [ ] Apenas `SUPABASE_URL` + `SUPABASE_ANON_KEY`
- [ ] **Sem** `service_role` ou chaves de serviço

Leitura no app: `--dart-define-from-file=env.local.json` (ou `env.production.json`).

---

## 3. Run desenvolvimento

```bash
cd mobile
flutter run --dart-define-from-file=env.local.json
```

Variantes:

```bash
# Android emulador (host 10.0.2.2)
flutter run --dart-define-from-file=env.android.json

# Homologação remota
flutter run --dart-define-from-file=env.production.json
```

- [ ] Login admin, psicólogo e paciente OK
- [ ] Questionário finaliza (Edge Functions acessíveis)
- [ ] Gerar PDF (staff) OK

---

## 4. Build debug APK (homologação / demo)

```bash
cd mobile
flutter build apk --debug --dart-define-from-file=env.local.json
```

Saída: `build/app/outputs/flutter-apk/app-debug.apk`

- [ ] APK instala em dispositivo/emulador
- [ ] Se dispositivo **físico**: URL Supabase = IP LAN ou cloud (não `127.0.0.1`)

Instalar:

```bash
adb install build/app/outputs/flutter-apk/app-debug.apk
```

---

## 5. Build release (futuro — pós-homologação MVP)

**Não obrigatório** para homologação funcional; preparar quando for loja.

### Android release

1. Criar o keystore de upload fora do repositório.
2. Copiar `android/key.properties.example` para `android/key.properties`.
3. Preencher senhas, alias e caminho do keystore. Não commitar esses arquivos.
4. Build:

```bash
flutter build appbundle --release --dart-define-from-file=env.production.json
# ou
flutter build apk --release --dart-define-from-file=env.production.json
```

- [ ] ProGuard/R8 revisado se ativado
- [ ] `android/key.properties` configurado; release nunca usa chave debug
- [ ] `SUPABASE_URL` de release usa HTTPS e foi passada explicitamente
- [ ] `applicationId` final definido (pode sair de `.mvp` para produção)
- [ ] Política de privacidade / LGPD alinhada ao cliente

### iOS release (rascunho)

- [ ] Certificados Apple Developer
- [ ] `flutter build ipa --release --dart-define-from-file=env.production.json`
- [ ] TestFlight antes de App Store

---

## 6. Checklist funcional pós-build

Executar no binário instalado (não só `flutter run`):

| # | Fluxo | OK |
|---|--------|-----|
| 1 | Login 3 perfis | ☐ |
| 2 | Trilha → 2 módulos (ex.: objetivo + check-in) | ☐ |
| 3 | Questionário demo → finalizar | ☐ |
| 4 | Staff → resultados + dashboard | ☐ |
| 5 | Staff → gerar PDF | ☐ |
| 6 | Logout / re-login | ☐ |

Roteiro detalhado: [demo-script.md](../demo-script.md).

---

## 7. Erros comuns

| Sintoma | Causa | Correção |
|---------|-------|----------|
| Network error no login | URL errada / Supabase parado | `supabase status` ou URL cloud |
| 127.0.0.1 no celular físico | Loopback do device | IP da máquina ou cloud |
| Questionário trava | Functions não deployadas | Deploy + `functions serve` |
| PDF falha | Mesma causa | Deploy `generate-clinical-report` |
| Gradle fail | SDK/JDK | `flutter doctor -v` |

---

## 8. Critério de aceite build mobile

- [ ] `flutter test` + `flutter analyze` OK
- [ ] `env.*.json` correto para o alvo (local vs remoto)
- [ ] APK debug gerado e testado **ou** `flutter run` validado na demo
- [ ] Identidade app (nome + applicationId) conferida
- [ ] Homologação staff + PDF executada no build entregue

---

Ver também: [mobile-app.md](../mobile-app.md) · [demo-checklist.md](../demo-checklist.md)
