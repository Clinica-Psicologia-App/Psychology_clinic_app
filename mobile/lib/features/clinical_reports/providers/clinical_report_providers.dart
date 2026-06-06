import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/clinical_report_repository.dart';

final clinicalReportRepositoryProvider = Provider<ClinicalReportRepository>(
  (ref) => ClinicalReportRepository(),
);
