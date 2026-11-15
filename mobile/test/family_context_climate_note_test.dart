import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/life_story/domain/family_context.dart';

String climateNoteLabel(Set<ClimateTrait> climate) =>
    climate.contains(ClimateTrait.other)
        ? 'Conte o que mais fazia parte do ambiente em que você cresceu.'
        : 'Se tivesse que descrever o clima da sua família em poucas palavras, como descreveria?';

void main() {
  group('climate_note rótulo e visibilidade', () {
    test('campo sempre visível: rótulo original sem Outro', () {
      expect(climateNoteLabel({}), contains('Se tivesse que descrever'));
      expect(climateNoteLabel({ClimateTrait.showedAffection}),
          contains('Se tivesse que descrever'));
    });

    test('rótulo específico quando Outro selecionado', () {
      expect(climateNoteLabel({ClimateTrait.other}),
          'Conte o que mais fazia parte do ambiente em que você cresceu.');
      expect(
          climateNoteLabel({ClimateTrait.showedAffection, ClimateTrait.other}),
          'Conte o que mais fazia parte do ambiente em que você cresceu.');
    });

    test('desmarcar Outro volta ao rótulo original (sem limpar texto)', () {
      final climate = {ClimateTrait.other};
      expect(climateNoteLabel(climate),
          'Conte o que mais fazia parte do ambiente em que você cresceu.');
      climate.remove(ClimateTrait.other);
      expect(climateNoteLabel(climate), contains('Se tivesse que descrever'));
    });

    test('ClimateTrait.other tem label Outro', () {
      expect(ClimateTrait.other.label, 'Outro');
    });
  });
}
