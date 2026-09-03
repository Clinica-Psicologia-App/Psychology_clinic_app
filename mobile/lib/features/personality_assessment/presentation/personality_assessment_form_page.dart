import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/brand_loading.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/personality_assessment.dart';
import '../domain/personality_instrument.dart';
import '../providers/personality_assessment_providers.dart';

/// Registro/edição de uma avaliação, em passos: metadados + 5 domínios.
class PersonalityAssessmentFormPage extends ConsumerStatefulWidget {
  const PersonalityAssessmentFormPage({
    super.key,
    required this.role,
    required this.patientId,
    this.assessmentId,
  });

  final ProfileRole role;
  final String patientId;
  final String? assessmentId;

  bool get isEdit => assessmentId != null;

  @override
  ConsumerState<PersonalityAssessmentFormPage> createState() =>
      _FormState();
}

class _FormState extends ConsumerState<PersonalityAssessmentFormPage> {
  final _instrument = kNeoPiR;

  // Passo 0 = metadados; 1..5 = domínios.
  int _step = 0;
  bool _loaded = false;
  bool _saving = false;

  DateTime? _appliedOn;
  final _applicationForm = TextEditingController();
  ProtocolValidity? _validity;

  // Chaves: '<domain>' (geral) e '<domain>.<facet>'.
  final Map<String, TextEditingController> _score = {};
  final Map<String, PersonalityLevel?> _level = {};

  @override
  void initState() {
    super.initState();
    for (final d in _instrument.domains) {
      _score[d.code] = TextEditingController();
      _level[d.code] = null;
      for (final f in d.facets) {
        _score['${d.code}.${f.code}'] = TextEditingController();
        _level['${d.code}.${f.code}'] = null;
      }
    }
  }

  @override
  void dispose() {
    _applicationForm.dispose();
    for (final c in _score.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _populate(PersonalityAssessment a) {
    if (_loaded) return;
    _loaded = true;
    _appliedOn = a.appliedOn;
    _applicationForm.text = a.applicationForm ?? '';
    _validity = a.protocolValidity;
    for (final d in _instrument.domains) {
      final dr = a.results.forDomain(d.code);
      _score[d.code]!.text = _numText(dr.overall.score);
      _level[d.code] = dr.overall.level;
      for (final f in d.facets) {
        final e = dr.facet(f.code);
        _score['${d.code}.${f.code}']!.text = _numText(e.score);
        _level['${d.code}.${f.code}'] = e.level;
      }
    }
  }

  static String _numText(num? v) => v == null ? '' : '$v';

  ScoreEntry _entry(String key) {
    final raw = _score[key]!.text.trim().replaceAll(',', '.');
    return ScoreEntry(
      score: raw.isEmpty ? null : num.tryParse(raw),
      level: _level[key],
    );
  }

  PersonalityResults _buildResults() {
    final domains = <String, DomainResult>{};
    for (final d in _instrument.domains) {
      final facets = <String, ScoreEntry>{};
      for (final f in d.facets) {
        facets[f.code] = _entry('${d.code}.${f.code}');
      }
      domains[d.code] = DomainResult(overall: _entry(d.code), facets: facets);
    }
    return PersonalityResults(domains: domains);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(personalityAssessmentRepositoryProvider);
      final results = _buildResults();
      if (widget.isEdit) {
        await repo.update(
          id: widget.assessmentId!,
          results: results,
          appliedOn: _appliedOn,
          applicationForm: _applicationForm.text,
          protocolValidity: _validity,
        );
      } else {
        await repo.create(
          patientId: widget.patientId,
          instrument: _instrument.code,
          results: results,
          appliedOn: _appliedOn,
          applicationForm: _applicationForm.text,
          protocolValidity: _validity,
        );
      }
      ref.invalidate(personalityAssessmentsProvider(widget.patientId));
      if (widget.assessmentId != null) {
        ref.invalidate(personalityAssessmentByIdProvider(widget.assessmentId!));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avaliação salva.')),
      );
      context.pop(true);
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _appliedOn ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
    );
    if (picked != null) setState(() => _appliedOn = picked);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEdit) {
      final async =
          ref.watch(personalityAssessmentByIdProvider(widget.assessmentId!));
      return async.when(
        loading: () => const AppScaffold(
          title: 'Carregando…',
          accent: AppColors.purple,
          body: BrandLoader(),
        ),
        error: (_, __) => AppScaffold(
          title: 'Erro',
          accent: AppColors.purple,
          body: Center(
            child: FilledButton(
              onPressed: () => ref.invalidate(
                  personalityAssessmentByIdProvider(widget.assessmentId!)),
              child: const Text('Tentar novamente'),
            ),
          ),
        ),
        data: (a) {
          if (a == null) {
            return const AppScaffold(
              title: 'Avaliação',
              accent: AppColors.purple,
              body: Center(child: Text('Avaliação não encontrada.')),
            );
          }
          _populate(a);
          return _scaffold(context);
        },
      );
    }
    return _scaffold(context);
  }

  Widget _scaffold(BuildContext context) {
    final total = _instrument.domains.length; // 5
    final isMeta = _step == 0;
    final domain = isMeta ? null : _instrument.domains[_step - 1];
    final isLast = _step == total;

    return AppScaffold(
      title: widget.isEdit ? 'Editar avaliação' : 'Registrar avaliação',
      accent: AppColors.purple,
      actions: [
        TextButton(
          onPressed: _saving ? null : _save,
          child: const Text('Salvar', style: TextStyle(color: Colors.white)),
        ),
      ],
      body: Column(
        children: [
          _stepHeader(context, isMeta, domain),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: isMeta ? _metaFields(context) : _domainFields(domain!),
            ),
          ),
          _bottomBar(context, isLast),
        ],
      ),
    );
  }

  Widget _stepHeader(
      BuildContext context, bool isMeta, PersonalityDomain? domain) {
    final theme = Theme.of(context);
    final total = _instrument.domains.length;
    final label = isMeta
        ? 'Dados da aplicação'
        : '$_step de $total — ${domain!.label}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: AppColors.purple.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _instrument.name,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.purple,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (_step + 1) / (total + 1),
              minHeight: 5,
              backgroundColor: AppColors.purple.withValues(alpha: 0.15),
              color: AppColors.purple,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _metaFields(BuildContext context) {
    final theme = Theme.of(context);
    return [
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Data da aplicação'),
        subtitle: Text(
          _appliedOn == null
              ? 'Não informada'
              : MaterialLocalizations.of(context).formatFullDate(_appliedOn!),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.calendar_today_outlined),
          onPressed: _pickDate,
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _applicationForm,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Forma de aplicação/correção (opcional)',
          hintText: 'Ex.: correção online pelo sistema da editora',
          isDense: true,
        ),
      ),
      const SizedBox(height: 16),
      Text('Validade do protocolo',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text(
        'Conforme o relatório oficial da aplicação/correção.',
        style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: [
          for (final v in ProtocolValidity.values)
            ChoiceChip(
              label: Text(v.label),
              selected: _validity == v,
              onSelected: (sel) => setState(() => _validity = sel ? v : null),
            ),
        ],
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceTint,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'Nos próximos passos, registre o resultado de cada domínio e suas '
          'facetas: o número obtido e a classificação, conforme o relatório. '
          'O app não converte número em classificação.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ),
    ];
  }

  List<Widget> _domainFields(PersonalityDomain domain) {
    return [
      _scoreRow(domain.code, 'Resultado geral', bold: true),
      const Divider(height: 26),
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          'Facetas',
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.textMuted),
        ),
      ),
      for (final f in domain.facets)
        _scoreRow('${domain.code}.${f.code}', f.label),
    ];
  }

  Widget _scoreRow(String key, String label, {bool bold = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            child: TextField(
              controller: _score[key],
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                labelText: 'Nº',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 128,
            child: DropdownButtonFormField<PersonalityLevel?>(
              initialValue: _level[key],
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Classificação',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('—')),
                for (final l in PersonalityLevel.values)
                  DropdownMenuItem(value: l, child: Text(l.label)),
              ],
              onChanged: (v) => setState(() => _level[key] = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(BuildContext context, bool isLast) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            if (_step > 0)
              OutlinedButton(
                onPressed: _saving ? null : () => setState(() => _step -= 1),
                child: const Text('Voltar'),
              ),
            if (_step > 0) const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.purple),
                onPressed: _saving
                    ? null
                    : () {
                        if (isLast) {
                          _save();
                        } else {
                          setState(() => _step += 1);
                        }
                      },
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isLast ? 'Salvar avaliação' : 'Salvar e continuar →'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
