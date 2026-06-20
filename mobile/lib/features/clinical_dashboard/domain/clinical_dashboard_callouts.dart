enum ClinicalDashboardCalloutKind {
  missingYsq,
  missingYami,
  missingCheckIn,
}

class ClinicalDashboardCallout {
  const ClinicalDashboardCallout({
    required this.kind,
    required this.message,
  });

  final ClinicalDashboardCalloutKind kind;
  final String message;
}

List<ClinicalDashboardCallout> buildClinicalDashboardCallouts({
  required bool hasYsqResult,
  required bool hasYamiResult,
  required bool hasRecentCheckIn,
}) {
  final callouts = <ClinicalDashboardCallout>[];

  if (!hasYsqResult && !hasYamiResult) {
    callouts.add(
      const ClinicalDashboardCallout(
        kind: ClinicalDashboardCalloutKind.missingYsq,
        message: 'Ainda não há YSQ ou YAMI concluídos. Aplique os instrumentos '
            'na trilha para enriquecer a visão clínica.',
      ),
    );
  } else {
    if (!hasYsqResult) {
      callouts.add(
        const ClinicalDashboardCallout(
          kind: ClinicalDashboardCalloutKind.missingYsq,
          message: 'Nenhuma aplicação YSQ concluída. Considere aplicar o '
              'inventário de esquemas iniciais.',
        ),
      );
    }
    if (!hasYamiResult) {
      callouts.add(
        const ClinicalDashboardCallout(
          kind: ClinicalDashboardCalloutKind.missingYami,
          message: 'Nenhuma aplicação YAMI concluída. Considere aplicar o '
              'inventário de modos esquemáticos.',
        ),
      );
    }
  }

  if (!hasRecentCheckIn) {
    callouts.add(
      const ClinicalDashboardCallout(
        kind: ClinicalDashboardCalloutKind.missingCheckIn,
        message: 'Não há check-in recente. Registrar o estado atual ajuda a '
            'acompanhar sinais entre sessões.',
      ),
    );
  }

  return callouts;
}

bool hasRecentCheckIn(DateTime? checkedInAt, {DateTime? now}) {
  if (checkedInAt == null) return false;
  final reference = (now ?? DateTime.now()).toLocal();
  final local = checkedInAt.toLocal();
  final difference = reference.difference(local);
  return difference.inDays <= 7;
}
