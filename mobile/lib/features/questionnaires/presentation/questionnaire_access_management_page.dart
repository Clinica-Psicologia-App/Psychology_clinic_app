import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../auth/providers/auth_providers.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/question_answer_type.dart';
import '../domain/questionnaire.dart';
import '../domain/questionnaire_access_item.dart';
import '../domain/questionnaire_professional_option.dart';
import '../domain/questionnaire_question.dart';
import '../providers/questionnaires_providers.dart';

class QuestionnaireAccessManagementPage extends ConsumerStatefulWidget {
  const QuestionnaireAccessManagementPage({super.key});

  @override
  ConsumerState<QuestionnaireAccessManagementPage> createState() =>
      _QuestionnaireAccessManagementPageState();
}

class _QuestionnaireAccessManagementPageState
    extends ConsumerState<QuestionnaireAccessManagementPage> {
  String? _selectedProfessionalId;
  bool _savingAccess = false;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Questionários',
      subtitle: 'Catálogo, edição e permissões',
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () {
            ref.invalidate(questionnaireAdminCatalogProvider);
            ref.invalidate(questionnaireStaffOptionsProvider);
            final professionalId = _selectedProfessionalId;
            if (professionalId != null) {
              ref.invalidate(
                questionnaireAccessManagementProvider(professionalId),
              );
            }
          },
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(
                  icon: Icon(Icons.fact_check_outlined),
                  text: 'Catálogo',
                ),
                Tab(
                  icon: Icon(Icons.assignment_ind_outlined),
                  text: 'Permissões',
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _QuestionnaireCatalogTab(
                    onEdit: (questionnaire) =>
                        _showQuestionnaireForm(questionnaire: questionnaire),
                    onQuestions: _showQuestionsManager,
                    onDelete: _confirmDeleteQuestionnaire,
                    onCreate: () => _showQuestionnaireForm(),
                  ),
                  _QuestionnaireAccessTab(
                    selectedProfessionalId: _selectedProfessionalId,
                    saving: _savingAccess,
                    onProfessionalChanged: (value) =>
                        setState(() => _selectedProfessionalId = value),
                    onToggleAccess: _toggleAccess,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showQuestionsManager(Questionnaire questionnaire) async {
    await showDialog<void>(
      context: context,
      builder: (context) =>
          _QuestionsManagerDialog(questionnaire: questionnaire),
    );
  }

  Future<void> _confirmDeleteQuestionnaire(Questionnaire questionnaire) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir questionário'),
        content: Text(
          'Deseja excluir definitivamente "${questionnaire.name}"?\n\n'
          'Use esta ação apenas para questionários cadastrados por engano. '
          'Se o instrumento já foi usado por pacientes, a exclusão será '
          'bloqueada para preservar histórico clínico. Nesse caso, edite o '
          'questionário e marque como inativo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(questionnairesRepositoryProvider)
          .deleteQuestionnaire(questionnaire.id);
      ref.invalidate(questionnaireAdminCatalogProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userMessageFor(mapToAppException(e)))),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Questionário excluído com sucesso.')),
    );
  }

  Future<void> _showQuestionnaireForm({Questionnaire? questionnaire}) async {
    final input = await showDialog<_QuestionnaireFormInput>(
      context: context,
      builder: (context) => _QuestionnaireFormDialog(
        questionnaire: questionnaire,
      ),
    );

    if (input == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          questionnaire == null
              ? 'Criando questionário...'
              : 'Atualizando questionário...',
        ),
      ),
    );

    try {
      final repo = ref.read(questionnairesRepositoryProvider);
      if (questionnaire == null) {
        await repo.createQuestionnaire(
          code: input.code,
          name: input.name,
          description: input.description,
          authorName: input.authorName,
          instrumentVersion: input.instrumentVersion,
          citation: input.citation,
          licenseNotes: input.licenseNotes,
          clinicalStatus: input.clinicalStatus,
          isActive: input.isActive,
        );
      } else {
        await repo.updateQuestionnaire(
          questionnaireId: questionnaire.id,
          code: input.code,
          name: input.name,
          description: input.description,
          authorName: input.authorName,
          instrumentVersion: input.instrumentVersion,
          citation: input.citation,
          licenseNotes: input.licenseNotes,
          clinicalStatus: input.clinicalStatus,
          isActive: input.isActive,
        );
      }
      ref.invalidate(questionnaireAdminCatalogProvider);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(userMessageFor(mapToAppException(e)))),
      );
      return;
    }

    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          questionnaire == null
              ? 'Questionário criado com sucesso.'
              : 'Questionário atualizado com sucesso.',
        ),
      ),
    );
  }

  Future<void> _toggleAccess(
    QuestionnaireAccessItem item,
    bool value,
  ) async {
    final professionalId = _selectedProfessionalId;
    if (professionalId == null) return;

    setState(() => _savingAccess = true);
    try {
      await ref.read(questionnairesRepositoryProvider).setQuestionnaireAccess(
            professionalId: professionalId,
            questionnaireId: item.questionnaire.id,
            isEnabled: value,
          );
      ref.invalidate(questionnaireAccessManagementProvider(professionalId));
    } finally {
      if (mounted) {
        setState(() => _savingAccess = false);
      }
    }
  }
}

class _QuestionnaireCatalogTab extends ConsumerWidget {
  const _QuestionnaireCatalogTab({
    required this.onEdit,
    required this.onQuestions,
    required this.onDelete,
    required this.onCreate,
  });

  final ValueChanged<Questionnaire> onEdit;
  final ValueChanged<Questionnaire> onQuestions;
  final ValueChanged<Questionnaire> onDelete;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(questionnaireAdminCatalogProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        AppPageHeader(
          icon: Icons.fact_check_outlined,
          title: 'Catálogo de questionários',
          subtitle:
              'Crie, edite, organize perguntas e controle o status clínico dos instrumentos. Permissões por psicólogo ficam na próxima aba.',
          primaryAction: FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Novo questionário'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AsyncStateBody(
          asyncValue: catalogAsync,
          onRetry: () => ref.invalidate(questionnaireAdminCatalogProvider),
          emptyMessage: 'Nenhum questionário cadastrado.',
          dataBuilder: (questionnaires) {
            final activeCount =
                questionnaires.where((item) => item.isActive).length;
            final validationCount = questionnaires
                .where((item) =>
                    item.clinicalStatus ==
                    QuestionnaireClinicalStatus.validation)
                .length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    StatusChip(
                      label: '${questionnaires.length} no catálogo',
                      tone: AppStatusTone.info,
                      icon: Icons.inventory_2_outlined,
                    ),
                    StatusChip(
                      label: '$activeCount ativos',
                      tone: AppStatusTone.success,
                      icon: Icons.check_circle_outline,
                    ),
                    if (validationCount > 0)
                      StatusChip(
                        label: '$validationCount em validação',
                        tone: AppStatusTone.warning,
                        icon: Icons.science_outlined,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                for (var i = 0; i < questionnaires.length; i++)
                  MotionReveal(
                    delay: staggerDelay(i),
                    child: _QuestionnaireCatalogTile(
                      questionnaire: questionnaires[i],
                      onEdit: () => onEdit(questionnaires[i]),
                      onQuestions: () => onQuestions(questionnaires[i]),
                      onDelete: () => onDelete(questionnaires[i]),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _QuestionnaireAccessTab extends ConsumerWidget {
  const _QuestionnaireAccessTab({
    required this.selectedProfessionalId,
    required this.saving,
    required this.onProfessionalChanged,
    required this.onToggleAccess,
  });

  final String? selectedProfessionalId;
  final bool saving;
  final ValueChanged<String?> onProfessionalChanged;
  final void Function(QuestionnaireAccessItem item, bool value) onToggleAccess;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authControllerProvider).valueOrNull;
    final staffAsync = ref.watch(questionnaireStaffOptionsProvider);
    final accessAsync = selectedProfessionalId == null
        ? null
        : ref.watch(
            questionnaireAccessManagementProvider(selectedProfessionalId!),
          );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const AppPageHeader(
          icon: Icons.psychology_alt_outlined,
          title: 'Permissões por psicólogo',
          subtitle:
              'Escolha um profissional e defina quais instrumentos ele pode aplicar. Esta aba não edita perguntas nem dados do catálogo.',
        ),
        const SizedBox(height: AppSpacing.md),
        staffAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text(
            'Não foi possível carregar os psicólogos.',
          ),
          data: (options) => _ProfessionalSelector(
            value: selectedProfessionalId,
            options: options,
            onChanged: onProfessionalChanged,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (selectedProfessionalId == null)
          const _SelectionHint()
        else if (accessAsync != null)
          AsyncStateBody(
            asyncValue: accessAsync,
            onRetry: () => ref.invalidate(
              questionnaireAccessManagementProvider(selectedProfessionalId!),
            ),
            emptyMessage: 'Nenhum questionário encontrado.',
            dataBuilder: (data) {
              final enabledCount =
                  data.items.where((item) => item.isEnabled).length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppInfoCard(
                    icon: Icons.assignment_ind_outlined,
                    title: 'Acesso do profissional selecionado',
                    body:
                        '$enabledCount de ${data.items.length} instrumento(s) liberado(s). Use os controles abaixo para permitir ou bloquear aplicação.',
                    tone: AppInfoCardTone.info,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (!data.supportsAccessControl)
                    Card(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text('Permissões indisponíveis'),
                        subtitle: Text(
                          'A listagem está em modo compatível até o banco receber a tabela de permissões.',
                        ),
                      ),
                    ),
                  for (var i = 0; i < data.items.length; i++)
                    MotionReveal(
                      delay: staggerDelay(i),
                      child: _AccessTile(
                        item: data.items[i],
                        enabled: data.supportsAccessControl && !saving,
                        showPendingLicense:
                            profile?.role == ProfileRole.platformAdmin,
                        onChanged: (value) => onToggleAccess(
                          data.items[i],
                          value,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _QuestionnaireCatalogTile extends StatelessWidget {
  const _QuestionnaireCatalogTile({
    required this.questionnaire,
    required this.onEdit,
    required this.onQuestions,
    required this.onDelete,
  });

  final Questionnaire questionnaire;
  final VoidCallback onEdit;
  final VoidCallback onQuestions;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final statusTone = switch (questionnaire.clinicalStatus) {
      QuestionnaireClinicalStatus.approved => AppStatusTone.success,
      QuestionnaireClinicalStatus.suspended => AppStatusTone.error,
      QuestionnaireClinicalStatus.draft => AppStatusTone.neutral,
      QuestionnaireClinicalStatus.validation => AppStatusTone.warning,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.moduleQuestionnaires.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: AppColors.moduleQuestionnaires,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        questionnaire.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navy,
                                ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xxs,
                        children: [
                          Text(
                            questionnaire.code,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          if (questionnaire.authorName != null &&
                              questionnaire.authorName!.trim().isNotEmpty)
                            Text(
                              'Autor: ${questionnaire.authorName}',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (questionnaire.description != null &&
                questionnaire.description!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                questionnaire.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                StatusChip(
                  label: questionnaire.isActive ? 'Ativo' : 'Inativo',
                  tone: questionnaire.isActive
                      ? AppStatusTone.success
                      : AppStatusTone.error,
                  icon: questionnaire.isActive
                      ? Icons.check_circle_outline
                      : Icons.pause_circle_outline,
                ),
                StatusChip(
                  label: questionnaire.clinicalStatus.label,
                  tone: statusTone,
                  icon: Icons.verified_outlined,
                ),
                if (questionnaire.instrumentVersion != null &&
                    questionnaire.instrumentVersion!.trim().isNotEmpty)
                  StatusChip(
                    label: 'Versão ${questionnaire.instrumentVersion}',
                    tone: AppStatusTone.info,
                    icon: Icons.sell_outlined,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar dados'),
                ),
                OutlinedButton.icon(
                  onPressed: onQuestions,
                  icon: const Icon(Icons.format_list_numbered_outlined),
                  label: const Text('Perguntas'),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Excluir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfessionalSelector extends StatelessWidget {
  const _ProfessionalSelector({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String? value;
  final List<QuestionnaireProfessionalOption> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Psicólogo',
        border: OutlineInputBorder(),
      ),
      items: options
          .map(
            (option) => DropdownMenuItem<String>(
              value: option.id,
              child: Text(option.displayLabel),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _SelectionHint extends StatelessWidget {
  const _SelectionHint();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.person_search_outlined),
        title: const Text('Selecione um psicólogo'),
        subtitle: Text(
          'A lista mostrará quais questionários esse profissional pode aplicar.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

class _AccessTile extends StatelessWidget {
  const _AccessTile({
    required this.item,
    required this.enabled,
    required this.showPendingLicense,
    required this.onChanged,
  });

  final QuestionnaireAccessItem item;
  final bool enabled;
  final bool showPendingLicense;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final questionnaire = item.questionnaire;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: (item.isEnabled ? AppColors.success : AppColors.disabled)
                    .withValues(alpha: 0.12),
                borderRadius: AppRadius.mdAll,
              ),
              child: Icon(
                item.isEnabled ? Icons.lock_open_outlined : Icons.lock_outline,
                color: item.isEnabled ? AppColors.success : AppColors.disabled,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          questionnaire.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navy,
                                  ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      StatusChip(
                        label: item.isEnabled ? 'Liberado' : 'Bloqueado',
                        tone: item.isEnabled
                            ? AppStatusTone.success
                            : AppStatusTone.neutral,
                        icon: item.isEnabled
                            ? Icons.check_circle_outline
                            : Icons.block_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Código: ${questionnaire.code}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  if (questionnaire.authorName != null &&
                      questionnaire.authorName!.trim().isNotEmpty)
                    Text(
                      'Autor: ${questionnaire.authorName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  if (questionnaire.instrumentVersion != null &&
                      questionnaire.instrumentVersion!.trim().isNotEmpty)
                    Text(
                      'Versão: ${questionnaire.instrumentVersion}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  if (showPendingLicense &&
                      questionnaire.licenseNotes != null &&
                      questionnaire.licenseNotes!.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      questionnaire.licenseNotes!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: questionnaire.hasLicensePendingValidation
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Switch(
              value: item.isEnabled,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionnaireFormInput {
  const _QuestionnaireFormInput({
    required this.code,
    required this.name,
    this.description,
    this.authorName,
    this.instrumentVersion,
    this.citation,
    this.licenseNotes,
    required this.clinicalStatus,
    required this.isActive,
  });

  final String code;
  final String name;
  final String? description;
  final String? authorName;
  final String? instrumentVersion;
  final String? citation;
  final String? licenseNotes;
  final QuestionnaireClinicalStatus clinicalStatus;
  final bool isActive;
}

class _QuestionnaireFormDialog extends StatefulWidget {
  const _QuestionnaireFormDialog({this.questionnaire});

  final Questionnaire? questionnaire;

  @override
  State<_QuestionnaireFormDialog> createState() =>
      _QuestionnaireFormDialogState();
}

class _QuestionnaireFormDialogState extends State<_QuestionnaireFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _authorController;
  late final TextEditingController _versionController;
  late final TextEditingController _citationController;
  late final TextEditingController _licenseController;
  late QuestionnaireClinicalStatus _clinicalStatus;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final questionnaire = widget.questionnaire;
    _codeController = TextEditingController(text: questionnaire?.code ?? '');
    _nameController = TextEditingController(text: questionnaire?.name ?? '');
    _descriptionController =
        TextEditingController(text: questionnaire?.description ?? '');
    _authorController =
        TextEditingController(text: questionnaire?.authorName ?? '');
    _versionController =
        TextEditingController(text: questionnaire?.instrumentVersion ?? '');
    _citationController =
        TextEditingController(text: questionnaire?.citation ?? '');
    _licenseController =
        TextEditingController(text: questionnaire?.licenseNotes ?? '');
    _clinicalStatus =
        questionnaire?.clinicalStatus ?? QuestionnaireClinicalStatus.draft;
    _isActive = questionnaire?.isActive ?? false;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _authorController.dispose();
    _versionController.dispose();
    _citationController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.questionnaire != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar questionário' : 'Novo questionário'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Código',
                    hintText: 'YSQ_S3',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do questionário',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _authorController,
                  decoration: const InputDecoration(labelText: 'Autor'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _versionController,
                  decoration: const InputDecoration(labelText: 'Versão'),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<QuestionnaireClinicalStatus>(
                  initialValue: _clinicalStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status clínico',
                  ),
                  items: QuestionnaireClinicalStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _clinicalStatus = value);
                    }
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isActive,
                  title: const Text('Questionário ativo'),
                  onChanged: (value) => setState(() => _isActive = value),
                ),
                TextFormField(
                  controller: _citationController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Referência / citação',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _licenseController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Observações de licença',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  String? _required(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? 'Campo obrigatório' : null;
  }

  String? _nullableText(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;

    Navigator.of(context).pop(
      _QuestionnaireFormInput(
        code: _codeController.text.trim(),
        name: _nameController.text.trim(),
        description: _nullableText(_descriptionController),
        authorName: _nullableText(_authorController),
        instrumentVersion: _nullableText(_versionController),
        citation: _nullableText(_citationController),
        licenseNotes: _nullableText(_licenseController),
        clinicalStatus: _clinicalStatus,
        isActive: _isActive,
      ),
    );
  }
}

class _QuestionsManagerDialog extends ConsumerWidget {
  const _QuestionsManagerDialog({required this.questionnaire});

  final Questionnaire questionnaire;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync =
        ref.watch(questionnaireAdminQuestionsProvider(questionnaire.id));

    return AlertDialog(
      title: Text('Perguntas - ${questionnaire.code}'),
      content: SizedBox(
        width: 640,
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => _showQuestionForm(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Nova pergunta'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: AsyncStateBody(
                asyncValue: questionsAsync,
                onRetry: () => ref.invalidate(
                  questionnaireAdminQuestionsProvider(questionnaire.id),
                ),
                emptyMessage: 'Nenhuma pergunta cadastrada.',
                dataBuilder: (questions) => ListView.builder(
                  itemCount: questions.length,
                  itemBuilder: (context, index) => _QuestionTile(
                    question: questions[index],
                    onEdit: () => _showQuestionForm(
                      context,
                      ref,
                      question: questions[index],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }

  Future<void> _showQuestionForm(
    BuildContext context,
    WidgetRef ref, {
    QuestionnaireQuestion? question,
  }) async {
    final input = await showDialog<_QuestionFormInput>(
      context: context,
      builder: (context) => _QuestionFormDialog(question: question),
    );

    if (input == null || !context.mounted) return;

    try {
      final repo = ref.read(questionnairesRepositoryProvider);
      if (question == null) {
        await repo.createQuestion(
          questionnaireId: questionnaire.id,
          code: input.code,
          text: input.text,
          orderIndex: input.orderIndex,
          answerType: input.answerType,
          scaleMin: input.scaleMin,
          scaleMax: input.scaleMax,
        );
      } else {
        await repo.updateQuestion(
          questionId: question.id,
          questionnaireId: questionnaire.id,
          code: input.code,
          text: input.text,
          orderIndex: input.orderIndex,
          answerType: input.answerType,
          scaleMin: input.scaleMin,
          scaleMax: input.scaleMax,
        );
      }
      ref.invalidate(questionnaireAdminQuestionsProvider(questionnaire.id));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userMessageFor(mapToAppException(e)))),
      );
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          question == null
              ? 'Pergunta criada com sucesso.'
              : 'Pergunta atualizada com sucesso.',
        ),
      ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({
    required this.question,
    required this.onEdit,
  });

  final QuestionnaireQuestion question;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.cyan.withValues(alpha: 0.12),
          foregroundColor: AppColors.cyan,
          child: Text('${question.orderIndex}'),
        ),
        title: Text(question.text),
        subtitle: Text(
          '${question.code} · ${_answerTypeLabel(question.answerType)}'
          '${question.scaleMin != null && question.scaleMax != null ? ' · ${question.scaleMin}-${question.scaleMax}' : ''}',
        ),
        trailing: IconButton(
          tooltip: 'Editar pergunta',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
      ),
    );
  }
}

class _QuestionFormInput {
  const _QuestionFormInput({
    required this.code,
    required this.text,
    required this.orderIndex,
    required this.answerType,
    this.scaleMin,
    this.scaleMax,
  });

  final String code;
  final String text;
  final int orderIndex;
  final QuestionAnswerType answerType;
  final int? scaleMin;
  final int? scaleMax;
}

class _QuestionFormDialog extends StatefulWidget {
  const _QuestionFormDialog({this.question});

  final QuestionnaireQuestion? question;

  @override
  State<_QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends State<_QuestionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _textController;
  late final TextEditingController _orderController;
  late final TextEditingController _scaleMinController;
  late final TextEditingController _scaleMaxController;
  late QuestionAnswerType _answerType;

  @override
  void initState() {
    super.initState();
    final question = widget.question;
    _codeController = TextEditingController(text: question?.code ?? '');
    _textController = TextEditingController(text: question?.text ?? '');
    _orderController =
        TextEditingController(text: question?.orderIndex.toString() ?? '1');
    _scaleMinController =
        TextEditingController(text: question?.scaleMin?.toString() ?? '1');
    _scaleMaxController =
        TextEditingController(text: question?.scaleMax?.toString() ?? '6');
    _answerType = question?.answerType ?? QuestionAnswerType.likertScale;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _textController.dispose();
    _orderController.dispose();
    _scaleMinController.dispose();
    _scaleMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.question != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar pergunta' : 'Nova pergunta'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(labelText: 'Código'),
                  validator: _required,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _textController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Texto'),
                  validator: _required,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _orderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Ordem'),
                  validator: _integerRequired,
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<QuestionAnswerType>(
                  initialValue: _answerType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de resposta',
                  ),
                  items: QuestionAnswerType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(_answerTypeLabel(type)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _answerType = value);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _scaleMinController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Escala mínima'),
                        validator: _optionalInteger,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _scaleMaxController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Escala máxima'),
                        validator: _optionalInteger,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  String? _required(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? 'Campo obrigatório' : null;
  }

  String? _integerRequired(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Campo obrigatório';
    final parsed = int.tryParse(text);
    return parsed == null || parsed < 0 ? 'Informe um número válido' : null;
  }

  String? _optionalInteger(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    return int.tryParse(text) == null ? 'Informe um número válido' : null;
  }

  int? _optionalInt(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : int.parse(text);
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;

    final scaleMin = _optionalInt(_scaleMinController);
    final scaleMax = _optionalInt(_scaleMaxController);
    if (scaleMin != null && scaleMax != null && scaleMin > scaleMax) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A escala mínima deve ser menor.')),
      );
      return;
    }

    Navigator.of(context).pop(
      _QuestionFormInput(
        code: _codeController.text.trim(),
        text: _textController.text.trim(),
        orderIndex: int.parse(_orderController.text.trim()),
        answerType: _answerType,
        scaleMin: scaleMin,
        scaleMax: scaleMax,
      ),
    );
  }
}

String _answerTypeLabel(QuestionAnswerType type) {
  return switch (type) {
    QuestionAnswerType.likertScale => 'Likert',
    QuestionAnswerType.numericScale => 'Escala numérica',
    QuestionAnswerType.singleChoice => 'Escolha única',
    QuestionAnswerType.text => 'Texto',
  };
}
