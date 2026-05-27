import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/errors/error_mapper.dart';

/// Corpo reutilizável para listas com loading, erro, vazio e conteúdo.
class AsyncStateBody<T> extends StatelessWidget {
  const AsyncStateBody({
    super.key,
    required this.asyncValue,
    required this.onRetry,
    required this.dataBuilder,
    this.emptyMessage = 'Nenhum item encontrado.',
    this.emptyIcon = Icons.inbox_outlined,
  });

  final AsyncValue<T> asyncValue;
  final VoidCallback onRetry;
  final Widget Function(T data) dataBuilder;
  final String emptyMessage;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorState(
        message: error is AppException
            ? userMessageFor(error)
            : 'Não foi possível carregar os dados.',
        onRetry: onRetry,
      ),
      data: (data) {
        if (data is List && data.isEmpty) {
          return _EmptyState(message: emptyMessage, icon: emptyIcon);
        }
        return dataBuilder(data);
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
