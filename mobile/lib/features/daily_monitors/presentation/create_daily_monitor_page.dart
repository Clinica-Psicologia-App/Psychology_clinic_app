import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../auth/providers/auth_providers.dart';
import '../domain/daily_monitor.dart';
import '../domain/daily_monitor_input.dart';
import '../providers/daily_monitors_providers.dart';

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
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => AppScaffold(
          title: 'Editar registro',
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
              body: Center(child: Text('Registro não encontrado.')),
            );
          }
          if (!monitor.isEditableToday) {
            return AppScaffold(
              title: 'Editar registro',
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
              AppPageHeader(
                icon: Icons.edit_note_outlined,
                title:
                    widget.isEdit ? 'Editar monitor diário' : 'Monitor diário',
                subtitle:
                    'Registre emoções, gatilhos e respostas do dia para observar padrões ao longo da terapia.',
                metadata: [
                  StatusChip(
                    label: 'Hoje: ${_todayLabel()}',
                    tone: AppStatusTone.info,
                    icon: Icons.today_outlined,
                  ),
                  StatusChip(
                    label: _intensity == null
                        ? 'Sem intensidade'
                        : 'Intensidade $_intensity',
                    tone: _intensity == null
                        ? AppStatusTone.neutral
                        : AppStatusTone.warning,
                    icon: Icons.speed_outlined,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const AppSectionHeader(
                title: 'Estado emocional',
                subtitle:
                    'Descreva brevemente como você se percebeu emocionalmente hoje.',
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _moodController,
                decoration: const InputDecoration(
                  labelText: 'Humor / estado emocional',
                  hintText: 'Como você está se sentindo?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Intensidade (1 a 10)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Slider(
                value: (_intensity ?? 5).toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: '${_intensity ?? 5}',
                onChanged: (v) => setState(() => _intensity = v.round()),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _intensity = null),
                  child: const Text('Limpar intensidade'),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const AppSectionHeader(
                title: 'Gatilhos e respostas',
                subtitle:
                    'Registre o que ativou a emoção e como você respondeu na prática.',
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _triggersController,
                decoration: const InputDecoration(
                  labelText: 'Gatilhos',
                  hintText: 'Situações ou pensamentos que impactaram',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _behaviorsController,
                decoration: const InputDecoration(
                  labelText: 'Comportamentos',
                  hintText: 'O que você fez ou evitou fazer',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSpacing.lg),
              const AppSectionHeader(
                title: 'Contexto adicional',
                subtitle:
                    'Inclua sono, acontecimentos importantes ou qualquer nota útil sobre o dia.',
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _observationsController,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  hintText: 'Sono, notas gerais ou contexto do dia',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSpacing.xl),
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

  String _todayLabel() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }
}
