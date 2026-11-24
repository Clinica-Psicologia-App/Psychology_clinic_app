import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/desktop_admin/desktop_admin_kit.dart';
import '../../../shared/widgets/desktop_admin/desktop_admin_shell.dart';
import '../domain/question_answer_type.dart';
import '../domain/questionnaire.dart';
import '../domain/questionnaire_catalog_admin.dart';
import '../domain/questionnaire_question.dart';
import '../domain/questionnaire_session.dart';
import '../providers/questionnaire_catalog_admin_providers.dart';
import 'questionnaire_routes.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';
import '../../../shared/widgets/brand_loading.dart';

class QuestionnaireCatalogEditorPage extends ConsumerStatefulWidget {
  const QuestionnaireCatalogEditorPage({super.key, this.questionnaireId});
  final String? questionnaireId;

  @override
  ConsumerState<QuestionnaireCatalogEditorPage> createState() =>
      _QuestionnaireCatalogEditorPageState();
}

class _QuestionnaireCatalogEditorPageState
    extends ConsumerState<QuestionnaireCatalogEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _version = TextEditingController(text: '1.0');
  final _description = TextEditingController();
  final _author = TextEditingController();
  final _citation = TextEditingController();
  final _license = TextEditingController();
  final _scaleMin = TextEditingController(text: '1');
  final _scaleMax = TextEditingController(text: '5');
  String _referencePeriod = 'unspecified';
  String? _loadedId;
  bool _busy = false;

  @override
  void dispose() {
    for (final controller in [
      _code,
      _name,
      _version,
      _description,
      _author,
      _citation,
      _license,
      _scaleMin,
      _scaleMax,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.questionnaireId;
    final detailAsync = id == null
        ? const AsyncValue<QuestionnaireCatalogDetail?>.data(null)
        : ref
            .watch(questionnaireCatalogAdminDetailProvider(id))
            .whenData((v) => v);
    // A partir de 768 px: casca de desktop com índice + edição em duas
    // colunas. Abaixo disso, a tela do celular, sem alteração.
    if (isDesktopAdminWidth(context)) return _buildDesktop(id, detailAsync);
    return AppSectionScaffold(
      title: id == null ? 'Novo questionário' : 'Editor do questionário',
      subtitle: 'Rascunho, perguntas e publicação',
      body: detailAsync.when(
        loading: () => const BrandLoader(),
        error: (error, _) => Center(child: Text(_message(error))),
        data: (detail) {
          if (detail != null && _loadedId != id) _load(detail);
          return _buildContent(detail);
        },
      ),
    );
  }

  Widget _buildContent(QuestionnaireCatalogDetail? detail) {
    final editable = detail?.isEditable ?? true;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
      children: [
        if (!editable)
          _ImmutableNotice(
              status: detail!.questionnaire['clinical_status'] as String?),
        ClayCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Identificação',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                        controller: _name,
                        enabled: editable,
                        decoration: const InputDecoration(labelText: 'Nome *'),
                        validator: _required),
                    const SizedBox(height: AppSpacing.sm),
                    Row(children: [
                      Expanded(
                          child: TextFormField(
                              controller: _code,
                              enabled: editable,
                              textCapitalization: TextCapitalization.characters,
                              decoration:
                                  const InputDecoration(labelText: 'Código *'),
                              validator: _required)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                          child: TextFormField(
                              controller: _version,
                              enabled: editable,
                              decoration:
                                  const InputDecoration(labelText: 'Versão *'),
                              validator: _required)),
                    ]),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                        controller: _description,
                        enabled: editable,
                        maxLines: 3,
                        decoration:
                            const InputDecoration(labelText: 'Descrição')),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                        controller: _author,
                        enabled: editable,
                        decoration:
                            const InputDecoration(labelText: 'Autor / fonte')),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                        controller: _citation,
                        enabled: editable,
                        maxLines: 2,
                        decoration: const InputDecoration(
                            labelText: 'Referência bibliográfica')),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                        controller: _license,
                        enabled: editable,
                        maxLines: 2,
                        decoration: const InputDecoration(
                            labelText: 'Licença e observações legais')),
                    const SizedBox(height: AppSpacing.md),
                    Text('Escala padrão',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.sm),
                    Row(children: [
                      Expanded(
                          child: TextFormField(
                              controller: _scaleMin,
                              enabled: editable,
                              keyboardType: TextInputType.number,
                              decoration:
                                  const InputDecoration(labelText: 'Mínimo'),
                              validator: _integer)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                          child: TextFormField(
                              controller: _scaleMax,
                              enabled: editable,
                              keyboardType: TextInputType.number,
                              decoration:
                                  const InputDecoration(labelText: 'Máximo'),
                              validator: _integer)),
                    ]),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      initialValue: _referencePeriod,
                      decoration: const InputDecoration(
                          labelText: 'Período de referência'),
                      items: const [
                        DropdownMenuItem(
                            value: 'unspecified',
                            child: Text('Não especificado')),
                        DropdownMenuItem(
                            value: 'last_month', child: Text('Último mês')),
                        DropdownMenuItem(
                            value: 'last_year', child: Text('Último ano')),
                        DropdownMenuItem(
                            value: 'lifetime', child: Text('Toda a vida')),
                      ],
                      onChanged: editable
                          ? (value) => setState(() => _referencePeriod = value!)
                          : null,
                    ),
                    if (editable) ...[
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                              onPressed: _busy ? null : () => _save(detail),
                              icon: const Icon(Icons.save_outlined),
                              label: Text(
                                  _busy ? 'Salvando...' : 'Salvar rascunho'))),
                    ],
                  ]),
            ),
          ),
        ),
        if (detail != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Row(children: [
            Expanded(
                child: Text('Perguntas (${detail.questions.length})',
                    style: Theme.of(context).textTheme.titleMedium)),
            if (editable)
              IconButton.filledTonal(
                  tooltip: 'Adicionar pergunta',
                  onPressed: _busy ? null : () => _editQuestion(detail),
                  icon: const Icon(Icons.add)),
          ]),
          const SizedBox(height: AppSpacing.sm),
          if (detail.questions.isEmpty)
            const ClayCard(
                child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                        child: Text(
                            'Adicione ao menos uma pergunta para publicar.'))))
          else
            ...detail.questions.map((question) => ClayCard(
                  child: ListTile(
                    leading:
                        CircleAvatar(child: Text('${question.orderIndex + 1}')),
                    title: Text(question.text),
                    subtitle: Text(
                        '${question.code} • ${question.scaleMin}–${question.scaleMax} • peso ${question.weight}${question.reverseScore ? ' • invertida' : ''}'),
                    onTap:
                        editable ? () => _editQuestion(detail, question) : null,
                    trailing: editable
                        ? IconButton(
                            tooltip: 'Excluir',
                            onPressed: () => _deleteQuestion(detail, question),
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.error))
                        : null,
                  ),
                )),
          const SizedBox(height: AppSpacing.lg),
          _actionPanel(detail),
        ],
      ],
    );
  }


  // ---------------------------------------------------------------------
  // Desktop (>= 768 px): casca + barra de ações fixa + índice e edição em
  // duas colunas. Usa os mesmos controllers, validações e métodos acima.
  // ---------------------------------------------------------------------
  final _secKeys = [GlobalKey(), GlobalKey(), GlobalKey()];
  int _activeSec = 0;

  Widget _buildDesktop(String? id,
      AsyncValue<QuestionnaireCatalogDetail?> detailAsync) {
    final t = DesktopAdminTokens.of(context);
    return DesktopAdminShell(
      nav: DesktopAdminNav.home,
      crumbs: const [
        DaCrumb('Início', '/platform'),
        DaCrumb('Questionários', QuestionnaireRoutes.adminCatalog),
      ],
      title: id == null ? 'Novo questionário' : 'Editor do questionário',
      subtitle: 'Rascunho, perguntas e publicação',
      body: detailAsync.when(
        loading: () => const BrandLoader(),
        error: (error, _) => Center(
            child: Text(_message(error),
                style: daText(context, t, color: t.err))),
        data: (detail) {
          if (detail != null && _loadedId != id) _load(detail);
          return _desktopBody(detail);
        },
      ),
    );
  }

  InputDecoration _dDeco(DesktopAdminTokens t, {String? hint}) {
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c, width: w));
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: t.rz,
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: b(t.bd2),
      enabledBorder: b(t.bd2),
      disabledBorder: b(t.bd),
      focusedBorder: b(t.foc, 1.5),
      errorBorder: b(t.err),
      focusedErrorBorder: b(t.err, 1.5),
    );
  }

  Widget _dLabeled(String label, Widget field) {
    final t = DesktopAdminTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(label,
              style: daText(context, t,
                  size: 12.5, weight: FontWeight.w500, color: t.tx2)),
        ),
        field,
      ],
    );
  }

  Widget _dField(String label, TextEditingController c,
      {required bool enabled,
      String? Function(String?)? validator,
      int maxLines = 1,
      TextInputType? keyboard,
      TextCapitalization caps = TextCapitalization.none}) {
    final t = DesktopAdminTokens.of(context);
    return _dLabeled(
      label,
      TextFormField(
        controller: c,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboard,
        textCapitalization: caps,
        validator: validator,
        style: daText(context, t, color: enabled ? t.tx : t.tx3),
        cursorColor: t.foc,
        decoration: _dDeco(t),
      ),
    );
  }

  /// Grade de 2 colunas; `full` ocupa a linha inteira.
  Widget _dGrid(List<(Widget, bool)> cells) => LayoutBuilder(
        builder: (context, c) {
          final half = (c.maxWidth - 16) / 2;
          return Wrap(
            spacing: 16,
            runSpacing: 14,
            children: [
              for (final cell in cells)
                SizedBox(
                    width: cell.$2 || c.maxWidth < 520 ? c.maxWidth : half,
                    child: cell.$1),
            ],
          );
        },
      );

  Widget _dSection(int i, String title, Widget child, {Widget? trailing}) {
    final t = DesktopAdminTokens.of(context);
    return Padding(
      key: _secKeys[i],
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(
              child: Text(title,
                  style: daText(context, t, size: 15, weight: FontWeight.w600)),
            ),
            if (trailing != null) trailing,
          ]),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _desktopBody(QuestionnaireCatalogDetail? detail) {
    final t = DesktopAdminTokens.of(context);
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    final editable = detail?.isEditable ?? true;
    final entries = [
      'Identificação',
      'Escala padrão',
      if (detail != null) 'Perguntas (${detail.questions.length})',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (detail != null) _dActionBar(detail),
        if (!editable)
          Container(
            padding: EdgeInsets.symmetric(horizontal: m.pad, vertical: 10),
            decoration: BoxDecoration(
              color: t.sel,
              border: Border(bottom: BorderSide(color: t.bd)),
            ),
            child: Row(children: [
              Icon(Icons.lock_outline, size: 16, color: t.tq),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                    'Esta versão está publicada e protegida. Use "Editar — criar '
                    'nova versão" para alterar perguntas sem afetar respostas já '
                    'registradas.',
                    style: daText(context, t, color: t.tx2)),
              ),
            ]),
          ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 220,
                padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
                decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: t.bd))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < entries.length; i++)
                      _IndexItem(
                        label: entries[i],
                        active: i == _activeSec,
                        onTap: () {
                          setState(() => _activeSec = i);
                          final ctx = _secKeys[i].currentContext;
                          if (ctx != null) {
                            Scrollable.ensureVisible(ctx,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic);
                          }
                        },
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(m.pad + 4, 24, m.pad + 4, 32),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _dSection(
                                  0,
                                  'Identificação',
                                  _dGrid([
                                    (
                                      _dField('Nome *', _name,
                                          enabled: editable,
                                          validator: _required),
                                      true
                                    ),
                                    (
                                      _dField('Código *', _code,
                                          enabled: editable,
                                          validator: _required,
                                          caps: TextCapitalization.characters),
                                      false
                                    ),
                                    (
                                      _dField('Versão *', _version,
                                          enabled: editable,
                                          validator: _required),
                                      false
                                    ),
                                    (
                                      _dField('Descrição', _description,
                                          enabled: editable, maxLines: 3),
                                      true
                                    ),
                                    (
                                      _dField('Autor / fonte', _author,
                                          enabled: editable),
                                      true
                                    ),
                                    (
                                      _dField('Referência bibliográfica',
                                          _citation,
                                          enabled: editable, maxLines: 2),
                                      false
                                    ),
                                    (
                                      _dField('Licença e observações legais',
                                          _license,
                                          enabled: editable, maxLines: 2),
                                      false
                                    ),
                                  ]),
                                ),
                                _dSection(
                                  1,
                                  'Escala padrão',
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _dGrid([
                                        (
                                          _dField('Mínimo', _scaleMin,
                                              enabled: editable,
                                              validator: _integer,
                                              keyboard: TextInputType.number),
                                          false
                                        ),
                                        (
                                          _dField('Máximo', _scaleMax,
                                              enabled: editable,
                                              validator: _integer,
                                              keyboard: TextInputType.number),
                                          false
                                        ),
                                        (
                                          _dLabeled(
                                            'Período de referência',
                                            DropdownButtonFormField<String>(
                                              initialValue: _referencePeriod,
                                              isExpanded: true,
                                              decoration: _dDeco(t),
                                              style: daText(context, t),
                                              items: const [
                                                DropdownMenuItem(
                                                    value: 'unspecified',
                                                    child: Text(
                                                        'Não especificado')),
                                                DropdownMenuItem(
                                                    value: 'last_month',
                                                    child:
                                                        Text('Último mês')),
                                                DropdownMenuItem(
                                                    value: 'last_year',
                                                    child:
                                                        Text('Último ano')),
                                                DropdownMenuItem(
                                                    value: 'lifetime',
                                                    child:
                                                        Text('Toda a vida')),
                                              ],
                                              onChanged: editable
                                                  ? (value) => setState(() =>
                                                      _referencePeriod =
                                                          value!)
                                                  : null,
                                            ),
                                          ),
                                          false
                                        ),
                                      ]),
                                      if (editable) ...[
                                        const SizedBox(height: 16),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: DaButton(
                                            kind: DaButtonKind.primary,
                                            icon: Icons.save_outlined,
                                            label: _busy
                                                ? 'Salvando...'
                                                : 'Salvar rascunho',
                                            onPressed: _busy
                                                ? null
                                                : () => _save(detail),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (detail != null)
                            _dSection(
                              2,
                              'Perguntas (${detail.questions.length})',
                              _dQuestions(detail, editable),
                              trailing: editable
                                  ? DaButton(
                                      kind: DaButtonKind.ghost,
                                      icon: Icons.add,
                                      tooltip: 'Adicionar pergunta',
                                      onPressed: _busy
                                          ? null
                                          : () => _editQuestion(detail),
                                    )
                                  : null,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dQuestions(QuestionnaireCatalogDetail detail, bool editable) {
    final t = DesktopAdminTokens.of(context);
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    if (detail.questions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: t.rz,
          border: Border.all(color: t.bd2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('Adicione ao menos uma pergunta para publicar.',
            style: daText(context, t, color: t.tx3)),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: t.rz,
        border: Border.all(color: t.bd2),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final q in detail.questions)
            _QuestionRow(
              question: q,
              minHeight: m.row,
              editable: editable,
              onOpen: () => _editQuestion(detail, q),
              onDelete: () => _deleteQuestion(detail, q),
            ),
        ],
      ),
    );
  }

  Widget _dActionBar(QuestionnaireCatalogDetail detail) {
    final t = DesktopAdminTokens.of(context);
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    final editable = detail.isEditable;
    final approved = detail.questionnaire['clinical_status'] == 'approved';
    final editingNewVersion = editable && detail.isPublished;
    final text = editingNewVersion
        ? 'Editando rascunho da versão ${detail.versionLabel ?? ''} — '
            'a versão ${detail.activeVersionLabel ?? 'ativa'} continua '
            'sendo aplicada aos pacientes até você publicar.'
        : editable
            ? 'A publicação homologa o instrumento e bloqueia alterações estruturais.'
            : 'Edições criam uma nova versão: respostas já registradas '
                'permanecem fixadas na versão em que foram respondidas.';
    final preview = DaButton(
      icon: Icons.visibility_outlined,
      label: 'Pré-visualizar sem gravar',
      onPressed: detail.questions.isEmpty ? null : () => _preview(detail),
    );
    final buttons = <Widget>[
      if (editable) ...[
        if (editingNewVersion)
          DaButton(
            kind: DaButtonKind.ghost,
            icon: Icons.undo_outlined,
            label: 'Descartar rascunho da nova versão',
            onPressed: _busy ? null : () => _discardDraftVersion(detail),
          )
        else
          DaButton(
            kind: DaButtonKind.ghost,
            icon: Icons.delete_outline,
            label: 'Excluir rascunho',
            onPressed: _busy ? null : () => _deleteDraft(detail),
          ),
        preview,
        DaButton(
          kind: DaButtonKind.primary,
          icon: Icons.verified_outlined,
          label:
              editingNewVersion ? 'Publicar nova versão' : 'Homologar e publicar',
          onPressed:
              _busy || detail.questions.isEmpty ? null : () => _publish(detail),
        ),
      ] else ...[
        if (approved)
          DaButton(
            kind: DaButtonKind.ghost,
            icon: Icons.archive_outlined,
            label: 'Arquivar instrumento',
            onPressed: _busy ? null : () => _archive(detail),
          ),
        preview,
        DaButton(
          icon: Icons.copy_outlined,
          label: 'Duplicar como novo instrumento',
          onPressed: _busy ? null : () => _duplicate(detail),
        ),
        if (detail.canCreateDraftVersion)
          DaButton(
            kind: DaButtonKind.primary,
            icon: Icons.edit_outlined,
            label: 'Editar — criar nova versão',
            onPressed: _busy ? null : () => _createDraftVersion(detail),
          ),
      ],
    ];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: m.pad, vertical: 12),
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: t.bd))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Governança',
                    style: daText(context, t, weight: FontWeight.w600)),
                Text(text, style: daText(context, t, size: 12.5, color: t.tx2)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 7,
            child: Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: buttons,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionPanel(QuestionnaireCatalogDetail detail) {
    final editable = detail.isEditable;
    final approved = detail.questionnaire['clinical_status'] == 'approved';
    final editingNewVersion = editable && detail.isPublished;

    return ClayCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Governança', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            editingNewVersion
                ? 'Editando rascunho da versão ${detail.versionLabel ?? ''} — '
                    'a versão ${detail.activeVersionLabel ?? 'ativa'} continua '
                    'sendo aplicada aos pacientes até você publicar.'
                : editable
                    ? 'A publicação homologa o instrumento e bloqueia alterações estruturais.'
                    : 'Edições criam uma nova versão: respostas já registradas '
                        'permanecem fixadas na versão em que foram respondidas.',
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: detail.questions.isEmpty ? null : () => _preview(detail),
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Pré-visualizar sem gravar'),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (editable) ...[
            FilledButton.icon(
                onPressed: _busy || detail.questions.isEmpty
                    ? null
                    : () => _publish(detail),
                icon: const Icon(Icons.verified_outlined),
                label: Text(editingNewVersion
                    ? 'Publicar nova versão'
                    : 'Homologar e publicar')),
            if (editingNewVersion)
              TextButton.icon(
                  onPressed: _busy ? null : () => _discardDraftVersion(detail),
                  icon: const Icon(Icons.undo_outlined),
                  label: const Text('Descartar rascunho da nova versão'))
            else
              TextButton.icon(
                  onPressed: _busy ? null : () => _deleteDraft(detail),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Excluir rascunho')),
          ] else ...[
            if (detail.canCreateDraftVersion)
              FilledButton.icon(
                  onPressed: _busy ? null : () => _createDraftVersion(detail),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar — criar nova versão')),
            OutlinedButton.icon(
                onPressed: _busy ? null : () => _duplicate(detail),
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Duplicar como novo instrumento')),
            if (approved)
              TextButton.icon(
                  onPressed: _busy ? null : () => _archive(detail),
                  icon: const Icon(Icons.archive_outlined),
                  label: const Text('Arquivar instrumento')),
          ],
        ]),
      ),
    );
  }

  Future<void> _createDraftVersion(QuestionnaireCatalogDetail detail) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Criar nova versão'),
        content: Text(
          'Uma cópia editável do instrumento será criada. A versão '
          '${detail.versionLabel ?? 'atual'} continua ativa para os pacientes '
          'e as respostas já registradas permanecem intactas. As alterações '
          'só valem após você publicar a nova versão.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Criar nova versão')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() async {
      await ref
          .read(questionnaireCatalogAdminRepositoryProvider)
          .createDraftVersion(detail.questionnaire['id'] as String);
      ref.invalidate(questionnaireCatalogAdminDetailProvider(
          detail.questionnaire['id'] as String));
      ref.invalidate(questionnaireCatalogAdminListProvider);
      _toast('Nova versão criada — edite e publique quando estiver pronta.');
    });
  }

  Future<void> _discardDraftVersion(QuestionnaireCatalogDetail detail) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descartar rascunho'),
        content: const Text(
          'As alterações desta nova versão serão perdidas. A versão ativa '
          'continua intacta.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Manter rascunho')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Descartar')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() async {
      await ref
          .read(questionnaireCatalogAdminRepositoryProvider)
          .discardDraftVersion(detail.questionnaire['id'] as String);
      ref.invalidate(questionnaireCatalogAdminDetailProvider(
          detail.questionnaire['id'] as String));
      ref.invalidate(questionnaireCatalogAdminListProvider);
      _toast('Rascunho descartado.');
    });
  }

  void _load(QuestionnaireCatalogDetail detail) {
    _loadedId = widget.questionnaireId;
    final q = detail.questionnaire;
    final v = detail.version;
    _code.text = q['code'] as String? ?? '';
    _name.text = q['name'] as String? ?? '';
    _version.text =
        v['version'] as String? ?? q['instrument_version'] as String? ?? '1.0';
    _description.text = q['description'] as String? ?? '';
    _author.text = q['author_name'] as String? ?? '';
    _citation.text = q['citation'] as String? ?? '';
    _license.text = q['license_notes'] as String? ?? '';
    _scaleMin.text = '${v['scale_min'] ?? 1}';
    _scaleMax.text = '${v['scale_max'] ?? 5}';
    _referencePeriod = v['reference_period'] as String? ?? 'unspecified';
  }

  Future<void> _save(QuestionnaireCatalogDetail? detail) async {
    if (!_formKey.currentState!.validate()) return;
    final min = int.parse(_scaleMin.text);
    final max = int.parse(_scaleMax.text);
    if (min > max) {
      return _toast('A escala mínima deve ser menor que a máxima.');
    }
    await _run(() async {
      final id = await ref
          .read(questionnaireCatalogAdminRepositoryProvider)
          .saveDraft(QuestionnaireDraftInput(
            id: widget.questionnaireId,
            code: _code.text,
            name: _name.text,
            version: _version.text,
            scaleMin: min,
            scaleMax: max,
            referencePeriod: _referencePeriod,
            description: _description.text,
            authorName: _author.text,
            citation: _citation.text,
            licenseNotes: _license.text,
          ));
      ref.invalidate(questionnaireCatalogAdminListProvider);
      if (widget.questionnaireId == null && mounted) {
        context.go(QuestionnaireRoutes.adminCatalogDetail(id));
      } else {
        ref.invalidate(questionnaireCatalogAdminDetailProvider(id));
        _toast('Rascunho salvo.');
      }
    });
  }

  Future<void> _editQuestion(QuestionnaireCatalogDetail detail,
      [QuestionnaireCatalogQuestion? question]) async {
    final input = isDesktopAdminWidth(context)
        ? await showDesktopSlideOver<_QuestionInput>(context,
            title: question == null ? 'Nova pergunta' : 'Editar pergunta',
            child: _QuestionDialog(
                question: question,
                nextOrder: detail.questions.length,
                embedded: true))
        : await showDialog<_QuestionInput>(
            context: context,
            builder: (_) => _QuestionDialog(
                question: question, nextOrder: detail.questions.length));
    if (input == null) return;
    await _run(() async {
      await ref.read(questionnaireCatalogAdminRepositoryProvider).saveQuestion(
            questionnaireId: widget.questionnaireId!,
            questionId: question?.id,
            code: input.code,
            text: input.text,
            orderIndex: input.order,
            answerType: input.type.value,
            scaleMin: input.min,
            scaleMax: input.max,
            weight: input.weight,
            reverseScore: input.reverse,
          );
      ref.invalidate(
          questionnaireCatalogAdminDetailProvider(widget.questionnaireId!));
    });
  }

  Future<void> _deleteQuestion(QuestionnaireCatalogDetail detail,
      QuestionnaireCatalogQuestion question) async {
    if (!await _confirm(
        'Excluir pergunta?', 'Essa ação remove a pergunta do rascunho.')) {
      return;
    }
    await _run(() async {
      await ref
          .read(questionnaireCatalogAdminRepositoryProvider)
          .deleteQuestion(widget.questionnaireId!, question.id);
      ref.invalidate(
          questionnaireCatalogAdminDetailProvider(widget.questionnaireId!));
    });
  }

  void _preview(QuestionnaireCatalogDetail detail) {
    final q = detail.questionnaire;
    final version = detail.version;
    final questionnaire = Questionnaire.fromJson({
      'id': q['id'],
      'code': q['code'],
      'name': q['name'],
      'description': q['description'],
      'is_active': true,
      'author_name': q['author_name'],
      'instrument_version': q['instrument_version'],
      'citation': q['citation'],
      'license_notes': q['license_notes'],
      'clinical_status': q['clinical_status'],
      'reference_period': version['reference_period'],
    });
    final session = QuestionnaireSession(
      responseId: 'admin-preview-${q['id']}',
      patientId: 'admin-preview',
      questionnaire: questionnaire,
      questions: detail.questions
          .map(
            (item) => QuestionnaireQuestion(
              id: item.id,
              code: item.code,
              text: item.text,
              orderIndex: item.orderIndex,
              answerType: item.answerType,
              scaleMin: item.scaleMin,
              scaleMax: item.scaleMax,
            ),
          )
          .toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex)),
    );
    context.push(
        '${QuestionnaireRoutes.adminCatalogDetail(q['id'] as String)}/preview',
        extra: session);
  }

  Future<void> _publish(QuestionnaireCatalogDetail detail) async {
    if (!await _confirm('Homologar e publicar?',
        'Depois da publicação, o conteúdo ficará imutável. Confirme também que licença e validação clínica foram revisadas.')) {
      return;
    }
    await _run(() async {
      await ref
          .read(questionnaireCatalogAdminRepositoryProvider)
          .publish(widget.questionnaireId!);
      _refreshAndBack();
    });
  }

  Future<void> _archive(QuestionnaireCatalogDetail detail) async {
    if (!await _confirm('Arquivar instrumento?',
        'Novas aplicações serão bloqueadas, mas respostas antigas serão preservadas.')) {
      return;
    }
    await _run(() async {
      await ref
          .read(questionnaireCatalogAdminRepositoryProvider)
          .archive(widget.questionnaireId!);
      _refreshAndBack();
    });
  }

  Future<void> _deleteDraft(QuestionnaireCatalogDetail detail) async {
    if (!await _confirm('Excluir rascunho?', 'Essa ação é permanente.')) {
      return;
    }
    await _run(() async {
      await ref
          .read(questionnaireCatalogAdminRepositoryProvider)
          .deleteDraft(widget.questionnaireId!);
      _refreshAndBack();
    });
  }

  Future<void> _duplicate(QuestionnaireCatalogDetail detail) async {
    final values = await showDialog<List<String>>(
        context: context,
        builder: (_) => _DuplicateDialog(
            currentCode: _code.text, currentVersion: _version.text));
    if (values == null) {
      return;
    }
    await _run(() async {
      final id = await ref
          .read(questionnaireCatalogAdminRepositoryProvider)
          .duplicate(
              id: widget.questionnaireId!, code: values[0], version: values[1]);
      ref.invalidate(questionnaireCatalogAdminListProvider);
      if (mounted) {
        context.go(QuestionnaireRoutes.adminCatalogDetail(id));
      }
    });
  }

  void _refreshAndBack() {
    ref.invalidate(questionnaireCatalogAdminListProvider);
    if (mounted) context.go(QuestionnaireRoutes.adminCatalog);
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      _toast(_message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String title, String body) async =>
      await showDialog<bool>(
          context: context,
          builder: (ctx) =>
              AlertDialog(title: Text(title), content: Text(body), actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancelar')),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Confirmar'))
              ])) ??
      false;
  void _toast(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obrigatório' : null;
  String? _integer(String? value) =>
      int.tryParse(value ?? '') == null ? 'Informe um número inteiro' : null;
}

class _ImmutableNotice extends StatelessWidget {
  const _ImmutableNotice({this.status});
  final String? status;
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
          color: AppColors.infoContainer,
          borderRadius: BorderRadius.circular(14)),
      child: const Row(children: [
        Icon(Icons.lock_outline, color: AppColors.info),
        SizedBox(width: AppSpacing.sm),
        Expanded(
            child: Text(
                'Esta versão está publicada e protegida. Use "Editar — criar '
                'nova versão" para alterar perguntas sem afetar respostas já '
                'registradas.'))
      ]));
}

class _QuestionInput {
  const _QuestionInput(this.code, this.text, this.order, this.type, this.min,
      this.max, this.weight, this.reverse);
  final String code, text;
  final int order, min, max;
  final QuestionAnswerType type;
  final double weight;
  final bool reverse;
}

class _QuestionDialog extends StatefulWidget {
  const _QuestionDialog(
      {this.question, required this.nextOrder, this.embedded = false});

  /// true = dentro do painel lateral do desktop (sem moldura de diálogo).
  final bool embedded;
  final QuestionnaireCatalogQuestion? question;
  final int nextOrder;
  @override
  State<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<_QuestionDialog> {
  final keyForm = GlobalKey<FormState>();
  late final TextEditingController code, text, order, min, max, weight;
  late QuestionAnswerType type;
  late bool reverse;
  @override
  void initState() {
    super.initState();
    final q = widget.question;
    code = TextEditingController(text: q?.code ?? 'Q${widget.nextOrder + 1}');
    text = TextEditingController(text: q?.text);
    order = TextEditingController(text: '${q?.orderIndex ?? widget.nextOrder}');
    min = TextEditingController(text: '${q?.scaleMin ?? 1}');
    max = TextEditingController(text: '${q?.scaleMax ?? 5}');
    weight = TextEditingController(text: '${q?.weight ?? 1}');
    type = q?.answerType ?? QuestionAnswerType.likertScale;
    reverse = q?.reverseScore ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final form = Form(
                      key: keyForm,
                      child: SingleChildScrollView(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                        TextFormField(
                            controller: text,
                            maxLines: 3,
                            decoration:
                                const InputDecoration(labelText: 'Enunciado *'),
                            validator: _req),
                        const SizedBox(height: 12),
                        TextFormField(
                            controller: code,
                            decoration:
                                const InputDecoration(labelText: 'Código *'),
                            validator: _req),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<QuestionAnswerType>(
                            initialValue: type,
                            decoration: const InputDecoration(
                                labelText: 'Tipo de resposta'),
                            items: QuestionAnswerType.values
                                .where((e) => e.supportsNumericSubmission)
                                .map((e) => DropdownMenuItem(
                                    value: e, child: Text(_typeLabel(e))))
                                .toList(),
                            onChanged: (v) => setState(() => type = v!)),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                              child: TextFormField(
                                  controller: min,
                                  keyboardType: TextInputType.number,
                                  decoration:
                                      const InputDecoration(labelText: 'Mínimo'),
                                  validator: _num)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: TextFormField(
                                  controller: max,
                                  keyboardType: TextInputType.number,
                                  decoration:
                                      const InputDecoration(labelText: 'Máximo'),
                                  validator: _num))
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                              child: TextFormField(
                                  controller: order,
                                  keyboardType: TextInputType.number,
                                  decoration:
                                      const InputDecoration(labelText: 'Ordem'),
                                  validator: _num)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: TextFormField(
                                  controller: weight,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration:
                                      const InputDecoration(labelText: 'Peso'),
                                  validator: (v) => double.tryParse(
                                              (v ?? '').replaceAll(',', '.')) ==
                                          null
                                      ? 'Número inválido'
                                      : null))
                        ]),
                        SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Pontuação invertida'),
                            subtitle:
                                const Text('Inverte a escala antes de calcular.'),
                            value: reverse,
                            onChanged: (v) => setState(() => reverse = v))
                      ])));
    if (widget.embedded) {
      final t = DesktopAdminTokens.of(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22), child: form)),
          Container(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
            decoration:
                BoxDecoration(border: Border(top: BorderSide(color: t.bd))),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              DaButton(
                  kind: DaButtonKind.ghost,
                  label: 'Cancelar',
                  onPressed: () => Navigator.pop(context)),
              const SizedBox(width: 8),
              DaButton(
                  kind: DaButtonKind.primary,
                  label: 'Salvar',
                  onPressed: _submit),
            ]),
          ),
        ],
      );
    }
    return AlertDialog(
          title: Text(
              widget.question == null ? 'Nova pergunta' : 'Editar pergunta'),
          content: SizedBox(width: 520, child: form),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            FilledButton(onPressed: _submit, child: const Text('Salvar'))
          ]);
  }

  void _submit() {
    if (!keyForm.currentState!.validate()) return;
    final lo = int.parse(min.text), hi = int.parse(max.text);
    if (lo > hi) return;
    Navigator.pop(
        context,
        _QuestionInput(
            code.text.trim(),
            text.text.trim(),
            int.parse(order.text),
            type,
            lo,
            hi,
            double.parse(weight.text.replaceAll(',', '.')),
            reverse));
  }
  String? _req(String? v) =>
      v == null || v.trim().isEmpty ? 'Campo obrigatório' : null;
  String? _num(String? v) =>
      int.tryParse(v ?? '') == null ? 'Número inválido' : null;
}

class _DuplicateDialog extends StatefulWidget {
  const _DuplicateDialog(
      {required this.currentCode, required this.currentVersion});
  final String currentCode, currentVersion;
  @override
  State<_DuplicateDialog> createState() => _DuplicateDialogState();
}

class _DuplicateDialogState extends State<_DuplicateDialog> {
  late final TextEditingController code =
      TextEditingController(text: '${widget.currentCode}_V2');
  late final TextEditingController version =
      TextEditingController(text: '${widget.currentVersion}.1');
  @override
  Widget build(BuildContext context) => AlertDialog(
          title: const Text('Nova versão como rascunho'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: code,
                decoration: const InputDecoration(labelText: 'Novo código')),
            const SizedBox(height: 12),
            TextField(
                controller: version,
                decoration: const InputDecoration(labelText: 'Nova versão'))
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.pop(
                    context, [code.text.trim(), version.text.trim()]),
                child: const Text('Duplicar'))
          ]);
}

String _typeLabel(QuestionAnswerType type) => switch (type) {
      QuestionAnswerType.likertScale => 'Escala Likert',
      QuestionAnswerType.numericScale => 'Escala numérica',
      QuestionAnswerType.singleChoice => 'Escolha única',
      QuestionAnswerType.text => 'Texto'
    };
String _message(Object error) =>
    error.toString().replaceFirst(RegExp(r'^AppException\([^)]*\):\s*'), '');


class _IndexItem extends StatefulWidget {
  const _IndexItem(
      {required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_IndexItem> createState() => _IndexItemState();
}

class _IndexItemState extends State<_IndexItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 36,
          alignment: Alignment.centerLeft,
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: widget.active
                ? t.rz
                : (_hover ? t.hov2 : Colors.transparent),
            border:
                Border.all(color: widget.active ? t.bd2 : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: daText(context, t,
                  weight: widget.active ? FontWeight.w600 : FontWeight.w500,
                  color: widget.active ? t.tx : t.tx2)),
        ),
      ),
    );
  }
}

class _QuestionRow extends StatefulWidget {
  const _QuestionRow({
    required this.question,
    required this.minHeight,
    required this.editable,
    required this.onOpen,
    required this.onDelete,
  });

  final QuestionnaireCatalogQuestion question;
  final double minHeight;
  final bool editable;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  State<_QuestionRow> createState() => _QuestionRowState();
}

class _QuestionRowState extends State<_QuestionRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final q = widget.question;
    return MouseRegion(
      cursor: widget.editable
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.editable ? widget.onOpen : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: BoxConstraints(minHeight: widget.minHeight),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _hover && widget.editable ? t.hov : Colors.transparent,
            border: Border(bottom: BorderSide(color: t.bd)),
          ),
          child: Row(children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: t.sel, shape: BoxShape.circle),
              child: Text('${q.orderIndex + 1}',
                  style: daText(context, t,
                      size: 12.5, weight: FontWeight.w600, color: t.tq)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q.text,
                      style: daText(context, t, weight: FontWeight.w600)),
                  Text(
                      '${q.code} • ${q.scaleMin}–${q.scaleMax} • peso ${q.weight}${q.reverseScore ? ' • invertida' : ''}',
                      style: daText(context, t, size: 12, color: t.tx3)),
                ],
              ),
            ),
            if (widget.editable)
              DaButton(
                kind: DaButtonKind.ghost,
                icon: Icons.delete_outline,
                danger: true,
                tooltip: 'Excluir',
                onPressed: widget.onDelete,
              ),
          ]),
        ),
      ),
    );
  }
}
