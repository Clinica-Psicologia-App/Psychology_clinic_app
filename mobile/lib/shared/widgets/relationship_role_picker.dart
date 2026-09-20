import 'package:flutter/material.dart';

import '../../features/life_story/domain/life_story_enums.dart';

/// Seletor de parentesco compacto: categorias em scroll horizontal,
/// chips da categoria ativa logo abaixo. Ocupa ~2 linhas de altura.
class RelationshipRolePicker extends StatefulWidget {
  const RelationshipRolePicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final RelationshipRole? selected;
  final ValueChanged<RelationshipRole?> onChanged;

  @override
  State<RelationshipRolePicker> createState() => _RelationshipRolePickerState();
}

class _RelationshipRolePickerState extends State<RelationshipRolePicker> {
  static const _groups = [
    _RoleGroup(label: 'Pais', roles: [
      RelationshipRole.mother,
      RelationshipRole.father,
      RelationshipRole.stepmother,
      RelationshipRole.stepfather,
    ]),
    _RoleGroup(label: 'Irmãos', roles: [
      RelationshipRole.sister,
      RelationshipRole.brother,
    ]),
    _RoleGroup(label: 'Avós', roles: [
      RelationshipRole.grandmother,
      RelationshipRole.grandfather,
    ]),
    _RoleGroup(label: 'Tios/primos', roles: [
      RelationshipRole.aunt,
      RelationshipRole.uncle,
      RelationshipRole.cousinF,
      RelationshipRole.cousinM,
    ]),
    _RoleGroup(label: 'Filhos', roles: [
      RelationshipRole.daughter,
      RelationshipRole.son,
    ]),
    _RoleGroup(label: 'Cônjuge', roles: [
      RelationshipRole.partner,
      RelationshipRole.exPartner,
    ]),
    _RoleGroup(label: 'Outros', roles: [
      RelationshipRole.caregiver,
      RelationshipRole.other,
    ]),
  ];

  late int _activeGroup;

  @override
  void initState() {
    super.initState();
    _activeGroup = _groupIndexFor(widget.selected);
  }

  @override
  void didUpdateWidget(RelationshipRolePicker old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected && widget.selected != null) {
      final idx = _groupIndexFor(widget.selected);
      if (idx != _activeGroup) setState(() => _activeGroup = idx);
    }
  }

  int _groupIndexFor(RelationshipRole? role) {
    if (role == null) return 0;
    for (var i = 0; i < _groups.length; i++) {
      if (_groups[i].roles.contains(role)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final group = _groups[_activeGroup];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── linha 1: categorias ──────────────────────────────────────────
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _groups.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final active = i == _activeGroup;
              return GestureDetector(
                onTap: () => setState(() => _activeGroup = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: active
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _groups[i].label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: active
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // ── linha 2: chips da categoria ─────────────────────────────────
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final role in group.roles)
              _RoleChip(
                role: role,
                selected: widget.selected == role,
                onTap: () => widget
                    .onChanged(widget.selected == role ? null : role),
                theme: theme,
              ),
          ],
        ),
      ],
    );
  }
}

class _RoleGroup {
  const _RoleGroup({required this.label, required this.roles});
  final String label;
  final List<RelationshipRole> roles;
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.role,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  final RelationshipRole role;
  final bool selected;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.4),
            width: selected ? 0 : 1,
          ),
        ),
        child: Text(
          role.label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
