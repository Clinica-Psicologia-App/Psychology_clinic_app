import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../patient_timeline/domain/patient_timeline_event.dart';
import '../../patient_timeline/presentation/patient_timeline_routes.dart';
import '../../patient_timeline/presentation/widgets/patient_timeline_widgets.dart';
import '../../patient_timeline/providers/patient_timeline_providers.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/genogram_data.dart';
import '../domain/genogram_gender.dart';
import '../domain/genogram_person.dart';
import '../providers/genogram_providers.dart';
import 'genogram_routes.dart';
import 'widgets/genogram_widgets.dart';
import '../../../shared/widgets/brand_loading.dart';

class GenogramPersonDetailPage extends ConsumerWidget {
  const GenogramPersonDetailPage({
    super.key,
    required this.role,
    required this.personId,
    this.patientId,
  });

  final ProfileRole role;
  final String personId;
  final String? patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personAsync = ref.watch(genogramPersonDetailProvider(personId));

    return AppScaffold(
      title: 'Pessoa',
      accent: AppColors.blue,
      body: personAsync.when(
        loading: () => const BrandLoader(),
        error: (_, __) => Center(
          child: FilledButton(
            onPressed: () =>
                ref.invalidate(genogramPersonDetailProvider(personId)),
            child: const Text('Tentar novamente'),
          ),
        ),
        data: (person) {
          if (person == null) {
            return const Center(child: Text('Pessoa não encontrada.'));
          }

          return _PersonDetailBody(
            person: person,
            role: role,
            patientId: patientId,
            onChanged: () {
              ref.invalidate(genogramPersonDetailProvider(personId));
              _refreshLists(ref);
            },
          );
        },
      ),
    );
  }

  void _refreshLists(WidgetRef ref) {
    if (role == ProfileRole.patient) {
      ref.read(myGenogramProvider.notifier).refresh();
    } else if (patientId != null) {
      ref.invalidate(
        staffGenogramProvider(
          StaffGenogramContext(role: role, patientId: patientId!),
        ),
      );
    }
  }
}

class _PersonDetailBody extends ConsumerWidget {
  const _PersonDetailBody({
    required this.person,
    required this.role,
    required this.patientId,
    required this.onChanged,
  });

  final GenogramPerson person;
  final ProfileRole role;
  final String? patientId;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genogramAsync = role == ProfileRole.patient
        ? ref.watch(myGenogramProvider)
        : ref.watch(
            staffGenogramProvider(
              StaffGenogramContext(
                role: role,
                patientId: patientId!,
              ),
            ),
          );

    return genogramAsync.when(
      loading: () => const BrandLoader(),
      error: (_, __) => const Center(child: Text('Erro ao carregar relações.')),
      data: (data) => _buildContent(context, ref, data),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, GenogramData data) {
    final linked =
        data.relationships.where((r) => r.involvesPerson(person.id)).toList();

    return MotionReveal(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxxl,
              ),
              children: [
                if (person.isSensitive)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppInfoCard(
                      title: 'Dados sensíveis',
                      body:
                          'As informações foram ocultadas na visualização principal.',
                      icon: Icons.lock_outline,
                      tone: AppInfoCardTone.error,
                    ),
                  ),
                AppPageHeader(
                  title: person.displayName,
                  subtitle:
                      'Detalhes desta pessoa no genograma e relações registradas.',
                  icon: person.isSensitive
                      ? Icons.lock_outline
                      : Icons.person_outline,
                  metadata: [
                    if (person.relationshipToPatient != null &&
                        person.relationshipToPatient!.trim().isNotEmpty)
                      Chip(label: Text(person.relationshipToPatient!.trim())),
                    if (person.gender != null)
                      Chip(label: Text(person.gender!.label)),
                    if (person.lifeSpanLabel != null)
                      Chip(label: Text(person.lifeSpanLabel!)),
                    if (person.isDeceased) const Chip(label: Text('Falecido')),
                  ],
                ),
                if (person.notes != null &&
                    person.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  AppInfoCard(
                    title: 'Observações',
                    body: person.notes!.trim(),
                    icon: Icons.notes_outlined,
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                const AppSectionHeader(
                  title: 'Relações vinculadas',
                  subtitle: 'Vínculos registrados com esta pessoa.',
                ),
                const SizedBox(height: AppSpacing.sm),
                if (linked.isEmpty)
                  const AppInfoCard(
                    title: 'Nenhuma relação cadastrada',
                    body: 'Ainda não há vínculo registrado com esta pessoa.',
                    icon: Icons.account_tree_outlined,
                  )
                else
                  ...linked.map(
                    (r) => GenogramRelationshipTile(
                      relationship: r,
                      data: data,
                      onTap: () => _openRelationship(context, r.id),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),
                const AppSectionHeader(
                  title: 'Linha do tempo',
                  subtitle: 'Acontecimentos registrados desta pessoa.',
                ),
                const SizedBox(height: AppSpacing.sm),
                _PersonTimelineSection(
                  person: person,
                  role: role,
                  patientId: patientId,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: FilledButton.icon(
              onPressed: () async {
                // Rota STANDALONE para editar: esta tela de detalhe também é
                // aberta a partir do diagrama (rota de topo, fora da árvore
                // de StaffPatientGenogramPage) — usar sempre a edição
                // standalone evita reconstruir aquele branch e o crash de
                // GlobalKey que isso causava.
                final updated = await context.push<bool>(
                  role == ProfileRole.patient
                      ? GenogramRoutes.patientPersonEdit(person.id)
                      : GenogramRoutes.personEditFor(
                          patientId ?? person.patientId,
                          person.id,
                        ),
                );
                if (updated == true) onChanged();
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar pessoa'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRelationship(BuildContext context, String id) async {
    await context.push(
      role == ProfileRole.patient
          ? GenogramRoutes.patientRelationshipDetail(id)
          : GenogramRoutes.staffRelationshipDetail(
              role: role,
              patientId: patientId!,
              relationshipId: id,
            ),
    );
    onChanged();
  }
}

/// Eventos da linha do tempo vinculados a esta pessoa — permite ao
/// psicólogo ir direto do genograma ao(s) acontecimento(s) registrado(s).
class _PersonTimelineSection extends ConsumerWidget {
  const _PersonTimelineSection({
    required this.person,
    required this.role,
    required this.patientId,
  });

  final GenogramPerson person;
  final ProfileRole role;
  final String? patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(
      timelineEventsForPersonProvider(
        TimelineEventsForPersonContext(
          patientId: person.patientId,
          personId: person.id,
        ),
      ),
    );

    return eventsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: BrandLoader()),
      ),
      error: (_, __) => const AppInfoCard(
        title: 'Erro ao carregar a linha do tempo',
        body: 'Não foi possível carregar os eventos desta pessoa.',
        icon: Icons.error_outline,
        tone: AppInfoCardTone.error,
      ),
      data: (events) {
        if (events.isEmpty) {
          return const AppInfoCard(
            title: 'Nenhum evento vinculado',
            body:
                'Nenhum acontecimento da linha do tempo está associado a '
                'esta pessoa ainda. É possível vincular ao editar um evento.',
            icon: Icons.event_note_outlined,
          );
        }

        return Column(
          children: [
            for (var i = 0; i < events.length; i++)
              PatientTimelineEventTile(
                event: events[i],
                isFirst: i == 0,
                isLast: i == events.length - 1,
                onTap: () => _openEvent(context, events[i]),
              ),
          ],
        );
      },
    );
  }

  Future<void> _openEvent(
    BuildContext context,
    PatientTimelineEvent event,
  ) async {
    await context.push(
      role == ProfileRole.patient
          ? PatientTimelineRoutes.patientDetail(event.id)
          // Rota STANDALONE: esta ficha é de topo (aberta pelo diagrama). Usar
          // a rota aninhada aqui reentraria no shell, duplicando a página dele
          // na pilha — crash de GlobalKey no Navigator.
          : PatientTimelineRoutes.staffDetailFor(
              patientId ?? person.patientId,
              event.id,
            ),
    );
  }
}
