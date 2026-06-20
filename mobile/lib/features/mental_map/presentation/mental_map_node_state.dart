import 'package:flutter/material.dart';

import '../domain/mental_case_map.dart';

enum MentalMapNodeVisualState {
  filled,
  partial,
  pending,
  blocked,
}

MentalMapNodeVisualState resolveMentalMapNodeVisualState(
    MentalCaseMapNode node) {
  final label = node.shortLabel.toLowerCase();
  if (label.contains('bloqueado') ||
      label.contains('aguardando') ||
      label.contains('revisão')) {
    return MentalMapNodeVisualState.blocked;
  }
  if (!node.isFilled) {
    return MentalMapNodeVisualState.pending;
  }
  if (label.contains('parcial') || node.items.length == 1) {
    return MentalMapNodeVisualState.partial;
  }
  return MentalMapNodeVisualState.filled;
}

String mentalMapNodeStateLabel(MentalMapNodeVisualState state) {
  return switch (state) {
    MentalMapNodeVisualState.filled => 'Preenchido',
    MentalMapNodeVisualState.partial => 'Parcial',
    MentalMapNodeVisualState.pending => 'Pendente',
    MentalMapNodeVisualState.blocked => 'Bloqueado',
  };
}

IconData mentalMapNodeStateIcon(MentalMapNodeVisualState state) {
  return switch (state) {
    MentalMapNodeVisualState.filled => Icons.check_circle_outline,
    MentalMapNodeVisualState.partial => Icons.contrast_outlined,
    MentalMapNodeVisualState.pending => Icons.radio_button_unchecked,
    MentalMapNodeVisualState.blocked => Icons.lock_outline,
  };
}
