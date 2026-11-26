import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_motion.dart';
import '../../../../shared/widgets/async_state_body.dart';
import '../../../../shared/widgets/desktop_admin/desktop_admin_kit.dart';
import '../../../../shared/widgets/desktop_psychologist/desktop_psychologist_shell.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../profile/domain/profile_role.dart';
import '../../../profile/presentation/widgets/user_avatar.dart';
import '../../domain/patient.dart';
import '../../domain/patient_attention.dart';
import '../../domain/patient_data_completion.dart';
import 'patient_list_tile.dart';

/// Uma linha da tabela de pacientes (mesmos dados do cartão do celular).
class DesktopPatientRow {
  const DesktopPatientRow({
    required this.patient,
    required this.attention,
    required this.checkinMissingDays,
    required this.completion,
    required this.onOpen,
    required this.onQuickAction,
  });

  final Patient patient;
  final PatientAttention? attention;
  final int? checkinMissingDays;
  final PatientDataCompletion? completion;
  final VoidCallback onOpen;

  /// Ação direta do motivo (liberar resultado, abrir avaliação).
  final VoidCallback? onQuickAction;
}

/// Pacientes da psicóloga a partir de 768 px: barra superior com as ações,
/// filtros e busca, e a carteira em tabela.
class DesktopPatientsView extends StatelessWidget {
  const DesktopPatientsView({
    super.key,
    required this.totalActive,
    required this.totalAll,
    required this.alertCount,
    required this.showActions,
    required this.onInvite,
    required this.onNew,
    required this.onRefresh,
    required this.filters,
    required this.filterIndex,
    required this.onFilter,
    required this.sorts,
    required this.sortIndex,
    required this.onSort,
    required this.searchController,
    required this.onSearch,
    required this.onClearSearch,
    required this.onClearAll,
    required this.loading,
    required this.failed,
    required this.hasPatients,
    required this.rows,
  });

  final int totalActive;
  final int totalAll;
  final int alertCount;
  final bool showActions;
  final VoidCallback onInvite;
  final VoidCallback onNew;
  final VoidCallback onRefresh;

  final List<String> filters;
  final int filterIndex;
  final ValueChanged<int> onFilter;
  final List<(IconData, String)> sorts;
  final int sortIndex;
  final ValueChanged<int> onSort;

  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final VoidCallback onClearSearch;

  /// "Limpar busca e filtros" (nenhum resultado).
  final VoidCallback onClearAll;

  final bool loading;
  final bool failed;

  /// Há pacientes na carteira (mesmo que nenhum passe nos filtros).
  final bool hasPatients;
  final List<DesktopPatientRow> rows;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    final big = m.size == DesktopAdminSize.desktop;

    return DesktopPsychologistFrame(
      title: 'Pacientes',
      titleTrailing: alertCount > 0
          ? DaTag(
              '$alertCount alertas',
              bg: t.dark ? const Color(0xFF4A3410) : const Color(0xFFFEF3C7),
              fg: t.dark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
            )
          : null,
      subtitle: '$totalActive ativos · $totalAll total',
      actions: [
        if (showActions) ...[
          DaButton(
            label: 'Convidar',
            icon: Icons.mark_email_unread_outlined,
            onPressed: onInvite,
          ),
          DaButton(
            label: 'Novo paciente',
            icon: Icons.person_add_outlined,
            kind: DaButtonKind.primary,
            onPressed: onNew,
          ),
        ],
        DaButton(
          icon: Icons.refresh,
          tooltip: 'Atualizar',
          kind: DaButtonKind.ghost,
          onPressed: onRefresh,
        ),
      ],
      body: failed
          ? ErrorStatePanel(
              message: 'Não conseguimos carregar. Pode tentar de novo?',
              onRetry: onRefresh,
            )
          : Padding(
              padding: EdgeInsets.fromLTRB(
                  m.pad, big ? 24 : 18, m.pad, big ? 32 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _tools(context),
                  const SizedBox(height: 14),
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

  Widget _tools(BuildContext context) {
    final segments = [
      DaSegmented<int>(
        value: filterIndex,
        items: [
          for (var i = 0; i < filters.length; i++)
            DaSegment(i, filters[i]),
        ],
        onChanged: onFilter,
      ),
      DaSegmented<int>(
        value: sortIndex,
        items: [
          for (var i = 0; i < sorts.length; i++)
            DaSegment(i, sorts[i].$2, icon: sorts[i].$1),
        ],
        onChanged: onSort,
      ),
    ];
    final search = DaSearchField(
      hint: 'Buscar por nome, e-mail ou psicólogo',
      controller: searchController,
      onChanged: onSearch,
      onClear: onClearSearch,
    );
    return LayoutBuilder(
      builder: (context, box) {
        // Uma linha quando cabe; no tablet a busca vai para a de baixo.
        if (box.maxWidth >= 920) {
          return Row(
            children: [
              segments[0],
              const SizedBox(width: 10),
              segments[1],
              const SizedBox(width: 10),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: search,
                  ),
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(spacing: 10, runSpacing: 10, children: segments),
            const SizedBox(height: 10),
            search,
          ],
        );
      },
    );
  }

  Widget _table(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    return LayoutBuilder(
      builder: (context, box) {
        final cols = _Columns.of(box.maxWidth);
        final Widget content;
        if (loading) {
          content = ListView(
            shrinkWrap: true,
            children: [
              for (var i = 0; i < 5; i++) _SkeletonRow(cols: cols, m: m),
            ],
          );
        } else if (!hasPatients) {
          content = const _Empty(
            icon: Icons.people_outline,
            title: 'Nenhum paciente',
            lines: [
              'Nenhum paciente encontrado.',
              'Use Novo paciente para cadastrar o primeiro.',
            ],
          );
        } else if (rows.isEmpty) {
          content = _Empty(
            icon: Icons.search_off_outlined,
            title: 'Nenhum resultado',
            lines: const ['Nenhum paciente corresponde à busca ou aos filtros.'],
            action: DaButton(
              label: 'Limpar busca e filtros',
              icon: Icons.filter_alt_off_outlined,
              onPressed: onClearAll,
            ),
          );
        } else {
          content = ListView.builder(
            shrinkWrap: true,
            itemCount: rows.length,
            itemBuilder: (context, i) => _Row(
              key: ValueKey(rows[i].patient.id),
              row: rows[i],
              cols: cols,
              m: m,
              last: i == rows.length - 1,
            ),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: t.rz,
            borderRadius: BorderRadius.circular(12),
          ),
          // Por cima, para os cantos não ficarem cobertos pelo cabeçalho.
          foregroundDecoration: BoxDecoration(
            border: Border.all(color: t.bd2),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(cols: cols),
              Flexible(child: content),
            ],
          ),
        );
      },
    );
  }
}

/// Larguras das colunas pela largura da tabela (a de nome ocupa o resto).
class _Columns {
  const _Columns(this.status, this.checkIn, this.week, this.ring, this.end,
      this.tight);

  final double status;
  final double checkIn;
  final double week;
  final double ring;
  final double end;

  /// Muito estreita (tablet em pé): some a seta onde já há botão.
  final bool tight;

  static _Columns of(double width) {
    if (width >= 900) {
      return const _Columns(110, 210, 140, 90, 240, false);
    }
    if (width >= 700) {
      return const _Columns(82, 120, 104, 52, 140, false);
    }
    return const _Columns(78, 106, 100, 48, 112, true);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.cols});

  final _Columns cols;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    Widget h(String s, {double? w}) {
      final text = Text(s,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: daText(context, t,
              size: 12, weight: FontWeight.w500, color: t.tx3));
      return w == null ? Expanded(child: text) : SizedBox(width: w, child: text);
    }

    return Container(
      height: 38,
      padding: const EdgeInsets.only(left: 18, right: 10),
      decoration: BoxDecoration(
        color: t.side,
        border: Border(bottom: BorderSide(color: t.bd2)),
      ),
      child: Row(
        children: [
          h('Paciente'),
          h('Status', w: cols.status),
          h('Último check-in', w: cols.checkIn),
          h('Semana', w: cols.week),
          h('Adesão', w: cols.ring),
          SizedBox(width: cols.end),
        ],
      ),
    );
  }
}

/// Cores de texto e fundo por motivo de atenção.
({Color fg, Color bg, Color border}) _tones(
    DesktopAdminTokens t, PatientAttentionKind kind) {
  switch (kind) {
    case PatientAttentionKind.noCheckin:
      return t.dark
          ? (
              fg: const Color(0xFFFCA5A5),
              bg: const Color(0xFF4A1D1D),
              border: const Color(0xFF7F2D2D)
            )
          : (
              fg: const Color(0xFFB91C1C),
              bg: const Color(0xFFFEE2E2),
              border: const Color(0xFFFECACA)
            );
    case PatientAttentionKind.pendingRelease:
      return t.dark
          ? (
              fg: const Color(0xFF7DD3FC),
              bg: const Color(0xFF12384F),
              border: const Color(0xFF1E5A7A)
            )
          : (
              fg: const Color(0xFF075985),
              bg: const Color(0xFFE0F2FE),
              border: const Color(0xFFBAE6FD)
            );
    case PatientAttentionKind.emptyData:
    case PatientAttentionKind.fewCheckins:
      return t.dark
          ? (
              fg: const Color(0xFFFCD34D),
              bg: const Color(0xFF4A3410),
              border: const Color(0xFF7A5718)
            )
          : (
              fg: const Color(0xFF92400E),
              bg: const Color(0xFFFEF3C7),
              border: const Color(0xFFFDE68A)
            );
  }
}

class _Row extends StatefulWidget {
  const _Row({
    super.key,
    required this.row,
    required this.cols,
    required this.m,
    required this.last,
  });

  final DesktopPatientRow row;
  final _Columns cols;
  final DesktopAdminMetrics m;
  final bool last;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hover = false;
  bool _focus = false;

  /// Texto da coluna "Último check-in"; nulo = traço (o motivo, quando é de
  /// outra natureza, fica na ponta da linha junto do botão).
  String? get _checkIn {
    final row = widget.row;
    final a = row.attention;
    if (a != null) {
      if (a.kind == PatientAttentionKind.noCheckin ||
          a.kind == PatientAttentionKind.fewCheckins) {
        return a.label;
      }
      if (row.checkinMissingDays == null &&
          row.patient.accessStatus != PatientAccessStatus.noAppAccess) {
        return null;
      }
    }
    return patientCheckInLabel(row.patient, row.checkinMissingDays);
  }

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final cols = widget.cols;
    final row = widget.row;
    final p = row.patient;
    final a = row.attention;
    final active = p.isActive;
    final accent = a != null ? attentionColor(a.kind) : AppColors.success;
    final email = p.email;
    final checkIn = _checkIn;
    final late = a?.kind == PatientAttentionKind.noCheckin ||
        a?.kind == PatientAttentionKind.fewCheckins;
    final quick = row.onQuickAction;

    final name = Row(
      children: [
        _Avatar(patient: p, attention: a),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(p.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: daText(context, t,
                      weight: FontWeight.w600,
                      color: active ? t.tx : t.tx2)),
              if (email != null && email.isNotEmpty)
                Text(email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: daText(context, t, size: 12, color: t.tx3)),
            ],
          ),
        ),
        const SizedBox(width: 8),
      ],
    );

    final status = a != null
        ? DaTag('Atenção', bg: _tones(t, a.kind).bg, fg: _tones(t, a.kind).fg)
        : active
            ? DaTag.ok(context, 'Em dia')
            : const DaTag('Inativo');

    Widget dash() => Text('—', style: daText(context, t, color: t.tx3));
    Widget cell(double width, Widget child) => SizedBox(
          width: width,
          child: Align(alignment: Alignment.centerLeft, child: child),
        );

    return Semantics(
      button: true,
      child: InkWell(
        onTap: row.onOpen,
        mouseCursor: SystemMouseCursors.click,
        hoverColor: Colors.transparent,
        onHover: (v) => setState(() => _hover = v),
        onFocusChange: (v) => setState(() => _focus = v),
        child: AnimatedContainer(
          duration: daHoverDuration(context),
          constraints: BoxConstraints(minHeight: widget.m.row),
          padding: const EdgeInsets.fromLTRB(18, 6, 10, 6),
          decoration: BoxDecoration(
            color: _hover || _focus ? t.hov : daClear(t.hov),
            border: Border(
              bottom: BorderSide(color: widget.last ? daClear(t.bd) : t.bd),
            ),
          ),
          child: Row(
            children: [
              Expanded(child: name),
              cell(cols.status, status),
              cell(
                cols.checkIn,
                checkIn == null
                    ? dash()
                    : Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(checkIn,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: daText(context, t,
                                weight:
                                    late ? FontWeight.w500 : FontWeight.w400,
                                color:
                                    late ? _tones(t, a!.kind).fg : t.tx)),
                      ),
              ),
              cell(cols.week,
                  active ? _Week(
                      filled: patientFilledDays(p, row.checkinMissingDays),
                      color: accent) : dash()),
              cell(
                cols.ring,
                row.completion != null && active
                    ? _Ring(completion: row.completion!)
                    : dash(),
              ),
              SizedBox(
                width: cols.end,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (a != null && quick != null) ...[
                      Flexible(
                        child: Text(a.label,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: daText(context, t,
                                size: cols.tight ? 11 : 12.5,
                                weight: FontWeight.w500,
                                color: _tones(t, a.kind).fg)),
                      ),
                      const SizedBox(width: 8),
                      _QuickButton(kind: a.kind, onPressed: quick),
                    ],
                    if (quick == null || !cols.tight) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 16, color: t.tx3),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Avatar com o selo do motivo de atenção.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.patient, required this.attention});

  final Patient patient;
  final PatientAttention? attention;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final a = attention;
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Opacity(
            opacity: patient.isActive ? 1 : 0.45,
            child: UserAvatar.parts(
              fullName: patient.fullName,
              initials: patientInitials(patient.fullName),
              role: ProfileRole.patient,
              avatarType: patient.avatarType,
              photoUrl: patient.photoUrl,
              avatarConfig: patient.avatarConfig,
              size: 36,
            ),
          ),
          if (a != null)
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  color: attentionColor(a.kind),
                  shape: BoxShape.circle,
                  border: Border.all(color: t.rz, width: 2),
                ),
                child: Icon(attentionStateIcon(a.kind),
                    size: 9, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

/// Semana: 7 pontos com as letras S T Q Q S S D.
class _Week extends StatelessWidget {
  const _Week({required this.filled, required this.color});

  final int filled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 7; i++)
          SizedBox(
            width: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < filled ? color : t.hov2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(patientWeekLabels[i],
                    style: daText(context, t,
                            size: 8.5,
                            weight: FontWeight.w600,
                            color: i < filled
                                ? color
                                : t.tx3.withValues(alpha: 0.45))
                        .copyWith(height: 1)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Anel de preenchimento que se desenha, com a porcentagem no centro.
class _Ring extends StatelessWidget {
  const _Ring({required this.completion});

  final PatientDataCompletion completion;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final color = completionColor(completion);
    return Tooltip(
      message: completionTooltip(completion),
      child: SizedBox(
        width: 34,
        height: 34,
        child: Stack(
          fit: StackFit.expand,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: completion.fraction),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => CircularProgressIndicator(
                value: value,
                strokeWidth: 3,
                strokeCap: StrokeCap.round,
                color: color,
                backgroundColor: t.hov2,
              ),
            ),
            Center(
              child: Text('${completion.percent}',
                  style: daText(context, t,
                      size: 11, weight: FontWeight.w600, color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botão do motivo (os mesmos ícone e dica do celular).
class _QuickButton extends StatelessWidget {
  const _QuickButton({required this.kind, required this.onPressed});

  final PatientAttentionKind kind;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final tones = _tones(t, kind);
    return Tooltip(
      message: actionLabelFor(kind),
      waitDuration: const Duration(milliseconds: 400),
      child: Semantics(
        button: true,
        label: actionLabelFor(kind),
        child: Material(
          color: tones.bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: tones.border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            mouseCursor: SystemMouseCursors.click,
            onTap: onPressed,
            child: SizedBox(
              width: 32,
              height: 32,
              child:
                  Icon(attentionActionIcon(kind), size: 16, color: tones.fg),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.cols, required this.m});

  final _Columns cols;
  final DesktopAdminMetrics m;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    Widget bar(double width, double column) => SizedBox(
          width: column,
          child: Align(
            alignment: Alignment.centerLeft,
            child: LoadingSkeleton(height: 10, width: width),
          ),
        );
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
                LoadingSkeleton(
                  height: 36,
                  width: 36,
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                ),
                SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingSkeleton(height: 10, width: 130),
                    SizedBox(height: 8),
                    LoadingSkeleton(height: 10, width: 100),
                  ],
                ),
              ],
            ),
          ),
          bar(54, cols.status),
          bar(cols.checkIn * 0.7, cols.checkIn),
          bar(cols.week * 0.8, cols.week),
          SizedBox(
            width: cols.ring,
            child: const Align(
              alignment: Alignment.centerLeft,
              child: LoadingSkeleton(
                height: 34,
                width: 34,
                borderRadius: BorderRadius.all(Radius.circular(17)),
              ),
            ),
          ),
          SizedBox(width: cols.end),
        ],
      ),
    );
  }
}

/// Carteira vazia ou busca sem resultado, dentro do painel.
class _Empty extends StatelessWidget {
  const _Empty({
    required this.icon,
    required this.title,
    required this.lines,
    this.action,
  });

  final IconData icon;
  final String title;
  final List<String> lines;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    return SingleChildScrollView(
      child: Container(
        constraints: const BoxConstraints(minHeight: 300),
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: t.bd2),
              ),
              child: Icon(icon, size: 24, color: t.tq),
            ),
            const SizedBox(height: 14),
            Text(title,
                style: daText(context, t, size: 15, weight: FontWeight.w600)),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(line,
                    textAlign: TextAlign.center,
                    style: daText(context, t, color: t.tx2)),
              ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
