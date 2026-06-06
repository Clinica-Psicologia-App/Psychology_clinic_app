# Master roadmap — Plataforma Terapia do Esquema

Visão consolidada do produto: materiais de wireframe/diagrama (referência cliente) × implementação atual do MVP no repositório.

**Última revisão:** 2026-05-31  
**Fontes:** ver [sources/README.md](./sources/README.md) · técnico: [next-steps.md](../next-steps.md), [mobile-app.md](../mobile-app.md), [scoring-engine/README.md](../scoring-engine/README.md)

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
| **Estilos de Apego** | Instrumento da aba correspondente na planilha | W+D | **Não iniciado** | Importação + regras de apuração | P2 | Alto |
| **Estilos de Enfrentamento** | Instrumento de coping/enfrentamento (validar nome exato no PDF) | W+D | **Não iniciado** | *Decisão pendente:* confirmar se existe aba separada na planilha ou só no diagrama | P2 | Médio |
| **Perguntas de Personalidade** | Bloco de personalidade na planilha do projeto | W+D | **Não iniciado** | Mapeamento pergunta → constructo; possível escala distinta | P2 | Alto |

### Apuração, visão clínica e conteúdo

| Módulo | Descrição funcional | PDF/tela | Status | Dependências técnicas | Prioridade | Risco |
|--------|---------------------|----------|--------|----------------------|------------|-------|
| **Motor de Apuração** | Cálculo estruturado por versão, esquemas/domínios, severidades; snapshot JSON | D (+ W staff) | **Implementado** | `questionnaire_versions`, regras, `finish-questionnaire`, `_shared/scoring/` | — | Médio (validação) |
| **Dashboarding / validação** | Gráficos, percentuais, comparação entre aplicações e instrumentos para staff | D (+ W) | **Parcial** | Dashboard home mobile com seções YSQ/YAMI + placeholders para instrumentos futuros; sem web/PDF/comparativo | P1 | Médio |
| **Catálogo e liberação de instrumentos** | Mostrar autor/versão/licença e controlar quais instrumentos cada profissional pode usar | D | **Implementado (v1)** | `questionnaire_professional_access`, metadados em `questionnaires`, tela admin mobile | P1 | Médio |
| **Mapa Mental** | Visão integrada de esquemas, modos, estilos e problemas | W+D | **Parcial** | Mapa mental v1.1 mobile com hub radial navegável + resumo read-only; sem tabelas novas nem IA | P2 | Alto (escopo) |
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
- Catálogo e apuração: `MVP_DEMO`, `YSQ_FOUNDATION_V1`, `YAMI_MODES_FOUNDATION_V1`
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
| Dashboard | Home por instrumento + YSQ/YAMI com barras | Estilos Parentais ainda sem dashboard específico por figura |
| Login | E-mail/senha seed | Sem recuperação de senha, MFA ou branding do wireframe — **validar no PDF** |
| Home paciente | Card da trilha + módulos de jornada | Hub clínico ainda concentrado em Mapa Mental e Dashboard |

### Ainda não iniciado (presente no inventário dos materiais)

- Anamnese, trilha central, genograma, linha do tempo
- Objetivos da terapia, check-in dedicado, problemas
- Estilos Parentais, Apego, Enfrentamento, Personalidade
- Mapa mental integrado
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

### Fase 5 — Mapa mental (P2) — v1 entregue

- [x] Agregação read-only (`features/mental_map/`) sem nova migration
- [x] YSQ/YAMI (últimos resultados + top scores), problemas/objetivos ativos, check-in, monitor, timeline, genograma
- [x] Hub radial/estrela responsivo aproximando o wireframe original, sem alterar banco nem scoring
- [ ] Grafo interativo avançado e IA (fora de escopo v1.1)

**Dependências:** módulos base da trilha (implementados).

### Fase 6 — Dashboard clínico (P1–P2)

- [x] v1 mobile: barras YSQ/YAMI a partir de `snapshot`, histórico básico, trilha + staff (sem recálculo)
- [x] Dashboard home com seções YSQ, YAMI, Estilos Parentais, Estilos de Apego, Estilos de Enfrentamento e Personalidade
- [ ] Gráficos avançados e dashboard web
- [ ] Percentuais e evolução entre aplicações
- [ ] Comparação entre instrumentos no mesmo paciente

**Dependências:** snapshots estáveis; definição de métricas com equipe clínica.

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
| Biblioteca | `mobile/lib/features/therapy_resources/` |
| Monitor | `mobile/lib/features/daily_monitors/` |

Análise de gaps detalhada: [gap-analysis-from-wireframes.md](./gap-analysis-from-wireframes.md).

---

## Histórico

| Data | Alteração |
|------|-----------|
| 2026-05-31 | Versão inicial do master roadmap (PDFs não no repo; inventário por especificação + estado do código) |
