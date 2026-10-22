import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../auth/providers/auth_providers.dart';
import '../../mental_map/domain/case_conceptualization.dart';
import '../../mental_map/domain/demands_text_history.dart';
import '../../mental_map/providers/case_conceptualization_providers.dart';
import '../../patient_problems/domain/patient_problem.dart';
import '../../patient_problems/domain/patient_problem_status.dart';
import '../../patient_problems/presentation/patient_problem_routes.dart';
import '../../patient_problems/providers/patient_problems_providers.dart';
import '../../patients/presentation/widgets/patient_context_header.dart';
import '../../patients/providers/patients_providers.dart';
import '../../profile/domain/profile_role.dart';

/// Nome de quem está gravando (autoria dos registros diagnósticos e das
/// versões anteriores dos textos). Substituível em testes.
final therapyDemandsAuthorNameProvider = Provider<String?>((ref) {
  return ref.read(authControllerProvider).valueOrNull?.fullName;
});

String _two(int n) => n.toString().padLeft(2, '0');
String _fmtDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';
String _fmtDateTime(DateTime d) =>
    '${_fmtDate(d)} ${_two(d.hour)}:${_two(d.minute)}';
String _isoDate(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';
String? _fmtIsoDate(String? iso) {
  final d = DateTime.tryParse(iso ?? '');
  return d == null ? null : _fmtDate(d);
}

String? _fmtStamp(String? iso) {
  final d = DateTime.tryParse(iso ?? '')?.toLocal();
  return d == null ? null : _fmtDateTime(d);
}

/// Demandas terapêuticas (bloco Conhecer): motivos da terapia, impressões
/// clínicas e perspectiva diagnóstica — itens 2, 3 e 4 da conceitualização.
/// Cada aba salva sozinha; a Síntese, o Mapa e o infográfico leem destes campos.
class TherapyDemandsPage extends ConsumerStatefulWidget {
  const TherapyDemandsPage({
    super.key,
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  ConsumerState<TherapyDemandsPage> createState() => _TherapyDemandsPageState();
}

class _TherapyDemandsPageState extends ConsumerState<TherapyDemandsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  final _reasonsInitial = TextEditingController();
  final _reasonsCurrent = TextEditingController();
  final _impInitial = TextEditingController();
  final _impCurrent = TextEditingController();

  // Estado salvo (base para detectar alterações não salvas).
  String _baseReasonsInitial = '';
  String _baseReasonsCurrent = '';
  String _baseImpInitial = '';
  String _baseImpCurrent = '';
  Diagnosis _baseDx = const Diagnosis();
  String _baseDxSig = '';

  final List<_DxDraft> _dx = [];
  bool _noDx = false;
  String? _dxError;
  DateTime? _updatedAt;

  bool _initialized = false;
  bool _leaving = false;
  bool _savingReasons = false;
  bool _savingImpressions = false;
  bool _savingDx = false;
  CaseConceptualization? _loaded;

  String get _pid => widget.patientId;

  @override
  void dispose() {
    _tabs.dispose();
    for (final c in [
      _reasonsInitial,
      _reasonsCurrent,
      _impInitial,
      _impCurrent
    ]) {
      c.dispose();
    }
    for (final d in _dx) {
      d.dispose();
    }
    super.dispose();
  }

  // ── Estado ────────────────────────────────────────────────────────────────

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _initFrom(CaseConceptualization data) {
    if (_initialized) return;
    _loaded = data;
    _updatedAt = data.updatedAt;

    _reasonsInitial.text = data.motivoInitial ?? '';
    _reasonsCurrent.text = data.motivoCurrent ?? '';
    _impInitial.text = data.generalImpressions.initial ?? '';
    _impCurrent.text = data.generalImpressions.current ?? '';
    _baseReasonsInitial = (data.motivoInitial ?? '').trim();
    _baseReasonsCurrent = (data.motivoCurrent ?? '').trim();
    _baseImpInitial = (data.generalImpressions.initial ?? '').trim();
    _baseImpCurrent = (data.generalImpressions.current ?? '').trim();
    for (final c in [
      _reasonsInitial,
      _reasonsCurrent,
      _impInitial,
      _impCurrent
    ]) {
      c.addListener(_onChanged);
    }

    _applyDiagnosisBaseline(data.diagnosis);
    _initialized = true;
  }

  void _applyDiagnosisBaseline(Diagnosis dx) {
    final old = [..._dx];
    _dx
      ..clear()
      ..addAll([
        for (final it in dx.items)
          if (!it.isEmpty) _DxDraft.fromItem(it, dx.system, _onChanged),
      ]);
    for (final d in old) {
      WidgetsBinding.instance.addPostFrameCallback((_) => d.dispose());
    }
    _noDx = dx.noDiagnosis;
    _baseDx = dx;
    _baseDxSig = _dxSignature();
  }

  String _dxSignature() => jsonEncode([
        _noDx,
        [
          for (final d in _dx)
            if (!d.isBlank)
              [
                d.id,
                d.system,
                d.nameCtrl.text.trim(),
                d.codeCtrl.text.trim(),
                d.status?.key,
                d.notesCtrl.text.trim(),
                d.reviewedOn,
              ],
        ],
      ]);

  bool get _reasonsDirty =>
      _reasonsInitial.text.trim() != _baseReasonsInitial ||
      _reasonsCurrent.text.trim() != _baseReasonsCurrent;
  bool get _impressionsDirty =>
      _impInitial.text.trim() != _baseImpInitial ||
      _impCurrent.text.trim() != _baseImpCurrent;
  bool get _dxDirty => _initialized && _dxSignature() != _baseDxSig;
  bool get _anyDirty => _reasonsDirty || _impressionsDirty || _dxDirty;

  String? get _author => ref.read(therapyDemandsAuthorNameProvider);

  void _afterSave() {
    _updatedAt = DateTime.now();
    ref.invalidate(caseConceptualizationProvider(_pid));
    ref.invalidate(demandsTextHistoryProvider(_pid));
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ── Salvar (cada aba é independente) ──────────────────────────────────────

  Future<void> _saveReasons() async {
    setState(() => _savingReasons = true);
    try {
      await ref.read(caseConceptualizationRepositoryProvider).saveReasons(
            _pid,
            initial: _reasonsInitial.text,
            current: _reasonsCurrent.text,
            previousInitial: _baseReasonsInitial,
            previousCurrent: _baseReasonsCurrent,
            authorName: _author,
          );
      _baseReasonsInitial = _reasonsInitial.text.trim();
      _baseReasonsCurrent = _reasonsCurrent.text.trim();
      _afterSave();
      if (!mounted) return;
      _snack('Motivos da terapia salvos.');
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _savingReasons = false);
    }
  }

  Future<void> _saveImpressions() async {
    setState(() => _savingImpressions = true);
    try {
      await ref.read(caseConceptualizationRepositoryProvider).saveImpressions(
            _pid,
            GeneralImpressions(
              initial: _impInitial.text,
              current: _impCurrent.text,
            ),
            previous: GeneralImpressions(
              initial: _baseImpInitial,
              current: _baseImpCurrent,
            ),
            authorName: _author,
          );
      _baseImpInitial = _impInitial.text.trim();
      _baseImpCurrent = _impCurrent.text.trim();
      _afterSave();
      if (!mounted) return;
      _snack('Impressões clínicas salvas.');
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _savingImpressions = false);
    }
  }

  String? _validateDx() {
    for (var i = 0; i < _dx.length; i++) {
      final d = _dx[i];
      if (d.isBlank) continue;
      final n = i + 1;
      if (d.nameCtrl.text.trim().isEmpty) {
        return 'Informe o diagnóstico ou a hipótese no registro $n.';
      }
      if (d.system == null) {
        return 'Selecione o sistema (CID-11 ou DSM-5-TR) no registro $n.';
      }
      if (d.status == null) {
        return 'Selecione a situação (em investigação ou estabelecido) no registro $n.';
      }
    }
    return _buildDiagnosis().conflictError;
  }

  Diagnosis _buildDiagnosis() => Diagnosis(
        system: _baseDx.system,
        noDiagnosis: _noDx,
        items: [
          for (final d in _dx)
            if (!d.isBlank) d.toItem(),
        ],
      );

  Future<void> _saveDiagnosis() async {
    final error = _validateDx();
    setState(() => _dxError = error);
    if (error != null) return;
    setState(() => _savingDx = true);
    try {
      final stored =
          await ref.read(caseConceptualizationRepositoryProvider).saveDiagnosis(
                _pid,
                _buildDiagnosis(),
                previous: _baseDx,
                authorName: _author,
              );
      _applyDiagnosisBaseline(stored);
      _afterSave();
      if (!mounted) return;
      _snack('Perspectiva diagnóstica salva.');
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _savingDx = false);
    }
  }

  // ── Sair com alterações ───────────────────────────────────────────────────

  Future<bool> _confirmDiscard() async {
    final pending = [
      if (_reasonsDirty) 'Motivos da terapia',
      if (_impressionsDirty) 'Impressões clínicas',
      if (_dxDirty) 'Perspectiva diagnóstica',
    ];
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair sem salvar?'),
        content: Text(
          'Há alterações não salvas em: ${pending.join(', ')}. '
          'Se sair agora, elas serão perdidas.',
        ),
        actions: [
          TextButton(
            key: const Key('demands_keep_editing'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continuar editando'),
          ),
          TextButton(
            key: const Key('demands_discard'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sair sem salvar'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  Future<void> _handleBack() async {
    if (!_anyDirty) {
      Navigator.of(context).maybePop();
      return;
    }
    if (await _confirmDiscard() && mounted) {
      setState(() => _leaving = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(caseConceptualizationProvider(_pid));
    // Depois do primeiro carregamento, recargas em segundo plano (invalidate)
    // não devem trocar a tela por um loader nem derrubar o foco do teclado.
    final value = _initialized && _loaded != null
        ? AsyncValue<CaseConceptualization>.data(_loaded!)
        : async;

    return PopScope(
      canPop: _leaving || !_anyDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBack();
      },
      child: AppCanopyScaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PatientContextHeader(
                patientId: _pid,
                pageTitle: 'DEMANDAS TERAPÊUTICAS',
                role: widget.role,
                accentColor: AppColors.cyan,
                onBack: _handleBack,
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: true,
              child: AsyncStateBody<CaseConceptualization>(
                asyncValue: value,
                onRetry: () =>
                    ref.invalidate(caseConceptualizationProvider(_pid)),
                dataBuilder: (data) {
                  _initFrom(data);
                  return _content(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Icon(Icons.schedule,
                  size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _updatedAt == null
                      ? 'Ainda sem registros salvos'
                      : 'Última atualização: ${_fmtDateTime(_updatedAt!)}',
                  key: const Key('demands_last_update'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: theme.colorScheme.onSurface,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: AppColors.cyan,
          tabs: [
            _tab('Motivos da terapia', _reasonsDirty),
            _tab('Impressões clínicas', _impressionsDirty),
            _tab('Perspectiva diagnóstica', _dxDirty),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _reasonsTab(context),
              _impressionsTab(context),
              _diagnosisTab(context),
            ],
          ),
        ),
      ],
    );
  }

  Tab _tab(String label, bool dirty) => Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (dirty) ...[
              const SizedBox(width: 6),
              const Icon(Icons.circle, size: 8, color: AppColors.warning),
            ],
          ],
        ),
      );

  // ── Abas de texto ─────────────────────────────────────────────────────────

  Widget _reasonsTab(BuildContext context) {
    return _TabScaffold(
      body: [
        _TextBlock(
          fieldKey: const Key('demands_reasons_initial'),
          controller: _reasonsInitial,
          label: 'Motivos iniciais da procura por terapia',
          guidance:
              'O que trouxe o paciente à terapia? Descreva dificuldades, sintomas, emoções, comportamentos, circunstâncias de vida e acontecimentos relevantes.',
          example:
              'Exemplo fictício: procurou terapia após uma separação, relatando ansiedade e dificuldades para dormir.',
          history: _history(DemandsTextField.reasonsInitial),
        ),
        _TextBlock(
          fieldKey: const Key('demands_reasons_current'),
          controller: _reasonsCurrent,
          label: 'Motivos atuais para permanecer em terapia',
          guidance:
              'Quais dificuldades ou circunstâncias mantêm a necessidade de acompanhamento atualmente? O que mudou desde o início?',
          example:
              'Exemplo fictício: atualmente, busca compreender padrões nas relações e lidar com dificuldades de expressão das próprias necessidades.',
          history: _history(DemandsTextField.reasonsCurrent),
        ),
        _legacySection(context),
      ],
      saveKey: const Key('demands_save_reasons'),
      saveLabel: 'Salvar motivos',
      dirty: _reasonsDirty,
      saving: _savingReasons,
      onSave: _saveReasons,
    );
  }

  Widget _impressionsTab(BuildContext context) {
    return _TabScaffold(
      body: [
        const _InfoNote(
          'Descreve a apresentação global do paciente. O vínculo terapêutico e as '
          'estratégias de mudança ficam nos espaços próprios do caso.',
        ),
        _TextBlock(
          fieldKey: const Key('demands_impressions_initial'),
          controller: _impInitial,
          label: 'Impressões iniciais',
          guidance:
              'Como o paciente se apresentava nas primeiras sessões? Descreva em linguagem cotidiana sua postura, expressão emocional, espontaneidade e forma de se comunicar.',
          example:
              'Exemplo fictício: apresentava-se reservada e preocupada em dar respostas corretas.',
          history: _history(DemandsTextField.impressionsInitial),
        ),
        _TextBlock(
          fieldKey: const Key('demands_impressions_current'),
          controller: _impCurrent,
          label: 'Impressões atuais',
          guidance:
              'Como o paciente se apresenta atualmente? Quais mudanças são percebidas em relação ao início?',
          example:
              'Exemplo fictício: atualmente, comunica opiniões com mais liberdade, embora ainda tenha dificuldade para demonstrar descontentamento.',
          history: _history(DemandsTextField.impressionsCurrent),
        ),
      ],
      saveKey: const Key('demands_save_impressions'),
      saveLabel: 'Salvar impressões',
      dirty: _impressionsDirty,
      saving: _savingImpressions,
      onSave: _saveImpressions,
    );
  }

  List<TextRevision> _history(String field) => ref
      .watch(demandsTextHistoryProvider(_pid))
      .maybeWhen(data: (h) => h.revisionsOf(field), orElse: () => const []);

  // ── Registros anteriores (demandas cadastradas antes desta tela) ──────────

  Widget _legacySection(BuildContext context) {
    final theme = Theme.of(context);
    final patient = ref.watch(patientDetailProvider(_pid)).valueOrNull;
    final problems = ref
            .watch(staffPatientProblemsProvider(
              StaffPatientProblemsContext(role: widget.role, patientId: _pid),
            ))
            .valueOrNull ??
        const <PatientProblem>[];
    final legacyText = (patient?.therapyDemands ?? '').trim();
    if (legacyText.isEmpty && problems.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      child: ClayCard(
        margin: EdgeInsets.zero,
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: const Key('demands_legacy_section'),
            initiallyExpanded: false,
            leading: const Icon(Icons.history, color: AppColors.cyan),
            title: Text('Registros anteriores',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            subtitle: const Text(
                'Demandas e focos já cadastrados. Consulte para preencher os textos acima.'),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (legacyText.isNotEmpty)
                _LegacyEntry(
                  title: 'Demandas informadas no cadastro',
                  body: legacyText,
                  onUseInitial: () => _appendTo(_reasonsInitial, legacyText),
                  onUseCurrent: () => _appendTo(_reasonsCurrent, legacyText),
                ),
              for (final p in problems)
                _LegacyEntry(
                  title: p.title,
                  chip: p.status.label,
                  body: (p.description ?? '').trim(),
                  onUseInitial: () =>
                      _appendTo(_reasonsInitial, _problemText(p)),
                  onUseCurrent: () =>
                      _appendTo(_reasonsCurrent, _problemText(p)),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.push(PatientProblemRoutes.staffList(
                      role: widget.role, patientId: _pid)),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Abrir lista completa de demandas'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _problemText(PatientProblem p) {
    final d = (p.description ?? '').trim();
    return d.isEmpty ? p.title : '${p.title}: $d';
  }

  /// Insere o texto de apoio no campo, sem apagar o que já foi escrito e sem
  /// copiar nada automaticamente.
  void _appendTo(TextEditingController c, String text) {
    final cur = c.text.trimRight();
    c.text = cur.isEmpty ? text : '$cur\n$text';
    c.selection = TextSelection.collapsed(offset: c.text.length);
  }

  // ── Aba diagnóstica ───────────────────────────────────────────────────────

  Widget _diagnosisTab(BuildContext context) {
    final theme = Theme.of(context);
    final String state;
    if (_noDx) {
      state = 'Marcado: sem diagnóstico estabelecido no momento.';
    } else if (_dx.where((d) => !d.isBlank).isEmpty) {
      state = 'Aba ainda não avaliada.';
    } else {
      final n = _dx.where((d) => !d.isBlank).length;
      state = n == 1 ? '1 registro.' : '$n registros.';
    }

    return _TabScaffold(
      body: [
        const _InfoNote(
          'Registre diagnósticos e hipóteses conforme a sua avaliação. O app não '
          'sugere nem infere diagnósticos a partir dos demais campos ou dos questionários.',
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(state,
              key: const Key('demands_dx_state'),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              )),
        ),
        CheckboxListTile(
          key: const Key('demands_no_dx'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _noDx,
          onChanged: (v) => setState(() => _noDx = v ?? false),
          title: const Text('Sem diagnóstico estabelecido no momento'),
          subtitle: const Text(
              'Pode coexistir com hipóteses em investigação, mas não com um diagnóstico estabelecido.'),
        ),
        for (var i = 0; i < _dx.length; i++) _dxCard(context, i, _dx[i]),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const Key('demands_add_dx'),
            onPressed: () =>
                setState(() => _dx.add(_DxDraft.blank(_onChanged))),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar diagnóstico ou hipótese'),
          ),
        ),
        if (_baseDx.removed.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _showRemoved(context),
              icon: const Icon(Icons.inventory_2_outlined, size: 16),
              label: Text('Registros removidos (${_baseDx.removed.length})'),
            ),
          ),
      ],
      saveKey: const Key('demands_save_dx'),
      errorKey: const Key('demands_dx_error'),
      errorText: _dxError,
      saveLabel: 'Salvar perspectiva diagnóstica',
      dirty: _dxDirty,
      saving: _savingDx,
      onSave: _saveDiagnosis,
    );
  }

  Widget _dxCard(BuildContext context, int index, _DxDraft d) {
    final theme = Theme.of(context);
    final meta = [
      if ((d.updatedByName ?? '').isNotEmpty) 'por ${d.updatedByName}',
      if (_fmtStamp(d.updatedAt) != null) 'em ${_fmtStamp(d.updatedAt)}',
    ].join(' ');

    return ClayCard(
      key: ValueKey(d.id),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Registro ${index + 1}',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  tooltip: 'Remover registro',
                  onPressed: () => setState(() {
                    final removed = _dx.removeAt(index);
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => removed.dispose());
                  }),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            Text('Sistema de referência', style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                for (final s in kDiagnosisSystems)
                  ChoiceChip(
                    label: Text(s),
                    selected: d.system == s,
                    onSelected: (sel) =>
                        setState(() => d.system = sel ? s : null),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: Key('demands_dx_name_$index'),
              controller: d.nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoration(context, 'Diagnóstico ou hipótese *'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: Key('demands_dx_code_$index'),
              controller: d.codeCtrl,
              decoration: _decoration(context, 'Código',
                  hint: 'Deixe em branco se ainda pendente'),
            ),
            const SizedBox(height: 12),
            Text('Situação da avaliação', style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                for (final s in DiagnosisStatus.values)
                  ChoiceChip(
                    label: Text(s.label),
                    selected: d.status == s,
                    onSelected: (sel) =>
                        setState(() => d.status = sel ? s : null),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: Key('demands_dx_notes_$index'),
              controller: d.notesCtrl,
              minLines: 2,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoration(
                  context, 'Observações clínicas (opcional)',
                  hint: 'Fundamentação, dúvidas e informações relevantes'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Data da revisão: ${_fmtIsoDate(d.reviewedOn) ?? 'não informada'}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.tryParse(d.reviewedOn ?? '') ??
                          DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (picked != null) {
                      setState(() => d.reviewedOn = _isoDate(picked));
                    }
                  },
                  child: const Text('Alterar'),
                ),
              ],
            ),
            if (meta.isNotEmpty)
              Text('Atualizado $meta',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            if (d.revisions.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _showRevisions(context, d),
                  icon: const Icon(Icons.history, size: 16),
                  label: Text('Revisões anteriores (${d.revisions.length})'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showRevisions(BuildContext context, _DxDraft d) {
    _showSheet(
      context,
      title: 'Revisões anteriores',
      children: [
        for (final r in d.revisions) _revisionTile(context, r),
      ],
    );
  }

  void _showRemoved(BuildContext context) {
    _showSheet(
      context,
      title: 'Registros removidos',
      children: [
        for (final r in _baseDx.removed) _revisionTile(context, r),
      ],
    );
  }

  Widget _revisionTile(BuildContext context, DiagnosisItem r) {
    final theme = Theme.of(context);
    final lines = [
      if ((r.name ?? '').trim().isNotEmpty) r.name!.trim(),
      if ((r.code ?? '').trim().isNotEmpty) '(${r.code!.trim()})',
    ].join(' ');
    final meta = r.metaLine();
    final when = _fmtStamp(r.updatedAt);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(lines.isEmpty ? 'Registro' : lines),
      subtitle: Text([
        if (meta != null) meta,
        if ((r.notes ?? '').trim().isNotEmpty) r.notes!.trim(),
        if (when != null)
          'Registrado em $when${(r.updatedByName ?? '').isEmpty ? '' : ' por ${r.updatedByName}'}',
      ].join('\n')),
      isThreeLine: true,
      titleTextStyle:
          theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  void _showSheet(BuildContext context,
      {required String title, required List<Widget> children}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.7),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            shrinkWrap: true,
            children: [
              Text(title,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _decoration(BuildContext context, String label,
    {String? hint, String? helper}) {
  final theme = Theme.of(context);
  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helper,
    helperMaxLines: 4,
    filled: true,
    fillColor: theme.colorScheme.surfaceContainerLow,
    isDense: true,
    alignLabelWithHint: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.colorScheme.outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.cyan, width: 1.5),
    ),
  );
}

/// Conteúdo rolável de uma aba + barra de salvar própria (cada aba salva
/// sem exigir as demais).
class _TabScaffold extends StatelessWidget {
  const _TabScaffold({
    required this.body,
    required this.saveKey,
    required this.saveLabel,
    required this.dirty,
    required this.saving,
    required this.onSave,
    this.errorText,
    this.errorKey,
  });

  final List<Widget> body;
  final String? errorText;
  final Key? errorKey;
  final Key saveKey;
  final String saveLabel;
  final bool dirty;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: body,
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (errorText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(errorText!,
                      key: errorKey,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error)),
                ),
              FilledButton.icon(
                key: saveKey,
                onPressed: (saving || !dirty) ? null : onSave,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: Text(saving
                    ? 'Salvando...'
                    : dirty
                        ? saveLabel
                        : 'Sem alterações para salvar'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    );
  }
}

/// Campo de texto longo com orientação, exemplo fictício e versões anteriores.
class _TextBlock extends StatelessWidget {
  const _TextBlock({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.guidance,
    required this.example,
    required this.history,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final String guidance;
  final String example;
  final List<TextRevision> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(guidance,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          TextField(
            key: fieldKey,
            controller: controller,
            minLines: 4,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            decoration: _decoration(context, label, hint: example),
          ),
          if (history.isNotEmpty)
            TextButton.icon(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (ctx) => SafeArea(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(ctx).height * 0.7),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      shrinkWrap: true,
                      children: [
                        Text('Versões anteriores',
                            style: Theme.of(ctx)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        for (final r in history)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Substituída em ${_fmtStamp(r.savedAt) ?? '—'}'
                                  '${(r.savedBy ?? '').isEmpty ? '' : ' por ${r.savedBy}'}',
                                  style: Theme.of(ctx)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                          color: Theme.of(ctx)
                                              .colorScheme
                                              .onSurfaceVariant),
                                ),
                                const SizedBox(height: 4),
                                SelectableText(r.text),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              icon: const Icon(Icons.history, size: 16),
              label: Text('Versões anteriores (${history.length})'),
            ),
        ],
      ),
    );
  }
}

class _LegacyEntry extends StatelessWidget {
  const _LegacyEntry({
    required this.title,
    required this.body,
    required this.onUseInitial,
    required this.onUseCurrent,
    this.chip,
  });

  final String title;
  final String body;
  final String? chip;
  final VoidCallback onUseInitial;
  final VoidCallback onUseCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                if (chip != null)
                  Text(chip!, style: theme.textTheme.labelSmall),
              ],
            ),
            if (body.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(body, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: [
                TextButton(
                    onPressed: onUseInitial,
                    child: const Text('Usar no registro inicial')),
                TextButton(
                    onPressed: onUseCurrent,
                    child: const Text('Usar no registro atual')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Rascunho editável de um registro diagnóstico.
class _DxDraft {
  _DxDraft({
    required this.id,
    this.system,
    String name = '',
    String code = '',
    String notes = '',
    this.status,
    this.reviewedOn,
    this.updatedByName,
    this.updatedAt,
    this.revisions = const [],
    VoidCallback? onChanged,
  })  : nameCtrl = TextEditingController(text: name),
        codeCtrl = TextEditingController(text: code),
        notesCtrl = TextEditingController(text: notes) {
    if (onChanged != null) {
      nameCtrl.addListener(onChanged);
      codeCtrl.addListener(onChanged);
      notesCtrl.addListener(onChanged);
    }
  }

  factory _DxDraft.fromItem(
          DiagnosisItem it, String? fallbackSystem, VoidCallback onChanged) =>
      _DxDraft(
        id: (it.id ?? '').isEmpty ? DiagnosisItem.newId() : it.id!,
        system: it.system ?? fallbackSystem,
        name: it.name ?? '',
        code: it.code ?? '',
        notes: it.notes ?? '',
        status: it.status,
        reviewedOn: it.reviewedOn,
        updatedByName: it.updatedByName,
        updatedAt: it.updatedAt,
        revisions: it.revisions,
        onChanged: onChanged,
      );

  factory _DxDraft.blank(VoidCallback onChanged) => _DxDraft(
        id: DiagnosisItem.newId(),
        reviewedOn: _isoDate(DateTime.now()),
        onChanged: onChanged,
      );

  final String id;
  String? system;
  DiagnosisStatus? status;
  String? reviewedOn;
  final String? updatedByName;
  final String? updatedAt;
  final List<DiagnosisItem> revisions;
  final TextEditingController nameCtrl;
  final TextEditingController codeCtrl;
  final TextEditingController notesCtrl;

  bool get isBlank =>
      nameCtrl.text.trim().isEmpty &&
      codeCtrl.text.trim().isEmpty &&
      notesCtrl.text.trim().isEmpty;

  DiagnosisItem toItem() => DiagnosisItem(
        id: id,
        name: nameCtrl.text,
        code: codeCtrl.text,
        system: system,
        status: status,
        notes: notesCtrl.text,
        reviewedOn: reviewedOn,
        updatedByName: updatedByName,
        updatedAt: updatedAt,
        revisions: revisions,
      );

  void dispose() {
    nameCtrl.dispose();
    codeCtrl.dispose();
    notesCtrl.dispose();
  }
}
