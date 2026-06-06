import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/core/router/route_access.dart';
import 'package:terapia_esquema/features/professional_onboarding/domain/create_professional_account_request.dart';

void main() {
  test('professional signup payload maps solo mode without clinic block', () {
    final json = const CreateProfessionalAccountRequest(
      email: '  ana@example.com ',
      password: 'SenhaSegura1',
      fullName: ' Ana Souza ',
      phone: '51999990000',
      crp: '06/12345',
      mode: ProfessionalAccountMode.solo,
    ).toJson();

    expect(json['email'], 'ana@example.com');
    expect(json['full_name'], 'Ana Souza');
    expect(json['mode'], 'solo');
    expect(json.containsKey('clinic'), isFalse);
  });

  test('professional signup payload maps clinic mode with clinic block', () {
    final json = CreateProfessionalAccountRequest(
      email: 'equipe@example.com',
      password: 'SenhaSegura1',
      fullName: 'Ana Souza',
      mode: ProfessionalAccountMode.clinic,
      clinic: const ProfessionalClinicRegistration(
        name: 'Clínica Horizonte',
        email: 'contato@horizonte.com',
        phone: '51999990000',
      ),
    ).toJson();

    expect(json['mode'], 'clinic');
    expect(json['clinic']['name'], 'Clínica Horizonte');
    expect(json['clinic']['email'], 'contato@horizonte.com');
  });

  test('clinic mode requires clinic name', () {
    expect(
      validateClinicNameForMode(ProfessionalAccountMode.clinic, ''),
      'Informe o nome da clínica',
    );
    expect(
      validateClinicNameForMode(ProfessionalAccountMode.solo, ''),
      isNull,
    );
  });

  test('password validation requires minimum length', () {
    expect(validateProfessionalPassword('1234567'), contains('pelo menos 8'));
    expect(validateProfessionalPassword('SenhaSegura1'), isNull);
  });

  test('professional sign up route is public', () {
    expect(RouteAccess.isPublic('/professional-sign-up'), isTrue);
  });
}
