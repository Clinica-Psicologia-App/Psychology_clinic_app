import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/daily_monitors/providers/daily_monitors_providers.dart';
import 'package:terapia_esquema/features/patients/domain/patient.dart';
import 'package:terapia_esquema/features/patients/providers/patients_providers.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/features/therapy_goals/domain/therapy_goal.dart';
import 'package:terapia_esquema/features/therapy_goals/domain/therapy_goal_status.dart';
import 'package:terapia_esquema/features/therapy_goals/presentation/patient_therapy_goals_page.dart';
import 'package:terapia_esquema/features/therapy_goals/providers/therapy_goals_providers.dart';

void main() {
  for (final staff in [false, true]) {
    for (final hasActive in [true, false]) {
      testWidgets('cabeçalho conta só ativas: staff=$staff ativa=$hasActive',
          (tester) async {
        tester.view.physicalSize = const Size(1080, 6000);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final now = DateTime(2026, 10, 21);
        final goals = [
          for (final status in TherapyGoalStatus.values)
            if (hasActive || status != TherapyGoalStatus.active)
              TherapyGoal(
                id: status.name,
                clinicId: 'clinic-test',
                patientId: 'patient-test',
                title: 'Meta ${status.name}',
                status: status,
                createdAt: now,
                updatedAt: now,
              ),
        ];
        await tester.pumpWidget(ProviderScope(
          overrides: [
            myTherapyGoalsProvider.overrideWith(() => _GoalsNotifier(goals)),
            staffPatientTherapyGoalsProvider.overrideWith((ref, ctx) => goals),
            myPatientIdProvider.overrideWith((ref) => 'patient-test'),
            patientDetailProvider('patient-test').overrideWith(
                (ref) => const Patient(id: 'patient-test', fullName: 'TESTE')),
          ],
          child: MaterialApp(
            home: staff
                ? const StaffPatientTherapyGoalsPage(
                    role: ProfileRole.psychologist, patientId: 'patient-test')
                : const PatientTherapyGoalsPage(),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.text('${hasActive ? 1 : 0} em andamento'), findsOneWidget);
        expect(find.text('1 arquivados'), findsOneWidget);
        expect(find.text('Meta completed'), findsOneWidget);
        expect(find.text('Meta archived'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}

class _GoalsNotifier extends MyTherapyGoalsNotifier {
  _GoalsNotifier(this.goals);
  final List<TherapyGoal> goals;
  @override
  Future<List<TherapyGoal>> build() async => goals;
}
