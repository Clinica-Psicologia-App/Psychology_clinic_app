import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/brand_loading.dart';
import '../../../shared/widgets/desktop_admin/desktop_admin_kit.dart';
import '../../../shared/widgets/desktop_admin/desktop_admin_shell.dart';
import '../../../shared/widgets/desktop_psychologist/desktop_form.dart';
import '../../../shared/widgets/desktop_psychologist/desktop_psychologist_shell.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/patient.dart';
import '../providers/patients_providers.dart';
import 'patient_routes.dart';
import 'widgets/desktop_patient_file.dart';
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
    final desktop = role == ProfileRole.psychologist &&
        inDesktopPsychologistShell(context);
    Widget plain(Widget child) =>
        desktop ? _DesktopRegistration.frame(role, null, child) : child;

    final content = asyncPatient.when(
        loading: () => plain(const Center(child: BrandLoader())),
        error: (_, __) => plain(Center(
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
        )),
        data: (patient) {
          if (patient == null) {
            return plain(
                const Center(child: Text('Paciente não encontrado.')));
          }
          if (desktop) {
            return _DesktopRegistration(patient: patient, role: role);
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
      );

    return desktop ? content : AppCanopyScaffold(body: content);
  }
}

/// Dados cadastrais em desktop: dados em 2 colunas, situação e "Editar
/// paciente" no pé.
class _DesktopRegistration extends StatelessWidget {
  const _DesktopRegistration({required this.patient, required this.role});

  final Patient patient;
  final ProfileRole role;

  static Widget frame(ProfileRole role, Patient? patient, Widget body) =>
      DesktopPsychologistFrame(
        title: 'Dados cadastrais',
        crumbs: [
          DaCrumb('Pacientes', PatientRoutes.list(role)),
          if (patient != null)
            DaCrumb(patient.fullName, PatientRoutes.detail(role, patient.id)),
        ],
        body: body,
      );

  /// Linha com valor (as vazias não ocupam lugar na grade).
  static bool _filled(Widget row) => switch (row) {
        PatientInfoRow r => (r.value ?? '').trim().isNotEmpty,
        PatientSensitiveInfoRow r => (r.value ?? '').trim().isNotEmpty,
        _ => true,
      };

  @override
  Widget build(BuildContext context) {
    final access = desktopAccessLabel(patient.accessStatus);
    final psychologist = patient.responsiblePsychologistName?.trim() ?? '';
    return frame(
      role,
      patient,
      DesktopFormBody(
        actions: [
          DaButton(
            label: 'Editar paciente',
            icon: Icons.edit_outlined,
            kind: DaButtonKind.primary,
            onPressed: () => context.push(
              PatientRoutes.edit(role, patient.id),
              extra: patient,
            ),
          ),
        ],
        children: [
          DesktopFormTags(children: [
            if (patient.isActive)
              DaTag.ok(context, 'PACIENTE ATIVO')
            else
              const DaTag('PACIENTE INATIVO'),
            if (access != null) DaTag(access),
            if (psychologist.isNotEmpty)
              DaTag(psychologist, icon: Icons.psychology_outlined),
          ]),
          const SizedBox(height: 16),
          DesktopFormCard(
            title: PatientRegistrationDataCard.title,
            subtitle: PatientRegistrationDataCard.subtitle,
            child: DesktopFormGrid(
              runSpacing: 0,
              children: [
                for (final row
                    in PatientRegistrationDataCard.rows(context, patient))
                  if (_filled(row)) row,
              ],
            ),
          ),
          const SizedBox(height: 14),
          PatientLifecycleCard(patient: patient, desktop: true),
        ],
      ),
    );
  }
}
