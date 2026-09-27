import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:terapia_esquema/features/results/data/results_repository.dart';
import 'package:terapia_esquema/features/questionnaires/domain/finish_questionnaire_result.dart';
import 'package:terapia_esquema/features/results/domain/category_result.dart';
import 'package:terapia_esquema/features/results/domain/patient_result_detail.dart';
import 'package:terapia_esquema/features/results/domain/schema_activation.dart';

void main() {
  test('repository reads patient activations through sanitized RPC', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final paths = <String>[];
    server.listen((request) async {
      paths.add(request.uri.path);
      final body = jsonDecode(await utf8.decoder.bind(request).join());
      expect(body, {'p_response_id': 'response'});
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode([
        {
          'id': 'activation',
          'questionnaire_response_id': 'response',
          'schema_code': 'SCHEMA',
          'schema_name': 'Schema',
          'created_at': '2026-09-24T12:00:00Z',
        },
      ]));
      await request.response.close();
    });
    final client = SupabaseClient('http://127.0.0.1:${server.port}', 'local');
    addTearDown(() async {
      await client.dispose();
      await server.close(force: true);
    });
    final rows = await ResultsRepository(client: client)
        .listSchemaActivations('response');
    expect(paths, ['/rest/v1/rpc/get_patient_schema_activations']);
    expect(rows.single.psiObservation, isNull);
    expect(rows.single.schemaCode, 'SCHEMA');
  });

  test('repository detail uses server-authorized projection', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final paths = <String>[];
    server.listen((request) async {
      paths.add(request.uri.path);
      await request.drain<void>();
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'id': 'response', 'patient_id': 'patient', 'questionnaire_id': 'q',
        'questionnaire': {'id': 'q', 'code': 'YSQ_FOUNDATION_V1', 'name': 'YSQ'},
        'status': 'completed', 'questionnaire_answers': [],
        'questionnaire_results': [],
      }));
      await request.response.close();
    });
    final client = SupabaseClient('http://127.0.0.1:${server.port}', 'local');
    addTearDown(() async {
      await client.dispose();
      await server.close(force: true);
    });
    final detail = await ResultsRepository(client: client)
        .getResponseDetail('response');
    expect(paths, ['/rest/v1/rpc/get_questionnaire_response_detail']);
    expect(detail?.hasResults, isFalse);
  });

  test('completion accepts operational payload without clinical results', () {
    final result = FinishQuestionnaireResult.fromApi({
      'response': {
        'id': 'response',
        'status': 'completed',
        'completed_at': '2026-09-24T12:00:00Z',
        'patient_id': 'patient',
        'questionnaire_id': 'questionnaire',
      },
    }, 'Questionnaire');
    expect(result.responseId, 'response');
    expect(result.completedAt, DateTime.utc(2026, 9, 24, 12));
    expect(result.resultsCount, 0);
  });

  test('released patient projection preserves charts without raw snapshot', () {
    final result = CategoryResult.fromJson({
      'id': 'result',
      'average_score': 4,
      'category': {'code': 'SCHEMA', 'name': 'Schema'},
      'patient_result': {
        'version': 'scoring-demo-1',
        'summary': {'average_score': 4},
        'schemas': [
          {
            'id': 'schema',
            'code': 'SCHEMA',
            'name': 'Schema',
            'average_score': 4
          },
        ],
        'contexts': [
          {'id': 'context', 'label': 'Mãe', 'schemas': []},
        ],
      },
    });
    expect(result.snapshot.scoring!.schemas.single.averageScore, 4);
    expect(result.snapshot.contexts.single.label, 'Mãe');
    expect(result.professionalNote, isNull);
    expect(result.professionalAverageScore, isNull);
  });

  test('patient activation projection does not require professional identity',
      () {
    final activation = SchemaActivation.fromJson({
      'id': 'activation',
      'questionnaire_response_id': 'response',
      'schema_code': 'SCHEMA',
      'schema_name': 'Schema',
      'created_at': '2026-09-24T12:00:00Z',
    });
    expect(activation.schemaName, 'Schema');
    expect(activation.psiObservation, isNull);
    expect(activation.activatedByProfileId, isEmpty);
  });

  test('unreleased operational detail contains no result or review', () {
    final detail = PatientResultDetail.fromJson({
      'id': 'response',
      'patient_id': 'patient',
      'questionnaire_id': 'questionnaire',
      'status': 'completed',
      'questionnaire_answers': [],
      'questionnaire_results': [],
    });
    expect(detail.hasResults, isFalse);
    expect(detail.reviewNotes, isNull);
    expect(detail.scoringDemo, isNull);
  });
}
