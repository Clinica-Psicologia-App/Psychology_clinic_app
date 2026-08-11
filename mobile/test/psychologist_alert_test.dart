import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/patients/domain/psychologist_alert.dart';

void main() {
  group('PsychologistAlert.pillLabel', () {
    test('check-in ausente: sentinel 999 vira "nunca"', () {
      const alert = PsychologistAlert(
        kind: PsychologistAlertKind.missingCheckin,
        patientName: 'Maria',
        daysCount: 999,
      );
      expect(alert.pillLabel, 'nunca');
    });

    test('check-in ausente: 1 dia no singular, N dias no plural', () {
      const um = PsychologistAlert(
        kind: PsychologistAlertKind.missingCheckin,
        patientName: 'Maria',
        daysCount: 1,
      );
      const cinco = PsychologistAlert(
        kind: PsychologistAlertKind.missingCheckin,
        patientName: 'Maria',
        daysCount: 5,
      );
      expect(um.pillLabel, '1 dia');
      expect(cinco.pillLabel, '5 dias');
    });

    test('convite expirando: hoje, amanhã e N dias', () {
      const hoje = PsychologistAlert(
        kind: PsychologistAlertKind.expiringInvitation,
        patientName: 'Ana',
        daysCount: 0,
      );
      const amanha = PsychologistAlert(
        kind: PsychologistAlertKind.expiringInvitation,
        patientName: 'Ana',
        daysCount: 1,
      );
      const tresDias = PsychologistAlert(
        kind: PsychologistAlertKind.expiringInvitation,
        patientName: 'Ana',
        daysCount: 3,
      );
      expect(hoje.pillLabel, 'hoje');
      expect(amanha.pillLabel, 'amanhã');
      expect(tresDias.pillLabel, '3 dias');
    });

    test('questionário parado: 1 dia no singular, N dias no plural', () {
      const um = PsychologistAlert(
        kind: PsychologistAlertKind.staleQuestionnaire,
        patientName: 'Roberto',
        daysCount: 1,
      );
      const nove = PsychologistAlert(
        kind: PsychologistAlertKind.staleQuestionnaire,
        patientName: 'Roberto',
        daysCount: 9,
      );
      expect(um.pillLabel, '1 dia');
      expect(nove.pillLabel, '9 dias');
    });
  });

  group('PsychologistAlert.subtitleLabel', () {
    test('um rótulo curto por tipo, sem repetir o nome do paciente', () {
      const checkin = PsychologistAlert(
        kind: PsychologistAlertKind.missingCheckin,
        patientName: 'Maria',
        daysCount: 999,
      );
      const convite = PsychologistAlert(
        kind: PsychologistAlertKind.expiringInvitation,
        patientName: 'Ana',
        daysCount: 1,
      );
      const questionario = PsychologistAlert(
        kind: PsychologistAlertKind.staleQuestionnaire,
        patientName: 'Roberto',
        daysCount: 9,
      );

      expect(checkin.subtitleLabel, 'Check-in');
      expect(convite.subtitleLabel, 'Convite');
      expect(questionario.subtitleLabel, 'Questionário em andamento');
    });
  });

  group('PsychologistAlert.message (compatibilidade)', () {
    test('continua produzindo a frase completa, usada na semântica', () {
      const alert = PsychologistAlert(
        kind: PsychologistAlertKind.staleQuestionnaire,
        patientName: 'Roberto',
        daysCount: 9,
      );
      expect(
        alert.message,
        'Roberto com questionário em andamento há 9 dias',
      );
    });
  });
}
