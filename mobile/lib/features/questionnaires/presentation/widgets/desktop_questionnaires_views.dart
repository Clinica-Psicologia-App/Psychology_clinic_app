import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/brand_loading.dart';
import '../../../../shared/widgets/desktop_admin/desktop_admin_kit.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../profile/domain/profile_role.dart';
import '../../domain/questionnaire_access_item.dart';
import '../../domain/questionnaire_catalog_admin.dart';
import '../../domain/questionnaire_professional_option.dart';
import '../../providers/questionnaires_providers.dart';

String _initialsOf(String name) {
  final p =
      name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  if (p.isEmpty) return '?';
  if (p.length == 1) return p.first.substring(0, 1).toUpperCase();
  return (p.first.substring(0, 1) + p.last.substring(0, 1)).toUpperCase();
}

/// Catálogo de questionários em tabela (a linha abre o editor).
class DesktopQuestionnaireCatalogView extends StatelessWidget {
  const DesktopQuestionnaireCatalogView({
    super.key,
    required this.items,
    required this.onOpen,
  });

  final List<QuestionnaireCatalogAdminItem> items;
  final ValueChanged<QuestionnaireCatalogAdminItem> onOpen;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    Widget h(String s, {double? w, bool right = false}) {
      final text = Text(s,
          maxLines: 1,
          textAlign: right ? TextAlign.right : TextAlign.left,
          style: daText(context, t,
              size: 12, weight: FontWeight.w500, color: t.tx3));
      return w == null ? Expanded(child: text) : SizedBox(width: w, child: text);
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
          m.pad, m.size == DesktopAdminSize.desktop ? 24 : 18, m.pad, 24),
      child: Container(
        decoration: BoxDecoration(
          color: t.rz,
          border: Border.all(color: t.bd2),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              height: 38,
              padding: const EdgeInsets.only(left: 18),
              decoration: BoxDecoration(
                color: t.side,
                border: Border(bottom: BorderSide(color: t.bd2)),
              ),
              child: Row(children: [
                h('Questionário'),
                h('Código', w: m.tablet ? 96 : 130),
                if (!m.tablet) h('Versão', w: 90),
                h('Status', w: m.tablet ? 110 : 130),
                h('Perguntas', w: m.tablet ? 84 : 100, right: true),
                h('Respostas', w: m.tablet ? 84 : 100, right: true),
                SizedBox(width: m.tablet ? 28 : 56),
              ]),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text('Nenhum questionário cadastrado.',
                          style: daText(context, t, color: t.tx3)))
                  : ListView(
                      children: [
                        for (final it in items)
                          _CatalogRow(item: it, m: m, onOpen: () => onOpen(it)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogRow extends StatefulWidget {
  const _CatalogRow(
      {required this.item, required this.m, required this.onOpen});

  final QuestionnaireCatalogAdminItem item;
  final DesktopAdminMetrics m;
  final VoidCallback onOpen;

  @override
  State<_CatalogRow> createState() => _CatalogRowState();
}

class _CatalogRowState extends State<_CatalogRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final it = widget.item;
    final m = widget.m;
    final status = switch (it.clinicalStatus) {
      'approved' => DaTag.ok(context, 'Publicado'),
      'suspended' => const DaTag('Arquivado'),
      'validation' => DaTag.rx(context, 'Em validação'),
      _ => DaTag.az(context, 'Rascunho'),
    };
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onOpen,
        child: AnimatedContainer(
          duration: daHoverDuration(context),
          height: m.row,
          padding: const EdgeInsets.only(left: 18),
          decoration: BoxDecoration(
            color: _hover ? t.hov : daClear(t.hov),
            border: Border(bottom: BorderSide(color: t.bd)),
          ),
          child: Row(children: [
            Expanded(
              child: Row(children: [
                const DaIconBox(Icons.assignment_outlined,
                    color: DesktopAdminTokens.blue),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(it.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: daText(context, t, weight: FontWeight.w600)),
                ),
              ]),
            ),
            SizedBox(
                width: m.tablet ? 96 : 130,
                child: Text(it.code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: daText(context, t, color: t.tx2))),
            if (!m.tablet)
              SizedBox(
                  width: 90,
                  child: Text(it.version ?? '–',
                      style: daText(context, t, color: t.tx3))),
            SizedBox(
                width: m.tablet ? 110 : 130,
                child: Align(alignment: Alignment.centerLeft, child: status)),
            SizedBox(
                width: m.tablet ? 84 : 100,
                child: Text('${it.questionCount}',
                    textAlign: TextAlign.right, style: daText(context, t))),
            SizedBox(
                width: m.tablet ? 84 : 100,
                child: Text('${it.responseCount}',
                    textAlign: TextAlign.right, style: daText(context, t))),
            SizedBox(
              width: m.tablet ? 28 : 56,
              child: AnimatedOpacity(
                duration: daHoverDuration(context),
                opacity: _hover ? 1 : 0,
                child: Icon(Icons.chevron_right, size: 18, color: t.tx3),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Permissões por psicólogo: lista à esquerda, instrumentos liberados à
/// direita (mesma gravação do celular via [onToggle]).
class DesktopQuestionnaireAccessView extends ConsumerWidget {
  const DesktopQuestionnaireAccessView({
    super.key,
    required this.selectedId,
    required this.saving,
    required this.onSelect,
    required this.onToggle,
  });

  final String? selectedId;
  final bool saving;
  final ValueChanged<String> onSelect;
  final void Function(QuestionnaireAccessItem item, bool value) onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = DesktopAdminTokens.of(context);
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    final staff = ref.watch(questionnaireStaffOptionsProvider);
    final listW = m.size == DesktopAdminSize.desktop
        ? 380.0
        : (m.tablet ? 270.0 : 320.0);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          m.pad, m.size == DesktopAdminSize.desktop ? 24 : 18, m.pad, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Permissões por psicólogo',
              style: daText(context, t,
                  size: m.size == DesktopAdminSize.desktop ? 16 : 15,
                  weight: FontWeight.w600)),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Text(
                'Escolha um profissional e defina quais instrumentos ele pode aplicar. Esta aba não edita perguntas nem dados do catálogo.',
                style: daText(context, t, color: t.tx2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: t.rz,
                border: Border.all(color: t.bd2),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: staff.when(
                loading: () => const Center(child: BrandLoader()),
                error: (_, __) => Center(
                  child: Text('Não foi possível carregar os psicólogos.',
                      style: daText(context, t, color: t.tx3)),
                ),
                data: (options) => Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: listW,
                      decoration: BoxDecoration(
                        color: t.bg,
                        border: Border(right: BorderSide(color: t.bd2)),
                      ),
                      child: Column(children: [
                        Container(
                          height: 38,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: t.side,
                            border: Border(bottom: BorderSide(color: t.bd2)),
                          ),
                          child: Text('Psicólogo',
                              style: daText(context, t,
                                  size: 12,
                                  weight: FontWeight.w500,
                                  color: t.tx3)),
                        ),
                        Expanded(
                          child: ListView(children: [
                            for (final o in options)
                              _ProItem(
                                option: o,
                                m: m,
                                selected: o.id == selectedId,
                                onTap: () => onSelect(o.id),
                              ),
                          ]),
                        ),
                      ]),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        layoutBuilder: (cur, prev) => Stack(
                          alignment: Alignment.topLeft,
                          children: [...prev, if (cur != null) cur],
                        ),
                        child: selectedId == null
                            ? const _Empty(key: ValueKey('vazio'))
                            : _AccessDetail(
                                key: ValueKey(selectedId),
                                option: options.firstWhere(
                                    (o) => o.id == selectedId,
                                    orElse: () => options.first),
                                saving: saving,
                                onToggle: onToggle,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({super.key});

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    return SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DaIconBox(Icons.person_search_outlined,
              color: t.tx3, size: 52, radius: 14),
          const SizedBox(height: 14),
          Text('Selecione um psicólogo',
              style: daText(context, t, size: 15, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
              'A lista mostrará quais questionários esse profissional pode aplicar.',
              style: daText(context, t, color: t.tx2)),
        ],
      ),
    );
  }
}

class _ProItem extends StatefulWidget {
  const _ProItem({
    required this.option,
    required this.m,
    required this.selected,
    required this.onTap,
  });

  final QuestionnaireProfessionalOption option;
  final DesktopAdminMetrics m;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ProItem> createState() => _ProItemState();
}

class _ProItemState extends State<_ProItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final o = widget.option;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: daHoverDuration(context),
          constraints: BoxConstraints(minHeight: widget.m.row),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.selected
                ? t.sel
                : (_hover ? t.hov : daClear(t.hov)),
            border: Border(
              bottom: BorderSide(color: t.bd),
              left: BorderSide(
                  color: widget.selected ? t.tq : daClear(t.tq),
                  width: 3),
            ),
          ),
          child: Row(children: [
            DaInitials(_initialsOf(o.fullName)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: daText(context, t, weight: FontWeight.w600)),
                  if (o.email != null && o.email!.trim().isNotEmpty)
                    Text(o.email!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: daText(context, t, size: 12, color: t.tx3)),
                ],
              ),
            ),
            AnimatedOpacity(
              duration: daHoverDuration(context),
              opacity: widget.selected || _hover ? 1 : 0,
              child: Icon(Icons.chevron_right, size: 16, color: t.tx3),
            ),
          ]),
        ),
      ),
    );
  }
}

class _AccessDetail extends ConsumerWidget {
  const _AccessDetail({
    super.key,
    required this.option,
    required this.saving,
    required this.onToggle,
  });

  final QuestionnaireProfessionalOption option;
  final bool saving;
  final void Function(QuestionnaireAccessItem item, bool value) onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = DesktopAdminTokens.of(context);
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    final profile = ref.watch(authControllerProvider).valueOrNull;
    final access = ref.watch(questionnaireAccessManagementProvider(option.id));
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
          horizontal: m.size == DesktopAdminSize.desktop ? 40 : 28,
          vertical: 24),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 18),
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: t.bd))),
                child: Row(children: [
                  DaInitials(_initialsOf(option.fullName), size: 44),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(option.fullName,
                            style: daText(context, t,
                                size: 17, weight: FontWeight.w600)),
                        Text(
                            '(${option.role.label})${option.email != null ? ' · ${option.email}' : ''}',
                            style: daText(context, t, color: t.tx3)),
                      ],
                    ),
                  ),
                ]),
              ),
              access.when(
                loading: () => const Padding(
                    padding: EdgeInsets.all(24), child: BrandLoader()),
                error: (e, _) => Text(
                    e.toString().replaceFirst(
                        RegExp(r'^AppException\([^)]*\):\s*'), ''),
                    style: daText(context, t, color: t.err)),
                data: (data) {
                  final enabledCount =
                      data.items.where((i) => i.isEnabled).length;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: t.sel,
                          border: Border.all(color: t.bd),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(children: [
                          Icon(Icons.assignment_ind_outlined,
                              size: 18, color: t.tq),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text.rich(TextSpan(children: [
                              TextSpan(
                                  text: 'Acesso do profissional selecionado\n',
                                  style: daText(context, t,
                                      weight: FontWeight.w600)),
                              TextSpan(
                                  text:
                                      '$enabledCount de ${data.items.length} instrumento(s) liberado(s). Use os controles abaixo para permitir ou bloquear aplicação.',
                                  style: daText(context, t, color: t.tx2)),
                            ])),
                          ),
                        ]),
                      ),
                      if (!data.supportsAccessControl)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text(
                              'Permissões indisponíveis — A listagem está em modo compatível até o banco receber a tabela de permissões.',
                              style: daText(context, t, color: t.tx2)),
                        ),
                      for (final item in data.items)
                        _AccessRow(
                          item: item,
                          enabled: data.supportsAccessControl && !saving,
                          showLicense:
                              profile?.role == ProfileRole.platformAdmin,
                          onChanged: (v) => onToggle(item, v),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessRow extends StatelessWidget {
  const _AccessRow({
    required this.item,
    required this.enabled,
    required this.showLicense,
    required this.onChanged,
  });

  final QuestionnaireAccessItem item;
  final bool enabled;
  final bool showLicense;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    final q = item.questionnaire;
    final detail = [
      'Código: ${q.code}',
      if (q.authorName != null && q.authorName!.trim().isNotEmpty)
        'Autor: ${q.authorName}',
      if (q.instrumentVersion != null && q.instrumentVersion!.trim().isNotEmpty)
        'Versão: ${q.instrumentVersion}',
    ].join(' · ');
    return Container(
      constraints: BoxConstraints(minHeight: m.row),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: t.bd))),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(q.name, style: daText(context, t, weight: FontWeight.w600)),
              Text(detail, style: daText(context, t, size: 12, color: t.tx3)),
              if (showLicense &&
                  q.licenseNotes != null &&
                  q.licenseNotes!.trim().isNotEmpty)
                Text(q.licenseNotes!,
                    style: daText(context, t,
                        size: 12,
                        color: q.hasLicensePendingValidation ? t.err : t.tx3)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        item.isEnabled
            ? DaTag.ok(context, 'Liberado')
            : const DaTag('Bloqueado'),
        const SizedBox(width: 14),
        DaSwitch(
          value: item.isEnabled,
          semantics: q.name,
          tablet: m.tablet,
          onChanged: enabled ? () => onChanged(!item.isEnabled) : null,
        ),
      ]),
    );
  }
}
