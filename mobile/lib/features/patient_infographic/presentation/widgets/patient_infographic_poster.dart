import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../profile/domain/avatar_type.dart';
import '../../../profile/domain/profile_role.dart';
import '../../../profile/presentation/widgets/user_avatar.dart';
import '../../domain/patient_infographic_data.dart';

/// Pôster/infográfico do paciente — layout de revista em 2 colunas, pensado
/// para exportar em imagem e PDF (largura fixa, sem rolagem interna).
///
/// Renderiza apenas o [PatientInfographicData]; todo o conteúdo vem do builder.
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
    // Seções de fluxo (com peso ≈ altura), distribuídas para equilibrar as
    // duas colunas em vez de uma divisão fixa.
    // Cada seção padrão aparece sempre: com os dados (card real) ou como
    // placeholder pontilhado ("a preencher") — assim o pôster mostra o que
    // ainda falta em vez de deixar um vazio.
    const challengesAccent = Color(0xFFE0519A);
    final flow = <_WeightedSection>[
      data.hasTimeline
          ? _WeightedSection(
              2 + data.timeline.length,
              _TimelineBlock(entries: data.timeline),
            )
          : const _WeightedSection(
              4,
              _GhostCard(title: 'LINHA DO TEMPO', accent: AppColors.cyan),
            ),
      data.hasSchemas
          ? _WeightedSection(
              1 + data.schemas.length,
              _SectionCard(
                title: 'ESQUEMAS EM DESTAQUE',
                subtitle: 'Domínios ativados no perfil',
                accent: AppColors.purple,
                child: _items(data.schemas, AppColors.purple),
              ),
            )
          : const _WeightedSection(
              4,
              _GhostCard(
                  title: 'ESQUEMAS EM DESTAQUE', accent: AppColors.purple),
            ),
      data.hasNeeds
          ? _WeightedSection(
              1 + data.needs.length,
              _SectionCard(
                title: 'NECESSIDADES EMOCIONAIS',
                subtitle: 'e eventos de vida relacionados',
                accent: AppColors.error,
                child: _needs(data.needs),
              ),
            )
          : const _WeightedSection(
              4,
              _GhostCard(
                  title: 'NECESSIDADES EMOCIONAIS', accent: AppColors.error),
            ),
      data.hasModes
          ? _WeightedSection(
              1 + data.modes.fold<int>(0, (s, m) => s + 1 + m.bullets.length),
              _SectionCard(
                title: 'MODOS E ESTILOS DE ENFRENTAMENTO',
                accent: AppColors.turquoise,
                child: _items(data.modes, AppColors.turquoise),
              ),
            )
          : const _WeightedSection(
              4,
              _GhostCard(
                  title: 'MODOS E ESTILOS DE ENFRENTAMENTO',
                  accent: AppColors.turquoise),
            ),
      data.hasStrengths
          ? _WeightedSection(
              1 + data.strengths.length,
              _SectionCard(
                title: 'PONTOS FORTES E POTENCIAIS',
                accent: AppColors.turquoise,
                child: _items(data.strengths, AppColors.turquoise),
              ),
            )
          : const _WeightedSection(
              4,
              _GhostCard(
                  title: 'PONTOS FORTES E POTENCIAIS',
                  accent: AppColors.turquoise),
            ),
      data.hasChallenges
          ? _WeightedSection(
              1 + data.challenges.length,
              _SectionCard(
                title: 'DESAFIOS NA VIDA ADULTA',
                accent: challengesAccent,
                child: _items(data.challenges, challengesAccent),
              ),
            )
          : const _WeightedSection(
              4,
              _GhostCard(
                  title: 'DESAFIOS NA VIDA ADULTA', accent: challengesAccent),
            ),
      data.hasDirections
          ? _WeightedSection(
              1 + data.directions.length,
              _SectionCard(
                title: 'DIREÇÕES TERAPÊUTICAS',
                accent: AppColors.cyan,
                child: _items(data.directions, AppColors.cyan),
              ),
            )
          : const _WeightedSection(
              4,
              _GhostCard(
                  title: 'DIREÇÕES TERAPÊUTICAS', accent: AppColors.cyan),
            ),
    ];
    final (left, right) = _balanceColumns(flow);

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
            _Header(data: data),
            const SizedBox(height: _gap),
            if (data.hasPersonality)
              _SectionCard(
                title: 'PERSONALIDADE (BIG FIVE)',
                accent: AppColors.purple,
                child: _personality(data.personality),
              )
            else
              const _GhostCard(
                title: 'PERSONALIDADE (BIG FIVE)',
                accent: AppColors.purple,
                subtitle: 'Registre em Avaliação → Personalidade',
              ),
            const SizedBox(height: _gap),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _column(left)),
                  const SizedBox(width: _gap),
                  Expanded(child: _column(right)),
                ],
              ),
            ),
            const SizedBox(height: _gap),
            if (data.hasResources)
              _SectionCard(
                title: 'RECURSOS E FORÇAS',
                accent: AppColors.success,
                child: _resourcesWrap(data.resources),
              )
            else
              const _GhostCard(
                  title: 'RECURSOS E FORÇAS', accent: AppColors.success),
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

  Widget _column(List<Widget> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(height: _gap),
          cards[i],
        ],
      ],
    );
  }

  // ── Itens (esquemas, modos, pontos fortes, desafios, direções) ─────────
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
              Text(item.title,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: accent,
                      fontSize: 13)),
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

  // ── Necessidades × eventos ─────────────────────────────────────────────
  Widget _needs(List<InfographicNeed> needs) {
    return Column(
      children: [
        for (var i = 0; i < needs.length; i++) ...[
          if (i > 0) const Divider(height: 18, color: Color(0xFFF0E9E0)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _iconBadge(needs[i].icon, needs[i].accent ?? AppColors.error),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(needs[i].need,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (needs[i].relatedEvents != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.arrow_forward,
                              size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(needs[i].relatedEvents!,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── Personalidade (barras) ─────────────────────────────────────────────
  Widget _personality(List<InfographicPersonalityDomain> domains) {
    return Column(
      children: [
        for (var i = 0; i < domains.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _personalityRow(domains[i]),
        ],
      ],
    );
  }

  Widget _personalityRow(InfographicPersonalityDomain d) {
    final accent = d.accent ?? AppColors.purple;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _iconBadge(d.icon, accent),
        const SizedBox(width: 10),
        SizedBox(
          width: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d.name,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: accent,
                      fontSize: 13)),
              if (d.classification != null)
                Text(d.classification!,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: d.fraction,
                          child: Container(
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(d.score.toStringAsFixed(0),
                        style: TextStyle(
                            fontWeight: FontWeight.w800, color: accent)),
                  ],
                ),
                if (d.meaning != null) ...[
                  const SizedBox(height: 3),
                  Text(d.meaning!,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Recursos (chips) ───────────────────────────────────────────────────
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
                Text(r.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.navy)),
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

// ── Placeholder de seção ainda não preenchida ("bloco em branco") ───────────
class _GhostCard extends StatelessWidget {
  const _GhostCard({required this.title, required this.accent, this.subtitle});

  final String title;
  final Color accent;
  final String? subtitle;

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              color: accent.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 0.4)),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _skeletonBar(0.95),
            _skeletonBar(0.75),
            _skeletonBar(0.55),
            const SizedBox(height: 6),
            const Row(
              children: [
                Icon(Icons.hourglass_empty,
                    size: 13, color: AppColors.textMuted),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'A preencher na Conceitualização',
                    style: TextStyle(
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
        final len = distance + dash < metric.length ? dash : metric.length - distance;
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
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(h.name,
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy)),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.favorite,
                        size: 18, color: Color(0xFFE0519A)),
                  ],
                ),
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
          if (data.quote != null) ...[
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceTintTurquoise,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('“',
                        style: TextStyle(
                            fontSize: 30,
                            height: 0.9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.turquoise)),
                    Text(data.quote!,
                        style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                            height: 1.4)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Seção de fluxo com um peso ≈ à sua altura, para balancear as colunas.
class _WeightedSection {
  const _WeightedSection(this.weight, this.widget);
  final int weight;
  final Widget widget;
}

/// Distribui as seções em duas colunas equilibrando a altura total: percorre
/// da mais "pesada" para a mais "leve", pondo cada uma na coluna mais curta.
/// Mantém a ordem relativa dentro de cada coluna estável (pela ordem original).
(List<Widget>, List<Widget>) _balanceColumns(List<_WeightedSection> sections) {
  final indexed = [
    for (var i = 0; i < sections.length; i++) (i, sections[i]),
  ]..sort((a, b) => b.$2.weight.compareTo(a.$2.weight));

  var leftWeight = 0;
  var rightWeight = 0;
  final leftIdx = <int>[];
  final rightIdx = <int>[];
  for (final (originalIndex, section) in indexed) {
    if (leftWeight <= rightWeight) {
      leftIdx.add(originalIndex);
      leftWeight += section.weight;
    } else {
      rightIdx.add(originalIndex);
      rightWeight += section.weight;
    }
  }
  leftIdx.sort();
  rightIdx.sort();
  return (
    [for (final i in leftIdx) sections[i].widget],
    [for (final i in rightIdx) sections[i].widget],
  );
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
      title: 'LINHA DO TEMPO',
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
