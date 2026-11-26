import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_motion.dart';
import '../../../../shared/widgets/async_state_body.dart';
import '../../../../shared/widgets/desktop_admin/desktop_admin_kit.dart';
import '../../../../shared/widgets/desktop_psychologist/desktop_psychologist_shell.dart';
import '../../../../shared/widgets/desktop_psychologist/desktop_table.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../domain/questionnaire.dart';
import '../../domain/reference_period.dart';
import 'questionnaire_list_tile.dart';

/// Questionários da psicóloga a partir de 768 px: o atalho de liberação e o
/// catálogo em tabela.
class DesktopPsychologistCatalog extends StatelessWidget {
  const DesktopPsychologistCatalog({
    super.key,
    required this.items,
    required this.loading,
    required this.failed,
    required this.canApply,
    required this.onRelease,
    required this.onOpen,
    required this.onRefresh,
  });

  /// Nulo enquanto carrega ou com erro.
  final List<Questionnaire>? items;
  final bool loading;
  final bool failed;

  /// Instrumento aplicável (o mesmo critério do celular); senão, cadeado.
  final bool Function(Questionnaire) canApply;
  final VoidCallback onRelease;
  final VoidCallback onOpen;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    final big = m.size == DesktopAdminSize.desktop;
    final list = items;

    return DesktopPsychologistFrame(
      title: 'Questionários',
      subtitle: 'Instrumentos clínicos',
      actions: [
        DaButton(
          icon: Icons.refresh,
          tooltip: 'Atualizar',
          kind: DaButtonKind.ghost,
          onPressed: onRefresh,
        ),
      ],
      body: failed
          ? ErrorStatePanel(
              message:
                  'Não conseguimos carregar os questionários. Tente novamente.',
              onRetry: onRefresh,
            )
          : Padding(
              padding: EdgeInsets.fromLTRB(
                  m.pad, big ? 24 : 18, m.pad, big ? 32 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!loading && list != null && list.isNotEmpty) ...[
                    MotionReveal(
                      delay: staggerDelay(0),
                      child: _Release(onTap: onRelease),
                    ),
                    const SizedBox(height: 18),
                  ],
                  DesktopTableHeading(
                    title: 'Catálogo disponível',
                    subtitle:
                        'A disponibilidade para o paciente segue esta lista e a relação clínica com você.',
                    counts: [
                      if (!loading && list != null)
                        (list.length, 'Instrumentos'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: MotionReveal(
                      delay: staggerDelay(1),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: _table(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _table(BuildContext context) {
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    final list = items;
    return LayoutBuilder(
      builder: (context, box) {
        final codeWidth = box.maxWidth < 700 ? 180.0 : 240.0;
        const endWidth = 32.0;
        final Widget content;
        if (loading) {
          content = ListView(
            shrinkWrap: true,
            children: [
              for (var i = 0; i < 4; i++)
                _SkeletonRow(m: m, codeWidth: codeWidth, endWidth: endWidth),
            ],
          );
        } else if (list == null || list.isEmpty) {
          content = const DesktopTableEmpty(
            icon: Icons.assignment_late_outlined,
            title: 'Sem questionários liberados',
            lines: [
              'Nenhum questionário liberado para você no momento.',
              'Solicite ao administrador a liberação dos instrumentos.',
            ],
          );
        } else {
          content = ListView.builder(
            shrinkWrap: true,
            itemCount: list.length,
            itemBuilder: (context, i) => _Row(
              key: ValueKey(list[i].id),
              questionnaire: list[i],
              enabled: canApply(list[i]),
              onTap: onOpen,
              codeWidth: codeWidth,
              endWidth: endWidth,
              m: m,
              last: i == list.length - 1,
            ),
          );
        }
        return DesktopTablePanel(
          header: DesktopTableHeader(
            children: [
              desktopColumnTitle(context, 'Instrumento'),
              desktopColumnTitle(context, 'Código', width: codeWidth),
              const SizedBox(width: endWidth),
            ],
          ),
          child: content,
        );
      },
    );
  }
}

/// Atalho em destaque: "Liberar para paciente".
class _Release extends StatefulWidget {
  const _Release({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_Release> createState() => _ReleaseState();
}

class _ReleaseState extends State<_Release> {
  bool _hover = false;
  bool _focus = false;

  static const _accent = Color(0xFF7B5CF6);

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final on = _hover || _focus;
    final radius = BorderRadius.circular(12);
    return Semantics(
      button: true,
      child: InkWell(
        onTap: widget.onTap,
        mouseCursor: SystemMouseCursors.click,
        hoverColor: Colors.transparent,
        borderRadius: radius,
        onHover: (v) => setState(() => _hover = v),
        onFocusChange: (v) => setState(() => _focus = v),
        child: AnimatedContainer(
          duration: daHoverDuration(context),
          padding: const EdgeInsets.fromLTRB(18, 14, 24, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                t.dark ? const Color(0xFF2F2A55) : const Color(0xFFF0EDFE),
                t.rz,
              ],
              stops: const [0, 0.6],
            ),
            border: Border.all(
              color: on
                  ? _accent
                  : t.dark
                      ? const Color(0xFF4B3F8F)
                      : const Color(0xFFC7BDFB),
            ),
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: on ? 0.16 : 0),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              const DaIconBox(Icons.fact_check_outlined,
                  color: _accent, size: 40, radius: 10),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Liberar para paciente',
                        style: daText(context, t,
                            size: 15, weight: FontWeight.w600)),
                    Text('Escolha um paciente e libere os questionários.',
                        style: daText(context, t, size: 12.5, color: t.tx2)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedSlide(
                duration: daHoverDuration(context),
                curve: Curves.easeOutCubic,
                offset: Offset(on ? 0.17 : 0, 0),
                child: const Icon(Icons.arrow_forward_rounded,
                    size: 18, color: _accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatefulWidget {
  const _Row({
    super.key,
    required this.questionnaire,
    required this.enabled,
    required this.onTap,
    required this.codeWidth,
    required this.endWidth,
    required this.m,
    required this.last,
  });

  final Questionnaire questionnaire;
  final bool enabled;
  final VoidCallback onTap;
  final double codeWidth;
  final double endWidth;
  final DesktopAdminMetrics m;
  final bool last;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final q = widget.questionnaire;
    final description = q.description?.trim() ?? '';
    final author = q.authorName?.trim() ?? '';
    final version = q.instrumentVersion?.trim() ?? '';
    final license = q.licenseNotes?.trim() ?? '';

    Widget meta(IconData icon, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: t.tx3),
            const SizedBox(width: 5),
            Flexible(
              child:
                  Text(text, style: daText(context, t, size: 12, color: t.tx2)),
            ),
          ],
        );

    final status = q.isClinicallyApproved
        ? DaTag.ok(context, q.clinicalStatus.label,
            icon: Icons.verified_outlined)
        : DaTag.az(context, q.clinicalStatus.label,
            icon: Icons.science_outlined);

    return Semantics(
      button: true,
      child: InkWell(
        onTap: widget.onTap,
        mouseCursor: SystemMouseCursors.click,
        hoverColor: Colors.transparent,
        onHover: (v) => setState(() => _hover = v),
        onFocusChange: (v) => setState(() => _focus = v),
        child: AnimatedContainer(
          duration: daHoverDuration(context),
          constraints: BoxConstraints(minHeight: widget.m.row),
          padding: const EdgeInsets.fromLTRB(18, 8, 10, 8),
          decoration: BoxDecoration(
            color: _hover || _focus ? t.hov : daClear(t.hov),
            border: Border(
              bottom: BorderSide(color: widget.last ? daClear(t.bd) : t.bd),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    DaIconBox(Icons.assignment_outlined,
                        color: widget.enabled
                            ? DesktopAdminTokens.blue
                            : AppColors.disabled),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(q.name,
                                  style: daText(context, t,
                                      weight: FontWeight.w600,
                                      color: widget.enabled ? t.tx : t.tx2)),
                              status,
                              if (q.referencePeriod !=
                                  ReferencePeriod.unspecified)
                                DaTag(
                                    questionnaireReferencePeriodLabel(
                                        q.referencePeriod),
                                    icon: Icons.schedule_outlined),
                              if (q.isParentalStyles)
                                const DaTag('Mãe e pai',
                                    icon: Icons.family_restroom_outlined),
                            ],
                          ),
                          if (description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(q.description!,
                                  style: daText(context, t,
                                      size: 12, color: t.tx3)),
                            ),
                          if (author.isNotEmpty || version.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Wrap(
                                spacing: 14,
                                children: [
                                  if (author.isNotEmpty)
                                    meta(Icons.person_outline, q.authorName!),
                                  if (version.isNotEmpty)
                                    meta(Icons.label_outline,
                                        q.instrumentVersion!),
                                ],
                              ),
                            ),
                          if (license.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(q.licenseNotes!,
                                  style: daText(context, t,
                                      size: 12,
                                      color: q.hasLicensePendingValidation
                                          ? t.err
                                          : t.tx2)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
              SizedBox(
                width: widget.codeWidth,
                child: meta(Icons.tag_outlined, q.code),
              ),
              SizedBox(
                width: widget.endWidth,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                      widget.enabled ? Icons.chevron_right : Icons.lock_outline,
                      size: 16,
                      color: t.tx3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({
    required this.m,
    required this.codeWidth,
    required this.endWidth,
  });

  final DesktopAdminMetrics m;
  final double codeWidth;
  final double endWidth;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    return Container(
      height: m.row,
      padding: const EdgeInsets.only(left: 18, right: 10),
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: t.bd))),
      child: Row(
        children: [
          const Expanded(
            child: Row(
              children: [
                LoadingSkeleton(height: 32, width: 32),
                SizedBox(width: 12),
                LoadingSkeleton(height: 10, width: 180),
              ],
            ),
          ),
          SizedBox(
            width: codeWidth,
            child: const Align(
              alignment: Alignment.centerLeft,
              child: LoadingSkeleton(height: 10, width: 60),
            ),
          ),
          SizedBox(width: endWidth),
        ],
      ),
    );
  }
}
