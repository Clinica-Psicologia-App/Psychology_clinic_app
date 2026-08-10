class MentalCaseMap {
  const MentalCaseMap({
    required this.center,
    required this.primaryNodes,
    required this.contextNodes,
  });

  static const empty = MentalCaseMap(
    center: MentalCaseMapCenter.empty,
    primaryNodes: [],
    contextNodes: [],
  );

  final MentalCaseMapCenter center;
  final List<MentalCaseMapNode> primaryNodes;
  final List<MentalCaseMapNode> contextNodes;

  List<MentalCaseMapNode> get allNodes => [...primaryNodes, ...contextNodes];
}

class MentalCaseMapCenter {
  const MentalCaseMapCenter({
    required this.patientName,
    required this.activeProblemsLabel,
    required this.activeGoalsLabel,
    required this.lastCheckInLabel,
    this.initials = 'P',
    this.avatarType = MentalCaseMapAvatarType.initials,
    this.photoUrl,
    this.avatarConfig,
  });

  static const empty = MentalCaseMapCenter(
    patientName: 'Paciente',
    activeProblemsLabel: 'Sem problemas ativos',
    activeGoalsLabel: 'Sem objetivos ativos',
    lastCheckInLabel: 'Sem check-in',
  );

  final String patientName;
  final String activeProblemsLabel;
  final String activeGoalsLabel;
  final String lastCheckInLabel;

  /// Iniciais para fallback quando o avatar não tem foto ou artwork.
  final String initials;

  final MentalCaseMapAvatarType avatarType;
  final String? photoUrl;

  /// Config de artwork customizado (mapa livre de chaves).
  final Map<String, dynamic>? avatarConfig;
}

/// Espelha [AvatarType] do domínio de perfil sem criar dependência direta.
enum MentalCaseMapAvatarType { photo, custom, initials }

class MentalCaseMapNode {
  const MentalCaseMapNode({
    required this.id,
    required this.title,
    required this.shortLabel,
    required this.items,
    required this.emptyLabel,
    required this.dataSource,
    this.lastUpdatedAt,
    this.responseId,
    this.aggregateSeverityColorKey,
  });

  final String id;
  final String title;
  final String shortLabel;
  final List<String> items;
  final String emptyLabel;
  final String dataSource;
  final DateTime? lastUpdatedAt;
  final String? responseId;

  /// Pior severidade clínica entre os destaques deste nó.
  /// Valores possíveis: `green`, `yellow`, `amber`, `orange`, `red` ou `null`.
  final String? aggregateSeverityColorKey;

  bool get isEmpty => items.isEmpty;

  bool get isFilled => items.isNotEmpty;
}
