import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/clay_card.dart';
import '../../daily_monitors/presentation/daily_monitor_routes.dart';
import 'psychoeducation_routes.dart';

class PracticeLibraryLinks extends StatelessWidget {
  const PracticeLibraryLinks({super.key});

  @override
  Widget build(BuildContext context) => ClayCard(
          child: Column(children: [
        ListTile(
          leading: const Icon(Icons.edit_note_outlined),
          title: const Text('Diários'),
          subtitle: const Text('Registrar situações e consultar meu Diário.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(DailyMonitorRoutes.patientList),
        ),
        ListTile(
          leading: const Icon(Icons.style_outlined),
          title: const Text('Cartões de enfrentamento'),
          subtitle: const Text('Reflexões a partir do YCI e YRAI.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(PsychoeducationRoutes.patientCopingCards),
        ),
      ]));
}
