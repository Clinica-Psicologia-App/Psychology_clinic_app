# Dívida técnica — EsquemaCore

> Observações do diagnóstico **2026-09-11**, com evidência no código. **Nada foi
> corrigido** (ver `AGENTS.md`). Severidade aproximada: CRITICAL / HIGH / MEDIUM / LOW.
> Não há problemas CRITICAL confirmados nesta baseline.

## CRITICAL

_Nenhum confirmado._ Verificações feitas que **não** revelaram problema crítico:
sem secrets versionados (nenhum JWT/`service_role` em `mobile/lib` além da anon
key pública local do `supabase start`); dumps de produção `backup_prod_*.sql`
ignorados pelo `.gitignore` e nunca commitados; RLS presente em todas as tabelas.

## HIGH

- **Observabilidade ausente.** Zero `print`/`debugPrint`/telemetria em
  `mobile/lib` — não há rastro de diagnóstico em produção. Falhas em runtime só
  aparecem como estado de erro na UI (`core/errors/`), sem log persistido.
- **Handlers HTTP das Edge Functions sem teste.** Os testes Deno cobrem só a
  lógica `_shared` (`deno task test:scoring`, `test:clinical-report`); os 15
  handlers em `supabase/functions/*/index.ts` não têm teste automatizado. Áreas
  privilegiadas (usam `service_role`) sem rede de segurança de teste.
- **Backend não validado nesta máquina.** Deno não instalado → testes de edge não
  rodaram; banco/RLS não iniciado. Conclusões sobre scoring/RLS dependem de rodar
  o que está descrito em `docs/CURRENT_STATE.md`.

## MEDIUM

- **Arquivos de UI muito grandes** (dificultam revisão/auditoria):
  `clinical_dashboard/presentation/widgets/clinical_dashboard_widgets.dart` (2431),
  `auth/presentation/role_home_shell.dart` (2280),
  `mental_map/presentation/case_conceptualization_page.dart` (1625),
  `auth/presentation/login_page.dart` (1613),
  `patients/presentation/patient_details_page.dart` (1568) — e outros >1000 linhas.
- **Mapa Mental agregado no cliente.** `MentalMapRepository` combina vários
  repositórios em `MentalMapData` no app (N chamadas). Relevante para o painel web
  e para performance — avaliar view/função SQL agregada.
- **Responsividade e acessibilidade não auditadas.** Breakpoints existem
  (`core/theme/app_breakpoints.dart`) mas não há verificação de layout em
  dispositivo nem de `Semantics`/contraste/foco.

## LOW

- **99 avisos do analyzer (todos `info`).** Cosméticos; CI usa `--no-fatal-infos`.
  Em código de produção: `prefer_const_constructors` em
  `shared/widgets/app_empty_state.dart:53`; `depend_on_referenced_packages`
  (`features/user_management/domain/clinic_user.dart:1` importa `characters` sem
  declarar); `curly_braces_in_flow_control_structures` em
  `shared/widgets/icon_optics.dart:17,19`. O restante é em testes.
- **1 TODO real:** `features/life_story/presentation/my_timeline_page.dart:839`
  (`// TODO: rota de edição do evento`).
- **Arquivos avulsos versionados:** `qids.txt` e `rid.txt` na raiz contêm UUIDs de
  seed/teste — lixo de desenvolvimento rastreado no git (sem dado sensível, mas
  não deveriam estar versionados).
- **Anon key local hardcoded** em `mobile/lib/core/config/env_config.dart:20` — é
  a demo key pública do `supabase start` (não é segredo); `EnvConfig.validate`
  impede seu uso em release. Documentar para não confundir auditor.
- **114 migrations acumuladas** — sem problema funcional; pesa em `db reset`/onboarding.

## Não é dívida (funciona como projetado)

447 testes verdes; analyzer sem erros; fronteira anon/service_role bem definida;
estrutura de 4 camadas consistente nos 33 módulos; CI cobrindo Flutter, Edge
Functions e banco; tratamento de erros estruturado (`AppException`/`error_mapper`).
