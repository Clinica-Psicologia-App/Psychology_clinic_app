import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:terapia_esquema/core/errors/app_exception.dart';
import 'package:terapia_esquema/features/personality_assessment/data/personality_assessment_repository.dart';
import 'package:terapia_esquema/features/personality_assessment/domain/personality_assessment.dart';
import 'package:terapia_esquema/features/personality_assessment/presentation/personality_assessment_form_page.dart';
import 'package:terapia_esquema/features/personality_assessment/providers/personality_assessment_providers.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';

class RecordingRepository extends PersonalityAssessmentRepository {
  RecordingRepository()
      : super(client: SupabaseClient('https://example.supabase.co', 'test',
            authOptions: const AuthClientOptions(autoRefreshToken: false)));

  int creates = 0;
  int updates = 0;
  bool fail = false;
  PersonalityResults? saved;

  @override
  Future<String> create({
    required String patientId,
    required String instrument,
    required PersonalityResults results,
    DateTime? appliedOn,
    String? applicationForm,
    ProtocolValidity? protocolValidity,
  }) async {
    creates++;
    saved = results;
    return 'assessment-1';
  }

  @override
  Future<void> update({
    required String id,
    required PersonalityResults results,
    DateTime? appliedOn,
    String? applicationForm,
    ProtocolValidity? protocolValidity,
  }) async {
    expect(id, 'assessment-1');
    updates++;
    if (fail) {
      throw AppException(code: 'network_error', message: 'Falha ao salvar.');
    }
    saved = results;
  }
}

void main() {
  testWidgets('salva cada etapa no mesmo registro e permite repetir falha',
      (tester) async {
    final repo = RecordingRepository();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        personalityAssessmentRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MaterialApp(
        home: PersonalityAssessmentFormPage(
          role: ProfileRole.psychologist,
          patientId: 'patient-1',
        ),
      ),
    ));
    await tester.tap(find.text('Salvar e continuar →'));
    await tester.pumpAndSettle();
    expect(repo.creates, 1);
    expect(find.text('1 de 5 — Neuroticismo'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'abc');
    await tester.tap(find.text('Salvar e continuar →'));
    await tester.pumpAndSettle();
    expect(repo.updates, 0);
    expect(find.text('Escore T inválido'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '52');
    expect(find.byType(DropdownButtonFormField), findsNothing);
    await tester.pump();
    expect(find.text('Médio'), findsOneWidget);
    repo.fail = true;
    await tester.tap(find.text('Salvar e continuar →'));
    await tester.pumpAndSettle();
    expect(find.text('1 de 5 — Neuroticismo'), findsOneWidget);
    expect(find.byType(MaterialBanner), findsOneWidget);
    expect(find.text('52'), findsOneWidget);

    repo.fail = false;
    await tester.tap(find.text('Salvar e continuar →'));
    await tester.pumpAndSettle();
    expect(repo.creates, 1);
    expect(repo.updates, 2);
    expect(repo.saved!.forDomain('neuroticism').overall.score, 52);
    expect(repo.saved!.toJson()['domains']['neuroticism']['classification'],
        'medium');
    expect(find.text('2 de 5 — Extroversão'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });
}
