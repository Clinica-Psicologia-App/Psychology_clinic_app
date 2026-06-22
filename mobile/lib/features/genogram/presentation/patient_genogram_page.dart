import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/genogram_data.dart';
import '../providers/genogram_providers.dart';
import 'genogram_routes.dart';
import 'widgets/genogram_widgets.dart';

class PatientGenogramPage extends ConsumerWidget {
  const PatientGenogramPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _GenogramPageBody(
      listAsync: ref.watch(myGenogramProvider),
      onRefresh: () => ref.read(myGenogramProvider.notifier).refresh(),
      onRetry: () => ref.read(myGenogramProvider.notifier).refresh(),
      personCreateRoute: GenogramRoutes.patientPersonCreate,
      relationshipCreateRoute: GenogramRoutes.patientRelationshipCreate,
      personDetailRoute: GenogramRoutes.patientPersonDetail,
      relationshipDetailRoute: GenogramRoutes.patientRelationshipDetail,
      onDataChanged: () => ref.read(myGenogramProvider.notifier).refresh(),
    );
  }
}

class StaffPatientGenogramPage extends ConsumerWidget {
  const StaffPatientGenogramPage({
    super.key,
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctx = StaffGenogramContext(role: role, patientId: patientId);
    final dataAsync = ref.watch(staffGenogramProvider(ctx));

    return _GenogramPageBody(
      listAsync: dataAsync,
      onRefresh: () async {
        ref.invalidate(staffGenogramProvider(ctx));
        await ref.read(staffGenogramProvider(ctx).future);
      },
      onRetry: () => ref.invalidate(staffGenogramProvider(ctx)),
      personCreateRoute: GenogramRoutes.staffPersonCreate(
        role: role,
        patientId: patientId,
      ),
      relationshipCreateRoute: GenogramRoutes.staffRelationshipCreate(
        role: role,
        patientId: patientId,
      ),
      personDetailRoute: (id) => GenogramRoutes.staffPersonDetail(
        role: role,
        patientId: patientId,
        personId: id,
      ),
      relationshipDetailRoute: (id) => GenogramRoutes.staffRelationshipDetail(
        role: role,
        patientId: patientId,
        relationshipId: id,
      ),
      onDataChanged: () => ref.invalidate(staffGenogramProvider(ctx)),
    );
  }
}

class _GenogramPageBody extends StatelessWidget {
  const _GenogramPageBody({
    required this.listAsync,
    required this.onRefresh,
    required this.onRetry,
    required this.personCreateRoute,
    required this.relationshipCreateRoute,
    required this.personDetailRoute,
    required this.relationshipDetailRoute,
    required this.onDataChanged,
  });

  final AsyncValue<GenogramData> listAsync;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final String personCreateRoute;
  final String relationshipCreateRoute;
  final String Function(String id) personDetailRoute;
  final String Function(String id) relationshipDetailRoute;
  final VoidCallback onDataChanged;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Genograma',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await context.push<bool>(personCreateRoute);
          if (created == true) onDataChanged();
        },
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Pessoa'),
      ),
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () => onRefresh(),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: AsyncStateBody<GenogramData>(
        asyncValue: listAsync,
        onRetry: onRetry,
        emptyMessage:
            'Nenhuma pessoa no genograma. Adicione membros da família e, depois, '
            'registre as relações entre eles.',
        emptyIcon: Icons.family_restroom_outlined,
        dataBuilder: (data) => RefreshIndicator(
          onRefresh: onRefresh,
          child: _GenogramContent(
            data: data,
            personCreateRoute: personCreateRoute,
            relationshipCreateRoute: relationshipCreateRoute,
            personDetailRoute: personDetailRoute,
            relationshipDetailRoute: relationshipDetailRoute,
            onDataChanged: onDataChanged,
          ),
        ),
      ),
    );
  }
}

class _GenogramContent extends StatelessWidget {
  const _GenogramContent({
    required this.data,
    required this.personCreateRoute,
    required this.relationshipCreateRoute,
    required this.personDetailRoute,
    required this.relationshipDetailRoute,
    required this.onDataChanged,
  });

  final GenogramData data;
  final String personCreateRoute;
  final String relationshipCreateRoute;
  final String Function(String id) personDetailRoute;
  final String Function(String id) relationshipDetailRoute;
  final VoidCallback onDataChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        const GenogramGraphicNotice(),
        const SizedBox(height: 12),
        GenogramSummaryCard(data: data),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: data.people.length < 2
              ? null
              : () async {
                  final created =
                      await context.push<bool>(relationshipCreateRoute);
                  if (created == true) onDataChanged();
                },
          icon: const Icon(Icons.add_link),
          label: Text(
            data.people.length < 2
                ? 'Adicione pelo menos 2 pessoas para relação'
                : 'Nova relação',
          ),
        ),
        const SizedBox(height: 24),
        Text('Pessoas', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (data.people.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Nenhuma pessoa cadastrada.'),
          )
        else
          MotionStaggered(
            children: [
              for (final p in data.people)
                GenogramPersonTile(
                  person: p,
                  onTap: () async {
                    await context.push(personDetailRoute(p.id));
                    onDataChanged();
                  },
                ),
            ],
          ),
        const SizedBox(height: 24),
        Text('Relações', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (data.relationships.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Nenhuma relação registrada.'),
          )
        else
          MotionStaggered(
            children: [
              for (final r in data.relationships)
                GenogramRelationshipTile(
                  relationship: r,
                  data: data,
                  onTap: () async {
                    await context.push(relationshipDetailRoute(r.id));
                    onDataChanged();
                  },
                ),
            ],
          ),
      ],
    );
  }
}
