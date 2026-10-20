import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/personality_domain_palette.dart';
import '../domain/personality_instrument.dart';

Color personalityDomainColor(String code) =>
    switch (personalityDomainPalette[code]) {
      PersonalityDomainTone.red => AppColors.error,
      PersonalityDomainTone.amber => AppColors.warning,
      PersonalityDomainTone.green => AppColors.success,
      PersonalityDomainTone.purple => AppColors.purple,
      PersonalityDomainTone.blue => AppColors.blue,
      null => AppColors.textMuted,
    };

/// O mapa mental armazena resumos textuais; resolve o rótulo canônico do fator.
Color? personalitySummaryColor(String item) {
  final label = item.split(':').first.trim();
  for (final domain in kNeoPiR.domains) {
    if (domain.label == label) return personalityDomainColor(domain.code);
  }
  return null;
}
