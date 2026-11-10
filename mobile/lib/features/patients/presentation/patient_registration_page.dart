import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/brand_loading.dart';
import '../../profile/domain/profile_role.dart';
import '../providers/patients_providers.dart';
import 'patient_routes.dart';
import 'widgets/patient_context_header.dart';
import 'widgets/patient_registration_widgets.dart';

/// Dados cadastrais do paciente: todos os dados pessoais (com botão de copiar),
/// "Editar paciente" e a situação do acompanhamento (inativar ou reativar o
/// acesso). Fica atrás de um botão da ficha para que ela abra nos módulos
/// clínicos.
class PatientRegistrationPage extends ConsumerWidget {
  const PatientRegistrationPage({
    super.key,
    required this.patientId,
    required this.role,
  });

  final String patientId;
  final ProfileRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPatient = ref.watch(patientDetailProvider(patientId));
    final isWide = AppBreakpoints.isWide(context);

    return AppCanopyScaffold(
      body: asyncPatient.when(
        loading: () => const Center(child: BrandLoader()),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Não foi possível carregar o paciente.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(patientDetailProvider(patientId)),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
        data: (patient) {
          if (patient == null) {
            return const Center(child: Text('Paciente não encontrado.'));
          }
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: PatientContextHeader(
                  patientId: patient.id,
                  pageTitle: 'DADOS CADASTRAIS',
                  role: role,
                  actions: [
                    PatientHeaderActionBtn(
                      label: 'Editar paciente',
                      icon: Icons.edit_outlined,
                      solid: true,
                      onTap: () => context.push(
                        PatientRoutes.edit(role, patient.id),
                        extra: patient,
                      ),
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: isWide
                    ? const EdgeInsets.fromLTRB(AppSpacing.xxxl, AppSpacing.md,
                        AppSpacing.xxxl, AppSpacing.md)
                    : const EdgeInsets.all(AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    PatientRegistrationDataCard(patient: patient),
                    const SizedBox(height: AppSpacing.md),
                    PatientLifecycleCard(patient: patient),
                    const SizedBox(height: AppSpacing.md),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
