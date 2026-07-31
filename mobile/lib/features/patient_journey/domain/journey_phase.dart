/// Fases clínicas encadeadas da jornada terapêutica.
///
/// Modelo proposto pela equipe clínica: o acompanhamento segue um raciocínio
/// encadeado — primeiro conhecer o paciente, depois avaliar, compreender o
/// quadro, intervir e, por fim, acompanhar a evolução.
enum JourneyPhase {
  conhecer,
  avaliar,
  compreender,
  intervir,
  acompanhar,
}

extension JourneyPhaseMeta on JourneyPhase {
  /// Rótulo curto da fase (ex.: "Conhecer").
  String get label => switch (this) {
        JourneyPhase.conhecer => 'Conhecer',
        JourneyPhase.avaliar => 'Avaliar',
        JourneyPhase.compreender => 'Compreender',
        JourneyPhase.intervir => 'Intervir',
        JourneyPhase.acompanhar => 'Acompanhar',
      };

  /// Subtítulo orientador, voltado ao paciente.
  String get subtitle => switch (this) {
        JourneyPhase.conhecer => 'Sua história e contexto',
        JourneyPhase.avaliar => 'Instrumentos e avaliação',
        JourneyPhase.compreender => 'Entendendo o quadro',
        JourneyPhase.intervir => 'Plano e recursos',
        JourneyPhase.acompanhar => 'Evolução ao longo do tempo',
      };

  /// Número da fase (1..5), para exibição.
  int get stepNumber => index + 1;
}
