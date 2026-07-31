import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../domain/question_answer_type.dart';
import '../domain/questionnaire.dart';
import '../domain/questionnaire_catalog_admin.dart';
import '../domain/questionnaire_question.dart';
import '../domain/questionnaire_session.dart';
import '../providers/questionnaire_catalog_admin_providers.dart';
import 'questionnaire_routes.dart';

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
    return AppScaffold(
      title: id == null ? 'Novo questionário' : 'Editor do questionário',
      subtitle: 'Rascunho, perguntas e publicação',
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
        Card(
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
            const Card(
                child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                        child: Text(
                            'Adicione ao menos uma pergunta para publicar.'))))
          else
            ...detail.questions.map((question) => Card(
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

  Widget _actionPanel(QuestionnaireCatalogDetail detail) {
    final editable = detail.isEditable;
    final approved = detail.questionnaire['clinical_status'] == 'approved';
    final editingNewVersion = editable && detail.isPublished;

    return Card(
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
    final input = await showDialog<_QuestionInput>(
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
          builder: (_) =>
              AlertDialog(title: Text(title), content: Text(body), actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
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
  const _QuestionDialog({this.question, required this.nextOrder});
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
  Widget build(BuildContext context) => AlertDialog(
          title: Text(
              widget.question == null ? 'Nova pergunta' : 'Editar pergunta'),
          content: SizedBox(
              width: 520,
              child: Form(
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
                  ])))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () {
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
                },
                child: const Text('Salvar'))
          ]);
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
