/// Capítulos da vida da Tela 2 (Minha História / Linha do Tempo).
/// As `key` batem com o CHECK de `patient_timeline_events.life_chapter`.
enum LifeChapter {
  birth,
  childhood,
  adolescence,
  adulthood,
  maturity,
  today,
}

extension LifeChapterMeta on LifeChapter {
  String get key => switch (this) {
        LifeChapter.birth => 'birth',
        LifeChapter.childhood => 'childhood',
        LifeChapter.adolescence => 'adolescence',
        LifeChapter.adulthood => 'adulthood',
        LifeChapter.maturity => 'maturity',
        LifeChapter.today => 'today',
      };

  String get label => switch (this) {
        LifeChapter.birth => 'Meu Nascimento',
        LifeChapter.childhood => 'Minha Infância',
        LifeChapter.adolescence => 'Minha Adolescência',
        LifeChapter.adulthood => 'Minha Vida Adulta',
        LifeChapter.maturity => 'Maturidade',
        LifeChapter.today => 'Minha Vida Hoje',
      };
}

/// Ordem cronológica canônica dos capítulos.
const List<LifeChapter> kLifeChaptersInOrder = LifeChapter.values;

LifeChapter? lifeChapterFromKey(String? key) {
  if (key == null) return null;
  for (final chapter in LifeChapter.values) {
    if (chapter.key == key) return chapter;
  }
  return null;
}
