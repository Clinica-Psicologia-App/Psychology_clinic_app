import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/core/errors/app_exception.dart';
import 'package:terapia_esquema/features/clinical_reports/domain/clinical_report_include_options.dart';
import 'package:terapia_esquema/features/clinical_reports/domain/clinical_report_response_parser.dart';

void main() {
  test('ClinicalReportIncludeOptions.defaults enables all sections', () {
    const opts = ClinicalReportIncludeOptions.defaults;
    expect(opts.questionnaires, isTrue);
    expect(opts.mentalMap, isTrue);
    expect(opts.goals, isTrue);
    expect(opts.problems, isTrue);
    expect(opts.checkIns, isTrue);
    expect(opts.dailyMonitors, isTrue);
    expect(opts.timeline, isTrue);
    expect(opts.genogram, isTrue);
    expect(opts.hasAnySection, isTrue);
  });

  test('toRequestJson maps snake_case include flags', () {
    const opts = ClinicalReportIncludeOptions(
      questionnaires: false,
      genogram: true,
    );
    final json = opts.toRequestJson('11111111-1111-1111-1111-111111111201');
    expect(json['patient_id'], '11111111-1111-1111-1111-111111111201');
    final include = json['include'] as Map<String, dynamic>;
    expect(include['questionnaires'], isFalse);
    expect(include['mental_map'], isTrue);
    expect(include['genogram'], isTrue);
    expect(include['check_ins'], isTrue);
  });

  test('parseClinicalReportPdfBytes accepts Uint8List', () {
    final bytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]);
    expect(parseClinicalReportPdfBytes(bytes), bytes);
  });

  test('parseClinicalReportPdfBytes decodes base64 string', () {
    final raw = Uint8List.fromList([1, 2, 3, 4]);
    final encoded = base64Encode(raw);
    expect(parseClinicalReportPdfBytes(encoded), raw);
  });

  test('parseClinicalReportPdfBytes throws on JSON error payload', () {
    const payload = '{"ok":false,"error":{"code":"FORBIDDEN","message":"x"}}';
    expect(
      () => parseClinicalReportPdfBytes(payload),
      throwsA(isA<AppException>()),
    );
  });

  test('mapClinicalReportHttpError maps 403 to forbidden', () {
    final err = mapClinicalReportHttpError(status: 403, data: null);
    expect(err.code, AppExceptionCodes.forbidden);
  });

  test('hasAnySection false when all disabled', () {
    const opts = ClinicalReportIncludeOptions(
      questionnaires: false,
      mentalMap: false,
      goals: false,
      problems: false,
      checkIns: false,
      dailyMonitors: false,
      timeline: false,
      genogram: false,
    );
    expect(opts.hasAnySection, isFalse);
  });
}
