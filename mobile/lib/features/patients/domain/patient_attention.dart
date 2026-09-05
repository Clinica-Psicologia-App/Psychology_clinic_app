import 'patient.dart';
import 'patient_data_completion.dart';

/// Por que um paciente precisa da atenção do psicólogo agora. Ordena a lista
/// de pacientes: quem tem motivo sobe para o grupo "Precisam de atenção".
enum PatientAttentionKind {
  /// Nunca fez check-in, ou parou há 5 dias ou mais.
  noCheckin,

  /// Questionário concluído e resultado ainda não liberado ao paciente.
  pendingRelease,

  /// Avaliação inicial praticamente vazia (nenhuma seção preenchida).
  emptyData,

  /// Entre 3 e 4 dias sem check-in.
  fewCheckins,
}

/// Motivo + texto pronto para exibição. `rank` ordena do mais urgente (0) para
/// o menos urgente dentro do grupo.
class PatientAttention {
  const PatientAttention({required this.kind, required this.label});

  final PatientAttentionKind kind;
  final String label;

  int get rank => switch (kind) {
        PatientAttentionKind.noCheckin => 0,
        PatientAttentionKind.pendingRelease => 1,
        PatientAttentionKind.emptyData => 2,
        PatientAttentionKind.fewCheckins => 3,
      };
}

/// Corte deliberadamente rigoroso: se quase todo mundo entra no grupo de
/// atenção, o grupo deixa de significar alguma coisa. Paciente inativo nunca
/// entra — não há acompanhamento em curso para cobrar.
PatientAttention? attentionFor({
  required Patient patient,
  bool hasPendingResultsRelease = false,
  int? checkinMissingDays,
  PatientDataCompletion? completion,
}) {
  if (!patient.isActive) return null;

  final missing = checkinMissingDays ?? 0;

  if (missing >= 999) {
    return const PatientAttention(
      kind: PatientAttentionKind.noCheckin,
      label: 'Nunca fez check-in',
    );
  }
  if (missing >= 5) {
    return PatientAttention(
      kind: PatientAttentionKind.noCheckin,
      label: '$missing dias sem check-in',
    );
  }
  if (hasPendingResultsRelease) {
    return const PatientAttention(
      kind: PatientAttentionKind.pendingRelease,
      label: 'Resultado a liberar',
    );
  }
  if (completion != null && completion.filledSections == 0) {
    return const PatientAttention(
      kind: PatientAttentionKind.emptyData,
      label: 'Sem avaliação inicial',
    );
  }
  if (missing >= 3) {
    return PatientAttention(
      kind: PatientAttentionKind.fewCheckins,
      label: '$missing dias sem check-in',
    );
  }
  return null;
}
