import 'package:flutter/material.dart';

/// Placeholders para módulos futuros (questionários, recursos, monitores).
class FutureModulesSection extends StatelessWidget {
  const FutureModulesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Em breve',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _PlaceholderTile(
          icon: Icons.assignment_outlined,
          title: 'Questionários',
          subtitle: 'Aplicação e histórico de instrumentos.',
        ),
        _PlaceholderTile(
          icon: Icons.menu_book_outlined,
          title: 'Recursos terapêuticos',
          subtitle: 'Materiais compartilhados com o paciente.',
        ),
        _PlaceholderTile(
          icon: Icons.monitor_heart_outlined,
          title: 'Monitores',
          subtitle: 'Acompanhamento entre sessões.',
        ),
      ],
    );
  }
}

class _PlaceholderTile extends StatelessWidget {
  const _PlaceholderTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        enabled: false,
        leading: Icon(icon, color: Theme.of(context).colorScheme.outline),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Chip(
          label: Text(
            'Em breve',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
