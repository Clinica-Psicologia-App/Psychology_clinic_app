import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/personality_reference/domain/personality_reference_content.dart';

void main() {
  test('personality reference content is structured by five factors', () {
    expect(personalityReferenceFactors.length, 5);
    expect(personalityReferenceFactors.first.facets.length, 6);
    expect(personalityReferenceFactors.last.facets.length, 6);
    expect(personalityReferenceNote, contains('esquemas subjacentes'));
  });
}
