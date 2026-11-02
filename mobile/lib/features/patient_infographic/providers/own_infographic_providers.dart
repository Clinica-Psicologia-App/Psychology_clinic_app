import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/authorized_timeline_entry.dart';

/// Linha do tempo do infográfico do próprio paciente: só o que o psicólogo
/// autorizou. Lê exclusivamente pela função `get_patient_infographic_timeline`,
/// que aplica o filtro no banco (nunca pela tabela).
final ownInfographicTimelineProvider =
    FutureProvider.family<List<AuthorizedTimelineEntry>, String>(
        (ref, patientId) async {
  try {
    final rows = await SupabaseBootstrap.client.rpc(
      'get_patient_infographic_timeline',
      params: {'p_patient_id': patientId},
    );
    return [
      for (final row in rows as List)
        AuthorizedTimelineEntry.fromJson(Map<String, dynamic>.from(row as Map)),
    ]..sort(AuthorizedTimelineEntry.compareChronologically);
  } catch (e) {
    throw mapToAppException(e);
  }
});
