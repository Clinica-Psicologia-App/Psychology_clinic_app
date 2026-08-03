"""Gera a migração do catálogo da Biblioteca a partir do works.json.

  python scripts/gen_library_migration.py <works.json> <saida.sql>

Emite: CREATE TABLE library_works + RLS + INSERT das 93 obras (idempotente).
As duas camadas (psicólogo/paciente) vão em JSONB. Tipos de animação são
normalizados para o tipo base + flag is_animation.
"""
import json
import re
import sys


def norm_type(t):
    t = (t or '').strip()
    anim = 'anima' in t.lower()
    base = 'Filme'
    if 'Miniss' in t:
        base = 'Minissérie'
    elif 'Epis' in t:
        base = 'Episódio'
    elif 'Série' in t or 'Serie' in t:
        base = 'Série'
    elif 'Filme' in t:
        base = 'Filme'
    return base, anim


def year_int(y):
    if not y:
        return 'null'
    m = re.search(r'(\d{4})', str(y))
    return m.group(1) if m else 'null'


def q(s):
    """Dollar-quote seguro para texto."""
    if s is None:
        return 'null'
    return "$lib$" + str(s) + "$lib$"


def arr(xs):
    if not xs:
        return "'{}'::text[]"
    items = ",".join("$lib$" + str(x).replace("$lib$", "") + "$lib$" for x in xs)
    return f"ARRAY[{items}]::text[]"


def jb(obj):
    if obj is None:
        return "'null'::jsonb"
    s = json.dumps(obj, ensure_ascii=False).replace("$lib$", "")
    return "$lib$" + s + "$lib$::jsonb"


HEADER = """-- Catálogo da Biblioteca (Terapia do Esquema com Filmes/Séries).
-- Curadoria do admin; leitura pelo staff. A indicação ao paciente e o acesso
-- do paciente entram numa migração seguinte (fluxo de indicação).

CREATE TABLE IF NOT EXISTS public.library_works (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ficha_number INT,
  display_title TEXT NOT NULL,
  original_title TEXT,
  work_type TEXT NOT NULL,
  is_animation BOOLEAN NOT NULL DEFAULT false,
  year INT,
  genres TEXT,
  duration TEXT,
  seasons TEXT,
  rating TEXT,
  synopsis TEXT,
  primary_schema TEXT,
  domain TEXT,
  associated_schemas TEXT[] NOT NULL DEFAULT '{}',
  themes TEXT[] NOT NULL DEFAULT '{}',
  intensity TEXT,
  cover_url TEXT,
  psychologist_layer JSONB NOT NULL DEFAULT '{}'::jsonb,
  patient_layer JSONB NOT NULL DEFAULT '{}'::jsonb,
  is_published BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE UNIQUE INDEX IF NOT EXISTS library_works_ficha_key
  ON public.library_works (ficha_number);

ALTER TABLE public.library_works ENABLE ROW LEVEL SECURITY;

-- Staff (psicólogo/admin) lê o catálogo publicado.
DROP POLICY IF EXISTS library_works_select_staff ON public.library_works;
CREATE POLICY library_works_select_staff
  ON public.library_works FOR SELECT TO authenticated
  USING (public.current_role()::TEXT <> 'patient' AND is_published);

-- Admin gerencia o catálogo.
DROP POLICY IF EXISTS library_works_admin_all ON public.library_works;
CREATE POLICY library_works_admin_all
  ON public.library_works FOR ALL TO authenticated
  USING (public.current_role()::TEXT IN ('platform_admin', 'admin'))
  WITH CHECK (public.current_role()::TEXT IN ('platform_admin', 'admin'));

-- ── Seed do catálogo (idempotente por ficha_number) ──────────────────────────
"""


def insert(w):
    base, anim = norm_type(w.get('work_type'))
    psy = {k: w.get(k) for k in [
        'when_to_indicate', 'objectives', 'observation_focus',
        'emotional_mobilizations', 'clinical_cautions', 'schema_modes',
        'session_interventions', 'session_questions', 'clinical_note',
    ] if w.get(k) is not None}
    pat = {k: w.get(k) for k in [
        'patient_before', 'patient_during', 'patient_after', 'where_to_watch',
    ] if w.get(k) is not None}
    return f"""INSERT INTO public.library_works (
  ficha_number, display_title, original_title, work_type, is_animation, year,
  genres, duration, seasons, rating, synopsis, primary_schema, domain,
  associated_schemas, themes, intensity, psychologist_layer, patient_layer
) VALUES (
  {w.get('ficha') or 'null'}, {q(w.get('display_title') or w.get('title'))},
  {q(w.get('original_title'))}, {q(base)}, {str(anim).lower()},
  {year_int(w.get('year'))}, {q(w.get('genres'))}, {q(w.get('duration'))},
  {q(w.get('seasons'))}, {q(w.get('rating'))}, {q(w.get('synopsis'))},
  {q(w.get('primary_schema'))}, {q(w.get('domain'))},
  {arr(w.get('associated_schemas'))}, {arr(w.get('themes'))},
  {q(w.get('intensity'))}, {jb(psy)}, {jb(pat)}
)
ON CONFLICT (ficha_number) DO UPDATE SET
  display_title = EXCLUDED.display_title,
  work_type = EXCLUDED.work_type,
  is_animation = EXCLUDED.is_animation,
  year = EXCLUDED.year,
  synopsis = EXCLUDED.synopsis,
  primary_schema = EXCLUDED.primary_schema,
  associated_schemas = EXCLUDED.associated_schemas,
  themes = EXCLUDED.themes,
  psychologist_layer = EXCLUDED.psychologist_layer,
  patient_layer = EXCLUDED.patient_layer,
  updated_at = timezone('utc', now());
"""


def main():
    works = json.load(open(sys.argv[1], encoding='utf-8'))
    out = [HEADER]
    for w in works:
        out.append(insert(w))
    open(sys.argv[2], 'w', encoding='utf-8').write("\n".join(out))
    print(f'Migração gerada com {len(works)} obras: {sys.argv[2]}')


if __name__ == '__main__':
    main()
