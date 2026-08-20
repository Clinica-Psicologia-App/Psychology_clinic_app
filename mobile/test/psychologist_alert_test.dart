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
      const resultado = PsychologistAlert(
        kind: PsychologistAlertKind.pendingResultsRelease,
        patientName: 'Carla',
        daysCount: 2,
      );

      expect(checkin.subtitleLabel, 'Check-in');
      expect(convite.subtitleLabel, 'Convite');
      expect(questionario.subtitleLabel, 'Questionário em andamento');
      expect(resultado.subtitleLabel, 'Resultado pendente de liberação');
    });
  });

  group('PsychologistAlert.fromRpcJson — resultado pendente de liberação', () {
    test('parseia pending_results_release e prioriza logo após convites', () {
      final alerts = PsychologistAlert.fromRpcJson({
        'expiring_invitations': [
          {
            'invitation_id': 'inv-1',
            'patient_name': 'Ana',
            'days_until_expiry': 1,
          },
        ],
        'pending_results_release': [
          {
            'patient_id': 'pat-1',
            'patient_name': 'Carla',
            'days_waiting': 2,
          },
        ],
        'stale_questionnaires': [
          {
            'patient_id': 'pat-2',
            'patient_name': 'Roberto',
            'days_waiting': 9,
          },
        ],
        'missing_checkins': [],
      });

      expect(alerts.length, 3);
      expect(alerts[0].kind, PsychologistAlertKind.expiringInvitation);
      expect(alerts[1].kind, PsychologistAlertKind.pendingResultsRelease);
      expect(alerts[1].patientName, 'Carla');
      expect(alerts[1].patientId, 'pat-1');
      expect(alerts[1].daysCount, 2);
      expect(alerts[2].kind, PsychologistAlertKind.staleQuestionnaire);
    });

    test('chave ausente não quebra o parse (compatibilidade)', () {
      final alerts = PsychologistAlert.fromRpcJson({
        'expiring_invitations': [],
        'stale_questionnaires': [],
        'missing_checkins': [],
      });
      expect(alerts, isEmpty);
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
