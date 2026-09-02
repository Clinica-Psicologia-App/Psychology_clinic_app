import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../auth/providers/auth_providers.dart';
import '../domain/daily_monitor.dart';
import '../domain/daily_monitor_input.dart';
import '../providers/daily_monitors_providers.dart';
import '../../../shared/widgets/brand_loading.dart';

class CreateDailyMonitorPage extends ConsumerStatefulWidget {
  const CreateDailyMonitorPage({super.key, this.monitorId});

  final String? monitorId;

  bool get isEdit => monitorId != null;

  @override
  ConsumerState<CreateDailyMonitorPage> createState() =>
      _CreateDailyMonitorPageState();
}

class _CreateDailyMonitorPageState
    extends ConsumerState<CreateDailyMonitorPage> {
  final _formKey = GlobalKey<FormState>();
  final _moodController = TextEditingController();
  final _observationsController = TextEditingController();
  final _triggersController = TextEditingController();
  final _behaviorsController = TextEditingController();

  int? _intensity;
  bool _saving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _moodController.dispose();
    _observationsController.dispose();
    _triggersController.dispose();
    _behaviorsController.dispose();
    super.dispose();
  }

  void _populateFromMonitor(DailyMonitor monitor) {
    if (_loaded) return;
    _loaded = true;
    final input = DailyMonitorInput.fromMonitor(monitor);
    _moodController.text = input.moodState ?? '';
    _observationsController.text = input.observations ?? '';
    _triggersController.text = input.triggers ?? '';
    _behaviorsController.text = input.behaviors ?? '';
    _intensity = input.intensity;
  }

  DailyMonitorInput _buildInput() {
    return DailyMonitorInput(
      moodState: _moodController.text,
      intensity: _intensity,
      observations: _observationsController.text,
      triggers: _triggersController.text,
      behaviors: _behaviorsController.text,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final input = _buildInput();
    final localError = input.validate();
    if (localError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localError)),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final repo = ref.read(dailyMonitorsRepositoryProvider);
      final DailyMonitor saved;

      if (widget.isEdit) {
        saved = await repo.update(id: widget.monitorId!, input: input);
      } else {
        final profile = ref.read(authControllerProvider).valueOrNull;
        if (profile == null) {
          throw AppException(
            code: AppExceptionCodes.unauthorized,
            message: 'Perfil não carregado.',
          );
        }
        final patientId = await repo.getPatientIdForCurrentProfile();
        saved = await repo.create(
          clinicId: profile.clinicId,
          patientId: patientId,
          input: input,
        );
      }

      ref.invalidate(myDailyMonitorsProvider);
      ref.invalidate(dailyMonitorDetailProvider(saved.id));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEdit ? 'Registro atualizado.' : 'Registro salvo.',
          ),
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;
      final message = e is AppException
          ? userMessageFor(e)
          : e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEdit) {
      final monitorAsync =
          ref.watch(dailyMonitorDetailProvider(widget.monitorId!));

      return monitorAsync.when(
        loading: () => const AppScaffold(
          title: 'Editar registro',
          accent: AppColors.cyan,
          body: BrandLoader(),
        ),
        error: (_, __) => AppScaffold(
          title: 'Editar registro',
          accent: AppColors.cyan,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Erro ao carregar registro.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(
                    dailyMonitorDetailProvider(widget.monitorId!),
                  ),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
        data: (monitor) {
          if (monitor == null) {
            return const AppScaffold(
              title: 'Editar registro',
              accent: AppColors.cyan,
              body: Center(child: Text('Registro não encontrado.')),
            );
          }
          if (!monitor.isEditableToday) {
            return AppScaffold(
              title: 'Editar registro',
              accent: AppColors.cyan,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Só é possível editar registros criados hoje.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            );
          }
          _populateFromMonitor(monitor);
          return _buildForm(context);
        },
      );
    }

    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    return AppScaffold(
      title: widget.isEdit ? 'Editar registro' : 'Novo registro',
      accent: AppColors.cyan,
      body: Form(
        key: _formKey,
        child: MotionReveal(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            children: [
              _introHeader(context),
              const SizedBox(height: 16),
              _section(
                context,
                icon: Icons.mood_outlined,
                accent: AppColors.cyan,
                title: 'Estado emocional',
                subtitle: 'Como você se percebeu emocionalmente hoje.',
                children: [
                  TextFormField(
                    controller: _moodController,
                    decoration: const InputDecoration(
                      labelText: 'Humor / estado emocional',
                      hintText: 'Como você está se sentindo?',
                    ),
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  _intensityField(context),
                ],
              ),
              _section(
                context,
                icon: Icons.bolt_outlined,
                accent: AppColors.blue,
                title: 'Gatilhos e respostas',
                subtitle: 'O que ativou a emoção e como você respondeu.',
                children: [
                  TextFormField(
                    controller: _triggersController,
                    decoration: const InputDecoration(
                      labelText: 'Gatilhos',
                      hintText: 'Situações ou pensamentos que impactaram',
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _behaviorsController,
                    decoration: const InputDecoration(
                      labelText: 'Comportamentos',
                      hintText: 'O que você fez ou evitou fazer',
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
              _section(
                context,
                icon: Icons.sticky_note_2_outlined,
                accent: AppColors.purple,
                title: 'Contexto adicional',
                subtitle: 'Sono, acontecimentos ou qualquer nota útil do dia.',
                children: [
                  TextFormField(
                    controller: _observationsController,
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      hintText: 'Sono, notas gerais ou contexto do dia',
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                    widget.isEdit ? 'Salvar alterações' : 'Salvar registro'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _introHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.cyan.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.edit_note_outlined,
              size: 20, color: AppColors.cyan),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isEdit ? 'Editar registro' : 'Monitor de hoje',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                'Registre emoções, gatilhos e respostas do dia — ${_todayLabel()}.',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _section(
    BuildContext context, {
    required IconData icon,
    required Color accent,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 1),
                    Text(subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _intensityField(BuildContext context) {
    final theme = Theme.of(context);
    final set = _intensity != null;
    final value = _intensity ?? 5;
    final tone = value >= 7
        ? AppColors.error
        : value >= 4
            ? AppColors.warning
            : AppColors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Intensidade',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700, fontSize: 12)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
              decoration: BoxDecoration(
                color: set
                    ? tone.withValues(alpha: 0.14)
                    : theme.colorScheme.outline.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                set ? '$value / 10' : 'Sem intensidade',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: set ? tone : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          activeColor: set ? tone : null,
          label: '$value',
          onChanged: (v) => setState(() => _intensity = v.round()),
        ),
        Row(
          children: [
            Text('Leve',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const Spacer(),
            Text('Intenso',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        if (set)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _intensity = null),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(0, 32),
              ),
              child: const Text('Limpar intensidade'),
            ),
          ),
      ],
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }
}
