import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';

/// Curadoria das permissões de módulo por clínica (somente platform_admin).
///
/// A RLS `clinic_feature_entitlements_write_platform_admin` restringe a escrita
/// ao admin de plataforma. Alterar aqui libera o módulo para os psicólogos
/// daquela clínica, independentemente do plano comercial.
class AdminEntitlementsRepository {
  AdminEntitlementsRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  /// Permissões atuais da clínica (feature_key → is_enabled).
  Future<Map<String, bool>> listForClinic(String clinicId) async {
    try {
      final rows = await _client
          .from('clinic_feature_entitlements')
          .select('feature_key, is_enabled')
          .eq('clinic_id', clinicId);
      final map = <String, bool>{};
      for (final row in rows as List) {
        final r = row as Map;
        final key = r['feature_key'] as String?;
        if (key != null) map[key] = r['is_enabled'] as bool? ?? false;
      }
      return map;
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Liga/desliga um módulo para a clínica (upsert por clinic_id+feature_key).
  Future<void> setEnabled({
    required String clinicId,
    required String featureKey,
    required String featureName,
    required bool enabled,
  }) async {
    try {
      await _client.from('clinic_feature_entitlements').upsert(
        {
          'clinic_id': clinicId,
          'feature_key': featureKey,
          'feature_name': featureName,
          'is_enabled': enabled,
        },
        onConflict: 'clinic_id,feature_key',
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}

/// Catálogo dos módulos controláveis, com nome e descrição amigáveis.
class AdminFeatureDef {
  const AdminFeatureDef(this.key, this.name, this.description);
  final String key;
  final String name;
  final String description;
}

const adminManageableFeatures = <AdminFeatureDef>[
  AdminFeatureDef(
      'patients', 'Pacientes', 'Cadastro e acompanhamento de pacientes.'),
  AdminFeatureDef('questionnaires', 'Questionários',
      'YSQ, YPI e instrumentos de esquema e apego.'),
  AdminFeatureDef('reports', 'Relatórios e dashboards',
      'Dashboard clínico, síntese gráfica e infográficos.'),
  AdminFeatureDef('resources', 'Recursos e Biblioteca',
      'Recursos terapêuticos, Biblioteca de filmes e Psicoeducação.'),
  AdminFeatureDef(
      'audit', 'Auditoria', 'Registros de auditoria e rastreabilidade.'),
];
