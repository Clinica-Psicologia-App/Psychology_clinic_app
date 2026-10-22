import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/psychoeducation_providers.dart';
import 'psychoeducation_routes.dart';

/// Botão discreto que leva o terapeuta ao módulo publicado da Biblioteca de
/// Psicoeducação com o [number] indicado. Resolve o número para o UUID do
/// ambiente; sem o módulo publicado (ou se a jornada falhar), leva à
/// biblioteca geral em vez de apontar para um link quebrado.
class _LibraryLink extends ConsumerWidget {
  const _LibraryLink({
    required this.number,
    required this.label,
    this.closeSheet = false,
  });

  final int number;
  final String label;
  final bool closeSheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journey = ref.watch(psychoeducationJourneyProvider);
    if (journey.isLoading && !journey.hasValue) return const SizedBox.shrink();
    final matches =
        journey.valueOrNull?.where((module) => module.number == number);
    final resolved = matches != null && matches.isNotEmpty;
    final route = resolved
        ? PsychoeducationRoutes.psychologistModule(matches.first.id)
        : PsychoeducationRoutes.psychologist;
    return TextButton.icon(
      onPressed: () {
        final router = GoRouter.of(context);
        if (closeSheet) Navigator.of(context).pop();
        router.push(route);
      },
      icon: const Icon(Icons.menu_book_outlined, size: 16),
      label: Text(resolved ? label : 'Abrir bibliotecas'),
    );
  }
}

/// Mapa Mental › Modos → Biblioteca 9 (Transformar).
class TransformarLibraryLink extends StatelessWidget {
  const TransformarLibraryLink({super.key, this.closeSheet = false});

  final bool closeSheet;

  @override
  Widget build(BuildContext context) => _LibraryLink(
        number: 9,
        label: 'Ver Biblioteca Transformar',
        closeSheet: closeSheet,
      );
}

/// Mapa Mental › Esquemas → Biblioteca 8 (Compreender).
class CompreenderLibraryLink extends StatelessWidget {
  const CompreenderLibraryLink({super.key, this.closeSheet = false});

  final bool closeSheet;

  @override
  Widget build(BuildContext context) => _LibraryLink(
        number: 8,
        label: 'Ver Biblioteca Compreender',
        closeSheet: closeSheet,
      );
}
