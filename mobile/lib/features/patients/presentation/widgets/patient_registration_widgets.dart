import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../../domain/patient.dart';
import '../../providers/patients_providers.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

/// Idade em anos completos na data [now].
int patientAgeYears(DateTime birthDate, DateTime now) {
  var age = now.year - birthDate.year;
  final hadBirthday = now.month > birthDate.month ||
      (now.month == birthDate.month && now.day >= birthDate.day);
  if (!hadBirthday) age -= 1;
  return age < 0 ? 0 : age;
}

String? patientBirthPlace(Patient patient) {
  final parts = [
    patient.stateBirth,
    patient.countryBirth,
  ].where((value) => value != null && value.trim().isNotEmpty).cast<String>();
  if (parts.isEmpty) return null;
  return parts.join(' / ');
}

String? patientHasChildrenLabel(bool? hasChildren) {
  if (hasChildren == null) return null;
  return hasChildren ? 'Sim' : 'Não';
}

String? maskCpf(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 11) return '***.***.***-**';
  return '***.***.${digits.substring(6, 9)}-**';
}

String? maskPhone(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 4) return '••••';
  return '•••••••${digits.substring(digits.length - 4)}';
}

/// Copia [text] para a área de transferência e avisa com um SnackBar.
Future<void> copyPatientValue(
  BuildContext context, {
  required String label,
  required String text,
}) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$label copiado.')));
}

/// Cartão de seção com título (usado nos dados cadastrais).
class PatientDataSectionCard extends StatelessWidget {
  const PatientDataSectionCard({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(title: title, subtitle: subtitle),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Todos os dados cadastrais do paciente, com botão de copiar em cada um
/// (os dados também são usados fora do app, por exemplo para emitir notas).
class PatientRegistrationDataCard extends StatelessWidget {
  const PatientRegistrationDataCard({super.key, required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final dateFormat = MaterialLocalizations.of(context);
    return PatientDataSectionCard(
      title: 'Dados do paciente',
      subtitle:
          'Informações principais para identificação, contato e contexto clínico.',
      children: [
        PatientInfoRow(
            icon: Icons.mail_outline, label: 'E-mail', value: patient.email),
        PatientSensitiveInfoRow(
          icon: Icons.phone_outlined,
          label: 'Telefone',
          value: patient.phone,
          maskedValue: maskPhone(patient.phone),
        ),
        PatientSensitiveInfoRow(
          icon: Icons.badge_outlined,
          label: 'CPF',
          value: patient.cpf,
          maskedValue: maskCpf(patient.cpf),
        ),
        PatientInfoRow(
          icon: Icons.cake_outlined,
          label: 'Nascimento',
          value: patient.birthDate != null
              ? dateFormat.formatFullDate(patient.birthDate!)
              : null,
          copyText: patient.birthDate != null
              ? dateFormat.formatCompactDate(patient.birthDate!)
              : null,
        ),
        PatientInfoRow(
            icon: Icons.wc_outlined,
            label: 'Gênero',
            value: patient.displayGender),
        PatientInfoRow(
          icon: Icons.favorite_border,
          label: 'Estado civil',
          value: patient.displayRelationshipStatus,
        ),
        PatientInfoRow(
          icon: Icons.school_outlined,
          label: 'Escolaridade',
          value: patient.displayEducationLevel,
        ),
        PatientInfoRow(
            icon: Icons.work_outline,
            label: 'Ocupação',
            value: patient.occupation),
        PatientInfoRow(
            icon: Icons.place_outlined,
            label: 'Naturalidade',
            value: patientBirthPlace(patient)),
        PatientInfoRow(
          icon: Icons.self_improvement_outlined,
          label: 'Religião',
          value: patient.religiousOrientation,
        ),
        PatientInfoRow(
            icon: Icons.groups_outlined,
            label: 'Grupo étnico',
            value: patient.displayEthnicGroup),
        PatientInfoRow(
          icon: Icons.diversity_1_outlined,
          label: 'Orient. sexual',
          value: patient.displaySexualOrientation,
        ),
        PatientInfoRow(
          icon: Icons.child_care_outlined,
          label: 'Filhos',
          value: patientHasChildrenLabel(patient.hasChildren),
        ),
      ],
    );
  }
}

/// Identificação resumida do paciente, na abertura da ficha: idade, data de
/// nascimento, profissão e estado civil. O nome e a situação (ativo ou
/// inativo) já aparecem no cabeçalho.
class PatientIdentificationSummary extends StatelessWidget {
  const PatientIdentificationSummary({
    super.key,
    required this.patient,
    this.now,
  });

  final Patient patient;

  /// Data de referência para a idade (injetável para teste).
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final birth = patient.birthDate;
    final age =
        birth == null ? null : patientAgeYears(birth, now ?? DateTime.now());
    final items = <(IconData, String, String)>[
      if (age != null)
        (Icons.hourglass_bottom_outlined, 'Idade', '$age anos'),
      if (birth != null)
        (Icons.cake_outlined, 'Nascimento', localizations.formatShortDate(birth)),
      if ((patient.occupation ?? '').trim().isNotEmpty)
        (Icons.work_outline, 'Ocupação', patient.occupation!.trim()),
      if ((patient.displayRelationshipStatus ?? '').trim().isNotEmpty)
        (
          Icons.favorite_border,
          'Estado civil',
          patient.displayRelationshipStatus!.trim()
        ),
    ];
    if (items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return ClayCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          children: [
            for (final item in items)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.$1, size: 18, color: AppColors.cyan),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$2,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        item.$3,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Linha de dado com ícone, rótulo, valor e botão de copiar. Some se o valor
/// está vazio.
class PatientInfoRow extends StatelessWidget {
  const PatientInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon = Icons.info_outline,
    this.copyText,
  });

  final String label;
  final String? value;
  final IconData icon;

  /// Texto levado pelo botão de copiar, quando difere do exibido (por
  /// exemplo, a data em dd/mm/aaaa em vez de por extenso).
  final String? copyText;

  @override
  Widget build(BuildContext context) {
    final text = value;
    if (text == null || text.trim().isEmpty) return const SizedBox.shrink();
    return PatientInfoRowLayout(
      icon: icon,
      label: label,
      value: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
      ),
      trailing: _CopyButton(label: label, text: copyText ?? text),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: 'Copiar $label',
      onPressed: () => copyPatientValue(context, label: label, text: text),
      icon: Icon(
        Icons.copy_rounded,
        size: 18,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Layout base de uma linha de dado: ícone + rótulo + valor (à direita).
class PatientInfoRowLayout extends StatelessWidget {
  const PatientInfoRowLayout({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final Widget value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: AppColors.cyan),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: value,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Dado sensível (telefone, CPF): vem mascarado, com botão de mostrar e de
/// copiar. A cópia leva o valor completo, sem máscara.
class PatientSensitiveInfoRow extends StatefulWidget {
  const PatientSensitiveInfoRow({
    super.key,
    required this.label,
    required this.value,
    required this.maskedValue,
    this.icon = Icons.lock_outline,
  });

  final String label;
  final String? value;
  final String? maskedValue;
  final IconData icon;

  @override
  State<PatientSensitiveInfoRow> createState() =>
      _PatientSensitiveInfoRowState();
}

class _PatientSensitiveInfoRowState extends State<PatientSensitiveInfoRow> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final raw = widget.value;
    if (raw == null || raw.trim().isEmpty) return const SizedBox.shrink();

    return PatientInfoRowLayout(
      icon: widget.icon,
      label: widget.label,
      value: Text(
        _revealed ? raw : widget.maskedValue!,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
              letterSpacing: _revealed ? 0 : 1.5,
            ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: _revealed
                ? 'Ocultar ${widget.label}'
                : 'Mostrar ${widget.label}',
            onPressed: () => setState(() => _revealed = !_revealed),
            icon: Icon(
              _revealed
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          _CopyButton(label: widget.label, text: raw),
        ],
      ),
    );
  }
}

/// Situação do acompanhamento: inativar ou reativar o acesso. Inativar
/// bloqueia o acesso do paciente e preserva todo o prontuário e histórico.
class PatientLifecycleCard extends ConsumerStatefulWidget {
  const PatientLifecycleCard({super.key, required this.patient});

  final Patient patient;

  @override
  ConsumerState<PatientLifecycleCard> createState() =>
      _PatientLifecycleCardState();
}

class _PatientLifecycleCardState extends ConsumerState<PatientLifecycleCard> {
  bool _updating = false;

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final isActive = patient.isActive;
    final colors = Theme.of(context).colorScheme;

    return ClayCard(
      color: isActive ? null : colors.errorContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  isActive
                      ? Icons.verified_user_outlined
                      : Icons.person_off_outlined,
                  color: isActive ? colors.primary : colors.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isActive ? 'Paciente ativo' : 'Paciente inativo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isActive
                  ? 'A inativação bloqueia o acesso do paciente, mas preserva todo o prontuário e histórico clínico.'
                  : 'O prontuário permanece preservado e disponível para consulta. Reative para restaurar o acesso do paciente.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            if (isActive)
              OutlinedButton.icon(
                onPressed: _updating ? null : _confirmStatusChange,
                icon: _updating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_off_outlined),
                label: const Text('Inativar acesso'),
              )
            else
              FilledButton.icon(
                onPressed: _updating ? null : _confirmStatusChange,
                icon: _updating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add_alt_1_outlined),
                label: const Text('Reativar acesso'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmStatusChange() async {
    final patient = widget.patient;
    final willActivate = !patient.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          willActivate ? 'Reativar acesso?' : 'Inativar acesso?',
        ),
        content: Text(
          willActivate
              ? 'O acesso de ${patient.fullName} será restaurado.'
              : 'O acesso de ${patient.fullName} será bloqueado. O prontuário, a conceitualização e todo o histórico clínico serão preservados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(willActivate ? 'Reativar' : 'Inativar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _updating = true);
    try {
      await ref.read(patientsRepositoryProvider).setPatientActiveStatus(
            patientId: patient.id,
            isActive: willActivate,
          );
      ref.invalidate(patientDetailProvider(patient.id));
      await ref.read(patientsListProvider.notifier).refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            willActivate
                ? 'Acesso do paciente reativado com sucesso.'
                : 'Acesso do paciente inativado com sucesso.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) showErrorBanner(context, error);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }
}
