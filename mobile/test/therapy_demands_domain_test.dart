import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/mental_map/domain/case_conceptualization.dart';
import 'package:terapia_esquema/features/mental_map/domain/demands_text_history.dart';

void main() {
  final t0 = DateTime.utc(2026, 10, 22, 12);
  final t1 = DateTime.utc(2026, 10, 23, 9);

  group('Diagnosis — formato antigo continua válido', () {
    test('lê nome + código + sistema geral e dá ids estáveis', () {
      final d = Diagnosis.fromJson({
        'system': 'CID-11',
        'items': [
          {'name': 'TAG', 'code': '6B00'},
          {'name': 'Depressão'},
        ],
      });
      expect(d.system, 'CID-11');
      expect(d.items.map((e) => e.id), ['legacy_0', 'legacy_1']);
      expect(d.items.first.metaLine(d.system), 'CID-11');
      expect(d.items.first.status, isNull);
      expect(d.noDiagnosis, isFalse);
    });

    test('ida e volta preserva todos os campos novos', () {
      const item = DiagnosisItem(
        id: 'dx_1',
        name: 'Transtorno de ansiedade generalizada',
        code: '6B00',
        system: 'CID-11',
        status: DiagnosisStatus.established,
        notes: 'critérios atendidos',
        reviewedOn: '2026-10-20',
        updatedByName: 'Dra. Ana',
        updatedAt: '2026-10-20T12:00:00.000Z',
      );
      final back = Diagnosis.fromJson(
          const Diagnosis(items: [item], noDiagnosis: false).toJson());
      final it = back.items.single;
      expect(it.id, 'dx_1');
      expect(it.system, 'CID-11');
      expect(it.status, DiagnosisStatus.established);
      expect(it.notes, 'critérios atendidos');
      expect(it.reviewedOn, '2026-10-20');
      expect(it.updatedByName, 'Dra. Ana');
      expect(it.metaLine(), 'CID-11 · Diagnóstico estabelecido');
    });
  });

  group('Diagnosis — estados distintos', () {
    test('aba não avaliada ≠ "sem diagnóstico" marcado', () {
      const untouched = Diagnosis();
      const explicit = Diagnosis(noDiagnosis: true);
      expect(untouched.isEmpty, isTrue);
      expect(untouched.toJson(), isEmpty);
      expect(explicit.isEmpty, isFalse);
      expect(Diagnosis.fromJson(explicit.toJson()).noDiagnosis, isTrue);
    });

    test('"sem diagnóstico" convive com hipótese, não com estabelecido', () {
      const hypothesis = DiagnosisItem(
          name: 'Possível TEPT',
          system: 'DSM-5-TR',
          status: DiagnosisStatus.investigating);
      const established = DiagnosisItem(
          name: 'TAG',
          system: 'CID-11',
          status: DiagnosisStatus.established);
      expect(
          const Diagnosis(noDiagnosis: true, items: [hypothesis]).conflictError,
          isNull);
      expect(
          const Diagnosis(noDiagnosis: true, items: [established])
              .conflictError,
          isNotNull);
      expect(const Diagnosis(items: [established]).conflictError, isNull);
    });
  });

  group('Diagnosis.withRevisions — histórico preservado', () {
    const base = DiagnosisItem(
      id: 'dx_a',
      name: 'Hipótese de TAG',
      code: '',
      system: 'CID-11',
      status: DiagnosisStatus.investigating,
    );

    test('registro novo recebe autoria e data', () {
      final out = const Diagnosis(items: [base])
          .withRevisions(previous: const Diagnosis(), now: t0, authorName: 'Ana');
      expect(out.items.single.updatedByName, 'Ana');
      expect(out.items.single.updatedAt, t0.toIso8601String());
      expect(out.items.single.revisions, isEmpty);
    });

    test('alteração guarda a versão anterior; sem alteração mantém tudo', () {
      final saved = const Diagnosis(items: [base])
          .withRevisions(previous: const Diagnosis(), now: t0, authorName: 'Ana');

      final unchanged = Diagnosis(items: [saved.items.single]).withRevisions(
          previous: saved, now: t1, authorName: 'Bia');
      expect(unchanged.items.single.updatedByName, 'Ana');
      expect(unchanged.items.single.updatedAt, t0.toIso8601String());

      final revised = const Diagnosis(items: [
        DiagnosisItem(
          id: 'dx_a',
          name: 'TAG',
          code: '6B00',
          system: 'CID-11',
          status: DiagnosisStatus.established,
        ),
      ]).withRevisions(previous: saved, now: t1, authorName: 'Bia');
      final it = revised.items.single;
      expect(it.status, DiagnosisStatus.established);
      expect(it.updatedByName, 'Bia');
      expect(it.revisions, hasLength(1));
      expect(it.revisions.single.name, 'Hipótese de TAG');
      expect(it.revisions.single.status, DiagnosisStatus.investigating);
      expect(it.revisions.single.updatedByName, 'Ana');

      final again = const Diagnosis(items: [
        DiagnosisItem(
            id: 'dx_a',
            name: 'TAG com ansiedade social',
            system: 'CID-11',
            status: DiagnosisStatus.established),
      ]).withRevisions(previous: revised, now: t1, authorName: 'Bia');
      expect(again.items.single.revisions.map((r) => r.name),
          ['TAG', 'Hipótese de TAG']);
    });

    test('registro removido vai para o histórico, não some', () {
      final saved = const Diagnosis(items: [base])
          .withRevisions(previous: const Diagnosis(), now: t0, authorName: 'Ana');
      final out = const Diagnosis(noDiagnosis: true)
          .withRevisions(previous: saved, now: t1, authorName: 'Ana');
      expect(out.items, isEmpty);
      expect(out.removed.single.name, 'Hipótese de TAG');
      expect(Diagnosis.fromJson(out.toJson()).removed, hasLength(1));
    });
  });

  group('DemandsTextHistory', () {
    test('guarda o texto substituído, mais recente primeiro', () {
      var h = DemandsTextHistory.empty;
      h = h.withReplaced(DemandsTextField.reasonsInitial,
          previousText: 'v1', newText: 'v2', now: t0, author: 'Ana');
      h = h.withReplaced(DemandsTextField.reasonsInitial,
          previousText: 'v2', newText: 'v3', now: t1);
      expect(h.revisionsOf(DemandsTextField.reasonsInitial).map((r) => r.text),
          ['v2', 'v1']);
      expect(h.revisionsOf(DemandsTextField.reasonsCurrent), isEmpty);
    });

    test('não registra se vazio ou sem mudança', () {
      var h = DemandsTextHistory.empty;
      h = h.withReplaced(DemandsTextField.impressionsInitial,
          previousText: '', newText: 'novo', now: t0);
      h = h.withReplaced(DemandsTextField.impressionsInitial,
          previousText: 'igual ', newText: ' igual', now: t0);
      expect(h.isEmpty, isTrue);
    });

    test('ida e volta em JSON', () {
      final h = const DemandsTextHistory().withReplaced(
          DemandsTextField.impressionsCurrent,
          previousText: 'antes',
          newText: 'depois',
          now: t0,
          author: 'Ana');
      final back = DemandsTextHistory.fromJson(h.toJson());
      final r = back.revisionsOf(DemandsTextField.impressionsCurrent).single;
      expect(r.text, 'antes');
      expect(r.savedBy, 'Ana');
    });
  });

  test('CaseConceptualization lê updated_at', () {
    final c = CaseConceptualization.fromJson(
        {'updated_at': '2026-10-22T15:30:00Z'});
    expect(c.updatedAt, isNotNull);
    expect(CaseConceptualization.fromJson(const {}).updatedAt, isNull);
  });
}
