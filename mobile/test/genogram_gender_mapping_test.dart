import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/genogram/data/genogram_repository.dart';

void main() {
  group('GenogramRepository.mapPatientGender', () {
    test('inglês existente mapeado corretamente', () {
      expect(GenogramRepository.mapPatientGender('male'), 'male');
      expect(GenogramRepository.mapPatientGender('female'), 'female');
      expect(GenogramRepository.mapPatientGender('other'), 'other');
      expect(GenogramRepository.mapPatientGender('unknown'), 'unknown');
      expect(GenogramRepository.mapPatientGender('non_binary'), 'other');
    });

    test('português maiúsculo mapeado corretamente', () {
      expect(GenogramRepository.mapPatientGender('Feminino'), 'female');
      expect(GenogramRepository.mapPatientGender('Masculino'), 'male');
      expect(GenogramRepository.mapPatientGender('Não binário'), 'other');
      expect(GenogramRepository.mapPatientGender('Outro'), 'other');
      expect(GenogramRepository.mapPatientGender('Prefiro não informar'), 'unknown');
    });

    test('português minúsculo mapeado corretamente', () {
      expect(GenogramRepository.mapPatientGender('feminino'), 'female');
      expect(GenogramRepository.mapPatientGender('masculino'), 'male');
    });

    test('nulo e valor desconhecido retornam null', () {
      expect(GenogramRepository.mapPatientGender(null), isNull);
      expect(GenogramRepository.mapPatientGender(''), isNull);
      expect(GenogramRepository.mapPatientGender('xyz'), isNull);
    });
  });
}
