import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/psychoeducation_providers.dart';
import 'psychoeducation_routes.dart';

/// Botão discreto que leva o terapeuta ao módulo publicado da Biblioteca de
/// Psicoeducação com o [number] indicado. Resolve o número para o UUID do
/// ambiente; sem o módulo publicado, não aparece.
class _LibraryLink extends ConsumerWidget {
  const _LibraryLink({required this.number, required this.label});

  final int number;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journey = ref.watch(psychoeducationJourneyProvider);
    final modules = journey.valueOrNull;
    final matches = modules?.where((module) => module.number == number);
    if (matches == null || matches.isEmpty) return const SizedBox.shrink();
    return TextButton.icon(
      onPressed: () => context.push(
        PsychoeducationRoutes.psychologistModule(matches.first.id),
      ),
      icon: const Icon(Icons.menu_book_outlined, size: 16),
      label: Text(label),
    );
  }
}

/// Mapa Mental › Modos → Biblioteca 9 (Transformar).
class TransformarLibraryLink extends StatelessWidget {
  const TransformarLibraryLink({super.key});

  @override
  Widget build(BuildContext context) => const _LibraryLink(
        number: 9,
        label: 'Ver Biblioteca Transformar',
      );
}

/// Mapa Mental › Esquemas → Biblioteca 8 (Compreender).
class CompreenderLibraryLink extends StatelessWidget {
  const CompreenderLibraryLink({super.key});

  @override
  Widget build(BuildContext context) => const _LibraryLink(
        number: 8,
        label: 'Ver Biblioteca Compreender',
      );
}
