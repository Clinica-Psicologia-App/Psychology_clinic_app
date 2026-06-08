# Master roadmap — Plataforma Terapia do Esquema

Visão consolidada do produto: materiais de wireframe/diagrama (referência cliente) × implementação atual do MVP no repositório.

**Última revisão:** 2026-06-07  
**Fontes:** ver [sources/README.md](./sources/README.md) · técnico: [next-steps.md](../next-steps.md), [mobile-app.md](../mobile-app.md), [scoring-engine/README.md](../scoring-engine/README.md)  
**Specs v3 (visão clínica):** [dashboard-v3-spec.md](./dashboard-v3-spec.md) · [mental-map-v3-spec.md](./mental-map-v3-spec.md)

---

## Legenda de status

| Status | Significado |
|--------|-------------|
| **Implementado** | Fluxo utilizável no app/backend documentado no repo |
| **Parcial** | Base existe; UX, escopo clínico ou integração incompletos |
| **Não iniciado** | Sem modelo de dados nem UI alinhados ao wireframe |

**Prioridade sugerida:** P0 (bloqueia MVP clínico) · P1 (valor alto pós-MVP) · P2 (médio) · P3 (futuro)

**Risco:** Baixo · Médio · Alto (clínico, LGPD, escopo ou arquitetura)

**PDF/tela:** `W` = Wireframe 19Abr2026 · `D` = Diagrama lógico · `W+D` = ambos (inferido pelo tipo de módulo até validação visual dos PDFs)

---

## Mapa de módulos

### Acesso e onboarding

| Módulo | Descrição funcional | PDF/tela | Status | Dependências técnicas | Prioridade | Risco |
|--------|---------------------|----------|--------|----------------------|------------|-------|
| **Acesso / Login** | Entrada por e-mail/senha; sessão JWT; redirect por `admin` / `psychologist` / `patient` | W+D | **Implementado** | Supabase Auth, `profiles`, RLS | — | Baixo |
| **Cadastro / aceite** | Cadastro de paciente/profissional, termos, consentimento LGPD, primeiro acesso | W | **Parcial** | Staff: `create-patient` legado + `create-patient-invitation`; paciente: `accept-patient-invitation`; profissional: `create-professional-account` com clínica pessoal opcional; sem e-mail real/reset/MFA | P1 | Alto (LGPD) |

### Jornada e registro clínico

| Módulo | Descrição funcional | PDF/tela | Status | Dependências técnicas | Prioridade | Risco |
|--------|---------------------|----------|--------|----------------------|------------|-------|
| **Anamnese** | Coleta estruturada de história clínica, contexto e dados iniciais do tratamento | W+D | **Não iniciado** | Novas tabelas/formulários versionados; RLS por paciente | P1 | Alto (dados sensíveis) |
| **Trilha / mapa do app** | Hub central da jornada do paciente (progresso, próximos passos, atalhos visuais) | W | **Parcial** | `patient_journey` + 10 passos; faltam módulos futuros | P1 | Médio |
| **Genograma** | Representação gráfica da família e relações para uso clínico | W+D | **Implementado (MVP lista)** | `genogram_people` + `genogram_relationships`; árvore gráfica futura | P2 | Médio |
| **Linha do tempo** | Eventos biográficos ou terapêuticos ordenados no tempo | W+D | **Implementado** | `patient_timeline_events`; trilha disponível/em andamento | — | Baixo |
| **Objetivos da terapia** | Metas acordadas, revisão periódica, vínculo com plano | W | **Implementado** | `therapy_goals` + Flutter; trilha integrada | — | Baixo |
| **Check-in** | Registro breve e frequente de estado (distinto de questionário longo) | W | **Implementado** | `patient_check_ins`; trilha concluído se feito hoje | — | Baixo |
| **Problemas** | Lista de queixas/focos de trabalho com prioridade e evolução | W+D | **Implementado** | `patient_problems` + Flutter; trilha Em andamento/Concluído | — | Baixo |

### Acompanhamento contínuo

| Módulo | Descrição funcional | PDF/tela | Status | Dependências técnicas | Prioridade | Risco |
|--------|---------------------|----------|--------|----------------------|------------|-------|
| **Monitor diário** | Paciente registra humor, sono, atividade, emoções; staff consulta histórico | W+D | **Implementado** | `daily_monitors`, RLS, UI paciente + staff | — | Baixo |
| **Questionários (hub)** | Listagem, início, resposta item a item, finalização via Edge Functions | W+D | **Implementado** | `questionnaires`, `start/submit/finish-questionnaire`, metadados clínicos e acesso por profissional | — | Baixo |

### Instrumentos (planilha / diagrama)

| Módulo | Descrição funcional | PDF/tela | Status | Dependências técnicas | Prioridade | Risco |
|--------|---------------------|----------|--------|----------------------|------------|-------|
| **YSQ** | Inventário de esquemas iniciais (`YSQ_FOUNDATION_V1`, 90 itens, período último ano) | W+D | **Parcial** | Catálogo + motor OK; homologação clínica e licença pendentes | P0 | Alto (clínico/legal) |
| **YAMI** | Modos esquemáticos (`YAMI_MODES_FOUNDATION_V1`, 124 itens, último mês) | W+D | **Parcial** | Idem YSQ; typos/duplicatas no catálogo (checklist P04–P10) | P0 | Alto (clínico/legal) |
| **Estilos Parentais** | Instrumento com múltiplas figuras parentais (`Mãe`, `Pai`, `Outro`) e progresso separado por contexto | W+D | **Parcial** | `questionnaire_response_contexts`, `response_context_id`, snapshot `parental-context-v1`; sem dashboard específico | P2 | Alto (conteúdo + licença) |
| **Estilos de Apego** | Instrumento da aba correspondente na planilha | W+D | **Implementado** | Catálogo + `question_scoring_rules`; painel real no dashboard; sem `severity_ranges` por falta de fonte documentada | P2 | Alto |
| **Estilos de Enfrentamento** | Instrumento de coping/enfrentamento (validar nome exato no PDF) | W+D | **Implementado** | `YCI_FOUNDATION_V1` e `YRAI_FOUNDATION_V1` com `question_scoring_rules`, painéis reais no dashboard e nó contextual compartilhado no mapa mental; sem `severity_ranges` por falta de fonte documentada | P2 | Médio |
| **Perguntas de Personalidade** | Bloco de personalidade na planilha do projeto | W+D | **Não iniciado** | Mapeamento pergunta → constructo; possível escala distinta | P2 | Alto |

### Apuração, visão clínica e conteúdo

| Módulo | Descrição funcional | PDF/tela | Status | Dependências técnicas | Prioridade | Risco |
|--------|---------------------|----------|--------|----------------------|------------|-------|
| **Motor de Apuração** | Cálculo estruturado por versão, esquemas/domínios, severidades; snapshot JSON | D (+ W staff) | **Implementado** | `questionnaire_versions`, regras, `finish-questionnaire`, `_shared/scoring/` | — | Médio (validação) |
| **Dashboarding / validação** | Gráficos, percentuais, comparação entre aplicações e instrumentos para staff | D (+ W) | **Parcial** | v2 mobile entregue; **v3 especificado** ([dashboard-v3-spec.md](./dashboard-v3-spec.md)): visão orientada ao caso, parentais por figura, comparativo longitudinal client-side, domínios YSQ — sem alterar banco/scoring | P1 | Médio |
| **Catálogo e liberação de instrumentos** | Mostrar autor/versão/licença e controlar quais instrumentos cada profissional pode usar | D | **Implementado (v1)** | `questionnaire_professional_access`, metadados em `questionnaires`, tela admin mobile | P1 | Médio |
| **Mapa Mental** | Visão integrada de esquemas, modos, problemas, objetivos, eventos e genograma em formulação visual do caso | W+D | **Parcial (v3 mobile)** | v3 M1–M5 entregue ([mental-map-v3-spec.md](./mental-map-v3-spec.md)): hub 8 nós, tabs Núcleo/História/Plano, sparkline, bottom sheet — sem tabelas novas, sem IA e sem inferência automática | P2 | Alto (escopo) |
| **Biblioteca** | Acervo de materiais da clínica; liberação e consumo pelo paciente | W+D | **Parcial** | `therapy_resources`, `patient_resource_access` — sem catálogo público nem busca avançada do wireframe | P1 | Baixo |
| **Sugestão Terapêutica** | Recomendações de intervenção/recursos com base em resultados; revisão do psicólogo | W+D | **Não iniciado** | Motor de regras (sem IA inicial); workflow de aprovação | P2 | Alto (clínico) |

---

## Comparação com MVP atual

### Já pronto (utilizável em demo/homologação)

- Autenticação e três perfis (`admin`, `psychologist`, `patient`) com RLS
- Onboarding público de profissional com clínica pessoal automática ou clínica/equipe
- Cadastro de paciente pelo staff (`create-patient`)
- Convite de paciente com link de primeiro acesso e aceite público no app
- Listagem e detalhe de pacientes; atalhos para módulos operacionais
- Fluxo completo de questionários (intro com `reference_period`, resposta, finalização)
- Catálogo com `autor`, `versão`, `período de referência` e observações internas de licença para staff
- Liberação de questionários por profissional, com gestão pelo admin
- Catálogo e apuração: `MVP_DEMO`, `YSQ_FOUNDATION_V1`, `YAMI_MODES_FOUNDATION_V1`, `ATTACHMENT_STYLES_V1`
- `PARENTAL_STYLES_V1` com seleção prévia de figuras parentais e progresso por contexto
- Resultados para staff: snapshot `scoring-demo-1`, banners por instrumento
- Recursos terapêuticos: biblioteca da clínica, liberação/revogação, progresso do paciente
- Monitor diário: CRUD paciente, leitura staff
- Documentação clínica-técnica: homologação, validação de catálogo, relatórios de importação

### Parcial (gap em relação aos materiais de referência)

| Área | No repo hoje | Gap provável vs wireframe/diagrama |
|------|----------------|-------------------------------------|
| YSQ / YAMI | Funcionais tecnicamente | Homologação, licença, correções de catálogo, instruções clínicas finais |
| Catálogo de instrumentos | Metadados e acesso por profissional no mobile | Sem billing e gestão de equipe |
| Cadastro / aceite | Convite mínimo + aceite público implementados; onboarding público de profissional com clínica opcional | Sem e-mail real, termos explícitos, reset de senha e MFA |
| Biblioteca | Liberação 1:1 | Wireframe pode prever catálogo maior, categorias, busca — **validar no PDF** |
| Dashboard | Home por instrumento + YSQ/YAMI/ATTACHMENT com barras | v3 spec cobre parentais por figura e comparativo; implementação pendente |
| Login | E-mail/senha seed | Sem recuperação de senha, MFA ou branding do wireframe — **validar no PDF** |
| Home paciente | Card da trilha + módulos de jornada | Hub clínico ainda concentrado em Mapa Mental e Dashboard |

### Ainda não iniciado (presente no inventário dos materiais)

- Anamnese, trilha central, genograma, linha do tempo
- Objetivos da terapia, check-in dedicado, problemas
- Estilos Parentais, Enfrentamento, Personalidade
- Sugestão terapêutica automatizada (regras + revisão humana)

### Implementado de forma diferente do wireframe (hipóteses — validar nos PDFs)

| Tema | MVP atual | Decisão pendente |
|------|-----------|------------------|
| Navegação paciente | Home com cards → módulos | Wireframe pode usar trilha/mapa único — **validar layout no PDF W** |
| Resultados | Somente staff vê apuração estruturada | Paciente vê só sucesso pós-questionário — wireframe mostra resultado ao paciente? |
| Monitor vs check-in | `daily_monitors` com campos texto/notas | Check-in pode ser UI mais curta ou escala fixa — **validar no PDF W** |
| Nomenclatura YAMI | Modos na seção “Esquemas” do snapshot | Copy/UI podem diverir do diagrama — ajuste de labels sem mudar motor |
| Staff e questionários | Psicólogo pode iniciar questionário pelo detalhe do paciente | Diagrama pode separar “aplicação” só pelo paciente — **validar papéis no PDF D** |
| Interpretação | Banner: validação pelo psicólogo; sem laudo automático | Alinhado a boa prática; wireframe pode prever texto interpretativo — **não implementar sem decisão clínica** |

---

## Roadmap recomendado

### Fase 1 — Fechar MVP clínico atual (P0)

- Homologação YSQ/YAMI ([clinical-homologation.md](../scoring-engine/clinical-homologation.md))
- Checklist de catálogo e licenciamento ([clinical-validation-checklist.md](../scoring-engine/clinical-validation-checklist.md))
- Correções via migrations versionadas (typos YAMI, reverse/peso se confirmados)
- Revisão de instruções e `reference_period` por instrumento
- Validar `author_name`, `instrument_version`, `citation` e `license_notes` com a equipe clínica
- `db push` remoto com migrations 014–016, 022, 023 e 024; ensaio de demo

**Saída:** instrumentos foundation utilizáveis com responsabilidade clínica documentada.

### Fase 2 — Trilha do paciente (P1)

- Tela central da jornada (progresso, pendências, atalhos)
- Navegação visual para questionários, monitor, biblioteca
- *Opcional:* resumo de “última atividade” sem expor interpretação clínica ao paciente

**Dependências:** definir o que o paciente pode ver além do staff (decisão PDF + LGPD).

### Fase 3 — Anamnese estruturada (P1)

- Cadastro clínico ampliado (além de `patients` atual)
- Objetivos da terapia
- Problemas principais
- Check-in (unificar ou separar do monitor diário)

**Dependências:** modelo de dados; formulários versionados; revisão com psicólogo responsável.

### Fase 4 — Genograma e linha do tempo (P2)

- Modelagem de dados (pessoas, relações, eventos)
- CRUD básico staff (+ permissão paciente se wireframe prever)
- Visualização inicial (lista ou grafo simples)

**Dependências:** decisão de escopo mínimo vs editor completo do wireframe.

### Fase 5 — Mapa mental (P2)

**v2 — entregue**

- [x] Agregação read-only (`features/mental_map/`) sem nova migration
- [x] Formulação Visual do Caso com centro clínico, camada principal e camada contextual
- [x] YSQ/YAMI/ATTACHMENT (últimos resultados + top scores), problemas/objetivos ativos, check-in, timeline e genograma integrados ao mapa
- [x] Hub radial responsivo com fallback em grid, navegação por nós e estados vazios

**v3 — entregue (2026-06-07)** ([mental-map-v3-spec.md](./mental-map-v3-spec.md))

- [x] Hub 8 nós em anéis principal + contextual (M1)
- [x] Legenda preenchido/pendente + indicador visual nos nós
- [x] Nó parentais + resumo estilo dominante por figura (`snapshot.contexts[]`)
- [x] Bottom sheet detalhe do nó (M5) com CTA para módulo
- [x] Tabs Núcleo / História / Plano (M2–M4)
- [x] Sparkline check-in (7 dias) na camada Plano
- [ ] Grafo interativo avançado, IA e relações inferidas automaticamente (fora de escopo)

**Dependências:** módulos base da trilha (implementados). **Sem** migration, scoring ou Edge Functions.

### Fase 6 — Dashboard clínico (P1–P2)

**v2 — entregue**

- [x] v1 mobile: barras YSQ/YAMI/ATTACHMENT a partir de `snapshot`, histórico básico, trilha + staff (sem recálculo)
- [x] Dashboard home com seções YSQ, YAMI, Estilos Parentais, Estilos de Apego, Estilos de Enfrentamento e Personalidade

**v3 — fatia 1 entregue (2026-06-07)** ([dashboard-v3-spec.md](./dashboard-v3-spec.md))

- [x] Visão clínica do caso (KPI + prioridades + destaques YSQ/YAMI/apego/enfrentamento)
- [x] Estilos parentais por figura a partir de `snapshot.contexts[]` (D3)
- [x] Sinais recentes, callouts orientativos, detalhes colapsáveis por instrumento
- [ ] Painéis por instrumento expandidos com agrupamento por domínio (D2/D5)
- [ ] Comparativo longitudinal client-side, staff only (D4)

**Dependências:** snapshots estáveis; regra staff vs paciente (DP-03).

### Fase 7 — Sugestão terapêutica (P2)

- Motor de regras (sem IA na v1)
- Psicólogo revisa e libera sugestão/recurso
- Auditoria do que foi sugerido vs aceito

**Dependências:** biblioteca populada; resultados homologados; governança clínica.

---

## Decisões pendentes (aguardam PDF ou workshop)

| ID | Tema | Por quê |
|----|------|---------|
| DP-01 | Colocar PDFs em `docs/product/sources/` | Validar nomes de telas e fluxos exatos |
| DP-02 | Check-in = monitor diário ou módulo novo? | Evitar duplicidade de UX |
| DP-03 | Paciente vê resultados estruturados? | LGPD + papel terapêutico |
| DP-04 | “Estilos de Enfrentamento” na planilha | Confirmar aba e código do instrumento |
| DP-05 | Escopo mínimo do genograma na v1 | Editor completo vs visualização somente leitura |
| DP-06 | IA em sugestão terapêutica | Fora de escopo até fase 7 estável sem IA |
| DP-07 | Catálogo global vs por clínica | Impacta migrations e RLS futuros |

---

## Rastreabilidade técnica

| Módulo implementado | Código / doc principal |
|---------------------|-------------------------|
| Auth | `mobile/lib/features/auth/`, migration `009` |
| Pacientes | `mobile/lib/features/patients/`, `create-patient`, `features/patient_invitations/` |
| Questionários | `mobile/lib/features/questionnaires/` |
| Motor | `supabase/functions/_shared/scoring/`, `finish-questionnaire` |
| Resultados | `mobile/lib/features/results/` |
| Mapa mental | `mobile/lib/features/mental_map/`, [mental-map-v3-spec.md](./mental-map-v3-spec.md) |
| Dashboard clínico | `mobile/lib/features/clinical_dashboard/`, [dashboard-v3-spec.md](./dashboard-v3-spec.md) |
| Biblioteca | `mobile/lib/features/therapy_resources/` |
| Monitor | `mobile/lib/features/daily_monitors/` |

Análise de gaps detalhada: [gap-analysis-from-wireframes.md](./gap-analysis-from-wireframes.md).

---

## Histórico

| Data | Alteração |
|------|-----------|
| 2026-06-07 | Mapa Mental v3 fatia 2 (M2–M4): tabs, sparkline, recursos |
| 2026-06-07 | Mapa Mental v3 fatia 1 (M1+M5): hub 8 nós, bottom sheet, parentais |
| 2026-06-07 | Specs Dashboard v3 e Mapa Mental v3; fases 5–6 atualizadas |
| 2026-05-31 | Versão inicial do master roadmap (PDFs não no repo; inventário por especificação + estado do código) |
