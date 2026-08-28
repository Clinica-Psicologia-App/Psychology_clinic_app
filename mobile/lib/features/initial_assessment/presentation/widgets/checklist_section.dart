import 'package:flutter/material.dart';

import '../../domain/assessment_catalog_item.dart';

/// Seção de checklist multi-seleção sobre um catálogo (esquemas, modos ou
/// necessidades emocionais) — usada no Bloco 4.
class ChecklistSection extends StatelessWidget {
  const ChecklistSection({
    super.key,
    required this.title,
    required this.items,
    required this.selectedIds,
    required this.onToggle,
  });

  final String title;
  final List<AssessmentCatalogItem> items;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        if (items.isEmpty)
          Text(
            'Catálogo indisponível.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          )
        else
          ...items.map(
            (item) => CheckboxListTile(
              value: selectedIds.contains(item.id),
              onChanged: (_) => onToggle(item.id),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(item.name),
              subtitle: (item.description ?? '').isEmpty
                  ? null
                  : Text(
                      item.description!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
            ),
          ),
      ],
    );
  }
}
