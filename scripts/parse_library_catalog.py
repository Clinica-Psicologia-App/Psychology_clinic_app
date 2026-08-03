"""Extrai as 93 fichas do documento mestre de Filmes/Séries para JSON.

Uso:
  python scripts/parse_library_catalog.py <caminho_txt> <saida_json>

O <caminho_txt> é o texto extraído do .docx (word/document.xml sem tags).
Gera uma lista de obras com metadados + camada do psicólogo + camada do paciente.
"""
import json
import re
import sys

# Rótulos que marcam o início de um campo (e, portanto, o fim do anterior).
SINGLE = {
    'Título de exibição': 'display_title',
    'Título original': 'original_title',
    'Tipo': 'work_type',
    'Ano': 'year',
    'Gênero': 'genres',
    'Duração': 'duration',
    'Temporadas': 'seasons',
    'Episódios': 'episodes',
    'Classificação': 'rating',
    'Onde assistir': 'where_to_watch',
    'Esquemas associados': 'associated_schemas',
    'Intensidade clínica': 'intensity',
    'Intensidade sugerida': 'intensity',
}
PSY_LIST = {
    'Temas terapêuticos': 'themes',
    'Quando indicar': 'when_to_indicate',
    'Objetivos terapêuticos': 'objectives',
    'Focos de observação': 'observation_focus',
    'Possíveis mobilizações emocionais': 'emotional_mobilizations',
    'Cuidados clínicos e alertas': 'clinical_cautions',
    'Modos esquemáticos mais ativados': 'schema_modes',
    'Possibilidades de intervenção em sessão': 'session_interventions',
    'Perguntas para exploração em sessão': 'session_questions',
}
PSY_TEXT = {
    'Sinopse clínica': 'synopsis',
    'Observação clínica': 'clinical_note',
}
PAT_TEXT = {'Antes de assistir': 'patient_before'}
PAT_LIST = {'Durante a obra': 'patient_during'}
PAT_QUESTIONS = {'Depois de assistir': 'patient_after'}

SECTIONS = {'CAMADA DO PSICÓLOGO', 'CAMADA DO PACIENTE', 'REGISTRO DA INDICAÇÃO'}

ALL_LABELS = set()
for d in (SINGLE, PSY_LIST, PSY_TEXT, PAT_TEXT, PAT_LIST, PAT_QUESTIONS):
    ALL_LABELS.update(d.keys())
ALL_LABELS.update(SECTIONS)


def is_boundary(line):
    s = line.strip()
    return (
        s in ALL_LABELS
        or s.startswith('FICHA ')
        or s.startswith('ESQUEMA ')
        or s.startswith('Indexação clínica')
    )


def field_key(label):
    for d in (SINGLE, PSY_LIST, PSY_TEXT, PAT_TEXT, PAT_LIST, PAT_QUESTIONS):
        if label in d:
            return d[label]
    return None


def parse(text):
    lines = text.split('\n')
    # Índices onde começa cada ficha.
    starts = [i for i, l in enumerate(lines) if l.strip().startswith('FICHA ')]
    starts.append(len(lines))

    works = []
    for k in range(len(starts) - 1):
        block = lines[starts[k]:starts[k + 1]]
        works.append(parse_ficha(block))
    return works


def parse_ficha(block):
    w = {
        'ficha': None, 'title': None, 'primary_schema': None, 'domain': None,
    }
    # cabeçalho
    m = re.match(r'FICHA\s+(\d+)', block[0].strip())
    w['ficha'] = int(m.group(1)) if m else None
    # título = primeira linha não vazia após a linha FICHA
    idx = 1
    while idx < len(block) and not block[idx].strip():
        idx += 1
    if idx < len(block):
        w['title'] = block[idx].strip()

    section = 'meta'
    i = 0
    while i < len(block):
        line = block[i]
        s = line.strip()
        if s.startswith('Indexação clínica'):
            mp = re.search(r'Esquema principal:\s*([^|]+)', s)
            md = re.search(r'Dom[ií]nio:\s*(.+)$', s)
            if mp:
                w['primary_schema'] = mp.group(1).strip()
            if md:
                w['domain'] = md.group(1).strip()
            i += 1
            continue
        if s == 'CAMADA DO PSICÓLOGO':
            section = 'psy'
            i += 1
            continue
        if s == 'CAMADA DO PACIENTE':
            section = 'patient'
            i += 1
            continue
        if s == 'REGISTRO DA INDICAÇÃO':
            break  # boilerplate igual em toda ficha
        key = field_key(s) if s in ALL_LABELS else None
        if key:
            # coletar linhas até o próximo boundary
            vals = []
            j = i + 1
            while j < len(block) and not is_boundary(block[j]):
                if block[j].strip():
                    vals.append(block[j].strip())
                j += 1
            store(w, s, key, vals)
            i = j
            continue
        i += 1
    return w


def store(w, label, key, vals):
    if not vals:
        return
    if label in SINGLE:
        val = vals[0]
        if label == 'Esquemas associados':
            w[key] = [x.strip() for x in re.split(r'[,;]', ' '.join(vals)) if x.strip()]
        elif label == 'Título original' and val == '—':
            w[key] = None
        else:
            w[key] = val
    elif label in PSY_TEXT or label in PAT_TEXT:
        w[key] = ' '.join(vals)
    elif label in PAT_QUESTIONS:
        w[key] = parse_questions(vals)
    else:  # listas
        w[key] = vals


def parse_questions(vals):
    """Depois de assistir: pares (pergunta, tipo de campo)."""
    questions = []
    current = None
    for v in vals:
        mt = re.match(r'Tipo de campo:\s*(.+)$', v)
        if mt:
            if current is not None:
                current['field_type'] = mt.group(1).strip()
        else:
            # nova pergunta (pode ou não começar com número)
            q = re.sub(r'^\d+\.\s*', '', v)
            current = {'question': q, 'field_type': None}
            questions.append(current)
    return questions


def main():
    src, out = sys.argv[1], sys.argv[2]
    text = open(src, encoding='utf-8').read()
    works = parse(text)
    json.dump(works, open(out, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)

    # validação
    print(f'Fichas extraídas: {len(works)}')
    faltando = {}
    for req in ['title', 'work_type', 'year', 'primary_schema', 'synopsis',
                'patient_before', 'patient_after']:
        n = sum(1 for w in works if not w.get(req))
        if n:
            faltando[req] = n
    print('Campos ausentes por obra:', faltando or 'nenhum')
    tipos = {}
    for w in works:
        t = (w.get('work_type') or '?')
        tipos[t] = tipos.get(t, 0) + 1
    print('Tipos:', tipos)
    # amostra
    print('\n--- Amostra (ficha 1) ---')
    print(json.dumps(works[0], ensure_ascii=False, indent=2)[:1400])


if __name__ == '__main__':
    main()
