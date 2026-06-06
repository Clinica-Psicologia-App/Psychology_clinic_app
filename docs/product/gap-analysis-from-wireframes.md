# Gap analysis — wireframes e diagrama lógico × MVP

Comparativo entre os materiais de referência do cliente e o que está implementado no repositório **Terapia do Esquema** (maio/2026).

**Referências nomeadas (fora do repo até cópia em [sources/](./sources/README.md)):**

- `Wireframe App Esquemas 19Abr2026.drawio.pdf`
- `Diagrama APP Esquemas.pdf`

**Documento irmão:** [master-roadmap.md](./master-roadmap.md) (tabelas por módulo e fases).

---

## 1. Escopo desta análise

| Incluído | Excluído |
|----------|----------|
| Inventário de módulos da especificação do roadmap | Implementação de código, migrations ou UI |
| Status verificável no monorepo | Funcionalidades não citadas nos PDFs nem na lista de módulos |
| Riscos de escopo e decisões | Estimativas de esforço em horas |

**Limitação:** sem os PDFs no workspace, diferenças de **layout, microcopy e ordem de telas** estão marcadas como *validar no wireframe*; a análise de **capacidades** usa o código e a documentação técnica existente.

---

## 2. Funcionalidades ausentes (vs visão dos materiais)

### 2.1 Ausência total (nenhum artefato técnico equivalente)

| Funcionalidade | Evidência no MVP | Impacto se ignorada |
|----------------|------------------|---------------------|
| Anamnese estruturada | Não há tabelas/UI | História clínica fragmentada fora do app |
| Trilha / mapa do app | Home = lista de módulos | Jornada do paciente menos guiada que no wireframe |
| Genograma | Citado em `next-steps` como futuro | Lacuna para Terapia do Esquema centrada em relações |
| Linha do tempo | Idem | Dificulta narrativa biográfica integrada |
| Objetivos da terapia | Idem | Plano terapêutico não rastreável no sistema |
| Check-in (como módulo distinto) | Só `daily_monitors` | Possível duplicidade ou confusão com monitor |
| Problemas / focos clínicos | Idem | Mapa mental e sugestões ficam sem âncora |
| Estilos Parentais | Aba planilha; `lifetime` previsto em doc 016 | Instrumento do diagrama incompleto |
| Estilos de Apego | Aba planilha pendente | Idem |
| Estilos de Enfrentamento | Não importado | *Confirmar existência na planilha* |
| Perguntas de Personalidade | Aba planilha pendente | Idem |
| Mapa mental | `next-steps` §11 — não modelado | Visão integrada do diagrama não realizada |
| Sugestão terapêutica | Sem regras nem workflow | Biblioteca reativa (só liberação manual) |

### 2.2 Ausência parcial (base técnica existe)

| Funcionalidade | O que existe | O que falta (típico em wireframe/diagrama) |
|----------------|--------------|---------------------------------------------|
| Cadastro / aceite | `create-patient`, Auth | Fluxo paciente, termos, consentimento, convite |
| YSQ / YAMI | Migrations 014–015, motor, UI | Homologação, licença, ajustes de catálogo |
| Dashboarding | `PatientResultsPage`, snapshot JSON | Gráficos, %, comparativo, validação visual |
| Biblioteca | CRUD recursos + liberação | UX de catálogo, categorias, descoberta — **validar PDF** |
| Questionários (visão paciente) | Fluxo completo | Trilha que mostre “próximo instrumento” e histórico resumido |

---

## 3. Diferenças entre app atual e wireframes (hipóteses)

Registrar como confirmadas ou refutadas quando os PDFs estiverem em `docs/product/sources/`.

| # | Área | App atual | Wireframe provável (hipótese) | Ação sugerida |
|---|------|-----------|-------------------------------|---------------|
| D1 | Home paciente | 3 cards lineares | Hub visual / trilha com progresso | Fase 2; validar PDF W |
| D2 | Resultados | Staff-only, lista + detalhe | Painel com gráficos no diagrama D | Fase 6; manter interpretação humana |
| D3 | Pós-login | Direto na home por role | Onboarding + aceite | Fase 1–3; LGPD |
| D4 | Nome dos modos YAMI | Seção “Esquemas” no snapshot | Rótulo “Modos” no wireframe | Copy Flutter; sem mudar motor |
| D5 | Monitor diário | Formulário com notas | Check-in rápido (escala única?) | DP-02 |
| D6 | Staff inicia questionário | Permitido no detalhe do paciente | Paciente só responde no celular | Validar papéis no PDF D |
| D7 | IA / sugestões | Explicitamente fora do escopo | Diagrama pode mostrar seta “sugestão” | Fase 7 sem IA; DP-06 |

---

## 4. Decisões necessárias

| ID | Pergunta | Opções | Quem decide | Bloqueia |
|----|----------|--------|-------------|----------|
| DN-01 | Paciente acessa resultados numéricos? | Não / resumo neutro / completo | Clínico + LGPD | Trilha, dashboard paciente |
| DN-02 | Unificar check-in e monitor diário? | Um módulo / dois / monitor evolui para check-in | Product + clínico | Fase 3 |
| DN-03 | Ordem obrigatória na trilha? | Livre / sequência YSQ→YAMI→… | Clínico | UX trilha |
| DN-04 | Quais instrumentos na Fase 1 produção? | Só YSQ+YAMI / + Parentais | Clínico + licença | Migrations |
| DN-05 | Mapa mental v1 | Lista agregada / grafo interativo | Product | Fase 5 escopo |
| DN-06 | Sugestão terapêutica v1 | Só recursos / texto estruturado | Clínico | Fase 7 |
| DN-07 | Versionar PDFs no repo? | Sim em `docs/product/sources/` / drive externo | Gestão projeto | Rastreabilidade |

---

## 5. Riscos de escopo

| Risco | Descrição | Probabilidade | Mitigação |
|-------|-----------|---------------|-----------|
| **Escopo “big bang”** | Implementar trilha + anamnese + genograma + mapa mental em paralelo | Alta se não fasear | Seguir fases 1–7 do master roadmap |
| **Duplicidade monitor/check-in** | Dois módulos com mesma função | Média | DN-02 antes de Fase 3 |
| **Dashboard antes de homologação** | Gráficos sobre scores não validados | Média | Fase 1 obrigatória |
| **Instrumentos sem licença** | Parentais, Apego, YSQ-S3 oficial | Alta | Checklist P01–P02 |
| **IA prematura** | Wireframe sugere “sugestão inteligente” | Média | Fase 7 explícita: regras + revisão humana |
| **Genograma complexo** | Editor draw.io-like no wireframe | Média | MVP CRUD simples (Fase 4) |
| **Divergência PDF × planilha** | Diagrama lista instrumentos que a planilha não tem | Média | Fonte única: planilha + parecer clínico |
| **RLS e novos módulos** | Cada módulo clínico exige policies | Alta | Modelar com `clinic_id` desde o início |

---

## 6. Recomendações

### 6.1 Imediato (documentação e processo)

1. Copiar os dois PDFs para `docs/product/sources/` e atualizar colunas *PDF/tela* no [master-roadmap.md](./master-roadmap.md).
2. Marcar no roadmap quais telas do wireframe são **v1 obrigatória** vs **v2 desejável**.
3. Manter [next-steps.md](../next-steps.md) focado em técnico; usar master roadmap para produto.

### 6.2 Produto (ordem)

1. **Não** iniciar mapa mental nem dashboard gráfico antes de homologar YSQ/YAMI.
2. Priorizar **trilha do paciente** antes de novos instrumentos — melhora adoção sem novo conteúdo clínico.
3. Tratar **anamnese + objetivos + problemas** como um único épico (Fase 3) com modelo de dados único.
4. Importar **Estilos Parentais** só após decisão DN-04 e licenciamento (aba planilha + `reference_period = lifetime` já previsto na migration 016).

### 6.3 Técnico (quando implementar — fora desta entrega)

- Reutilizar `questionnaire_versions`, motor e snapshot para novos instrumentos (templates `supabase/templates/scoring/`).
- Não antecipar tabelas de genograma/mapa mental no schema até DN-05 fechada.
- Edge Functions apenas onde RLS não basta (padrão atual).

### 6.4 O que não fazer agora

- IA generativa para interpretação ou sugestão
- PDF de laudo automático
- Pagamentos / multi-clínica comercial
- Replicação fiel de cada tela do drawio sem priorização clínica

---

## 7. Matriz resumida — cobertura do MVP

| Categoria | Módulos no material | Implementados | Parciais | Não iniciados |
|-----------|---------------------|---------------|----------|---------------|
| Acesso / jornada | 4 | 1 | 1 | 2 |
| Registro clínico | 6 | 0 | 0 | 6 |
| Acompanhamento | 2 | 2 | 0 | 0 |
| Instrumentos | 6 | 0 | 2 | 4 |
| Apuração / visão | 5 | 1 | 2 | 2 |
| **Total (26 linhas)** | **26** | **4** | **5** | **17** |

*Contagem por linhas da tabela de módulos do master roadmap; “parcial” inclui YSQ/YAMI e itens com base técnica incompleta.*

---

## 8. Próxima revisão

Checklist quando os PDFs estiverem disponíveis:

- [ ] Conferir cada módulo contra telas numeradas do wireframe
- [ ] Conferir setas e caixas do diagrama lógico (dependências entre módulos)
- [ ] Atualizar seção “Implementado diferente” com evidência (screenshot ou página drawio)
- [ ] Fechar DP-01 a DP-07 e DN-01 a DN-07
- [ ] Ajustar prioridades P0–P3 se o cliente alterar escopo

---

## Histórico

| Data | Alteração |
|------|-----------|
| 2026-05-31 | Versão inicial (PDFs ausentes no repo) |
