import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/domain/profile_role.dart';
import '../data/genogram_repository.dart';
import '../domain/genogram_bootstrap.dart';
import '../domain/genogram_data.dart';
import '../domain/genogram_family_patterns.dart';
import '../domain/genogram_layout_adapter.dart';
import '../domain/genogram_person.dart';
import '../domain/genogram_relationship.dart';

final genogramRepositoryProvider = Provider<GenogramRepository>((ref) {
  return GenogramRepository();
});

final myGenogramProvider =
    AsyncNotifierProvider<MyGenogramNotifier, GenogramData>(
  MyGenogramNotifier.new,
);

class MyGenogramNotifier extends AsyncNotifier<GenogramData> {
  @override
  Future<GenogramData> build() async {
    return ref.read(genogramRepositoryProvider).loadMyGenogram();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(genogramRepositoryProvider).loadMyGenogram(),
    );
  }
}

class StaffGenogramContext {
  const StaffGenogramContext({
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffGenogramContext &&
          role == other.role &&
          patientId == other.patientId;

  @override
  int get hashCode => Object.hash(role, patientId);
}

final staffGenogramProvider =
    FutureProvider.family<GenogramData, StaffGenogramContext>(
  (ref, ctx) {
    return ref.read(genogramRepositoryProvider).loadForPatient(ctx.patientId);
  },
);

final genogramFamilyPatternsProvider =
    FutureProvider.family<GenogramFamilyPatterns, String>((ref, patientId) {
  return ref.read(genogramRepositoryProvider).getFamilyPatterns(patientId);
});

/// Só as relações tipadas do genograma de um paciente — camada emocional
/// explícita (cônjuge, conflito, rompida…) para o diagrama do fluxo Conhecer,
/// que antes só inferia a estrutura pelo parentesco. Reusa o repositório do
/// genograma clínico (mesma tabela `genogram_relationships`).
final genogramRelationshipsForPatientProvider =
    FutureProvider.family<List<GenogramRelationship>, String>(
  (ref, patientId) async {
    final data =
        await ref.read(genogramRepositoryProvider).loadForPatient(patientId);
    return data.relationships;
  },
);

final genogramPersonDetailProvider =
    FutureProvider.family<GenogramPerson?, String>((ref, id) {
  return ref.read(genogramRepositoryProvider).getPersonById(id);
});

final genogramRelationshipDetailProvider =
    FutureProvider.family<GenogramRelationship?, String>((ref, id) {
  return ref.read(genogramRepositoryProvider).getRelationshipById(id);
});

/// Genograma completo (pessoas + relações) de um paciente, por id — para o
/// desenho pelo motor.
final genogramDataForPatientProvider =
    FutureProvider.autoDispose.family<GenogramData, String>((ref, patientId) {
  return ref.read(genogramRepositoryProvider).loadForPatient(patientId);
});

/// Dados do bootstrap de vínculos: as propostas + o contexto para gravá-las.
class GBootstrapData {
  final List<GEdgeProposal> proposals;
  final String? clinicId;
  final String patientId;
  const GBootstrapData(this.proposals, this.clinicId, this.patientId);
}

/// Carrega o genograma do paciente e propõe os vínculos estruturais que faltam
/// a partir dos papéis (para o terapeuta confirmar).
final genogramBootstrapProvider =
    FutureProvider.autoDispose.family<GBootstrapData, String>(
  (ref, patientId) async {
    final data =
        await ref.read(genogramRepositoryProvider).loadForPatient(patientId);
    final clinicId =
        data.people.isNotEmpty ? data.people.first.clinicId : null;
    final proposals = proposeBootstrap(
      people: data.people,
      relationships: data.relationships,
    );
    return GBootstrapData(proposals, clinicId, patientId);
  },
);
