import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/status_chip.dart';
import '../domain/genogram_family_patterns.dart';
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
      familyPatternsPatientId: null,
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
      familyPatternsPatientId:
          role == ProfileRole.psychologist ? patientId : null,
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
    required this.familyPatternsPatientId,
  });

  final AsyncValue<GenogramData> listAsync;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final String personCreateRoute;
  final String relationshipCreateRoute;
  final String Function(String id) personDetailRoute;
  final String Function(String id) relationshipDetailRoute;
  final VoidCallback onDataChanged;
  final String? familyPatternsPatientId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Genograma',
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
            familyPatternsPatientId: familyPatternsPatientId,
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
    required this.familyPatternsPatientId,
  });

  final GenogramData data;
  final String personCreateRoute;
  final String relationshipCreateRoute;
  final String Function(String id) personDetailRoute;
  final String Function(String id) relationshipDetailRoute;
  final VoidCallback onDataChanged;
  final String? familyPatternsPatientId;

  @override
  Widget build(BuildContext context) {
    final sensitivePeople = data.people.where((p) => p.isSensitive).length;
    final sensitiveRelationships =
        data.relationships.where((r) => r.isSensitive).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: [
        AppPageHeader(
          icon: Icons.family_restroom_outlined,
          title: 'Genograma',
          subtitle:
              'Mapeie pessoas, relações e padrões familiares relevantes para a formulação clínica.',
          metadata: [
            StatusChip(
              label: '${data.people.length} pessoa(s)',
              tone: AppStatusTone.info,
              icon: Icons.person_outline,
            ),
            StatusChip(
              label: '${data.relationships.length} relação(ões)',
              tone: AppStatusTone.info,
              icon: Icons.link,
            ),
            if (sensitivePeople + sensitiveRelationships > 0)
              StatusChip(
                label:
                    '${sensitivePeople + sensitiveRelationships} sensível(is)',
                tone: AppStatusTone.error,
                icon: Icons.lock_outline,
              ),
          ],
          primaryAction: FilledButton.icon(
            onPressed: () async {
              final created = await context.push<bool>(personCreateRoute);
              if (created == true) onDataChanged();
            },
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Nova pessoa'),
          ),
          secondaryAction: OutlinedButton.icon(
            onPressed: data.people.length < 2
                ? null
                : () async {
                    final created =
                        await context.push<bool>(relationshipCreateRoute);
                    if (created == true) onDataChanged();
                  },
            icon: const Icon(Icons.add_link),
            label: Text(
              data.people.length < 2 ? 'Relação indisponível' : 'Nova relação',
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const GenogramGraphicNotice(),
        const SizedBox(height: AppSpacing.md),
        GenogramSummaryCard(data: data),
        const SizedBox(height: AppSpacing.md),
        if (familyPatternsPatientId != null) ...[
          FamilyPatternsCard(patientId: familyPatternsPatientId!),
          const SizedBox(height: AppSpacing.lg),
        ],
        const AppSectionHeader(
          title: 'Pessoas',
          subtitle: 'Membros e figuras relevantes no mapa familiar.',
        ),
        const SizedBox(height: AppSpacing.sm),
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
        const SizedBox(height: AppSpacing.xl),
        const AppSectionHeader(
          title: 'Relações',
          subtitle: 'Natureza das conexões entre pessoas do genograma.',
        ),
        const SizedBox(height: AppSpacing.sm),
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

class FamilyPatternsCard extends ConsumerStatefulWidget {
  const FamilyPatternsCard({super.key, required this.patientId});

  final String patientId;

  @override
  ConsumerState<FamilyPatternsCard> createState() => _FamilyPatternsCardState();
}

class _FamilyPatternsCardState extends ConsumerState<FamilyPatternsCard> {
  final _otherController = TextEditingController();
  Set<String> _selectedKeys = {};
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  void _populate(GenogramFamilyPatterns patterns) {
    if (_loaded) return;
    _loaded = true;
    _selectedKeys = {...patterns.selectedKeys};
    _otherController.text = patterns.otherText ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final patternsAsync =
        ref.watch(genogramFamilyPatternsProvider(widget.patientId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: patternsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Padrões familiares',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(userMessageFor(mapToAppException(error))),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () => ref.invalidate(
                  genogramFamilyPatternsProvider(widget.patientId),
                ),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
          data: (patterns) {
            _populate(patterns);
            final hasOther =
                _selectedKeys.contains(GenogramFamilyPatternOption.other.key);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ao olhar para sua família, você percebe que alguns temas se repetem?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Registro visível apenas para o psicólogo. Use como apoio à formulação, sem expor automaticamente ao paciente.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: GenogramFamilyPatternOption.values.map((option) {
                    final selected = _selectedKeys.contains(option.key);
                    return FilterChip(
                      selected: selected,
                      label: Text(option.label),
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            _selectedKeys.add(option.key);
                          } else {
                            _selectedKeys.remove(option.key);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                if (hasOther) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _otherController,
                    decoration: const InputDecoration(
                      labelText: 'Outro padrão percebido *',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Salvar padrões'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _save() async {
    final hasOther =
        _selectedKeys.contains(GenogramFamilyPatternOption.other.key);
    if (hasOther && _otherController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Descreva o outro padrão familiar.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(genogramRepositoryProvider).saveFamilyPatterns(
            patientId: widget.patientId,
            selectedKeys: _selectedKeys,
            otherText: _otherController.text,
          );
      ref.invalidate(genogramFamilyPatternsProvider(widget.patientId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userMessageFor(mapToAppException(e)))),
      );
      return;
    } finally {
      if (mounted) setState(() => _saving = false);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Padrões familiares salvos.')),
    );
  }
}
