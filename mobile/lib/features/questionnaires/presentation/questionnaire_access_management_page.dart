import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../auth/providers/auth_providers.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/questionnaire_access_item.dart';
import '../domain/questionnaire_professional_option.dart';
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
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authControllerProvider).valueOrNull;
    final staffAsync = ref.watch(questionnaireStaffOptionsProvider);
    final accessAsync = _selectedProfessionalId == null
        ? null
        : ref.watch(
            questionnaireAccessManagementProvider(_selectedProfessionalId!));

    return AppScaffold(
      title: 'Acesso a questionários',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Controle quais instrumentos cada profissional pode visualizar e aplicar.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          staffAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text(
              'Não foi possível carregar os profissionais da clínica.',
            ),
            data: (options) => _ProfessionalSelector(
              value: _selectedProfessionalId,
              options: options,
              onChanged: (value) =>
                  setState(() => _selectedProfessionalId = value),
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedProfessionalId == null)
            const _SelectionHint()
          else if (accessAsync != null)
            AsyncStateBody(
              asyncValue: accessAsync,
              onRetry: () => ref.invalidate(
                questionnaireAccessManagementProvider(_selectedProfessionalId!),
              ),
              emptyMessage: 'Nenhum questionário encontrado.',
              dataBuilder: (data) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!data.supportsAccessControl)
                      Card(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: const ListTile(
                          leading: Icon(Icons.info_outline),
                          title: Text('Controle de acesso indisponível'),
                          subtitle: Text(
                            'Disponível após atualização do banco. A listagem atual continua funcionando em modo compatível.',
                          ),
                        ),
                      ),
                    ...data.items.map(
                      (item) => _AccessTile(
                        item: item,
                        enabled: data.supportsAccessControl && !_saving,
                        showPendingLicense:
                            profile?.role == ProfileRole.platformAdmin,
                        onChanged: (value) => _toggleAccess(
                          item,
                          value,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _toggleAccess(
    QuestionnaireAccessItem item,
    bool value,
  ) async {
    final professionalId = _selectedProfessionalId;
    if (professionalId == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(questionnairesRepositoryProvider).setQuestionnaireAccess(
            professionalId: professionalId,
            questionnaireId: item.questionnaire.id,
            isEnabled: value,
          );
      ref.invalidate(questionnaireAccessManagementProvider(professionalId));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
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
        labelText: 'Profissional',
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
        title: const Text('Selecione um profissional'),
        subtitle: Text(
          'Após escolher um profissional, a tela exibirá os questionários liberados para ele.',
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
      margin: const EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        value: item.isEnabled,
        onChanged: enabled ? onChanged : null,
        title: Text(questionnaire.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Código: ${questionnaire.code}'),
            if (questionnaire.authorName != null &&
                questionnaire.authorName!.trim().isNotEmpty)
              Text('Autor: ${questionnaire.authorName}'),
            if (questionnaire.instrumentVersion != null &&
                questionnaire.instrumentVersion!.trim().isNotEmpty)
              Text('Versão: ${questionnaire.instrumentVersion}'),
            if (showPendingLicense &&
                questionnaire.licenseNotes != null &&
                questionnaire.licenseNotes!.trim().isNotEmpty)
              Text(
                questionnaire.licenseNotes!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: questionnaire.hasLicensePendingValidation
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}
