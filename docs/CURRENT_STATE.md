# Estado atual — EsquemaCore

## Atualização de 2026-10-20 — ajustes pós-teste

Na branch `audit/astra`, os sete ajustes de Guacira/Luciana foram implementados.
Validação inicial: 46 testes direcionados aprovados; suíte mais recente com **492 aprovados,
sem falhas**; analyzer sem errors, com 12 warnings e 132 infos em trechos preexistentes.
Persistência pelo contrato REST remoto validada com um novo psicólogo e paciente
sintéticos em clínica isolada: criação, cinco atualizações/releituras, bloqueio
de leitura anônima e limpeza aprovados. Script com 8 testes locais aprovados.
Homologação do formulário Android aprovada em emulador de 360 × 640: gravação
por etapa no mesmo registro, reabertura após encerrar o processo, erro com a rede
desligada e nova tentativa sem redigitar. Avaliação sintética removida após a
conferência. Isolamento autenticado homologado em 101 casos de pacientes,
questionários e personalidade, com duas clínicas e cinco contas descartáveis.
Não é cobertura completa dos demais módulos.
A conta demo antiga retornou `invalid_credentials`.
Veja [procedimento e evidências](qa/personality-remote-smoke.md).
Na continuação, o Top 5 passou a excluir resultados sem média, evitando comparar
pontos brutos com médias em snapshots legados. Os detalhes permanecem disponíveis.
Veja [escopo, evidências e limitações](post-test-guacira-luciana-2026-10-20.md).
Panorama YSQ/YAMI conferido no Android com duas aplicações sintéticas processadas
pelas Edge Functions: Top 5 por média, nomes sem códigos, pontos secundários,
YAMI sem bloco duplicado e barras do consolidado lilás/cinza aprovados. A
orientação de ativação e os símbolos ainda vermelhos foram alinhados ao lilás.
Veja [homologação do Panorama](qa/panorama-ysq-yami-smoke.md).
NEO no Infográfico aprovado no Android com os cinco domínios e cores esperadas.
No Mapa Mental, o nó Personalidade agora fica acessível em cartão abaixo do
diagrama, com o resumo e detalhe existentes. Abertura, três cores e atalho para
a lista de avaliações aprovados no Android; layouts de 360/900 e cartão vazio
cobertos por testes. Quinze testes direcionados aprovados. A órbita antiga
tem overflow com texto ampliado em 1,6, documentado em `TECH_DEBT.md`.
O Panorama atual não exibe NEO. Veja [evidências e limites](qa/neo-domain-colors-smoke.md).
Permissões remotas: acesso entre clínicas e responsáveis bloqueado; gates de
liberação/revogação YSQ e compartilhamento NEO aprovados, incluindo proteção
dos campos privados. Conjunto descartável integralmente removido, sem alterar
policies. Veja [matriz e limites](qa/clinical-access-remote-smoke.md).
A primeira falha conhecida da suíte foi corrigida no teste de mapa sem dados:
a expectativa de quatro nós de contexto estava desatualizada após incluir
Personalidade. Agora são conferidos os cinco módulos e o estado pendente, sem
alterar o builder. Os 47 testes direcionados do mapa passaram. A falha da jornada
também foi corrigida somente no teste: a ordem esperada de Problemas e demandas
estava desatualizada. Os 19 testes de jornada passaram, preservando a implementação
existente. A expectativa antiga de dois títulos na biblioteca também foi corrigida
somente no teste. Os três testes de indicação passaram, incluindo fechamento do
formulário e permanência no mesmo catálogo. Os quatro timeouts da home foram
resolvidos somente na preparação dos testes: o card do plano tem animação contínua,
incompatível com `pumpAndSettle`. Agora são renderizados dois segundos em passos
de 100 ms, preservando as verificações e a animação real. Os oito testes das homes
passaram. As sete falhas inicialmente conhecidas estão resolvidas na suíte atual.

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
