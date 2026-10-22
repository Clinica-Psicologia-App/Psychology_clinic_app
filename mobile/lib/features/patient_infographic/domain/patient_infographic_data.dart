import 'package:flutter/material.dart';

import '../../genogram/domain/genogram_data.dart';
import '../../initial_assessment/domain/life_area.dart';
import '../../profile/domain/avatar_config.dart';
import '../../profile/domain/avatar_type.dart';

/// Conteúdo consolidado que alimenta o pôster/infográfico do paciente.
///
/// É um modelo puramente de apresentação: o builder determinístico
/// preenche o modelo a partir dos dados reais do paciente (cadastro, Conhecer,
/// Avaliar e Compreender). O widget do pôster só sabe desenhar este modelo.
///
/// As seções seguem a ordem em que o terapeuta preenche o caso: demandas,
/// contexto de vida, personalidade, história, genograma, esquemas, modos,
/// apego, recursos saudáveis e plano terapêutico.
class PatientInfographicData {
  const PatientInfographicData({
    required this.header,
    this.reasonsInitial,
    this.reasonsCurrent,
    this.demands = const [],
    this.lifeWheel = const {},
    this.personality = const [],
    this.timeline = const [],
    this.genogram,
    this.genogramMembers = const [],
    this.schemas = const [],
    this.modes = const [],
    this.coping = const [],
    this.attachment,
    this.resources = const [],
    this.plan = const [],
    this.closingLine,
    this.generatedOn,
  });

  final InfographicHeader header;

  /// Demandas terapêuticas — motivos da procura (inicial e atual), de
  /// Conhecer › Demandas Terapêuticas.
  final String? reasonsInitial;
  final String? reasonsCurrent;

  /// Demandas/focos abertos já cadastrados (`patient_problems`).
  final List<InfographicItem> demands;

  /// Roda da Vida: satisfação 1–10 por área (só áreas respondidas), de
  /// Conhecer › Contexto de Vida.
  final Map<LifeArea, int> lifeWheel;

  /// Personalidade (Big Five). Só aparece quando há dados de instrumento.
  final List<InfographicPersonalityDomain> personality;

  final List<InfographicTimelineEntry> timeline;

  /// Genograma sem pessoas sensíveis, para o desenho. O pôster só desenha
  /// quando há estrutura suficiente; senão usa [genogramMembers].
  final GenogramData? genogram;

  /// Membros do genograma (sem sensíveis) — alternativa quando não há estrutura
  /// para desenhar.
  final List<InfographicGenogramMember> genogramMembers;

  final List<InfographicItem> schemas;

  /// Modos esquemáticos ativados no YAMI.
  final List<InfographicItem> modes;

  /// Estilos de enfrentamento (YCI/YRAI).
  final List<InfographicItem> coping;

  /// Estilo de apego principal, com breve explicação.
  final InfographicItem? attachment;

  /// Recursos saudáveis (Conhecer › Recursos Saudáveis).
  final List<InfographicItem> resources;

  /// Plano terapêutico — metas ativas (Intervir › Plano Terapêutico).
  final List<InfographicItem> plan;

  /// Mensagem final de acolhimento (rodapé).
  final String? closingLine;

  /// Data de geração do material (rodapé de documento).
  final DateTime? generatedOn;

  bool get hasReasons =>
      (reasonsInitial ?? '').trim().isNotEmpty ||
      (reasonsCurrent ?? '').trim().isNotEmpty;
  bool get hasDemands => hasReasons || demands.isNotEmpty;
  bool get hasLifeWheel => lifeWheel.isNotEmpty;
  bool get hasPersonality => personality.isNotEmpty;
  bool get hasTimeline => timeline.isNotEmpty;
  bool get hasGenogram => genogramMembers.isNotEmpty;
  bool get hasSchemas => schemas.isNotEmpty;
  bool get hasModes => modes.isNotEmpty;
  bool get hasCoping => coping.isNotEmpty;
  bool get hasAttachment => attachment != null;
  bool get hasResources => resources.isNotEmpty;
  bool get hasPlan => plan.isNotEmpty;

  /// Média de satisfação da Roda da Vida (0 se vazia).
  double get lifeWheelAverage => lifeWheel.isEmpty
      ? 0
      : lifeWheel.values.reduce((a, b) => a + b) / lifeWheel.length;

  /// Quantas seções de conteúdo (fora o cabeçalho) têm dados.
  int get contentSectionCount => [
        hasDemands,
        hasLifeWheel,
        hasPersonality,
        hasTimeline,
        hasGenogram,
        hasSchemas,
        hasModes || hasCoping,
        hasAttachment,
        hasResources,
        hasPlan,
      ].where((v) => v).length;

  /// Há ao menos uma seção de conteúdo preenchida.
  bool get hasAnyContent => contentSectionCount > 0;

  /// Conteúdo mínimo — sugere ao profissional completar o caso.
  bool get isSparse => contentSectionCount <= 2;
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
    this.badge,
    this.bullets = const [],
    this.icon = Icons.circle,
    this.accent,
  });

  final String title;
  final String? description;

  /// Pontuação/nível mostrado ao lado do título (ex.: "Média 4,3").
  final String? badge;

  /// Sub-pontos (bullets) — usado nos modos ativos, como na referência.
  final List<String> bullets;
  final IconData icon;
  final Color? accent;
}

/// Membro do genograma resumido para o pôster.
class InfographicGenogramMember {
  const InfographicGenogramMember({
    required this.name,
    this.relationship,
    this.isDeceased = false,
  });

  final String name;
  final String? relationship;
  final bool isDeceased;
}
