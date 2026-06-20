import 'package:flutter/material.dart';

import '../../core/errors/app_exception.dart';
import '../../core/errors/error_mapper.dart';

MaterialBanner buildErrorBanner(
  ScaffoldMessengerState messenger,
  BuildContext context,
  Object error,
) {
  final message = error is AppException
      ? userMessageFor(error)
      : 'Ocorreu um erro. Tente novamente.';

  return MaterialBanner(
    backgroundColor: Theme.of(context).colorScheme.errorContainer,
    content: Text(message),
    actions: [
      TextButton(
        onPressed: () => messenger.hideCurrentMaterialBanner(),
        child: const Text('OK'),
      ),
    ],
  );
}

void showErrorBanner(BuildContext context, Object error) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentMaterialBanner()
    ..showMaterialBanner(buildErrorBanner(messenger, context, error));
}
