/// Crenças em formação da Tela 2 ("o que você passou a pensar sobre você
/// mesmo(a)?"). As `key` batem com o CHECK de
/// `patient_timeline_events.belief_keys`.
enum TimelineBelief {
  notImportant,
  inadequate,
  mustPlease,
  cannotTrust,
  mustHandleAlone,
  mustBePerfect,
  iAmABurden,
  feelingsAreDangerous,
}

extension TimelineBeliefMeta on TimelineBelief {
  String get key => switch (this) {
        TimelineBelief.notImportant => 'not_important',
        TimelineBelief.inadequate => 'inadequate',
        TimelineBelief.mustPlease => 'must_please',
        TimelineBelief.cannotTrust => 'cannot_trust',
        TimelineBelief.mustHandleAlone => 'must_handle_alone',
        TimelineBelief.mustBePerfect => 'must_be_perfect',
        TimelineBelief.iAmABurden => 'i_am_a_burden',
        TimelineBelief.feelingsAreDangerous => 'feelings_are_dangerous',
      };

  String get label => switch (this) {
        TimelineBelief.notImportant => 'Não sou importante.',
        TimelineBelief.inadequate => 'Sou inadequado(a).',
        TimelineBelief.mustPlease => 'Preciso agradar para ser amado(a).',
        TimelineBelief.cannotTrust => 'Não posso confiar nas pessoas.',
        TimelineBelief.mustHandleAlone => 'Tenho que resolver tudo sozinho(a).',
        TimelineBelief.mustBePerfect => 'Preciso ser perfeito(a).',
        TimelineBelief.iAmABurden => 'Sou um peso.',
        TimelineBelief.feelingsAreDangerous =>
          'Mostrar sentimentos é perigoso.',
      };
}

const List<TimelineBelief> kTimelineBeliefsInOrder = TimelineBelief.values;

TimelineBelief? timelineBeliefFromKey(String? key) {
  if (key == null) return null;
  for (final belief in TimelineBelief.values) {
    if (belief.key == key) return belief;
  }
  return null;
}

/// Converte a lista de chaves persistida (`text[]`) em enums, ignorando
/// valores desconhecidos.
List<TimelineBelief> timelineBeliefsFromKeys(dynamic raw) {
  if (raw is! List) return const [];
  final result = <TimelineBelief>[];
  for (final item in raw) {
    final belief = timelineBeliefFromKey(item as String?);
    if (belief != null) result.add(belief);
  }
  return result;
}
