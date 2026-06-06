# Auditoria funcional — MVP Terapia do Esquema

**Data:** 2026-06-04  
**Escopo:** comparar o que está implementado no repositório com o [master roadmap](../product/master-roadmap.md), os wireframes e o diagrama lógico da clínica (referências de produto).  
**Tipo:** auditoria **documental** — sem alteração de código, banco ou app.

---

## Metodologia

| Fonte | O que foi usado |
|-------|-----------------|
| **Roadmap** | [master-roadmap.md](../product/master-roadmap.md) — status por módulo, fases 1–7, decisões pendentes |
| **Wireframes** | `Wireframe App Esquemas 19Abr2026.drawio.pdf` (referência W) — **não presente no repo**; hipóteses de [gap-analysis-from-wireframes.md](../product/gap-analysis-from-wireframes.md) §3 |
| **Diagrama clínico** | `Diagrama APP Esquemas.pdf` (referência D) — **não presente no repo**; relações instrumento → apuração → visão clínica inferidas do roadmap |
| **Implementação** | [mobile-app.md](../mobile-app.md), migrations `001–021`, Edge Functions, [qa/post-roadmap-stabilization.md](../qa/post-roadmap-stabilization.md) |
| **Clínico** | [clinical-homologation.md](../scoring-engine/clinical-homologation.md), [clinical-validation-checklist.md](../scoring-engine/clinical-validation-checklist.md) |

**Escala de maturidade (0–100):**

| Faixa | Significado |
|-------|-------------|
| 80–100 | Alinhado ao objetivo do material; utilizável em homologação com gaps menores |
| 60–79 | Funcional no MVP; gaps relevantes vs wireframe/diagrama ou clínica |
| 40–59 | v1 mínima; grande parte da visão de produto ainda por fazer |
| 0–39 | Não iniciado ou só esboço |

**Limitação:** sem PDFs em [product/sources/](../product/sources/README.md), diferenças de **layout, microcopy e ordem exata de telas** permanecem marcadas como *validar no wireframe*.

---

## Resumo executivo

### Pronto para homologação funcional (demo + sessão clínica supervisionada)

Fluxos utilizáveis de ponta a ponta, com RLS e testes automatizados, sujeitos a validação clínica onde aplicável:

| Módulo | Nota | Observação |
|--------|------|------------|
| Questionários (fluxo técnico) | 78 | YSQ/YAMI exigem homologação de conteúdo, não de pipeline |
| Resultados (staff) | 72 | Snapshot estruturado + disclaimers |
| Objetivos da terapia | 75 | CRUD paciente/staff + trilha |
| Problemas | 75 | CRUD + intensidade + status |
| Check-in | 70 | Distinto do monitor; staff só leitura |
| Monitor diário | 72 | CRUD paciente; histórico staff |
| Linha do tempo | 78 | CRUD paciente/staff |
| Biblioteca (core) | 68 | Liberar/consumir; sem catálogo avançado |

### Parcial (homologação possível com ressalvas explícitas)

| Módulo | Nota | Principal ressalva |
|--------|------|-------------------|
| Trilha do paciente | 65 | Hub funcional; UX provavelmente abaixo do wireframe visual |
| Dashboard clínico | 55 | v1 mobile; sem web, % ou evolução longitudinal |
| Mapa mental | 50 | Agregador read-only; diagrama prevê visão integrada mais rica |
| Genograma | 58 | Lista + relações; wireframe/diagrama prevê representação gráfica |
| Relatório PDF | 62 | Staff only; sem Storage/e-mail/assinatura; PT parcial no PDF |
| YSQ / YAMI (como produto clínico) | 45* | *Contam dentro de Questionários/Resultados/Dashboard — catálogo no ar, homologação pendente |

### Não iniciado (presente no roadmap/diagrama, ausente no app)

| Item | Referência |
|------|------------|
| Anamnese estruturada | Roadmap Fase 3 · W+D |
| Estilos Parentais, Apego, Enfrentamento, Personalidade | Roadmap instrumentos · planilha |
| Sugestão terapêutica (regras + revisão) | Roadmap Fase 7 · diagrama |
| Dashboard web | Roadmap Fase 6 |
| IA / interpretação automática / laudo | Explícito fora do MVP |
| Onboarding LGPD / termos / aceite paciente | Wireframe hipótese D3 |
| Recuperação de senha / MFA | Gap login |

---

## Auditoria por módulo

---

### 1. Trilha do paciente

| Campo | Conteúdo |
|-------|----------|
| **Objetivo esperado (roadmap / W / D)** | Hub central da jornada: progresso, próximos passos, atalhos visuais para questionários, monitor, biblioteca e módulos clínicos (W). Diagrama: paciente percorre instrumentos e registros contínuos em torno do plano terapêutico (D). |
| **O que foi implementado** | `PatientJourneyPage` com **10 passos**; status Disponível / Em andamento / Concluído; navegação para módulos reais; `JourneyPlaceholderPage` para bloqueados/futuros; agregação de progresso via `PatientJourneyRepository` (questionários, monitor do dia, recursos, objetivos, problemas, check-in, timeline, genograma, YSQ/YAMI). Home paciente: card **Meu plano terapêutico** → `/patient/journey`. |
| **O que está faltando** | Trilha **visual** tipo mapa/wireframe (ilustração, ordem narrativa forte); ordem **obrigatória** de passos (DN-03); passos futuros ainda genéricos; resumo “próximo instrumento recomendado”; integração com anamnese (inexistente). |
| **Limitações atuais** | Progresso heurístico (ex.: check-in “concluído” = feito hoje); sem gamificação; sem notificações/pendências push. |
| **Dependências futuras** | Decisão LGPD sobre o que o paciente vê (DN-01); anamnese como passo formal; PDFs no repo para validar layout W. |
| **Maturidade** | **65 / 100** |

---

### 2. Questionários

| Campo | Conteúdo |
|-------|----------|
| **Objetivo esperado** | Hub de instrumentos: listar, orientar período de referência, responder item a item, finalizar com apuração (W+D). Diagrama: YSQ, YAMI e demais blocos da planilha alimentam o motor de scores (D). |
| **O que foi implementado** | Fluxo completo via Edge Functions (`start` / `submit` / `finish`); intro com `reference_period`; Likert/numeric; staff pode aplicar no paciente; catálogo: `MVP_DEMO`, `YSQ_FOUNDATION_V1`, `YAMI_MODES_FOUNDATION_V1`; motor em `finish-questionnaire` + `_shared/scoring/`; snapshot JSON persistido. |
| **O que está faltando** | Instrumentos **Parentais, Apego, Enfrentamento, Personalidade**; homologação clínica formal YSQ/YAMI; licenciamento; correções de catálogo (typos YAMI, etc.); recuperação de sessão interrompida explícita na UI; perguntas `text` sem resposta numérica. |
| **Limitações atuais** | YSQ (90) e YAMI (~124) longos para demo rápida; scores **não validados** clinicamente; staff e paciente podem iniciar (validar se diagrama restringe a D6). |
| **Dependências futuras** | Migrations de importação por instrumento; checklist [clinical-validation-checklist.md](../scoring-engine/clinical-validation-checklist.md); decisão DN-04 (quais instrumentos em produção). |
| **Maturidade** | **78 / 100** (pipeline) · **45 / 100** (aceite clínico YSQ/YAMI) |

---

### 3. Resultados

| Campo | Conteúdo |
|-------|----------|
| **Objetivo esperado** | Staff visualiza respostas e apuração por esquema/modo/domínio; base para decisão clínica (D). Wireframe pode incluir painéis gráficos (W — hipótese D2). |
| **O que foi implementado** | `PatientResultsPage` + detalhe; lista de respostas; snapshot `scoring-demo-1` (resumo, domínios, esquemas, itens, severidades); banners por `questionnaire.code`; fallback legado `mvp-1`; **somente staff**; RLS. |
| **O que está faltando** | Gráficos no detalhe de resultados (gráficos estão no **Dashboard**, não aqui); export PDF por resposta (PDF é relatório agregado separado); comparativo entre aplicações; visão paciente (DN-01 / DP-03). |
| **Limitações atuais** | Sem interpretação textual; sem laudo; nomenclatura YAMI às vezes sob rótulo “esquemas” no snapshot (D4). |
| **Dependências futuras** | Homologação de severidades; decisão se paciente vê resumo neutro; dashboard web Fase 6. |
| **Maturidade** | **72 / 100** |

---

### 4. Dashboard clínico

| Campo | Conteúdo |
|-------|----------|
| **Objetivo esperado** | Dashboarding: gráficos, percentuais, comparação entre aplicações e instrumentos para validação clínica (D + W). |
| **O que foi implementado** | `clinical_dashboard` v1: último YSQ/YAMI, top esquemas/modos, barras horizontais, severidade, data, histórico básico; paciente (trilha) + staff; lê `snapshot` sem recálculo; disclaimer de validação clínica. |
| **O que está faltando** | Dashboard **web**; percentuais; evolução longitudinal; comparativo multi-instrumento; painel staff unificado tipo wireframe; materialized views / agregados server-side. |
| **Limitações atuais** | Gráficos simples (barras); empty states quando sem YSQ/YAMI; uso clínico **pré-homologação** explícito na UI. |
| **Dependências futuras** | Snapshots estáveis pós-homologação; métricas acordadas com equipe clínica; Fase 6 roadmap. |
| **Maturidade** | **55 / 100** |

---

### 5. Mapa mental

| Campo | Conteúdo |
|-------|----------|
| **Objetivo esperado** | Visão integrada de esquemas, modos, estilos, problemas e plano — visão “mental map” do diagrama (W+D). |
| **O que foi implementado** | `mental_map` v1: agregador **read-only** (questionários YSQ/YAMI, problemas/objetivos ativos, check-in, monitor, timeline, genograma); paciente + staff; disclaimer; sem migration própria. |
| **O que está faltando** | Grafo interativo; ligação visual esquema ↔ problema ↔ objetivo; estilos parentais/apego (instrumentos inexistentes); sugestões terapêuticas; edição in-place. |
| **Limitações atuais** | Lista de seções com hints; não substitui sessão clínica; depende de dados de outros módulos. |
| **Dependências futuras** | DN-05 (escopo v2); instrumentos adicionais; possível modelagem grafo se wireframe exigir. |
| **Maturidade** | **50 / 100** |

---

### 6. Objetivos da terapia

| Campo | Conteúdo |
|-------|----------|
| **Objetivo esperado** | Metas acordadas, revisão periódica, vínculo com plano terapêutico (W). |
| **O que foi implementado** | Tabela `therapy_goals`; CRUD paciente e staff; status (ativo, concluído, arquivado); data alvo (staff); trilha integrada; formulário + detalhe + refresh. |
| **O que está faltando** | Revisão periódica guiada; vínculo explícito objetivo ↔ esquema/resultado; lembretes; histórico de revisões; wireframe pode prever UX de plano visual — **validar W**. |
| **Limitações atuais** | Modelo CRUD simples; sem OKR clínico estruturado. |
| **Dependências futuras** | Anamnese/plano terapêutico formal; mapa mental v2. |
| **Maturidade** | **75 / 100** |

---

### 7. Problemas

| Campo | Conteúdo |
|-------|----------|
| **Objetivo esperado** | Queixas/focos com prioridade, intensidade e evolução (W+D); âncora para mapa mental e intervenção. |
| **O que foi implementado** | `patient_problems`; CRUD; intensidade 0–10; status (ativo, melhorou, resolvido, arquivado); trilha Em andamento/Concluído; paciente + staff. |
| **O que está faltando** | Priorização explícita multi-problema; link a esquemas YSQ/YAMI; categorização clínica padronizada; wireframe pode ter campos extras — **validar W**. |
| **Limitações atuais** | Lista plana; sem matriz de gravidade agregada. |
| **Dependências futuras** | Sugestão terapêutica Fase 7; mapa mental grafo. |
| **Maturidade** | **75 / 100** |

---

### 8. Check-in

| Campo | Conteúdo |
|-------|----------|
| **Objetivo esperado** | Registro breve e frequente de estado (humor, ansiedade, energia) — distinto de questionário longo (W). Diagrama pode diferenciar de monitor (DN-02). |
| **O que foi implementado** | `patient_check_ins`; sliders 0–10; notas; paciente cria/edita (ênfase no de hoje); staff **somente leitura**; trilha Concluído se check-in hoje. |
| **O que está faltando** | Unificação ou diferenciação clara vs monitor na UX (DN-02); check-in staff (RLS impede); wireframe pode prever UI ainda mais rápida (1 tap) — **validar W**. |
| **Limitações atuais** | Dois módulos similares (check-in + monitor) podem confundir usuário. |
| **Dependências futuras** | Decisão produto DN-02; notificações diárias. |
| **Maturidade** | **70 / 100** |

---

### 9. Monitor diário

| Campo | Conteúdo |
|-------|----------|
| **Objetivo esperado** | Registro diário de humor, sono, atividade, emoções; staff acompanha (W+D). |
| **O que foi implementado** | `daily_monitors`; campos texto (humor, sono, atividade, emoções); CRUD paciente; histórico staff; trilha; parsing de emoções no domínio. |
| **O que está faltando** | Escalas estruturadas fixas se wireframe exigir; gráficos de tendência; alertas clínicos; unificação com check-in. |
| **Limitações atuais** | Texto livre no MVP; sem métricas agregadas no app. |
| **Dependências futuras** | DN-02; dashboard evolução temporal. |
| **Maturidade** | **72 / 100** |

---

### 10. Linha do tempo (Timeline)

| Campo | Conteúdo |
|-------|----------|
| **Objetivo esperado** | Eventos biográficos/terapêuticos ordenados no tempo (W+D). |
| **O que foi implementado** | `patient_timeline_events`; título, descrição, data, período, categoria, impacto 0–10, flag sensível; CRUD paciente/staff; ordenação cronológica; trilha. |
| **O que está faltando** | Visualização timeline gráfica (eixo temporal); filtros; anexos; integração com anamnese. |
| **Limitações atuais** | Lista cronológica, não linha visual estilo wireframe. |
| **Dependências futuras** | PDF já inclui eventos; mapa mental já resume. |
| **Maturidade** | **78 / 100** |

---

### 11. Genograma

| Campo | Conteúdo |
|-------|----------|
| **Objetivo esperado** | Representação gráfica da família e relações para uso clínico (W+D). |
| **O que foi implementado** | `genogram_people` + `genogram_relationships`; CRUD pessoas e relações; gênero, anos, tipos de relação; lista + resumo; aviso “gráfico v1 futuro”; paciente + staff; trilha. |
| **O que está faltando** | **Árvore/gráfico interativo** (core do wireframe provável); símbolos clínicos padrão; export imagem; layout draw.io-like. |
| **Limitações atuais** | MVP lista; difícil visualizar rede complexa. |
| **Dependências futuras** | DP-05 escopo mínimo vs editor completo; possível canvas Flutter ou web. |
| **Maturidade** | **58 / 100** |

---

### 12. Biblioteca (recursos terapêuticos)

| Campo | Conteúdo |
|-------|----------|
| **Objetivo esperado** | Acervo da clínica; liberação seletiva; consumo pelo paciente (W+D). Diagrama: biblioteca ligada a sugestões futuras. |
| **O que foi implementado** | `therapy_resources` + `patient_resource_access`; biblioteca staff; liberar/revogar; paciente vê liberados; status visualizado/concluído; abrir URL; trilha passo Biblioteca. |
| **O que está faltando** | Catálogo com categorias, busca, tags; conteúdo in-app (só URL); sugestão automática de recurso pós-resultado; revogação em massa; wireframe catálogo rico — **validar W**. |
| **Limitações atuais** | Seed com URLs fictícias; progresso manual. |
| **Dependências futuras** | Sugestão terapêutica Fase 7; Storage para PDFs internos. |
| **Maturidade** | **68 / 100** |

---

### 13. Relatório PDF

| Campo | Conteúdo |
|-------|----------|
| **Objetivo esperado** | Relatório clínico supervisionado para equipe (diagrama: consolidação de dados para revisão — distinto de laudo automático). Wireframe pode prever export/laudo — **validar W** (MVP exclui laudo automático). |
| **O que foi implementado** | Edge Function `generate-clinical-report`; seleção de seções; PDF com capa, aviso, resumo, YSQ/YAMI, mapa resumido, anexos; **somente staff**; Flutter `clinical_reports`; abrir/salvar local (`open_filex`). |
| **O que está faltando** | Storage permanente; e-mail; assinatura digital; versão paciente; PT-BR completo no PDF (sanitize ASCII); template visual da clínica; laudo interpretativo (propositalmente fora). |
| **Limitações atuais** | Geração sob demanda; acentuação limitada; sem auditoria de downloads centralizada. |
| **Dependências futuras** | Homologação conteúdo; branding; LGPD retenção; integração com prontuário externo. |
| **Maturidade** | **62 / 100** |

---

## Matriz consolidada

| Módulo | Roadmap | vs Wireframe (hipótese) | vs Diagrama | Maturidade |
|--------|---------|-------------------------|-------------|------------|
| Trilha | Parcial | Hub visual incompleto | OK como hub lógico | **65** |
| Questionários | Implementado | Fluxo OK; trilha guiada fraca | OK pipeline | **78** |
| Resultados | Implementado | Gráficos no painel, não na lista | OK apuração staff | **72** |
| Dashboard | Parcial | Gráficos simples vs painel rico | Parcial visão D | **55** |
| Mapa mental | Parcial | Lista vs mapa integrado | Parcial | **50** |
| Objetivos | Implementado | CRUD OK; plano visual ? | OK | **75** |
| Problemas | Implementado | CRUD OK | OK âncora clínica | **75** |
| Check-in | Implementado | Pode ser mais rápido que W | OK; overlap monitor | **70** |
| Monitor | Implementado | Texto vs escala W ? | OK acompanhamento | **72** |
| Timeline | Implementado | Lista vs eixo visual W | OK | **78** |
| Genograma | MVP lista | Gráfico ausente | Parcial | **58** |
| Biblioteca | Parcial | Catálogo básico | OK manual | **68** |
| PDF | Parcial (v1) | Export staff OK; laudo N/A | Consolidação parcial | **62** |

**Média ponderada (13 módulos auditados):** ~**68 / 100** — MVP funcional para homologação técnica e demo; gaps concentrados em **visão gráfica**, **homologação clínica YSQ/YAMI** e **módulos não importados**.

---

## Cruzamento roadmap × wireframe × diagrama

| Tema transversal | Roadmap | Wireframe (W) | Diagrama (D) | Situação MVP |
|------------------|---------|---------------|--------------|--------------|
| Paciente vê scores? | DP-03 / DN-01 | Incerto | Setas para visão clínica | Dashboard + mapa paciente **sim** (com disclaimer); resultados detalhados **não** |
| Check-in vs monitor | DN-02 | D5 hipótese | Dois blocos | **Dois módulos** implementados |
| Ordem trilha | DN-03 | Sequência visual? | Fluxo instrumentos | **Livre** |
| Homologação YSQ/YAMI | Fase 1 P0 | — | Base do resto | **Pendente** |
| Sugestão / IA | Fase 7 / fora | D7 | Setas sugestão | **Não iniciado** |
| PDFs no repo | DP-01 | — | — | **Pendente** — auditoria visual incompleta |

---

## Recomendações pós-auditoria

1. **Copiar PDFs** para `docs/product/sources/` e revisar maturidade das colunas “vs Wireframe”.
2. **Priorizar homologação YSQ/YAMI** antes de expandir dashboard ou novos instrumentos.
3. **Workshop DN-01 / DN-02 / DN-03** com psicólogas antes de unificar check-in/monitor ou expor mais dados ao paciente.
4. **Atualizar** [gap-analysis-from-wireframes.md](../product/gap-analysis-from-wireframes.md) §2.1 — vários itens marcados “ausência total” já foram implementados (trilha, genograma, timeline, objetivos, problemas, check-in, mapa mental).
5. Usar [final-mvp-homologation.md](../demo/final-mvp-homologation.md) como roteiro de validação funcional pós-auditoria.

---

## Critérios de aceite desta auditoria

- [x] 13 módulos documentados com os 6 campos solicitados + maturidade
- [x] Resumo executivo (pronto / parcial / não iniciado)
- [x] Referência explícita a roadmap, wireframe e diagrama
- [x] Sem alteração de código, banco ou Flutter

---

## Histórico

| Data | Alteração |
|------|-----------|
| 2026-06-04 | Versão inicial — estado pós-MVP (migrations 021, PDF v1, trilha 10 passos) |

---

## Referências

- [master-roadmap.md](../product/master-roadmap.md)
- [gap-analysis-from-wireframes.md](../product/gap-analysis-from-wireframes.md)
- [mobile-app.md](../mobile-app.md)
- [final-mvp-homologation.md](../demo/final-mvp-homologation.md)
- [clinical-homologation.md](../scoring-engine/clinical-homologation.md)
