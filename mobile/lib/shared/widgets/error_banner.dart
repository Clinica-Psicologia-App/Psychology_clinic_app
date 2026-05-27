import 'package:flutter/material.dart';

import '../../core/errors/app_exception.dart';
import '../../core/errors/error_mapper.dart';

MaterialBanner buildErrorBanner(BuildContext context, Object error) {
  final message = error is AppException
      ? userMessageFor(error as AppException)
      : 'Ocorreu um erro. Tente novamente.';

  return MaterialBanner(
    backgroundColor: Theme.of(context).colorScheme.errorContainer,
    content: Text(message),
    actions: [
      TextButton(
        onPressed: () =>
            ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
        child: const Text('OK'),
      ),
    ],
  );
}

void showErrorBanner(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
    ..hideCurrentMaterialBanner()
    ..showMaterialBanner(buildErrorBanner(context, error));
}
