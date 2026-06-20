import 'package:flutter/material.dart';

import '../../domain/patient_resource_access.dart';
import '../../domain/resource_access_status.dart';
import '../../domain/therapy_resource.dart';
import '../../domain/therapy_resource_recommendation.dart';

class ResourceStatusChip extends StatelessWidget {
  const ResourceStatusChip({super.key, required this.status});

  final ResourceAccessStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (status) {
      ResourceAccessStatus.released => (
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.primaryContainer,
        ),
      ResourceAccessStatus.viewed => (
          Theme.of(context).colorScheme.tertiary,
          Theme.of(context).colorScheme.tertiaryContainer,
        ),
      ResourceAccessStatus.completed => (
          Theme.of(context).colorScheme.secondary,
          Theme.of(context).colorScheme.secondaryContainer,
        ),
    };

    return Chip(
      label: Text(
        status.label,
        style: TextStyle(color: color, fontSize: 12),
      ),
      backgroundColor: bg,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}

class TherapyResourceTile extends StatelessWidget {
  const TherapyResourceTile({
    super.key,
    required this.resource,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.status,
  });

  final TherapyResource resource;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final ResourceAccessStatus? status;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(resource.type.icon),
        title: Text(resource.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(resource.type.label),
            if (subtitle != null) Text(subtitle!),
            if (status != null) ...[
              const SizedBox(height: 4),
              ResourceStatusChip(status: status!),
            ],
          ],
        ),
        isThreeLine: subtitle != null || status != null,
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class PatientAccessTile extends StatelessWidget {
  const PatientAccessTile({
    super.key,
    required this.access,
    required this.onTap,
  });

  final PatientResourceAccess access;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TherapyResourceTile(
      resource: access.resource,
      subtitle: access.isActive ? null : 'Acesso bloqueado',
      status: access.isActive ? access.progressStatus : null,
      onTap: onTap,
    );
  }
}

class TherapyRecommendationTile extends StatelessWidget {
  const TherapyRecommendationTile({
    super.key,
    required this.recommendation,
    required this.onTap,
  });

  final TherapyResourceRecommendation recommendation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final resource = recommendation.resource;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(resource.type.icon),
        title: Text(resource.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(resource.type.label),
            const SizedBox(height: 4),
            for (final reason in recommendation.reasons)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('• $reason'),
              ),
            if (recommendation.isAlreadyAssigned) ...[
              const SizedBox(height: 6),
              ResourceStatusChip(
                status: recommendation.activeAccess!.progressStatus,
              ),
            ],
          ],
        ),
        isThreeLine: true,
        trailing: Icon(
          recommendation.isAlreadyAssigned
              ? Icons.check_circle_outline
              : Icons.auto_awesome_outlined,
        ),
        onTap: onTap,
      ),
    );
  }
}
