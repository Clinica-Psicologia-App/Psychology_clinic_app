import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/document_logo_repository.dart';

final documentLogoRepositoryProvider = Provider<DocumentLogoRepository>(
  (ref) => DocumentLogoRepository(),
);

/// Logo da usuária logada (null = usar a logo padrão do EsquemaCore).
final documentLogoProvider = FutureProvider<Uint8List?>(
  (ref) => ref.read(documentLogoRepositoryProvider).downloadOwn(),
);
