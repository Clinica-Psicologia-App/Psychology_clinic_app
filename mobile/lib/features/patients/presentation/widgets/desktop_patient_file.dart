import 'package:flutter/material.dart';

import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_motion.dart';
import '../../../../shared/widgets/desktop_admin/desktop_admin_kit.dart';
import '../../../../shared/widgets/desktop_admin/desktop_admin_shell.dart';
import '../../../../shared/widgets/desktop_psychologist/desktop_psychologist_shell.dart';
import '../../../profile/domain/profile_role.dart';
import '../../../profile/presentation/widgets/user_avatar.dart';
import '../../domain/patient.dart';
import '../../domain/patient_vitals.dart';
import '../patient_routes.dart';
import 'future_modules_section.dart';
import 'patient_list_tile.dart';
import 'patient_registration_widgets.dart';

/// Moldura da ficha em desktop: a trilha "Pacientes ›" leva à lista.
class DesktopPatientFileFrame extends StatelessWidget {
  const DesktopPatientFileFrame({
    super.key,
    required this.body,
    this.heading = const SizedBox.shrink(),
    this.actions = const [],
  });

  final Widget heading;
  final List<Widget> actions;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return DesktopPsychologistFrame(
      crumbs: [
        DaCrumb('Pacientes', PatientRoutes.list(ProfileRole.psychologist)),
      ],
      heading: heading,
      actions: actions,
      body: body,
    );
  }
}

/// Ficha do paciente a partir de 768 px: identidade e ações na barra, faixa de
/// resumo parada e os grupos de módulos lado a lado.
class DesktopPatientFile extends StatelessWidget {
  const DesktopPatientFile({
    super.key,
    required this.patient,
    required this.vitals,
    required this.modules,
    required this.onRegistration,
    required this.onReport,
    required this.onTour,
    required this.onInvite,
    required this.onCheckIns,
    required this.onGoals,
    required this.onQuestionnaires,
    this.reportKey,
    this.vitalsKey,
  });

  final Patient patient;

  /// Nulo (carregando ou erro) = sem o resumo, como no celular.
  final PatientVitals? vitals;
  final Widget modules;
  final VoidCallback onRegistration;
  final VoidCallback? onReport;
  final VoidCallback? onTour;

  /// Só quando o paciente ativo ainda não tem acesso ao app.
  final VoidCallback? onInvite;
  final VoidCallback? onCheckIns;
  final VoidCallback? onGoals;
  final VoidCallback? onQuestionnaires;
  final Key? reportKey;
  final Key? vitalsKey;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final m = DesktopAdminMetrics.of(width);
    // O que não cabe na barra vai para a faixa de resumo.
    final roomy = width >= 1360;
    final iconActions = width < 1200;
    final status = patient.isActive ? 'PACIENTE ATIVO' : 'PACIENTE INATIVO';
    final statusTag =
        patient.isActive ? DaTag.ok(context, status) : DaTag(status);
    // Ao lado de "PACIENTE ATIVO", o acesso ativo diz "App ativo" (só no
    // desktop); os outros estados, como no celular.
    final accessStatus = patient.accessStatus;
    final access = accessStatus == PatientAccessStatus.active
        ? 'App ativo'
        : accessStatus?.label;
    final psychologist = patient.responsiblePsychologistName?.trim() ?? '';
    // "Sem acesso ao app" só cabe ao lado da psicóloga em telas largas.
    final accessInBar = roomy &&
        access != null &&
        (width >= 1440 || accessStatus == PatientAccessStatus.active);

    final showPsychologist = roomy && psychologist.isNotEmpty;
    final name = Text(patient.fullName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: daText(context, t,
            size: m.size == DesktopAdminSize.desktop ? 18 : 16,
            weight: FontWeight.w600));

    final heading = LayoutBuilder(
      builder: (context, box) => Row(
        children: [
        UserAvatar.parts(
          fullName: patient.fullName,
          initials: patientInitials(patient.fullName),
          role: ProfileRole.patient,
          avatarType: patient.avatarType,
          photoUrl: patient.photoUrl,
          avatarConfig: patient.avatarConfig,
          size: 34,
        ),
        const SizedBox(width: 10),
        // Com a psicóloga ao lado, o nome longo não toma o espaço dela.
        if (showPsychologist)
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: box.maxWidth * 0.38),
            child: name,
          )
        else
          Flexible(child: name),
        if (!m.tablet) ...[const SizedBox(width: 8), statusTag],
        if (accessInBar) ...[
          const SizedBox(width: 6),
          DaTag(access),
        ],
        if (showPsychologist)
          Flexible(
            child: Container(
              margin: const EdgeInsets.only(left: 10),
              padding: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: t.bd2))),
              child: Text(psychologist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: daText(context, t, color: t.tx3)),
            ),
          ),
        // Com a psicóloga, o respiro do botão seguinte já separa os dois.
        if (!showPsychologist) const SizedBox(width: 12),
      ],
      ),
    );

    return DesktopPatientFileFrame(
      heading: heading,
      actions: [
        if (onTour != null)
          DaButton(
            kind: DaButtonKind.ghost,
            icon: Icons.help_outline_rounded,
            label: iconActions ? null : 'Tour',
            tooltip: iconActions ? 'Tour' : null,
            onPressed: onTour,
          ),
        KeyedSubtree(
          key: reportKey,
          child: DaButton(
            icon: Icons.picture_as_pdf_outlined,
            label: iconActions ? null : 'Relatório clínico',
            tooltip: iconActions ? 'Relatório clínico' : null,
            onPressed: onReport,
          ),
        ),
        DaButton(
          kind: DaButtonKind.primary,
          icon: Icons.badge_outlined,
          label: 'Dados cadastrais',
          onPressed: onRegistration,
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryStrip(
            patient: patient,
            vitals: vitals,
            vitalsKey: vitalsKey,
            extra: [
              if (m.tablet || (!accessInBar && access != null))
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (m.tablet) statusTag,
                    if (m.tablet && access != null) const SizedBox(width: 8),
                    if (!accessInBar && access != null) DaTag(access),
                  ],
                ),
              if (!roomy && psychologist.isNotEmpty)
                _Fact(
                  icon: Icons.psychology_outlined,
                  label: 'Psicólogo responsável',
                  value: psychologist,
                ),
            ],
            onCheckIns: onCheckIns,
            onGoals: onGoals,
            onQuestionnaires: onQuestionnaires,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(m.pad,
                  m.size == DesktopAdminSize.desktop ? 24 : 16, m.pad, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (onInvite != null) ...[
                    _InviteBanner(onInvite: onInvite!),
                    const SizedBox(height: 14),
                  ],
                  modules,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Faixa fixa: identificação à esquerda, "Resumo do paciente" à direita.
class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.patient,
    required this.vitals,
    required this.vitalsKey,
    required this.extra,
    required this.onCheckIns,
    required this.onGoals,
    required this.onQuestionnaires,
  });

  final Patient patient;
  final PatientVitals? vitals;
  final Key? vitalsKey;
  final List<Widget> extra;
  final VoidCallback? onCheckIns;
  final VoidCallback? onGoals;
  final VoidCallback? onQuestionnaires;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    final v = vitals;
    final pending = v?.pendingQuestionnaires ?? 0;
    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: EdgeInsets.symmetric(horizontal: m.pad, vertical: 10),
      decoration: BoxDecoration(
        color: t.side,
        border: Border(bottom: BorderSide(color: t.bd)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 24,
        runSpacing: 10,
        children: [
          Wrap(
            spacing: 24,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final item in patientIdentificationItems(context, patient))
                _Fact(icon: item.$1, label: item.$2, value: item.$3),
              ...extra,
            ],
          ),
          if (v != null)
            Wrap(
              key: vitalsKey,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text('Resumo do paciente',
                      style: daText(context, t,
                          size: 12, weight: FontWeight.w600, color: t.tx3)),
                ),
                _Vital(
                  icon: Icons.favorite_border,
                  accent: AppColors.turquoise,
                  label: 'Último check-in',
                  value: v.lastCheckinLabel,
                  onTap: onCheckIns,
                ),
                _Vital(
                  icon: Icons.flag_outlined,
                  accent: AppColors.purple,
                  label: 'Metas ativas',
                  value: '${v.activeGoals}',
                  onTap: onGoals,
                ),
                _Vital(
                  icon: Icons.assignment_outlined,
                  accent: AppColors.blue,
                  label: 'Questionários',
                  value: pending == 0 ? 'Em dia' : '$pending pend.',
                  highlight: pending > 0,
                  onTap: onQuestionnaires,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Um dado de identificação: ícone, rótulo e valor.
class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.cyan),
        const SizedBox(width: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: daText(context, t, size: 11.5, color: t.tx3)
                      .copyWith(height: 1.3)),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: daText(context, t, weight: FontWeight.w600)
                      .copyWith(height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Um número do resumo; leva ao módulo.
class _Vital extends StatefulWidget {
  const _Vital({
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final Color accent;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  State<_Vital> createState() => _VitalState();
}

class _VitalState extends State<_Vital> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final accent = widget.highlight ? AppColors.warning : widget.accent;
    final style = daText(context, t,
            size: 15,
            weight: FontWeight.w700,
            color: widget.highlight ? accent : t.tx)
        .copyWith(height: 1.2);
    // O número sobe até o valor, como no celular.
    final number = int.tryParse(widget.value.replaceAll(RegExp(r'\D'), ''));
    final Widget value = number != null && !widget.highlight
        ? TweenAnimationBuilder<int>(
            duration: AppAnimations.resolve(
                context, const Duration(milliseconds: 320)),
            tween: IntTween(begin: 0, end: number),
            builder: (_, n, __) => Text(
                widget.value.replaceAll(RegExp(r'\d+'), '$n'),
                style: style),
          )
        : Text(widget.value, style: style);

    return Semantics(
      button: true,
      label: '${widget.label}: ${widget.value}',
      excludeSemantics: true,
      onTap: widget.onTap,
      child: InkWell(
        onTap: widget.onTap,
        mouseCursor: SystemMouseCursors.click,
        hoverColor: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        onHover: (v) => setState(() => _hover = v),
        onFocusChange: (v) => setState(() => _focus = v),
        child: AnimatedContainer(
          duration: daHoverDuration(context),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(
            color: _hover || _focus ? t.hov2 : daClear(t.hov2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 18, color: accent),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  value,
                  Text(widget.label,
                      style: daText(context, t, size: 11.5, color: t.tx3)
                          .copyWith(height: 1.2)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InviteBanner extends StatelessWidget {
  const _InviteBanner({required this.onInvite});

  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      decoration: BoxDecoration(
        color: t.rz,
        border: Border.all(color: t.bd2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const DaIconBox(Icons.mark_email_unread_outlined,
              color: Color(0xFF00A39B), size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Convidar paciente',
                    style: daText(context, t, weight: FontWeight.w600)),
                Text(
                    'Gere um link para o paciente criar senha e concluir o primeiro acesso.',
                    style: daText(context, t, size: 12.5, color: t.tx2)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          DaButton(
            kind: DaButtonKind.ghost,
            icon: Icons.arrow_forward_rounded,
            tooltip: 'Convidar paciente',
            onPressed: onInvite,
          ),
        ],
      ),
    );
  }
}

/// Os grupos de módulos: uma coluna por grupo quando cabe; senão, um bloco por
/// grupo com os módulos em 2 colunas.
class DesktopModuleBoard extends StatelessWidget {
  const DesktopModuleBoard({super.key, required this.groups});

  final List<PatientModuleGroup> groups;

  /// Largura mínima para as colunas lado a lado.
  static const double columnsMinWidth = 900;

  @override
  Widget build(BuildContext context) {
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    final big = m.size == DesktopAdminSize.desktop;
    return LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth >= columnsMinWidth;
        final panels = [
          for (var i = 0; i < groups.length; i++)
            MotionReveal(
              delay: staggerDelay(i),
              child: _GroupPanel(group: groups[i], big: big, wide: !columns),
            ),
        ];
        if (!columns) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < panels.length; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                panels[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < panels.length; i++) ...[
              if (i > 0) SizedBox(width: big ? 16 : 10),
              Expanded(child: panels[i]),
            ],
          ],
        );
      },
    );
  }
}

class _GroupPanel extends StatelessWidget {
  const _GroupPanel({
    required this.group,
    required this.big,
    required this.wide,
  });

  final PatientModuleGroup group;
  final bool big;

  /// Bloco de largura inteira: módulos em 2 colunas.
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final modules = group.modules;
    Widget tile(PatientModuleSpec spec) =>
        _ModuleTile(spec: spec, color: group.accentColor, big: big);
    final divider = Divider(height: 1, thickness: 1, color: t.bd);

    return Container(
      decoration: BoxDecoration(
        color: t.rz,
        borderRadius: BorderRadius.circular(12),
      ),
      foregroundDecoration: BoxDecoration(
        border: Border.all(color: t.bd2),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 3, color: group.accentColor),
          Container(
            color: group.accentColor.withValues(alpha: 0.05),
            padding: EdgeInsets.fromLTRB(
                big ? 16 : 12, big ? 12 : 8, big ? 16 : 12, big ? 12 : 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(group.title,
                      style: daText(context, t,
                              size: big ? 15 : 13.5, weight: FontWeight.w600)
                          .copyWith(height: 1.3)),
                ),
                Text(group.subtitle,
                    style: daText(context, t,
                            size: big ? 12.5 : 11.5, color: t.tx2)
                        .copyWith(height: 1.35)),
              ],
            ),
          ),
          divider,
          if (!wide)
            for (var i = 0; i < modules.length; i++) ...[
              if (i > 0) divider,
              tile(modules[i]),
            ]
          else
            for (var i = 0; i < modules.length; i += 2) ...[
              if (i > 0) divider,
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: tile(modules[i])),
                    VerticalDivider(width: 1, thickness: 1, color: t.bd),
                    Expanded(
                      child: i + 1 < modules.length
                          ? tile(modules[i + 1])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }
}

class _ModuleTile extends StatefulWidget {
  const _ModuleTile({
    required this.spec,
    required this.color,
    required this.big,
  });

  final PatientModuleSpec spec;
  final Color color;
  final bool big;

  @override
  State<_ModuleTile> createState() => _ModuleTileState();
}

class _ModuleTileState extends State<_ModuleTile> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final spec = widget.spec;
    final big = widget.big;
    final enabled = spec.onTap != null;
    final active = enabled && (_hover || _focus);
    final box = big ? 36.0 : 30.0;

    return Semantics(
      button: true,
      enabled: enabled,
      child: InkWell(
        onTap: spec.onTap,
        mouseCursor:
            enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        hoverColor: Colors.transparent,
        onHover: (v) => setState(() => _hover = v),
        onFocusChange: (v) => setState(() => _focus = v),
        child: AnimatedContainer(
          duration: daHoverDuration(context),
          padding: EdgeInsets.symmetric(
              horizontal: big ? 16 : 12, vertical: big ? 14 : 9),
          decoration: BoxDecoration(color: active ? t.hov : daClear(t.hov)),
          child: Opacity(
            opacity: enabled ? 1 : 0.62,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedScale(
                  scale: active ? 1.08 : 1,
                  duration: daHoverDuration(context),
                  curve: Curves.easeOutCubic,
                  child: Container(
                    width: box,
                    height: box,
                    decoration: BoxDecoration(
                      color: enabled ? widget.color : AppColors.disabled,
                      borderRadius: BorderRadius.circular(big ? 10 : 8),
                    ),
                    child: Icon(spec.icon,
                        size: big ? 20 : 17, color: Colors.white),
                  ),
                ),
                SizedBox(width: big ? 14 : 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(spec.title,
                          style: daText(context, t, weight: FontWeight.w600)
                              .copyWith(height: 1.3)),
                      Text(spec.subtitle,
                          style: daText(context, t,
                                  size: big ? 12.5 : 11.5, color: t.tx2)
                              .copyWith(height: 1.35)),
                    ],
                  ),
                ),
                if (!enabled) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.lock_outline_rounded, size: 15, color: t.tx2),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
