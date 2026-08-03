import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../clinical_dashboard/providers/clinical_dashboard_providers.dart';
import '../../initial_assessment/providers/initial_assessment_providers.dart';
import '../../patient_timeline/providers/patient_timeline_providers.dart';
import '../../patients/providers/patients_providers.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/patient_infographic_builder.dart';
import '../domain/patient_infographic_data.dart';

class PatientInfographicContext {
  const PatientInfographicContext({
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientInfographicContext &&
          role == other.role &&
          patientId == other.patientId;

  @override
  int get hashCode => Object.hash(role, patientId);
}

/// Compõe cadastro + dashboard consolidado + conceitualização + linha do tempo
/// num único [PatientInfographicData], via builder determinístico.
final patientInfographicProvider = FutureProvider.family<PatientInfographicData,
    PatientInfographicContext>((ref, ctx) async {
  final patient = await ref.watch(patientDetailProvider(ctx.patientId).future);
  if (patient == null) {
    throw StateError('Paciente não encontrado.');
  }

  final dashboard = await ref.watch(
    staffClinicalDashboardProvider(
      StaffClinicalDashboardContext(role: ctx.role, patientId: ctx.patientId),
    ).future,
  );

  final assessment = await ref.watch(
    initialAssessmentProvider(
      InitialAssessmentContext(role: ctx.role, patientId: ctx.patientId),
    ).future,
  );

  final timeline = await ref.watch(
    staffPatientTimelineProvider(
      StaffPatientTimelineContext(role: ctx.role, patientId: ctx.patientId),
    ).future,
  );

  return buildPatientInfographic(
    patient: patient,
    dashboard: dashboard,
    assessment: assessment,
    timelineEvents: timeline,
  );
});
