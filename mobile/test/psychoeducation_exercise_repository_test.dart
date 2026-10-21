import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:terapia_esquema/features/psychoeducation/data/exercise_repository.dart';
import 'package:terapia_esquema/core/errors/app_exception.dart';

void main() {
  for (final missing in [true, false]) {
    test('no response query for missing=$missing patient profile', () async {
      final requests = <Uri>[];
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        requests.add(request.uri);
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(missing ? null : {'profile_id': null}));
        await request.response.close();
      });
      final client = SupabaseClient('http://127.0.0.1:${server.port}', 'test');
      addTearDown(client.dispose);
      final result = ExerciseRepository(client: client).listPatientResponses('record');
      if (missing) {
        await expectLater(result, throwsA(isA<AppException>()));
      } else {
        expect(await result, isEmpty);
      }
      expect(requests, hasLength(1));
    });
  }
  test('resolves patients.id to profiles.id before reading responses',
      () async {
    final requests = <Uri>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      requests.add(request.uri);
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(request.uri.path.endsWith('/patients')
          ? {'profile_id': 'profile-test'}
          : <Object>[]));
      await request.response.close();
    });
    final client = SupabaseClient('http://127.0.0.1:${server.port}', 'test');
    addTearDown(client.dispose);
    expect(
        await ExerciseRepository(client: client)
            .listPatientResponses('record-test'),
        isEmpty);
    expect(requests.first.queryParameters['id'], 'eq.record-test');
    expect(requests.last.queryParameters['patient_id'], 'eq.profile-test');
    expect(
        requests.last.queryParameters['order'], startsWith('updated_at.desc'));
  });
}
