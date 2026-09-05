import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/patients/domain/patient.dart';
import 'package:terapia_esquema/features/patients/domain/patient_attention.dart';
import 'package:terapia_esquema/features/patients/domain/patient_data_completion.dart';

Patient _p({bool active = true}) =>
    Patient(id: 'p1', fullName: 'Fulano', isActive: active);

PatientDataCompletion _c(int filled) {
  final f = List.generate(6, (i) => i < filled);
  return PatientDataCompletion(
    patientId: 'p1',
    perfil: f[0],
    queixa: f[1],
    areas: f[2],
    historia: f[3],
    familia: f[4],
    questionarios: f[5],
  );
}

void main() {
  group('attentionFor', () {
    test('paciente em dia não entra no grupo de atenção', () {
      expect(
        attentionFor(
          patient: _p(),
          checkinMissingDays: 2,
          completion: _c(4),
        ),
        isNull,
      );
    });

    test('nunca fez check-in é o motivo mais urgente', () {
      final a = attentionFor(patient: _p(), checkinMissingDays: 999);
      expect(a!.kind, PatientAttentionKind.noCheckin);
      expect(a.label, 'Nunca fez check-in');
      expect(a.rank, 0);
    });

    test('5 dias sem check-in entra; 4 dias entra como menos urgente', () {
      expect(attentionFor(patient: _p(), checkinMissingDays: 5)!.kind,
          PatientAttentionKind.noCheckin);
      final few = attentionFor(patient: _p(), checkinMissingDays: 4)!;
      expect(few.kind, PatientAttentionKind.fewCheckins);
      expect(few.label, '4 dias sem check-in');
      expect(few.rank, greaterThan(0));
    });

    test('sem check-in ganha de resultado pendente', () {
      final a = attentionFor(
        patient: _p(),
        checkinMissingDays: 999,
        hasPendingResultsRelease: true,
      );
      expect(a!.kind, PatientAttentionKind.noCheckin);
    });

    test('resultado pendente entra quando o check-in está em dia', () {
      final a = attentionFor(
        patient: _p(),
        checkinMissingDays: 1,
        hasPendingResultsRelease: true,
      );
      expect(a!.kind, PatientAttentionKind.pendingRelease);
    });

    test('avaliação vazia entra; uma seção preenchida já não entra', () {
      expect(attentionFor(patient: _p(), completion: _c(0))!.kind,
          PatientAttentionKind.emptyData);
      expect(attentionFor(patient: _p(), completion: _c(1)), isNull);
    });

    test('paciente inativo nunca precisa de atenção', () {
      expect(
        attentionFor(
          patient: _p(active: false),
          checkinMissingDays: 999,
          hasPendingResultsRelease: true,
          completion: _c(0),
        ),
        isNull,
      );
    });

    test('sem dados de alerta nem preenchimento, ninguém é urgente', () {
      expect(attentionFor(patient: _p()), isNull);
    });
  });

  group('hasDirectAction', () {
    test('resultado pendente e avaliação vazia têm botão', () {
      expect(PatientAttentionKind.pendingRelease.hasDirectAction, isTrue);
      expect(PatientAttentionKind.emptyData.hasDirectAction, isTrue);
    });

    test('motivos de check-in não têm — o discador está fora por ora', () {
      expect(PatientAttentionKind.noCheckin.hasDirectAction, isFalse);
      expect(PatientAttentionKind.fewCheckins.hasDirectAction, isFalse);
    });
  });
}
