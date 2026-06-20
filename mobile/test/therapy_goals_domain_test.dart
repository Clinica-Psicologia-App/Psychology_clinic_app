import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/therapy_goals/domain/therapy_goal.dart';
import 'package:terapia_esquema/features/therapy_goals/domain/therapy_goal_input.dart';
import 'package:terapia_esquema/features/therapy_goals/domain/therapy_goal_status.dart';

void main() {
  test('TherapyGoal.fromJson parses fields', () {
    final goal = TherapyGoal.fromJson({
      'id': 'g1',
      'clinic_id': 'c1',
      'patient_id': 'p1',
      'created_by': 'u1',
      'title': 'Reduzir ansiedade',
      'description': 'Praticar respiração',
      'status': 'active',
      'target_date': '2026-06-15',
      'completed_at': null,
      'created_at': '2026-05-01T12:00:00Z',
      'updated_at': '2026-05-01T12:00:00Z',
    });

    expect(goal.title, 'Reduzir ansiedade');
    expect(goal.status, TherapyGoalStatus.active);
    expect(goal.targetDate?.year, 2026);
    expect(goal.isActive, isTrue);
  });

  test('therapyGoalStatusFromStorage maps values and defaults', () {
    expect(
      therapyGoalStatusFromStorage('completed'),
      TherapyGoalStatus.completed,
    );
    expect(
      therapyGoalStatusFromStorage('archived'),
      TherapyGoalStatus.archived,
    );
    expect(
      therapyGoalStatusFromStorage('unknown'),
      TherapyGoalStatus.active,
    );
  });

  test('TherapyGoalInput validates title', () {
    expect(
      const TherapyGoalInput(title: '  ').validate(),
      isNotNull,
    );
    expect(
      const TherapyGoalInput(title: 'Meta válida').validate(),
      isNull,
    );
  });

  test('TherapyGoalInput patient update omits target_date', () {
    final json = const TherapyGoalInput(
      title: 'Título',
      description: 'Desc',
      status: TherapyGoalStatus.completed,
    ).toPatientUpdateJson();

    expect(json['title'], 'Título');
    expect(json['status'], 'completed');
    expect(json.containsKey('target_date'), isFalse);
  });

  test('status labels in Portuguese', () {
    expect(TherapyGoalStatus.active.label, 'Ativo');
    expect(TherapyGoalStatus.completed.label, 'Concluído');
    expect(TherapyGoalStatus.archived.label, 'Arquivado');
  });
}
