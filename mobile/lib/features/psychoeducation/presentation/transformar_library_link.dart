import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/psychoeducation_providers.dart';
import 'psychoeducation_routes.dart';

/// Resolves the published module number to its environment-specific UUID.
class TransformarLibraryLink extends ConsumerWidget {
  const TransformarLibraryLink({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journey = ref.watch(psychoeducationJourneyProvider);
    final modules = journey.valueOrNull;
    final matches = modules?.where((module) => module.number == 9);
    if (matches == null || matches.isEmpty) return const SizedBox.shrink();
    return TextButton.icon(
      onPressed: () => context.push(
        PsychoeducationRoutes.psychologistModule(matches.first.id),
      ),
      icon: const Icon(Icons.menu_book_outlined, size: 16),
      label: const Text('Ver Biblioteca Transformar'),
    );
  }
}
