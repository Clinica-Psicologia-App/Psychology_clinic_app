import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../genogram/presentation/widgets/motor_genogram_diagram.dart';
import '../../../initial_assessment/domain/life_area.dart';
import '../../../initial_assessment/presentation/widgets/life_area_wheel_chart.dart';
import '../../../profile/domain/avatar_type.dart';
import '../../../profile/domain/profile_role.dart';
import '../../../profile/presentation/widgets/user_avatar.dart';
import '../../domain/patient_infographic_data.dart';

/// Pôster/infográfico do paciente — layout de revista em 2 colunas, pensado
/// para exportar em imagem e PDF (largura fixa, sem rolagem interna).
///
/// Renderiza apenas o [PatientInfographicData]; todo o conteúdo vem do builder.
/// A ordem das seções segue a do preenchimento do caso: demandas, contexto de
/// vida, personalidade, história, genograma, esquemas, apego, modos, recursos
/// saudáveis e plano terapêutico. Seção sem dados aparece como "a preencher".
class PatientInfographicPoster extends StatelessWidget {
  const PatientInfographicPoster({
    super.key,
    required this.data,
    this.width = 1000,
  });

  final PatientInfographicData data;
  final double width;

  static const _bg = Color(0xFFFBF8F3);
  static const _gap = 20.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: _bg,
      padding: const EdgeInsets.all(28),
      child: DefaultTextStyle.merge(
        style:
            const TextStyle(color: AppColors.navy, fontSize: 13, height: 1.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopBar(generatedOn: data.generatedOn),
            const SizedBox(height: 14),
            _Header(data: data),
            const SizedBox(height: _gap),
            _row(_demandsCard(), _lifeWheelCard()),
            const SizedBox(height: _gap),
            _personalityCard(),
            const SizedBox(height: _gap),
            _row(_timelineCard(), _genogramCard()),
            const SizedBox(height: _gap),
            _row(_schemasCard(), _attachmentCard()),
            const SizedBox(height: _gap),
            _row(_modesCard(), _resourcesCard()),
            const SizedBox(height: _gap),
            _planCard(),
            if (data.closingLine != null) ...[
              const SizedBox(height: _gap),
              _closing(data.closingLine!),
            ],
            if (data.generatedOn != null) ...[
              const SizedBox(height: 12),
              Text(
                'Gerado em ${_formatDate(data.generatedOn!)} · material de apoio, '
                'sob revisão do profissional',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  /// Duas seções lado a lado, com a mesma altura.
  Widget _row(Widget left, Widget right) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: _gap),
          Expanded(child: right),
        ],
      ),
    );
  }

  // ── Seções ───────────────────────────────────────────────────────────────

  Widget _demandsCard() {
    const accent = AppColors.blue;
    if (!data.hasDemands) {
      return const _GhostCard(
        title: 'DEMANDAS TERAPÊUTICAS',
        accent: accent,
        hint: 'A preencher em Conhecer › Demandas Terapêuticas',
      );
    }
    return _SectionCard(
      title: 'DEMANDAS TERAPÊUTICAS',
      accent: accent,
      icon: Icons.record_voice_over_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((data.reasonsInitial ?? '').trim().isNotEmpty)
            _quote('Inicialmente', data.reasonsInitial!.trim(), accent),
          if ((data.reasonsCurrent ?? '').trim().isNotEmpty)
            _quote('Atualmente', data.reasonsCurrent!.trim(), accent),
          if (data.demands.isNotEmpty) ...[
            if (data.hasReasons) const SizedBox(height: 4),
            _items(data.demands, accent),
          ],
        ],
      ),
    );
  }

  Widget _quote(String label, String text, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: accent)),
          const SizedBox(height: 2),
          Text(
            '“$text”',
            maxLines: 7,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontStyle: FontStyle.italic, color: AppColors.navy),
          ),
        ],
      ),
    );
  }

  Widget _lifeWheelCard() {
    const accent = AppColors.cyan;
    if (!data.hasLifeWheel) {
      return const _GhostCard(
        title: 'CONTEXTO DE VIDA ATUAL',
        accent: accent,
        hint: 'A preencher em Conhecer › Contexto de Vida',
      );
    }
    final Map<LifeArea, int?> scores = {
      for (final e in data.lifeWheel.entries) e.key: e.value,
    };
    return _SectionCard(
      title: 'CONTEXTO DE VIDA ATUAL',
      subtitle: 'Roda da Vida — satisfação de 1 a 10',
      accent: accent,
      icon: Icons.donut_large_outlined,
      child: LifeAreaWheelChart(scores: scores),
    );
  }

  Widget _personalityCard() {
    const accent = AppColors.purple;
    if (!data.hasPersonality) {
      return const _GhostCard(
        title: 'PERSONALIDADE · BIG FIVE',
        accent: accent,
        hint: 'A preencher em Avaliar › Personalidade',
      );
    }
    return _SectionCard(
      title: 'PERSONALIDADE · BIG FIVE',
      accent: accent,
      icon: Icons.psychology_alt_outlined,
      child: _personality(data.personality),
    );
  }

  Widget _timelineCard() {
    if (!data.hasTimeline) {
      return const _GhostCard(
        title: 'HISTÓRIA DE VIDA · LINHA DO TEMPO',
        accent: AppColors.cyan,
        hint: 'A preencher em Conhecer › Linha do Tempo',
      );
    }
    return _TimelineBlock(entries: data.timeline);
  }

  Widget _genogramCard() {
    const accent = AppColors.turquoise;
    if (!data.hasGenogram) {
      return const _GhostCard(
        title: 'GENOGRAMA · VÍNCULOS FAMILIARES',
        accent: accent,
        hint: 'A preencher em Conhecer › Genograma',
      );
    }
    final genogram = data.genogram;
    final canDraw =
        genogram != null && MotorGenogramDiagram.hasStructure(genogram);
    return _SectionCard(
      title: 'GENOGRAMA · VÍNCULOS FAMILIARES',
      accent: accent,
      icon: Icons.account_tree_outlined,
      child: canDraw
          ? ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: Center(
                child: MotorGenogramDiagram(
                  data: genogram,
                  showEmotional: false,
                  interactive: false,
                ),
              ),
            )
          : _genogramChips(data.genogramMembers),
    );
  }

  Widget _schemasCard() {
    const accent = AppColors.purple;
    if (!data.hasSchemas) {
      return const _GhostCard(
        title: 'ESQUEMAS EM DESTAQUE',
        accent: accent,
        hint: 'A preencher em Avaliar › Esquemas',
      );
    }
    return _SectionCard(
      title: 'ESQUEMAS EM DESTAQUE',
      subtitle: 'Domínios ativados no perfil',
      accent: accent,
      icon: Icons.psychology_outlined,
      child: _items(data.schemas, accent),
    );
  }

  Widget _attachmentCard() {
    const accent = AppColors.blue;
    if (!data.hasAttachment) {
      return const _GhostCard(
        title: 'ESTILO DE APEGO',
        accent: accent,
        hint: 'A preencher em Avaliar › Apego',
      );
    }
    return _SectionCard(
      title: 'ESTILO DE APEGO',
      subtitle: 'Estilo principal',
      accent: accent,
      icon: Icons.link_outlined,
      child: _items([data.attachment!], accent),
    );
  }

  Widget _modesCard() {
    const accent = AppColors.turquoise;
    if (!data.hasModes && !data.hasCoping) {
      return const _GhostCard(
        title: 'MODOS E ENFRENTAMENTO',
        accent: accent,
        hint: 'A preencher em Avaliar › Esquemas (YAMI e YCI/YRAI)',
      );
    }
    return _SectionCard(
      title: 'MODOS E ENFRENTAMENTO',
      accent: accent,
      icon: Icons.theater_comedy_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.hasModes) ...[
            _subLabel('Modos ativados', accent),
            _items(data.modes, accent),
          ],
          if (data.hasModes && data.hasCoping) const SizedBox(height: 14),
          if (data.hasCoping) ...[
            _subLabel('Estilos de enfrentamento', AppColors.cyan),
            _items(data.coping, AppColors.cyan),
          ],
        ],
      ),
    );
  }

  Widget _subLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text.toUpperCase(),
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: color)),
    );
  }

  Widget _resourcesCard() {
    const accent = AppColors.success;
    if (!data.hasResources) {
      return const _GhostCard(
        title: 'RECURSOS SAUDÁVEIS E POTENCIAIS',
        accent: accent,
        hint: 'A preencher em Conhecer › Recursos Saudáveis',
      );
    }
    return _SectionCard(
      title: 'RECURSOS SAUDÁVEIS E POTENCIAIS',
      accent: accent,
      icon: Icons.spa_outlined,
      child: _resourcesWrap(data.resources),
    );
  }

  Widget _planCard() {
    const accent = AppColors.moduleGoals;
    if (!data.hasPlan) {
      return const _GhostCard(
        title: 'PLANO TERAPÊUTICO',
        accent: accent,
        hint: 'A preencher em Intervir › Plano Terapêutico',
      );
    }
    return _SectionCard(
      title: 'PLANO TERAPÊUTICO',
      subtitle: 'Metas e objetivos da terapia',
      accent: accent,
      icon: Icons.flag_outlined,
      child: _items(data.plan, accent),
    );
  }

  // ── Itens (esquemas, modos, apego, demandas, plano) ──────────────────────
  Widget _items(List<InfographicItem> items, Color fallbackAccent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _itemTile(items[i], fallbackAccent),
        ],
      ],
    );
  }

  Widget _itemTile(InfographicItem item, Color fallbackAccent) {
    final accent = item.accent ?? fallbackAccent;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _iconBadge(item.icon, accent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(item.title,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: accent,
                            fontSize: 13)),
                  ),
                  if (item.badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(item.badge!,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: accent,
                              fontSize: 11)),
                    ),
                  ],
                ],
              ),
              if (item.description != null) ...[
                const SizedBox(height: 2),
                Text(item.description!,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
              for (final b in item.bullets) ...[
                const SizedBox(height: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5, right: 6),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                            color: accent, shape: BoxShape.circle),
                      ),
                    ),
                    Expanded(
                      child: Text(b,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Personalidade (compacta: 5 colunas numa faixa) ───────────────────────
  Widget _personality(List<InfographicPersonalityDomain> domains) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < domains.length; i++) ...[
          if (i > 0) const SizedBox(width: 14),
          Expanded(child: _personalityColumn(domains[i])),
        ],
      ],
    );
  }

  Widget _personalityColumn(InfographicPersonalityDomain d) {
    final accent = d.accent ?? AppColors.purple;
    final detail = [
      if (d.classification != null) d.classification!,
      if (d.score > 0) d.score.toStringAsFixed(0),
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(d.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontWeight: FontWeight.w700, color: accent, fontSize: 12)),
        if (detail.isNotEmpty)
          Text(detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(color: AppColors.textMuted, fontSize: 10.5)),
        const SizedBox(height: 6),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: d.fraction,
            child: Container(
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Recursos (chips) ─────────────────────────────────────────────────────
  Widget _resourcesWrap(List<InfographicItem> resources) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final r in resources)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceTintTurquoise,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(r.icon, size: 15, color: AppColors.success),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(r.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: AppColors.navy)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Genograma (alternativa em chips, sem estrutura para desenhar) ────────
  Widget _genogramChips(List<InfographicGenogramMember> members) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final m in members)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceTintTurquoise,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  m.isDeceased
                      ? Icons.person_off_outlined
                      : Icons.person_outline,
                  size: 15,
                  color: AppColors.cyan,
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      m.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppColors.navy),
                    ),
                    if (m.relationship != null)
                      Text(
                        m.relationship!,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textMuted),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _closing(String line) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceTintPurple,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite, size: 18, color: AppColors.purple),
          const SizedBox(width: 10),
          Expanded(
            child: Text(line,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: AppColors.navy,
                    fontWeight: FontWeight.w500)),
          ),
          const Icon(Icons.favorite, size: 18, color: AppColors.purple),
        ],
      ),
    );
  }

  static Widget _iconBadge(IconData icon, Color accent) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: accent),
    );
  }
}

// ── Faixa superior com a logo ───────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({required this.generatedOn});

  final DateTime? generatedOn;

  @override
  Widget build(BuildContext context) {
    final date = generatedOn == null
        ? null
        : PatientInfographicPoster._formatDate(generatedOn!);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          AppBrandingAssets.logoPrincipal,
          height: 84,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text(
            'EsquemaCore',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.navy),
          ),
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('INFOGRÁFICO · SÍNTESE CLÍNICA',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textMuted)),
            if (date != null)
              Text(date,
                  style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.8,
                      color: AppColors.textMuted)),
          ],
        ),
      ],
    );
  }
}

// ── Placeholder de seção ainda não preenchida ("bloco em branco") ───────────
class _GhostCard extends StatelessWidget {
  const _GhostCard({
    required this.title,
    required this.accent,
    this.hint = 'A preencher',
  });

  final String title;
  final Color accent;
  final String hint;

  Widget _skeletonBar(double widthFactor) => FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: widthFactor,
        child: Container(
          height: 10,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.navy.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRRectPainter(
        color: accent.withValues(alpha: 0.45),
        radius: 16,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.more_horiz,
                      size: 16, color: accent.withValues(alpha: 0.8)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                          color: accent.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.4)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _skeletonBar(0.95),
            _skeletonBar(0.75),
            _skeletonBar(0.55),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.hourglass_empty,
                    size: 13, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    hint,
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Borda tracejada arredondada (aparência de "campo a preencher").
class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color, this.radius = 16});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const dash = 6.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final len =
            distance + dash < metric.length ? dash : metric.length - distance;
        canvas.drawPath(metric.extractPath(distance, distance + len), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}

// ── Cabeçalho ────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.data});

  final PatientInfographicData data;

  @override
  Widget build(BuildContext context) {
    final h = data.header;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderAvatar(header: h),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.name,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 18,
                  runSpacing: 8,
                  children: [
                    for (final f in h.facts)
                      SizedBox(
                        width: 200,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(f.icon, size: 16, color: AppColors.turquoise),
                            const SizedBox(width: 6),
                            Expanded(child: Text(f.text)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Avatar do cabeçalho ─────────────────────────────────────────────────────
class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({required this.header});

  final InfographicHeader header;

  static const _size = 92.0;

  @override
  Widget build(BuildContext context) {
    final hasReal = header.avatarType == AvatarType.photo ||
        header.avatarType == AvatarType.custom;

    if (hasReal) {
      // Foto ou avatar geométrico do paciente (degrada para iniciais sozinho).
      return UserAvatar.parts(
        fullName: header.name,
        initials: header.avatarInitials ?? '—',
        role: ProfileRole.patient,
        avatarType: header.avatarType,
        photoUrl: header.photoUrl,
        avatarConfig: header.avatarConfig,
        size: _size,
      );
    }

    // Sem foto/avatar: círculo com gradiente + iniciais.
    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.turquoise, AppColors.cyan],
        ),
      ),
      child: Text(
        header.avatarInitials ?? '—',
        style: const TextStyle(
            color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800),
      ),
    );
  }
}

// ── Bloco da linha do tempo ────────────────────────────────────────────────
class _TimelineBlock extends StatelessWidget {
  const _TimelineBlock({required this.entries});

  final List<InfographicTimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'HISTÓRIA DE VIDA · LINHA DO TEMPO',
      accent: AppColors.cyan,
      icon: Icons.schedule,
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 92,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(entries[i].periodLabel,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: entries[i].accent ?? AppColors.cyan)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: entries[i].accent ?? AppColors.cyan,
                            shape: BoxShape.circle),
                        child: Icon(entries[i].icon,
                            size: 14, color: Colors.white),
                      ),
                      if (i < entries.length - 1)
                        Expanded(
                            child:
                                Container(width: 2, color: AppColors.border)),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 14),
                      child: Text(entries[i].description),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Cartão de seção com cabeçalho tonal ─────────────────────────────────────
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.accent,
    required this.child,
    this.subtitle,
    this.icon,
  });

  final String title;
  final Color accent;
  final Widget child;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: accent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: 0.6)),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 11,
                                fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}
