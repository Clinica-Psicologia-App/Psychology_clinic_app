import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/library_indication.dart';

class PatientLibraryRepository {
  PatientLibraryRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  /// Obras indicadas ao paciente logado (via RPC com campos seguros).
  Future<List<LibraryIndication>> getMyLibrary() async {
    try {
      final res = await _client.rpc('get_my_library');
      final list = res as List? ?? const [];
      return list
          .map((e) =>
              LibraryIndication.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Paciente atualiza a própria indicação (progresso/ativação/respostas).
  Future<void> updateMyIndication({
    required String indicationId,
    String? status,
    DateTime? watchedAt,
    int? activation,
    bool? shareResponses,
    Map<String, dynamic>? patientResponses,
  }) async {
    try {
      final patch = <String, dynamic>{
        if (status != null) 'status': status,
        if (watchedAt != null) 'watched_at': watchedAt.toIso8601String(),
        if (activation != null) 'activation_0_10': activation,
        if (shareResponses != null) 'share_responses': shareResponses,
        if (patientResponses != null) 'patient_responses': patientResponses,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      await _client
          .from('library_indications')
          .update(patch)
          .eq('id', indicationId);
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}
