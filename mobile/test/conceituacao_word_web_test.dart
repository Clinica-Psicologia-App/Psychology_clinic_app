import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_data.dart';
import 'package:terapia_esquema/features/mental_map/presentation/case_conceptualization_word.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    CaseConceptualizationWord.debugForceWeb = null;
    CaseConceptualizationWord.debugWebDeliver = null;
  });

  test('web: não lança e entrega bytes RTF com nome .rtf', () async {
    Uint8List? gotBytes;
    String? gotName;
    CaseConceptualizationWord.debugForceWeb = true;
    CaseConceptualizationWord.debugWebDeliver = (bytes, name) async {
      gotBytes = bytes;
      gotName = name;
    };

    await CaseConceptualizationWord.shareOrOpen(data: MentalMapData.empty);

    expect(gotBytes, isNotNull);
    expect(ascii.decode(gotBytes!.sublist(0, 5)), r'{\rtf');
    expect(gotName, 'formulacao_paciente.rtf');
    expect(gotName!.endsWith('.rtf'), isTrue);
  });

  test('web: arquivos montados têm mime, nome e bytes RTF', () async {
    final bytes = CaseConceptualizationWord.buildBytes(
        data: MentalMapData.empty);
    final files = CaseConceptualizationWord.webFiles(
        bytes, 'formulacao_paciente.rtf');
    expect(files, hasLength(1));
    expect(files.first.mimeType, 'application/rtf');
    // `name` do XFile.fromData é ignorado na VM (só vale na web); o nome .rtf
    // é garantido por fileNameOverrides e coberto no teste acima.
    final read = await files.first.readAsBytes();
    expect(ascii.decode(read.sublist(0, 5)), r'{\rtf');
  });
}
