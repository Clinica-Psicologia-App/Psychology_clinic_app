/// Enums da camada emocional da relação no Genograma (Tela 3).
/// Rótulos literais da spec. Etapas 5 e 6 (§24, §25) retiradas conforme
/// a própria spec sugere.
library;

/// Etapa 3 (§22) — papel de cuidado.
enum CaregiverRole { important, partial, no, dontKnow }

extension CaregiverRoleMeta on CaregiverRole {
  String get key => switch (this) {
        CaregiverRole.important => 'important',
        CaregiverRole.partial => 'partial',
        CaregiverRole.no => 'no',
        CaregiverRole.dontKnow => 'dont_know',
      };
  String get label => switch (this) {
        CaregiverRole.important => 'Sim, teve um papel importante',
        CaregiverRole.partial => 'Sim, em alguns períodos',
        CaregiverRole.no => 'Não',
        CaregiverRole.dontKnow => 'Não sei',
      };
}

const kCaregiverRolesInOrder = CaregiverRole.values;
CaregiverRole? caregiverRoleFromKey(String? k) {
  for (final v in CaregiverRole.values) {
    if (v.key == k) return v;
  }
  return null;
}

/// Etapa 4 (§23) — "como você descreveria essa relação?"
enum BondType {
  closeAffectionate,
  distant,
  conflictual,
  ambivalent,
  broken,
  changed,
  other,
}

extension BondTypeMeta on BondType {
  String get key => switch (this) {
        BondType.closeAffectionate => 'close_affectionate',
        BondType.distant => 'distant',
        BondType.conflictual => 'conflictual',
        BondType.ambivalent => 'ambivalent',
        BondType.broken => 'broken',
        BondType.changed => 'changed',
        BondType.other => 'other',
      };
  String get label => switch (this) {
        BondType.closeAffectionate => 'Próxima e afetiva',
        BondType.distant => 'Distante',
        BondType.conflictual => 'Conflituosa',
        BondType.ambivalent =>
          'Ambivalente — próxima em alguns momentos e difícil em outros',
        BondType.broken => 'Rompida',
        BondType.changed => 'Mudou muito ao longo do tempo',
        BondType.other => 'Outra',
      };
}

const kBondTypesInOrder = BondType.values;
BondType? bondTypeFromKey(String? k) {
  for (final v in BondType.values) {
    if (v.key == k) return v;
  }
  return null;
}

/// Etapa 7 (§26) — "quando estava com essa pessoa, geralmente se sentia..."
enum FeltInRelationship {
  safe,
  loved,
  accepted,
  understood,
  valued,
  respected,
  protected,
  freeToBe,
  freeToSpeak,
  encouragedAutonomy,
  calm,
  happy,
  afraid,
  alone,
  rejected,
  criticized,
  controlled,
  responsibleForThem,
  walkingOnEggshells,
  other,
}

extension FeltInRelationshipMeta on FeltInRelationship {
  String get key => switch (this) {
        FeltInRelationship.safe => 'safe',
        FeltInRelationship.loved => 'loved',
        FeltInRelationship.accepted => 'accepted',
        FeltInRelationship.understood => 'understood',
        FeltInRelationship.valued => 'valued',
        FeltInRelationship.respected => 'respected',
        FeltInRelationship.protected => 'protected',
        FeltInRelationship.freeToBe => 'free_to_be',
        FeltInRelationship.freeToSpeak => 'free_to_speak',
        FeltInRelationship.encouragedAutonomy => 'encouraged_autonomy',
        FeltInRelationship.calm => 'calm',
        FeltInRelationship.happy => 'happy',
        FeltInRelationship.afraid => 'afraid',
        FeltInRelationship.alone => 'alone',
        FeltInRelationship.rejected => 'rejected',
        FeltInRelationship.criticized => 'criticized',
        FeltInRelationship.controlled => 'controlled',
        FeltInRelationship.responsibleForThem => 'responsible_for_them',
        FeltInRelationship.walkingOnEggshells => 'walking_on_eggshells',
        FeltInRelationship.other => 'other',
      };
  String get label => switch (this) {
        FeltInRelationship.safe => 'Seguro(a)',
        FeltInRelationship.loved => 'Amado(a)',
        FeltInRelationship.accepted => 'Aceito(a)',
        FeltInRelationship.understood => 'Compreendido(a)',
        FeltInRelationship.valued => 'Valorizado(a)',
        FeltInRelationship.respected => 'Respeitado(a)',
        FeltInRelationship.protected => 'Protegido(a)',
        FeltInRelationship.freeToBe => 'Livre para ser quem eu era',
        FeltInRelationship.freeToSpeak => 'Livre para falar do que sentia',
        FeltInRelationship.encouragedAutonomy =>
          'Incentivado(a) a aprender e fazer as coisas sozinho(a)',
        FeltInRelationship.calm => 'Tranquilo(a)',
        FeltInRelationship.happy => 'Feliz',
        FeltInRelationship.afraid => 'Com medo',
        FeltInRelationship.alone => 'Sozinho(a)',
        FeltInRelationship.rejected => 'Rejeitado(a)',
        FeltInRelationship.criticized => 'Criticado(a)',
        FeltInRelationship.controlled => 'Controlado(a)',
        FeltInRelationship.responsibleForThem =>
          'Responsável pelo bem-estar dessa pessoa',
        FeltInRelationship.walkingOnEggshells =>
          'Como se precisasse tomar cuidado com o que fazia ou dizia',
        FeltInRelationship.other => 'Outro',
      };
}

const kFeltInRelationshipInOrder = FeltInRelationship.values;
FeltInRelationship? feltInRelationshipFromKey(String? k) {
  for (final v in FeltInRelationship.values) {
    if (v.key == k) return v;
  }
  return null;
}

/// Etapas 8 e 9 (§27–28) — o que recebi / gostaria de ter recebido mais.
enum RelationalNeed {
  affection,
  attention,
  presence,
  protection,
  safety,
  stability,
  understanding,
  acceptance,
  validation,
  respect,
  encouragement,
  confidence,
  freedomToBe,
  freedomToExpress,
  spaceToLearn,
  fairLimits,
  guidance,
  fun,
  other,
}

extension RelationalNeedMeta on RelationalNeed {
  String get key => switch (this) {
        RelationalNeed.affection => 'affection',
        RelationalNeed.attention => 'attention',
        RelationalNeed.presence => 'presence',
        RelationalNeed.protection => 'protection',
        RelationalNeed.safety => 'safety',
        RelationalNeed.stability => 'stability',
        RelationalNeed.understanding => 'understanding',
        RelationalNeed.acceptance => 'acceptance',
        RelationalNeed.validation => 'validation',
        RelationalNeed.respect => 'respect',
        RelationalNeed.encouragement => 'encouragement',
        RelationalNeed.confidence => 'confidence',
        RelationalNeed.freedomToBe => 'freedom_to_be',
        RelationalNeed.freedomToExpress => 'freedom_to_express',
        RelationalNeed.spaceToLearn => 'space_to_learn',
        RelationalNeed.fairLimits => 'fair_limits',
        RelationalNeed.guidance => 'guidance',
        RelationalNeed.fun => 'fun',
        RelationalNeed.other => 'other',
      };
  String get label => switch (this) {
        RelationalNeed.affection => 'Carinho',
        RelationalNeed.attention => 'Atenção',
        RelationalNeed.presence => 'Presença',
        RelationalNeed.protection => 'Proteção',
        RelationalNeed.safety => 'Segurança',
        RelationalNeed.stability => 'Estabilidade',
        RelationalNeed.understanding => 'Compreensão',
        RelationalNeed.acceptance => 'Aceitação',
        RelationalNeed.validation => 'Validação do que eu sentia',
        RelationalNeed.respect => 'Respeito',
        RelationalNeed.encouragement => 'Incentivo',
        RelationalNeed.confidence => 'Confiança na minha capacidade',
        RelationalNeed.freedomToBe => 'Liberdade para ser eu mesmo(a)',
        RelationalNeed.freedomToExpress =>
          'Liberdade para expressar sentimentos e opiniões',
        RelationalNeed.spaceToLearn =>
          'Espaço para aprender a fazer coisas sozinho(a)',
        RelationalNeed.fairLimits => 'Limites claros e justos',
        RelationalNeed.guidance => 'Orientação',
        RelationalNeed.fun => 'Diversão e leveza',
        RelationalNeed.other => 'Outro',
      };
}

const kRelationalNeedsInOrder = RelationalNeed.values;
RelationalNeed? relationalNeedFromKey(String? k) {
  for (final v in RelationalNeed.values) {
    if (v.key == k) return v;
  }
  return null;
}

/// Etapa 10 (§29) — "como está sua relação com essa pessoa hoje?"
enum CurrentRelationship {
  veryClose,
  close,
  neutral,
  distant,
  veryDistant,
  conflictual,
  broken,
  deceased,
  other,
}

extension CurrentRelationshipMeta on CurrentRelationship {
  String get key => switch (this) {
        CurrentRelationship.veryClose => 'very_close',
        CurrentRelationship.close => 'close',
        CurrentRelationship.neutral => 'neutral',
        CurrentRelationship.distant => 'distant',
        CurrentRelationship.veryDistant => 'very_distant',
        CurrentRelationship.conflictual => 'conflictual',
        CurrentRelationship.broken => 'broken',
        CurrentRelationship.deceased => 'deceased',
        CurrentRelationship.other => 'other',
      };
  String get label => switch (this) {
        CurrentRelationship.veryClose => 'Muito próxima',
        CurrentRelationship.close => 'Próxima',
        CurrentRelationship.neutral => 'Nem próxima nem distante',
        CurrentRelationship.distant => 'Distante',
        CurrentRelationship.veryDistant => 'Muito distante',
        CurrentRelationship.conflictual => 'Conflituosa',
        CurrentRelationship.broken => 'Rompida',
        CurrentRelationship.deceased => 'Essa pessoa faleceu',
        CurrentRelationship.other => 'Outro',
      };
}

const kCurrentRelationshipInOrder = CurrentRelationship.values;
CurrentRelationship? currentRelationshipFromKey(String? k) {
  for (final v in CurrentRelationship.values) {
    if (v.key == k) return v;
  }
  return null;
}
