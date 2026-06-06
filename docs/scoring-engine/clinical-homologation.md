# Homologação clínica — resultados do motor de apuração

Fluxo para **psicólogos** validarem se o sistema produz resultados coerentes com o instrumento importado, após resposta real no app e `finish-questionnaire`.

| Documento | Papel |
|-----------|--------|
| Este arquivo | Homologação **operacional** (app + snapshot + leitura clínica dos agrupamentos) |
| [clinical-validation-checklist.md](./clinical-validation-checklist.md) | Validação do **catálogo** no banco (textos, licença, mapeamentos planilha) |
| [ysq-import-report.md](./ysq-import-report.md) / [yami-import-report.md](./yami-import-report.md) | Referência da importação |

**Não altera** Supabase, Flutter nem Edge Functions. Registre achados na tabela §4 e no checklist §5; correções de catálogo seguem o checklist clínico (migrations versionadas).

---

## Pré-requisitos

| Item | Verificação |
|------|-------------|
| Ambiente | `supabase db reset` + `supabase functions serve` (local) ou projeto remoto com migrations **014–015** |
| App Flutter | `flutter run --dart-define-from-file=env.local.json` |
| Contas seed | Senha `TesteMVP2025!` — ver tabela abaixo |
| Paciente de teste | Maria Silva (`paciente.login@clinicateste-mvp.example`) ou paciente dedicado à homologação |
| Tempo estimado | YSQ completo: ~45–60 min resposta + ~30 min revisão; YAMI: ~90–120 min resposta + ~45 min revisão |
| Material de apoio | Manual YSQ-S3 / SMI 1.1 (ou planilha autorizada) para conferir mapeamentos |

### Contas (seed)

| Perfil | E-mail | Uso na homologação |
|--------|--------|-------------------|
| Paciente | `paciente.login@clinicateste-mvp.example` | Responder questionários |
| Psicólogo | `psicologo@clinicateste-mvp.example` | Ver resultados (módulo Resultados) |
| Admin | `admin@clinicateste-mvp.example` | Opcional — mesmo acesso a resultados da clínica |

### Instrumentos no app

| Código | Nome no app | Itens |
|--------|-------------|-------|
| `YSQ_FOUNDATION_V1` | YSQ — Fundação (Esquemas) | 90 |
| `YAMI_MODES_FOUNDATION_V1` | YAMI — Modos Esquemáticos Foundation v1 | 124 |
| `MVP_DEMO` | Inventário Demo — 5 itens | 5 (fora deste roteiro; apenas demo técnica) |

---

## Papéis

| Papel | Responsabilidade |
|-------|------------------|
| Psicólogo homologador | Responde (ou supervisiona resposta), revisa snapshot, preenche tabelas |
| Revisor (opcional) | Segundo psicólogo confere amostra e assina |
| Suporte técnico | Garante `functions serve`, env do app, anota `response_id` |

---

## Visão do resultado no app (staff)

1. Login **psicólogo** ou **admin**.
2. **Pacientes** → paciente de teste → **Resultados**.
3. Abrir a `response_id` da sessão homologada.
4. Verificar:
   - Banner conforme questionário (YSQ / YAMI — ver `result_disclaimer.dart`).
   - Seção **Apuração estruturada**: resumo, domínios, esquemas/modos, itens.
   - `version` do snapshot: `scoring-demo-1`.
5. **Não** tratar o snapshot como laudo clínico — validar se **estrutura e números** batem com respostas e manual.

Consulta opcional no Studio (somente leitura):

```sql
SELECT id, status, completed_at, questionnaire_id
FROM questionnaire_responses
WHERE patient_id = '<uuid-paciente>'
ORDER BY started_at DESC;
```

---

## Roteiro — YSQ (`YSQ_FOUNDATION_V1`)

### Fase A — Responder questionário

| Passo | Ação | ✓ |
|-------|------|---|
| A1 | Login **paciente** | ☐ |
| A2 | **Questionários** → selecionar *YSQ — Fundação (Esquemas)* | ☐ |
| A3 | **Iniciar** nova resposta (evitar confundir com resposta antiga) | ☐ |
| A4 | Anotar `response_id` (ver §4 ou detalhe staff após concluir) | ☐ |
| A5 | Responder **90** itens (Likert 1–6) | ☐ |
| A6 | Usar **protocolo de respostas** abaixo (recomendado) ou respostas clínicas livres (documentar) | ☐ |
| A7 | **Finalizar** → tela de sucesso sem erro | ☐ |

**Protocolo sugerido (reprodutível):** resposta fixa **4** em todos os itens (média 4 por esquema → faixa **Ativado** 4,0–5,0). Alternativa: planilha anexa com resposta por item.

### Fase B — Gerar e abrir resultado

| Passo | Ação | ✓ |
|-------|------|---|
| B1 | Login **psicólogo** | ☐ |
| B2 | **Resultados** → mesma resposta (status Concluído) | ☐ |
| B3 | Confirmar banner: *"Resultado estruturado para validação clínica… psicólogo responsável"* | ☐ |
| B4 | Snapshot presente (`scoring-demo-1`), não só legado MVP | ☐ |

### Fase C — Revisar esquemas

Para **cada um dos 18 esquemas** na seção **Esquemas** do snapshot:

| Verificação | ✓ |
|-------------|---|
| Nome do esquema confere com manual/planilha | ☐ |
| `answered_items` = 5 (cinco itens por esquema) | ☐ |
| `average_score` coerente com respostas dadas (ex.: tudo 4 → média ≈ 4) | ☐ |
| `weighted_score` coerente (peso 1 → igual soma dos ajustados) | ☐ |
| **Severidade** (Baixo / Médio / Ativado) coerente com média e faixas 1,0–2,4 / 2,5–3,9 / 4,0–5,0 | ☐ |
| Amostra detalhada: Abandono, Desconfiança, um esquema do domínio Limites (2 esquemas) | ☐ |

### Fase D — Revisar domínios

| Verificação | ✓ |
|-------------|---|
| Cinco domínios listados com nomes da planilha | ☐ |
| Agregação do domínio = soma/média dos esquemas filhos (sentido clínico) | ☐ |
| Domínio **Limites prejudicados** com 2 esquemas refletido no resumo | ☐ |

### Fase E — Revisar severidades (amostra)

| Verificação | ✓ |
|-------------|---|
| Faixa **Baixo** aplicada quando média ≤ 2,4 | ☐ |
| Faixa **Médio** entre 2,5 e 3,9 | ☐ |
| Faixa **Ativado** entre 4,0 e 5,0 | ☐ |
| Label exibido = "Ativado" (não "Alto") — aceitável para homologação? | ☐ |

### Resultado esperado (protocolo resposta = 4 em todos)

| Campo | Esperado aproximado |
|-------|---------------------|
| Resumo `answered_items` | 90 |
| Resumo `average_score` | ~4,0 |
| Cada esquema `average_score` | ~4,0 |
| Severidade por esquema | **Ativado** |
| Banner | Texto YSQ (validação clínica) |

---

## Roteiro — YAMI (`YAMI_MODES_FOUNDATION_V1`)

### Fase A — Responder questionário

| Passo | Ação | ✓ |
|-------|------|---|
| A1 | Login **paciente** | ☐ |
| A2 | **Questionários** → *YAMI — Modos Esquemáticos Foundation v1* | ☐ |
| A3 | **Iniciar** nova resposta | ☐ |
| A4 | Anotar `response_id` | ☐ |
| A5 | Responder **124** itens (frequência 1–6) | ☐ |
| A6 | Protocolo sugerido: **3** em todos (média 3 → faixa **Médio**) ou planilha anexa | ☐ |
| A7 | **Finalizar** sem erro | ☐ |

> Resposta completa é longa; pode dividir em duas sessões mantendo a mesma `response_id` (continuar rascunho) se o app permitir — senão concluir em uma sessão.

### Fase B — Gerar e abrir resultado

| Passo | Ação | ✓ |
|-------|------|---|
| B1 | Login **psicólogo** | ☐ |
| B2 | **Resultados** → resposta concluída | ☐ |
| B3 | Banner: *"Resultado estruturado de modos esquemáticos para validação clínica…"* | ☐ |
| B4 | Snapshot estruturado presente | ☐ |

### Fase C — Revisar modos

Modos aparecem na seção **Esquemas** (modelagem: modo = `schemas`).

| Verificação | ✓ |
|-------------|---|
| 19 modos listados (nomes como na planilha, inclusive typos se ainda no banco) | ☐ |
| Contagem de itens por modo bate com expectativa (ver [yami-import-report.md](./yami-import-report.md) § modos) | ☐ |
| Modos com 1 item: conferir se faz sentido clínico ou erro de planilha | ☐ |
| Duplicatas: `Criança Feliz` vs `Criança  Feliz`; `Ciança…` — registrar na tabela §4 | ☐ |
| Amostra: Pais Punitivos (10 itens), Adulto Saudável (10), modo com 1 item | ☐ |

### Fase D — Revisar domínio único

| Verificação | ✓ |
|-------------|---|
| Um domínio `YAMI_DOMAIN_SCHEMA_MODES` / “Modos esquemáticos” | ☐ |
| Agregação global coerente com itens respondidos | ☐ |

### Fase E — Revisar severidades

| Verificação | ✓ |
|-------------|---|
| Mesmas faixas YSQ (Baixo / Médio / Ativado) | ☐ |
| Com protocolo resposta = 3: severidade **Médio** nos modos com itens | ☐ |

### Resultado esperado (protocolo resposta = 3 em todos)

| Campo | Esperado aproximado |
|-------|---------------------|
| Resumo `answered_items` | 124 |
| Resumo `average_score` | ~3,0 |
| Severidade típica por modo | **Médio** |

---

## Tabela de validação (preencher por sessão)

Duplicar blocos por homologador / data. Anexar export do snapshot (JSON) ou prints se necessário.

### Sessão 1 — YSQ

| Campo | Valor |
|-------|-------|
| **Questionário** | `YSQ_FOUNDATION_V1` |
| **response_id** | |
| **Paciente teste** | |
| **Data** | |
| **Homologador** | |
| **Protocolo de respostas** | (ex.: todos = 4 / planilha anexa / livre) |
| **Resultado esperado** | (ex.: 18 esquemas × média 4, severidade Ativado) |
| **Resultado obtido** | (descrever divergências: esquema X média Y, severidade Z) |
| **Aprovado** | ☐ Sim ☐ Não ☐ Com ressalvas |
| **Observações** | |

### Sessão 2 — YAMI

| Campo | Valor |
|-------|-------|
| **Questionário** | `YAMI_MODES_FOUNDATION_V1` |
| **response_id** | |
| **Paciente teste** | |
| **Data** | |
| **Homologador** | |
| **Protocolo de respostas** | |
| **Resultado esperado** | |
| **Resultado obtido** | |
| **Aprovado** | ☐ Sim ☐ Não ☐ Com ressalvas |
| **Observações** | |

### Registro consolidado (opcional)

| questionário | response_id | paciente teste | aprovado | observações resumidas |
|--------------|-------------|----------------|----------|------------------------|
| YSQ_FOUNDATION_V1 | | | ☐ | |
| YAMI_MODES_FOUNDATION_V1 | | | ☐ | |

---

## Checklist técnico-clínico do snapshot

Marcar após cada instrumento homologado. Detalhe de catálogo (textos oficiais, licença) permanece em [clinical-validation-checklist.md](./clinical-validation-checklist.md).

### Escala

| Critério | YSQ | YAMI | Notas |
|----------|-----|------|-------|
| Itens usam escala 1–6 no app | ☐ | ☐ | |
| Rótulos Likert legíveis na tela de resposta | ☐ | ☐ | YSQ: verdade; YAMI: frequência |
| Valores fora da escala rejeitados pelo app | ☐ | ☐ | |
| `scale_min` / `scale_max` no snapshot coerentes (1 e 6) | ☐ | ☐ | Metadado versão |

### Faixas de severidade

| Critério | YSQ | YAMI |
|----------|-----|------|
| Três faixas: Baixo, Médio, Ativado | ☐ | ☐ |
| Cortes 1,0–2,4 / 2,5–3,9 / 4,0–5,0 aplicados corretamente | ☐ | ☐ |
| Nenhum “buraco” entre faixas para médias inteiras | ☐ | ☐ |
| Severidade ausente quando deveria existir | ☐ | ☐ | Registrar modo/esquema |
| Label “Ativado” aceito na homologação | ☐ | ☐ | |

### Pesos

| Critério | YSQ | YAMI |
|----------|-----|------|
| Pontuação ponderada = soma (peso 1) × valor ajustado | ☐ | ☐ |
| Nenhum item com peso diferente no snapshot | ☐ | ☐ | Banco: todos 1 |
| Peso diferente do manual exige pendência P12 | ☐ | ☐ | |

### Reverse scoring

| Critério | YSQ | YAMI |
|----------|-----|------|
| Respostas altas aumentam score (sem inversão) | ☐ | ☐ | `reverse_score=false` |
| Item que deveria ser reverse no manual listado em §4 | ☐ | ☐ | |

### Agrupamentos

| Critério | YSQ | YAMI |
|----------|-----|------|
| Cada item aparece uma vez em `scoring_items` / itens | ☐ | ☐ |
| Item ligado ao esquema/modo correto (amostra + spot-check) | ☐ | ☐ |
| Domínios YSQ: 5 agrupamentos corretos | ☐ | N/A | YAMI: 1 domínio |
| Modos YAMI: contagens por modo corretas | N/A | ☐ |
| Resumo global (`summary`) = agregação de todos os itens | ☐ | ☐ |

### Nomenclatura (UI)

| Critério | YSQ | YAMI |
|----------|-----|------|
| Nomes de esquemas legíveis e fiéis à planilha | ☐ | ☐ |
| Modos não confundidos com esquemas Young na UI | ☐ | ☐ | Banner YAMI diferencia |
| Banner correto para o código do questionário | ☐ | ☐ |
| Seção “Esquemas” aceitável para modos YAMI (até melhoria de copy) | ☐ | ☐ |

---

## Critérios de aprovação da homologação

Homologação **aprovada** para um instrumento quando:

1. Pelo menos **uma sessão completa** (resposta + resultado) registrada na tabela §4 com **Aprovado = Sim** ou **Com ressalvas** documentadas.
2. Checklist §5 sem itens ✗ críticos (erro de cálculo, severidade errada, itens perdidos).
3. Divergências de nomenclatura/typo encaminhadas à tabela de pendências do [clinical-validation-checklist.md](./clinical-validation-checklist.md) §4.
4. Revisor (se houver) concorda com aprovação ou ressalvas.

Homologação **não aprovada** se:

- Snapshot ausente ou `mvp-1` apenas, com versão active no banco.
- Médias incompreensíveis vs. respostas registradas.
- Itens respondidos não aparecem no snapshot.

---

## Após a homologação

| Situação | Próximo passo |
|----------|----------------|
| Aprovado sem ressalvas | Atualizar [clinical-validation-checklist.md](./clinical-validation-checklist.md); considerar uso piloto controlado |
| Ressalvas menores | Registrar P0x; agendar migration de correção |
| Reprovado | Não usar em produção; corrigir catálogo + repetir homologação |

**Não** corrigir banco manualmente durante homologação — apenas documentar.

---

## Referências rápidas

```bash
# Local
supabase db reset
supabase functions serve
cd mobile && flutter run --dart-define-from-file=env.local.json
```

- Demo geral: [../demo-script.md](../demo-script.md)
- Checklist pré-demo: [../demo-checklist.md](../demo-checklist.md)

---

## Histórico

| Data | Versão doc | Alteração |
|------|------------|-----------|
| 2026-05-31 | 1.0 | Criação do fluxo YSQ + YAMI |
