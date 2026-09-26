class CheckInMode {
  const CheckInMode({
    required this.family,
    required this.clinicalName,
    required this.patientLabel,
    this.nickname,
  });

  final String family;
  final String clinicalName;
  final String patientLabel;
  final String? nickname;

  bool get isEmpty => family.isEmpty;

  factory CheckInMode.fromJson(Map<String, dynamic> json) => CheckInMode(
        family: json['family'] as String? ?? '',
        clinicalName: json['clinical_name'] as String? ?? '',
        patientLabel: json['patient_label'] as String? ?? '',
        nickname: json['nickname'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'family': family,
        'clinical_name': clinicalName,
        'patient_label': patientLabel,
        if (nickname != null && nickname!.trim().isNotEmpty)
          'nickname': nickname!.trim(),
      };

  String get displayLabel {
    final base = nickname?.trim().isNotEmpty == true ? nickname! : patientLabel;
    return base;
  }
}

// ── Catálogo de modos ──────────────────────────────────────────────────────

class ModeFamily {
  const ModeFamily({
    required this.id,
    required this.icon,
    required this.patientLabel,
    required this.clinicalLabel,
    required this.submodes,
  });

  final String id;
  final String icon;
  final String patientLabel;
  final String clinicalLabel;
  final List<ModeOption> submodes;
}

class ModeOption {
  const ModeOption({
    required this.icon,
    required this.patientLabel,
    required this.patientDescription,
    required this.clinicalName,
  });

  final String icon;
  final String patientLabel;
  final String patientDescription;
  final String clinicalName;
}

const List<ModeFamily> kModeFamilies = [
  ModeFamily(
    id: 'child',
    icon: '🧸',
    patientLabel: 'Minha parte emocional',
    clinicalLabel: 'Modos Criança',
    submodes: [
      ModeOption(
        icon: '🫧',
        patientLabel: 'Vulnerável',
        patientDescription:
            'Estou me sentindo frágil, sozinho(a), inseguro(a), triste ou precisando de cuidado.',
        clinicalName: 'Criança Vulnerável',
      ),
      ModeOption(
        icon: '🔥',
        patientLabel: 'Zangado(a)',
        patientDescription:
            'Estou com raiva porque algo importante para mim parece não estar sendo atendido.',
        clinicalName: 'Criança Zangada',
      ),
      ModeOption(
        icon: '🌋',
        patientLabel: 'Muito enfurecido(a)',
        patientDescription:
            'Minha raiva está muito intensa e difícil de conter.',
        clinicalName: 'Criança Enfurecida',
      ),
      ModeOption(
        icon: '⚡',
        patientLabel: 'Impulsivo(a)',
        patientDescription:
            'Estou com vontade de agir imediatamente, sem pensar muito nas consequências.',
        clinicalName: 'Criança Impulsiva',
      ),
      ModeOption(
        icon: '🎈',
        patientLabel: 'Indisciplinado(a)',
        patientDescription:
            'Está difícil tolerar limites, frustração ou fazer algo que exige esforço.',
        clinicalName: 'Criança Indisciplinada',
      ),
      ModeOption(
        icon: '☀️',
        patientLabel: 'Feliz',
        patientDescription:
            'Estou me sentindo seguro(a), conectado(a), espontâneo(a) ou à vontade.',
        clinicalName: 'Criança Feliz',
      ),
    ],
  ),
  ModeFamily(
    id: 'critic',
    icon: '📣',
    patientLabel: 'Minha voz crítica',
    clinicalLabel: 'Modos Pai/Mãe Disfuncionais',
    submodes: [
      ModeOption(
        icon: '📏',
        patientLabel: 'Exigente',
        patientDescription:
            'Estou me cobrando muito, sentindo que preciso fazer mais, fazer melhor ou que não posso falhar.',
        clinicalName: 'Pai/Mãe Exigente',
      ),
      ModeOption(
        icon: '🔨',
        patientLabel: 'Punitivo(a)',
        patientDescription:
            'Estou me criticando, me culpando ou sentindo que mereço ser punido(a) pelos meus erros ou pelo que sou.',
        clinicalName: 'Pai/Mãe Punitivo',
      ),
    ],
  ),
  ModeFamily(
    id: 'surrender',
    icon: '🏳️',
    patientLabel: 'Quando eu cedo',
    clinicalLabel: 'Rendição',
    submodes: [
      ModeOption(
        icon: '🤲',
        patientLabel: 'Cedendo',
        patientDescription:
            'Estou deixando minhas necessidades de lado, concordando ou fazendo o que esperam de mim para evitar conflito, rejeição ou desaprovação.',
        clinicalName: 'Capitulador Complacente',
      ),
    ],
  ),
  ModeFamily(
    id: 'avoidance',
    icon: '🛡️',
    patientLabel: 'Quando eu me afasto',
    clinicalLabel: 'Evitação/Desligamento',
    submodes: [
      ModeOption(
        icon: '🧊',
        patientLabel: 'Me desligando',
        patientDescription:
            'Estou me afastando do que sinto, ficando distante, anestesiado(a) ou evitando me envolver.',
        clinicalName: 'Protetor Desligado',
      ),
      ModeOption(
        icon: '🎧',
        patientLabel: 'Me distraindo',
        patientDescription:
            'Estou buscando estímulos, distrações ou atividades para não entrar em contato com o que estou sentindo.',
        clinicalName: 'Protetor Autoestimulador',
      ),
      ModeOption(
        icon: '🫶',
        patientLabel: 'Me aliviando',
        patientDescription:
            'Estou buscando algo que me acalme, conforte ou alivie o que estou sentindo, mesmo que só por um tempo.',
        clinicalName: 'Autoaliviador',
      ),
    ],
  ),
  ModeFamily(
    id: 'overcompensation',
    icon: '⚔️',
    patientLabel: 'Quando eu reajo',
    clinicalLabel: 'Hipercompensação',
    submodes: [
      ModeOption(
        icon: '🦅',
        patientLabel: 'Atacando',
        patientDescription:
            'Estou reagindo de forma dura, intimidando, atacando ou tentando fazer o outro recuar.',
        clinicalName: 'Predador/Ataque',
      ),
      ModeOption(
        icon: '🥊',
        patientLabel: 'Dominando',
        patientDescription:
            'Estou tentando me impor, dominar ou mostrar que sou mais forte para não me sentir vulnerável.',
        clinicalName: 'Bullying/Ataque',
      ),
      ModeOption(
        icon: '👁️',
        patientLabel: 'Desconfiado(a) e no controle',
        patientDescription:
            'Estou muito atento(a) às intenções dos outros, desconfiando e tentando manter tudo sob controle para me proteger.',
        clinicalName: 'Controlador Paranoico',
      ),
      ModeOption(
        icon: '👑',
        patientLabel: 'Por cima',
        patientDescription:
            'Estou me colocando acima dos outros, buscando reconhecimento ou agindo como se minhas necessidades e capacidades fossem mais importantes.',
        clinicalName: 'Autoengrandecimento',
      ),
    ],
  ),
  ModeFamily(
    id: 'healthy',
    icon: '🧭',
    patientLabel: 'Minha parte saudável',
    clinicalLabel: 'Adulto Saudável',
    submodes: [
      ModeOption(
        icon: '🧭',
        patientLabel: 'Cuidando de mim',
        patientDescription:
            'Consigo perceber o que estou sentindo e do que preciso, sem me abandonar nem me atacar.',
        clinicalName: 'Adulto Saudável',
      ),
      ModeOption(
        icon: '🌱',
        patientLabel: 'Escolhendo como agir',
        patientDescription:
            'Consigo pensar antes de agir e escolher uma resposta que cuide de mim e da situação.',
        clinicalName: 'Adulto Saudável',
      ),
      ModeOption(
        icon: '⚖️',
        patientLabel: 'Colocando limites',
        patientDescription:
            'Consigo respeitar minhas necessidades e as dos outros, colocando limites quando necessário.',
        clinicalName: 'Adulto Saudável',
      ),
      ModeOption(
        icon: '🤝',
        patientLabel: 'Me relacionando de forma saudável',
        patientDescription:
            'Consigo me posicionar, ouvir o outro e buscar uma resposta equilibrada.',
        clinicalName: 'Adulto Saudável',
      ),
      ModeOption(
        icon: '💙',
        patientLabel: 'Acolhendo minhas partes difíceis',
        patientDescription:
            'Consigo reconhecer minha vulnerabilidade, raiva ou medo sem deixar que eles decidam tudo por mim.',
        clinicalName: 'Adulto Saudável',
      ),
    ],
  ),
];

// ── Emoções por faixa de humor ─────────────────────────────────────────────

const Map<String, List<String>> kMoodEmotionsByRange = {
  '0-2': [
    'Desesperançoso(a)',
    'Desolado(a)',
    'Muito triste',
    'Aflito(a)',
    'Miserável',
    'Apático(a)',
    'Assustado(a)',
    'Enfurecido(a)',
  ],
  '3-4': [
    'Triste',
    'Desanimado(a)',
    'Preocupado(a)',
    'Irritado(a)',
    'Decepcionado(a)',
    'Incomodado(a)',
    'Solitário(a)',
    'Sem ânimo',
  ],
  '5': [
    'Neutro(a)',
    'Pensativo(a)',
    'Indiferente',
    'Estável',
  ],
  '6-7': [
    'À vontade',
    'Calmo(a)',
    'Tranquilo(a)',
    'Contente',
    'Acolhido(a)',
    'Grato(a)',
    'Seguro(a)',
    'Satisfeito(a)',
  ],
  '8-10': [
    'Feliz',
    'Animado(a)',
    'Otimista',
    'Inspirado(a)',
    'Motivado(a)',
    'Amoroso(a)',
    'Entusiasmado(a)',
    'Realizado(a)',
  ],
};

const Map<int, String> kMoodLabels = {
  0: 'Péssimo',
  1: 'Muito mal',
  2: 'Mal',
  3: 'Para baixo',
  4: 'Não muito bem',
  5: 'Neutro',
  6: 'Razoavelmente bem',
  7: 'Bem',
  8: 'Muito bem',
  9: 'Ótimo',
  10: 'Excelente',
};

const List<String> kMoodEmojis = [
  '😭', // 0
  '😞', // 1
  '😔', // 2
  '😟', // 3
  '😕', // 4
  '😐', // 5
  '🙂', // 6
  '😊', // 7
  '😄', // 8
  '😁', // 9
  '🤩', // 10
];

List<String> emotionsForScore(int score) {
  if (score <= 2) return kMoodEmotionsByRange['0-2']!;
  if (score <= 4) return kMoodEmotionsByRange['3-4']!;
  if (score == 5) return kMoodEmotionsByRange['5']!;
  if (score <= 7) return kMoodEmotionsByRange['6-7']!;
  return kMoodEmotionsByRange['8-10']!;
}
