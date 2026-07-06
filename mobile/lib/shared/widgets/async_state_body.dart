import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/theme/app_spacing.dart';
import 'app_empty_state.dart';
import 'loading_skeleton.dart';
import 'app_motion.dart';

/// Corpo reutilizável para listas com loading, erro, vazio e conteúdo.
class AsyncStateBody<T> extends StatelessWidget {
  const AsyncStateBody({
    super.key,
    required this.asyncValue,
    required this.onRetry,
    required this.dataBuilder,
    this.emptyMessage = 'Nenhum item encontrado.',
    this.emptyIcon = Icons.inbox_outlined,
    this.useSkeleton = true,
  });

  final AsyncValue<T> asyncValue;
  final VoidCallback onRetry;
  final Widget Function(T data) dataBuilder;
  final String emptyMessage;
  final IconData emptyIcon;
  final bool useSkeleton;

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      loading: () => useSkeleton
          ? const LoadingSkeletonList()
          : const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorStatePanel(
        message: error is AppException
            ? userMessageFor(error)
            : 'Não foi possível carregar os dados.',
        onRetry: onRetry,
      ),
      data: (data) {
        if (data is List && data.isEmpty) {
          return EmptyStatePanel(message: emptyMessage, icon: emptyIcon);
        }
        return MotionReveal(child: dataBuilder(data));
      },
    );
  }
}

class EmptyStatePanel extends StatelessWidget {
  const EmptyStatePanel({
    super.key,
    required this.message,
    required this.icon,
    this.title = 'Nada por aqui ainda',
    this.hint,
    this.action,
  });

  final String message;
  final IconData icon;
  final String title;
  final String? hint;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: MotionReveal(
          child: AppEmptyState(
            icon: icon,
            title: title,
            message: message,
            hint: hint,
            action: action,
          ),
        ),
      ),
    );
  }
}

class ErrorStatePanel extends StatelessWidget {
  const ErrorStatePanel({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl),
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
