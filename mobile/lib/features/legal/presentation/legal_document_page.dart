import 'package:flutter/material.dart';

import '../../../core/legal/legal_documents.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/responsive_content.dart';

enum LegalDocumentType { terms, privacy }

class LegalDocumentPage extends StatelessWidget {
  const LegalDocumentPage({
    super.key,
    required this.type,
  });

  final LegalDocumentType type;

  @override
  Widget build(BuildContext context) {
    final isTerms = type == LegalDocumentType.terms;
    final title =
        isTerms ? LegalDocuments.termsTitle : LegalDocuments.privacyTitle;
    final version = isTerms
        ? LegalDocuments.termsVersion
        : LegalDocuments.privacyVersion;
    final text =
        isTerms ? LegalDocuments.termsText : LegalDocuments.privacyText;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ResponsiveContent(
            maxWidth: 760,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Versão $version',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.55,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
