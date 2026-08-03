import 'package:flutter/material.dart';

import '../../profile/domain/avatar_config.dart';
import '../../profile/domain/avatar_type.dart';

/// Conteúdo consolidado que alimenta o pôster/infográfico do paciente.
///
/// É um modelo puramente de apresentação: o builder determinístico
/// (Estágio 2) o preenche a partir dos dados reais do paciente
/// (dashboard consolidado, conceitualização, linha do tempo, cadastro).
/// O widget do pôster só sabe desenhar este modelo.
class PatientInfographicData {
  const PatientInfographicData({
    required this.header,
    this.quote,
    this.timeline = const [],
    this.schemas = const [],
    this.needs = const [],
    this.modes = const [],
    this.strengths = const [],
    this.challenges = const [],
    this.directions = const [],
    this.personality = const [],
    this.resources = const [],
    this.closingLine,
  });

  final InfographicHeader header;

  /// Frase de abertura/identidade (entre aspas no pôster).
  final String? quote;

  final List<InfographicTimelineEntry> timeline;
  final List<InfographicItem> schemas;
  final List<InfographicNeed> needs;
  final List<InfographicItem> modes;

  /// Pontos fortes e potenciais.
  final List<InfographicItem> strengths;

  /// Desafios na vida adulta.
  final List<InfographicItem> challenges;

  /// Direções terapêuticas.
  final List<InfographicItem> directions;

  /// Personalidade (Big Five). Só aparece quando há dados de instrumento.
  final List<InfographicPersonalityDomain> personality;

  /// Recursos e forças (chips curtos).
  final List<InfographicItem> resources;

  /// Mensagem final de acolhimento (rodapé).
  final String? closingLine;

  bool get hasTimeline => timeline.isNotEmpty;
  bool get hasSchemas => schemas.isNotEmpty;
  bool get hasNeeds => needs.isNotEmpty;
  bool get hasModes => modes.isNotEmpty;
  bool get hasStrengths => strengths.isNotEmpty;
  bool get hasChallenges => challenges.isNotEmpty;
  bool get hasDirections => directions.isNotEmpty;
  bool get hasPersonality => personality.isNotEmpty;
  bool get hasResources => resources.isNotEmpty;
}

/// Domínio de personalidade (Big Five) com escore e classificação.
class InfographicPersonalityDomain {
  const InfographicPersonalityDomain({
    required this.name,
    required this.score,
    this.maxScore = 100,
    this.classification,
    this.meaning,
    this.icon = Icons.circle,
    this.accent,
  });

  final String name;
  final double score;
  final double maxScore;
  final String? classification;
  final String? meaning;
  final IconData icon;
  final Color? accent;

  double get fraction => (score / maxScore).clamp(0.0, 1.0);
}

/// Cabeçalho: identificação e bio curta do paciente.
class InfographicHeader {
  const InfographicHeader({
    required this.name,
    this.avatarInitials,
    this.avatarType = AvatarType.initials,
    this.photoUrl,
    this.avatarConfig,
    this.facts = const [],
  });

  final String name;
  final String? avatarInitials;

  /// Dados do avatar real da conta do paciente (foto, avatar geométrico ou
  /// iniciais). Renderizado com o mesmo componente do resto do app.
  final AvatarType avatarType;
  final String? photoUrl;
  final AvatarConfig? avatarConfig;

  /// Linhas de bio: (ícone, texto). Ex.: (person, "39 anos").
  final List<InfographicFact> facts;
}

class InfographicFact {
  const InfographicFact(this.icon, this.text);
  final IconData icon;
  final String text;
}

/// Uma entrada da linha do tempo: rótulo do período + descrição do evento.
class InfographicTimelineEntry {
  const InfographicTimelineEntry({
    required this.periodLabel,
    required this.description,
    this.icon = Icons.circle,
    this.accent,
  });

  final String periodLabel;
  final String description;
  final IconData icon;
  final Color? accent;
}

/// Item genérico com ícone, título e descrição (esquemas, modos, recursos).
class InfographicItem {
  const InfographicItem({
    required this.title,
    this.description,
    this.bullets = const [],
    this.icon = Icons.circle,
    this.accent,
  });

  final String title;
  final String? description;

  /// Sub-pontos (bullets) — usado nos modos ativos, como na referência.
  final List<String> bullets;
  final IconData icon;
  final Color? accent;
}

/// Necessidade emocional + evento(s) de vida relacionado(s).
class InfographicNeed {
  const InfographicNeed({
    required this.need,
    this.relatedEvents,
    this.icon = Icons.favorite_border,
    this.accent,
  });

  final String need;
  final String? relatedEvents;
  final IconData icon;
  final Color? accent;
}
