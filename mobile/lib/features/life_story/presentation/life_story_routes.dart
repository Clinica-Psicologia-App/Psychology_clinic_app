/// Rotas do fluxo "Minha História / Linha do Tempo" (etapa Conhecer, Tela 2).
///
/// Nasce em paralelo à tela antiga de timeline — não a substitui ainda.
abstract final class LifeStoryRoutes {
  /// A trilha do paciente (resultado visual) e ponto de entrada.
  static const myHistory = '/patient/my-history';

  /// O fluxo em etapas para registrar um novo acontecimento.
  static const newEvent = '/patient/my-history/new';

  /// "Aprofundar este momento" — recebe o evento via `extra`.
  static const deepen = '/patient/my-history/deepen';

  /// Tela 3 — Minha Família (Genograma).
  static const myFamily = '/patient/my-family';

  /// "Aprofundar a relação" com uma pessoa — recebe a pessoa via `extra`.
  static const deepenRelationship = '/patient/my-family/deepen';

  /// Clima e padrões familiares — recebe o contexto atual via `extra`.
  static const familyContext = '/patient/my-family/context';
}
