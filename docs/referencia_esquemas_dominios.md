# Referência — Esquemas, Domínios e Necessidades Emocionais (YSQ)

Tabela de referência dos 18 esquemas de Young, seus 5 domínios e as necessidades
emocionais associadas.

**Fontes:**
- `QuestionárioS de EsquemaS.xlsx` (material da cliente) — abas `Resultado GERAL`,
  `Resultado YSQ`, `Resultado RNE`
- `supabase/migrations/20250531140014_seed_real_ysq_foundation.sql` — catálogo já
  existente no banco
- `supabase/migrations/20260723120200_emotional_needs_catalog.sql` — necessidades
  centrais

---

## 1. O catálogo já existe no banco

Não é preciso criar tabela nova. A cadeia completa já está modelada:

```
question_scoring_rules.schema_id → schemas.id
schemas.domain_id                → schema_domains.id
```

`schemas` tem `code`, `name` e `sort_order`; `schema_domains` tem `code`, `name` e
`sort_order`. Há inclusive um trigger em `scoring_engine_foundation.sql` que impede
`domain_id` de divergir do domínio do `schema_id`.

O que falta é apenas **propagar isso até a UI**: `ConsolidatedSchemaRow` não carrega
domínio, e `buildConsolidatedSchemas` ordena por score global
(`clinical_dashboard_builder.dart:271`).

---

## 2. Os 18 esquemas por domínio

Ordem conforme `schemas.sort_order` no banco.

### Domínio I — Desconexão e rejeição
`YSQ_DOMAIN_DISCONNECTION_REJECTION` · `sort_order = 0`
Necessidade central: **Vínculos seguros**

| # | Código | Nome (banco) | Necessidade específica (planilha) |
|---|---|---|---|
| 0 | `YSQ_SCHEMA_ABANDONMENT_INSTABILITY` | Abandono/Instabilidade | Estabilidade |
| 1 | `YSQ_SCHEMA_MISTRUST_ABUSE` | Desconfiança/Abuso | Segurança e proteção |
| 2 | `YSQ_SCHEMA_EMOTIONAL_DEPRIVATION` | Privação emocional | Cuidado e/ou afeto |
| 3 | `YSQ_SCHEMA_DEFECTIVENESS_SHAME` | Defectividade/Vergonha | Amor e/ou aceitação |
| 4 | `YSQ_SCHEMA_SOCIAL_ISOLATION` | Isolamento social/Alienação | Pertencimento |

> Esta ordem bate exatamente com o exemplo que a Guacira deu por mensagem.

### Domínio II — Autonomia e desempenho prejudicados
`YSQ_DOMAIN_IMPAIRED_AUTONOMY` · `sort_order = 1`
Necessidade central: **Autonomia e competência**

| # | Código | Nome (banco) | Necessidade específica (planilha) |
|---|---|---|---|
| 0 | `YSQ_SCHEMA_DEPENDENCE_INCOMPETENCE` | Dependência/Incompetência | Validação de ações independentes |
| 1 | `YSQ_SCHEMA_VULNERABILITY` | Vulnerabilidade ao dano ou doença | Segurança e/ou força pessoal |
| 2 | `YSQ_SCHEMA_ENMESHMENT_UNDEVELOPED_SELF` | Emaranhamento/Self subdesenvolvido | Individualização |
| 3 | `YSQ_SCHEMA_FAILURE` | Fracasso | Orientação e/ou suporte |

> ⚠️ A planilha (`Resultado RNE`) lista este domínio em outra ordem:
> Emaranhamento → Vulnerabilidade → Fracasso → Dependência. Ver §4.

### Domínio III — Limites prejudicados
`YSQ_DOMAIN_IMPAIRED_LIMITS` · `sort_order = 2`
Necessidade central: **Limites realistas**

| # | Código | Nome (banco) | Necessidade específica (planilha) |
|---|---|---|---|
| 0 | `YSQ_SCHEMA_ENTITLEMENT_GRANDIOSITY` | Merecimento/Grandiosidade | Limites realistas e/ou considerações empáticas |
| 1 | `YSQ_SCHEMA_INSUFFICIENT_SELF_CONTROL` | Autocontrole/Autodisciplina insuficientes | Respeito de regras e/ou disciplina |

### Domínio IV — Direcionamento para o outro
`YSQ_DOMAIN_OTHER_DIRECTEDNESS` · `sort_order = 3`
Necessidade central: **Liberdade de expressão**

| # | Código | Nome (banco) | Necessidade específica (planilha) |
|---|---|---|---|
| 0 | `YSQ_SCHEMA_SUBJUGATION` | Subjugação | Validação de inclinações naturais |
| 1 | `YSQ_SCHEMA_SELF_SACRIFICE` | Autos sacrifico ⚠️ | Aceitação incondicional |
| 2 | `YSQ_SCHEMA_APPROVAL_SEEKING` | Busca de aprovação/Reconhecimento | Validação das próprias necessidades |

### Domínio V — Supervigilância e inibição
`YSQ_DOMAIN_OVERVIGILANCE_INHIBITION` · `sort_order = 4`
Necessidade central: **Espontaneidade e lazer**

| # | Código | Nome (banco) | Necessidade específica (planilha) |
|---|---|---|---|
| 0 | `YSQ_SCHEMA_NEGATIVISM_PESSIMISM` | Negativismo/Pessimismo | Relaxamento |
| 1 | `YSQ_SCHEMA_EMOTIONAL_INHIBITION` | Inibição emocional | Espontaneidade |
| 2 | `YSQ_SCHEMA_UNRELENTING_STANDARDS` | Padrões inflexíveis/Crítica exagerada | Lazer e/ou prazer |
| 3 | `YSQ_SCHEMA_PUNITIVENESS` | Postura punitiva | Compaixão e/ou perdão |

> ⚠️ A planilha lista este domínio em outra ordem:
> Postura punitiva → Inibição emocional → Padrões inflexíveis → Negativismo. Ver §4.

---

## 3. Necessidades centrais (uma por domínio)

Já cadastradas em `emotional_needs`. Correspondem ao "cada domínio corresponde a uma
fase da vida" mencionado pela cliente.

| Código | Nome | Domínio |
|---|---|---|
| `EMOTIONAL_NEED_SECURE_ATTACHMENT` | Vínculos seguros | I |
| `EMOTIONAL_NEED_AUTONOMY_COMPETENCE` | Autonomia e competência | II |
| `EMOTIONAL_NEED_REALISTIC_LIMITS` | Limites realistas | III |
| `EMOTIONAL_NEED_FREEDOM_EXPRESSION` | Liberdade de expressão | IV |
| `EMOTIONAL_NEED_SPONTANEITY_PLAY` | Espontaneidade e lazer | V |

As necessidades **específicas por esquema** (coluna direita das tabelas do §2) são uma
granularidade a mais, presente só na planilha. Ainda não estão no banco.

---

## 4. Divergências a resolver com a cliente

### 4.1 Ordem interna dos domínios II e V

| Domínio | Ordem no banco | Ordem na planilha (`Resultado RNE`) |
|---|---|---|
| I | Abandono, Desconfiança, Privação, Defectividade, Isolamento | ✅ idêntica |
| II | Dependência, Vulnerabilidade, Emaranhamento, Fracasso | Emaranhamento, Vulnerabilidade, Fracasso, Dependência |
| III | Merecimento, Autocontrole | ✅ idêntica |
| IV | Subjugação, Auto sacrifício, Busca de aprovação | ✅ idêntica |
| V | Negativismo, Inibição, Padrões, Postura punitiva | Postura punitiva, Inibição, Padrões, Negativismo |

A cliente só exemplificou o Domínio I, que já bate. **Confirmar II e V.**

### 4.2 Nomes divergentes

| Banco | Planilha |
|---|---|
| Merecimento/Grandiosidade | Arrogo e Grandiosidade |
| Direcionamento para o outro (domínio IV) | Orientação para o outro |
| `Autos sacrifico` | Auto Sacrifício |

`Autos sacrifico` é erro de digitação no seed e deve ser corrigido de qualquer forma.
Os outros dois são escolha de vocabulário — vale adotar o termo da cliente.

Nomes de domínio no banco usam prefixo ordinal (`Primeiro Domínio-Desconexão e
rejeição`), sem espaço após o hífen. Para exibir na UI convém um nome curto
(`Desconexão e rejeição`) com o numeral romano separado.

### 4.3 Necessidade órfã

`Resultado RNE` linha 20 traz **"Validação de aspectos positivos da personalidade"**
sem esquema pareado — 19 necessidades para 18 esquemas. Provavelmente é uma segunda
necessidade de "Busca por aprovação". Confirmar.

### 4.4 Como medir "domínio mais ativado"

Os domínios têm de 2 a 5 esquemas, então contagem crua distorce (2 de 2 = 100% parece
menos que 4 de 5 = 80%). Opções: média dos scores, proporção de ativados, ou pico do
domínio. **Decisão clínica, pendente com a cliente.**

---

## 5. Para implementar o card agrupado

1. Incluir `schema_id` no snapshot de resultado ou fazer o join
   `question_scoring_rules → schemas → schema_domains` ao montar os dashboards.
2. Adicionar a `ConsolidatedSchemaRow`: `domainCode`, `domainName`, `domainSortOrder`,
   `schemaSortOrder` e (opcional) `emotionalNeed`.
3. Trocar o `rows.sort` global de `clinical_dashboard_builder.dart:271` por ordenação
   em dois níveis: `domainSortOrder`, depois `schemaSortOrder` — **não** por score.
4. Decidir o destino dos modos YAMI: `buildConsolidatedSchemas` também agrega YAMI, e
   modos não pertencem aos 5 domínios. Seção própria ou card separado.

---

## 6. Outros achados da planilha

- **RNE (Registro de Necessidades Emocionais)** — instrumento com avaliação por imagem
  mental, 3 pessoas significativas e descrição de ambiente. Não parece implementado.
- **Terceira figura** — o RNE avalia MÃE, PAI e **TERCEIRO**. O fluxo de estilos
  parentais do app trata apenas mãe e pai.
- **Estilos parentais cobre 17 esquemas**, não 18 — falta Isolamento Social. É
  característica do instrumento.
- **YAMI tem 10 modos**: Protetor Desligado, Criança Vulnerável, Pai Punitivo, Criança
  Zangada, Adulto Feliz, Vencido Submisso, Hipercompensador, Criança Impulsiva,
  Supercontrolador, Criança Satisfeita.
- **YSQ**: 90 itens, 5 por esquema, espaçados de 18 em 18 (esquema *n* recebe os itens
  *n*, *n*+18, *n*+36, *n*+54, *n*+72).
