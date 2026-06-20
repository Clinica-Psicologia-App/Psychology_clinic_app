# Assets de marca EsquemaCore

Arquivos oficiais (nomes exatos):

| Arquivo | Uso |
|---------|-----|
| `esquema_core_logo_principal.png` | Splash, login mobile, aceite de convite |
| `esquema_core_logo_horizontal.png` | Headers desktop, shell institucional |
| `esquema_core_icon.png` | Mark compacto, launcher icon |
| `esquema_core_logo_monochrome.png` | Fundos com gradiente de marca |

**Não** incluir a prancha completa da marca no app — apenas estes recortes.

Enquanto os PNGs não estiverem nesta pasta, o widget `EsquemaCoreLogo` usa fallback com gradiente institucional.

Após adicionar os arquivos:

```bash
cd mobile
flutter pub get
```

Launcher icon (somente após validar resolução ≥ 1024×1024, sem texto, margens adequadas):

```bash
dart run flutter_launcher_icons
```
