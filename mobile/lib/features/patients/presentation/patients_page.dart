import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../auth/providers/auth_providers.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/patient.dart';
import '../providers/patients_providers.dart';
import 'patient_routes.dart';
import 'widgets/patient_list_tile.dart';

class PatientsPage extends ConsumerStatefulWidget {
  const PatientsPage({super.key, required this.role});

  final ProfileRole role;

  @override
  ConsumerState<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends ConsumerState<PatientsPage> {
  String _query = '';
  _PatientFilter _filter = _PatientFilter.active;
  final _searchController = SearchController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(patientsListProvider);
    final profile = ref.watch(authControllerProvider).valueOrNull;

    return AppScaffold(
      title: 'Pacientes',
      useResponsivePadding: true,
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () => ref.read(patientsListProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: AsyncStateBody<List<Patient>>(
        asyncValue: listState,
        onRetry: () => ref.read(patientsListProvider.notifier).refresh(),
        emptyMessage: 'Nenhum paciente encontrado.\n'
            'Toque em + para cadastrar o primeiro.',
        dataBuilder: (patients) {
          final normalized = _query.trim().toLowerCase();
          final searched = normalized.isEmpty
              ? patients
              : patients.where((patient) {
                  return patient.fullName.toLowerCase().contains(normalized) ||
                      (patient.email?.toLowerCase().contains(normalized) ??
                          false) ||
                      (patient.responsiblePsychologistName
                              ?.toLowerCase()
                              .contains(normalized) ??
                          false);
                }).toList();
          final filtered = searched.where((patient) {
            return switch (_filter) {
              _PatientFilter.all => true,
              _PatientFilter.active => patient.isActive,
              _PatientFilter.inactive => !patient.isActive,
            };
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: AppPageHeader(
                  icon: Icons.people_outline,
                  title: 'Pacientes',
                  subtitle:
                      'Gerencie a carteira clínica, convites e status de acompanhamento.',
                  metadata: [
                    StatusChip(
                      label: '${filtered.length} na lista',
                      tone: AppStatusTone.info,
                      icon: Icons.filter_list,
                    ),
                    StatusChip(
                      label:
                          '${patients.where((p) => p.isActive).length} ativos',
                      tone: AppStatusTone.success,
                      icon: Icons.check_circle_outline,
                    ),
                  ],
                  primaryAction: profile != null && widget.role.isStaff
                      ? FilledButton.icon(
                          onPressed: () =>
                              context.push(PatientRoutes.create(widget.role)),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Novo paciente'),
                        )
                      : null,
                  secondaryAction: profile != null && widget.role.isStaff
                      ? OutlinedButton.icon(
                          onPressed: () => context.push(
                            PatientRoutes.invitationCreate(widget.role),
                          ),
                          icon: const Icon(Icons.mark_email_unread_outlined),
                          label: const Text('Convidar'),
                        )
                      : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Column(
                  children: [
                    SearchBar(
                      controller: _searchController,
                      hintText: 'Buscar por nome, e-mail ou psicólogo',
                      leading: const Icon(Icons.search),
                      trailing: [
                        if (_query.isNotEmpty)
                          IconButton(
                            tooltip: 'Limpar busca',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close),
                          ),
                      ],
                      onChanged: (value) => setState(() => _query = value),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: _PatientFilter.values.map((filter) {
                          return FilterChip(
                            selected: _filter == filter,
                            label: Text(filter.label),
                            onSelected: (_) => setState(() => _filter = filter),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: AppEmptyState(
                          icon: Icons.search_off_outlined,
                          title: 'Nenhum resultado',
                          message:
                              'Nenhum paciente corresponde à busca ou aos filtros.',
                          action: TextButton.icon(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _query = '';
                                _filter = _PatientFilter.all;
                              });
                            },
                            icon: const Icon(Icons.filter_alt_off_outlined),
                            label: const Text('Limpar busca e filtros'),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.read(patientsListProvider.notifier).refresh(),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final patient = filtered[index];
                            return MotionReveal(
                              delay: staggerDelay(index),
                              child: PatientListTile(
                                patient: patient,
                                onTap: () => context.push(
                                  PatientRoutes.detail(
                                    widget.role,
                                    patient.id,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

extension on ProfileRole {
  bool get isStaff => this == ProfileRole.psychologist;
}

enum _PatientFilter { active, inactive, all }

extension on _PatientFilter {
  String get label => switch (this) {
        _PatientFilter.active => 'Ativos',
        _PatientFilter.inactive => 'Inativos',
        _PatientFilter.all => 'Todos',
      };
}
