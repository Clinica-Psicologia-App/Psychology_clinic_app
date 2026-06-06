import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../patients/presentation/patient_routes.dart';
import '../../patient_journey/presentation/patient_journey_routes.dart';
import '../../profile/domain/profile_role.dart';
import '../../profile/domain/user_profile.dart';
import '../../questionnaires/presentation/questionnaire_routes.dart';
import '../providers/auth_providers.dart';

class RoleHomeShell extends ConsumerWidget {
  const RoleHomeShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.role,
  });

  final String title;
  final String subtitle;
  final ProfileRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final profile = authState.valueOrNull;

    return AppScaffold(
      title: title,
      actions: [
        IconButton(
          tooltip: 'Sair',
          onPressed: () =>
              ref.read(authControllerProvider.notifier).signOut(),
          icon: const Icon(Icons.logout),
        ),
      ],
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            e is AppException ? userMessageFor(e) : 'Erro ao carregar perfil.',
          ),
        ),
        data: (p) {
          final user = p ?? profile;
          if (user == null) {
            return const Center(child: Text('Perfil não carregado.'));
          }
          return _HomeBody(profile: user, subtitle: subtitle, role: role);
        },
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.profile,
    required this.subtitle,
    required this.role,
  });

  final UserProfile profile;
  final String subtitle;
  final ProfileRole role;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: CircleAvatar(child: Text(profile.fullName[0])),
              title: Text(profile.fullName),
              subtitle: Text('${profile.role.label}\n${profile.email}'),
              isThreeLine: true,
            ),
          ),
          if (role == ProfileRole.admin ||
              role == ProfileRole.psychologist) ...[
            const SizedBox(height: 8),
            Text(
              'Módulos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.people_outline),
                title: const Text('Pacientes'),
                subtitle: const Text('Listar, cadastrar e ver detalhes'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(PatientRoutes.list(role)),
              ),
            ),
            if (role == ProfileRole.admin)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.assignment_ind_outlined),
                  title: const Text('Acesso a questionários'),
                  subtitle: const Text(
                    'Liberar ou bloquear instrumentos por profissional.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(QuestionnaireRoutes.adminAccess),
                ),
              ),
          ],
          if (role == ProfileRole.patient) ...[
            const SizedBox(height: 8),
            Text(
              'Jornada',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.route_outlined),
                title: const Text('Meu plano terapêutico'),
                subtitle: const Text(
                  'Trilha com questionários, monitor, biblioteca e próximos módulos.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(PatientJourneyRoutes.journey),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
