import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../clinical_dashboard/domain/clinical_dashboard_builder.dart';
import '../../daily_monitors/providers/daily_monitors_providers.dart';
import '../../patients/providers/patients_providers.dart';
import '../../results/providers/results_providers.dart';
import '../domain/coping_card.dart';

final myCopingCardsProvider =
    FutureProvider.autoDispose<List<CopingCard>>((ref) async {
  final patientId = await ref.watch(myPatientIdProvider.future);
  final patient = await ref.watch(patientDetailProvider(patientId).future);
  if (patient == null || !patient.resultsReleased) {
    throw AppException(
        code: AppExceptionCodes.forbidden,
        message:
            'Os cartões ficam disponíveis após a liberação dos resultados pelo terapeuta.');
  }
  final repository = ref.watch(resultsRepositoryProvider);
  final summaries = await repository.listPatientResponses(patientId);
  final cards = <CopingCard>[];
  // One summary request and at most two detail requests; existing RPCs retain
  // server-side release/ownership checks and patient-safe projections.
  for (final code in [yciInstrumentCode, yraiInstrumentCode]) {
    final latest = latestStructuredResponseByCode(summaries, code);
    if (latest == null) continue;
    final detail = await repository.getResponseDetail(latest.id);
    if (detail != null && detail.patientId == patientId) {
      cards.addAll(CopingCard.fromResult(detail));
    }
  }
  return cards;
});
