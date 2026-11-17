import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:terapia_esquema/core/errors/app_exception.dart';
import 'package:terapia_esquema/core/network/edge_api_client.dart';

class _Functions extends FunctionsClient {
  _Functions() : super('http://localhost', const {});

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
    if (failure != null) throw failure!;
    return response!;
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

Map<String, dynamic> _payload(String code) => {
      'ok': false,
      'error': {'code': code, 'message': 'x'}
    };

AppException? _mask(Map<String, dynamic> e, int? s) =>
    AppException(code: AppExceptionCodes.unknown, message: 'MASCARADO');

void main() {
  late _Functions fn;
  late _Auth auth;
  late EdgeApiClient api;

  setUp(() {
    fn = _Functions();
    auth = _Auth();
    api = EdgeApiClient(client: _Client(fn, auth));
  });

  Future<AppException> run({bool override = true}) async {
    try {
      await api.invoke('f', errorOverride: override ? _mask : null);
    } on AppException catch (e) {
      return e;
    }
    fail('deveria lançar');
  }

  for (final c in ['UNAUTHORIZED', 'SESSION_EXPIRED']) {
    test('override não mascara $c no payload devolvido (status 200)', () async {
      fn.response = FunctionResponse(data: _payload(c), status: 200);
      // status 200 + ok:false cai no 2º ramo do cliente
      final e = await run();
      expect(e.message, isNot('MASCARADO'));
    });

    test('override não mascara $c em FunctionException (status 400)', () async {
      fn.failure = FunctionException(status: 400, details: _payload(c));
      final e = await run();
      expect(e.message, isNot('MASCARADO'));
    });
  }

  test('override não mascara status 401 (resposta e exceção)', () async {
    fn.response = FunctionResponse(data: _payload('OUTRO'), status: 401);
    var e = await run();
    expect(e.message, isNot('MASCARADO'));
    fn.response = null;
    fn.failure = FunctionException(status: 401, details: _payload('OUTRO'));
    e = await run();
    expect(e.message, isNot('MASCARADO'));
  });

  test('401 na resposta continua chamando signOut, com e sem override',
      () async {
    fn.response = FunctionResponse(data: _payload('UNAUTHORIZED'), status: 401);
    await run();
    await run(override: false);
    expect(auth.signOuts, 2);
  });

  test('outros erros ainda podem ser tratados pelo override', () async {
    fn.failure = FunctionException(status: 409, details: _payload('CONFLICT'));
    expect((await run()).message, 'MASCARADO');
    fn.failure = null;
    fn.response = FunctionResponse(data: _payload('CONFLICT'), status: 409);
    expect((await run()).message, 'MASCARADO');
  });

  test('sem override, o resultado é o mapeamento padrão (inalterado)',
      () async {
    fn.failure = FunctionException(status: 409, details: _payload('CONFLICT'));
    final e = await run(override: false);
    expect(e.code, AppExceptionCodes.conflict);
    fn.failure =
        FunctionException(status: 401, details: _payload('UNAUTHORIZED'));
    expect((await run(override: false)).code, AppExceptionCodes.sessionExpired);
  });
}
