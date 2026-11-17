import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:terapia_esquema/core/errors/app_exception.dart';
import 'package:terapia_esquema/features/patients/data/patients_repository.dart';
import 'package:terapia_esquema/features/patients/domain/update_patient_credentials_request.dart';

class _Functions extends FunctionsClient {
  _Functions() : super('http://localhost', const {});

  String? name;
  Object? sentBody;
  FunctionResponse? response;
  FunctionException? failure;

  @override
  Future<FunctionResponse> invoke(
    String functionName, {
    Map<String, String>? headers,
    Object? body,
    Iterable<MultipartFile>? files,
    Map<String, dynamic>? queryParameters,
    HttpMethod method = HttpMethod.post,
    String? region,
    Future<void>? abortSignal,
  }) async {
    name = functionName;
    sentBody = body;
    if (failure != null) throw failure!;
    return response ?? FunctionResponse(data: {'ok': true}, status: 200);
  }
}

class _Auth implements GoTrueClient {
  int signOuts = 0;

  @override
  Future<void> signOut({SignOutScope scope = SignOutScope.local}) async {
    signOuts++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Client implements SupabaseClient {
  _Client(this.functions, this.auth);

  @override
  final _Functions functions;

  @override
  final _Auth auth;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Functions fn;
  late _Auth auth;
  late PatientsRepository repo;

  setUp(() {
    fn = _Functions();
    auth = _Auth();
    repo = PatientsRepository(client: _Client(fn, auth));
  });

  test('envia só os campos informados para update-patient-credentials',
      () async {
    await repo.updatePatientCredentials(const UpdatePatientCredentialsRequest(
        patientId: 'p1', email: 'novo@exemplo.com'));
    expect(fn.name, 'update-patient-credentials');
    expect(fn.sentBody, {'patient_id': 'p1', 'email': 'novo@exemplo.com'});

    await repo.updatePatientCredentials(const UpdatePatientCredentialsRequest(
        patientId: 'p1', password: 'senha-segura-1'));
    expect(fn.sentBody, {'patient_id': 'p1', 'password': 'senha-segura-1'});
  });

  test('o texto do pedido nunca contém a senha', () {
    const r = UpdatePatientCredentialsRequest(
        patientId: 'p1', password: 'senha-segura-1');
    expect(r.toString().contains('senha-segura-1'), isFalse);
  });

  test('409: mostra a mensagem do servidor como veio', () async {
    fn.failure = const FunctionException(status: 409, details: {
      'ok': false,
      'error': {
        'code': 'CONFLICT',
        'message': 'Este e-mail não pode ser usado.'
      }
    });
    await expectLater(
      repo.updatePatientCredentials(const UpdatePatientCredentialsRequest(
          patientId: 'p1', email: 'x@exemplo.com')),
      throwsA(isA<AppException>().having(
          (e) => e.message, 'message', 'Este e-mail não pode ser usado.')),
    );
  });

  test('estado parcial (500): mostra "Repita o pedido" do servidor', () async {
    const msg =
        'O login já foi alterado, mas a ficha do paciente não foi atualizada. Repita o pedido para concluir.';
    fn.failure = const FunctionException(status: 500, details: {
      'ok': false,
      'error': {'code': 'INTERNAL_ERROR', 'message': msg}
    });
    await expectLater(
      repo.updatePatientCredentials(const UpdatePatientCredentialsRequest(
          patientId: 'p1', email: 'x@exemplo.com')),
      throwsA(isA<AppException>().having((e) => e.message, 'message', msg)),
    );
  });

  test('500 genérico segue a mensagem padrão de erro de servidor', () async {
    fn.failure = const FunctionException(status: 500, details: {
      'ok': false,
      'error': {'code': 'INTERNAL_ERROR', 'message': 'Failed to record audit'}
    });
    await expectLater(
      repo.updatePatientCredentials(const UpdatePatientCredentialsRequest(
          patientId: 'p1', password: 'senha-segura-1')),
      throwsA(isA<AppException>().having(
          (e) => e.message, 'message', contains('problema no servidor'))),
    );
  });

  test('401 lançado: vira SESSION_EXPIRED como nas demais funções', () async {
    fn.failure = const FunctionException(status: 401, details: {
      'ok': false,
      'error': {'code': 'UNAUTHORIZED', 'message': 'JWT expired'}
    });
    await expectLater(
      repo.updatePatientCredentials(const UpdatePatientCredentialsRequest(
          patientId: 'p1', password: 'senha-segura-1')),
      throwsA(isA<AppException>()
          .having((e) => e.code, 'code', AppExceptionCodes.sessionExpired)),
    );
  });

  test('401 devolvido na resposta: mesma política de sessão (signOut)',
      () async {
    fn.response = FunctionResponse(data: {
      'ok': false,
      'error': {'code': 'UNAUTHORIZED', 'message': 'JWT expired'}
    }, status: 401);
    await expectLater(
      repo.updatePatientCredentials(const UpdatePatientCredentialsRequest(
          patientId: 'p1', password: 'senha-segura-1')),
      throwsA(isA<AppException>()
          .having((e) => e.code, 'code', AppExceptionCodes.sessionExpired)),
    );
    expect(auth.signOuts, 1);
  });
}
