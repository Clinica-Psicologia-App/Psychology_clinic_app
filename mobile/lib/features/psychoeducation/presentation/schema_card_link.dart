import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../profile/domain/profile_role.dart';
import '../domain/schema_library_card.dart';
import '../providers/psychoeducation_providers.dart';
import 'psychoeducation_routes.dart';

/// Botão "Ver card" ao lado de um esquema no Mapa Mental: abre a Biblioteca 8
/// direto no card daquele esquema. Resolve o número da biblioteca para o id do
/// ambiente; sem a biblioteca publicada, leva à biblioteca geral em vez de
/// apontar para um link quebrado. Some se [schemaCode] não for um dos 18
/// esquemas.
class SchemaCardButton extends ConsumerWidget {
  const SchemaCardButton({
    super.key,
    required this.schemaCode,
    required this.role,
    this.closeSheet = false,
  });

  final String? schemaCode;
  final ProfileRole role;

  /// `true` quando o botão está dentro de uma folha que deve fechar antes de
  /// navegar.
  final bool closeSheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = schemaLibraryCardNumber(schemaCode);
    if (card == null) return const SizedBox.shrink();

    final isPatient = role == ProfileRole.patient;
    final journey = ref.watch(psychoeducationJourneyProvider);
    final matches = journey.valueOrNull
        ?.where((module) => module.number == kSchemaLibraryNumber);
    final module = (matches != null && matches.isNotEmpty) ? matches.first : null;
    final route = module != null
        ? (isPatient
            ? PsychoeducationRoutes.patientModule(module.id, card: card)
            : PsychoeducationRoutes.psychologistModule(module.id, card: card))
        : (isPatient
            ? PsychoeducationRoutes.patient
            : PsychoeducationRoutes.psychologist);

    return OutlinedButton.icon(
      onPressed: () {
        final router = GoRouter.of(context);
        if (closeSheet) Navigator.of(context).pop();
        router.push(route);
      },
      icon: const Icon(Icons.menu_book_outlined, size: 14),
      label: const Text('Ver card'),
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: const StadiumBorder(),
        textStyle: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
