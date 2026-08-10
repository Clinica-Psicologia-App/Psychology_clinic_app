import 'clinical_case_summary.dart';
import 'clinical_dashboard_builder.dart';
import 'clinical_dashboard_callouts.dart';
import 'clinical_dashboard_history_entry.dart';
import 'clinical_instrument_dashboard.dart';
import 'clinical_parental_dashboard.dart';
import 'consolidated_domain_group.dart';
import 'consolidated_schema_row.dart';

class ClinicalDashboardData {
  const ClinicalDashboardData({
    required this.patientName,
    required this.caseSummary,
    required this.callouts,
    this.ysq,
    this.yami,
    this.attachment,
    this.yci,
    this.yrai,
    this.parental,
    required this.history,
    this.consolidatedSchemas = const [],
  });

  static const empty = ClinicalDashboardData(
    patientName: 'Paciente',
    caseSummary: ClinicalCaseSummary.empty,
    callouts: [],
    history: [],
    consolidatedSchemas: [],
  );

  final String patientName;
  final ClinicalCaseSummary caseSummary;
  final List<ClinicalDashboardCallout> callouts;
  final ClinicalInstrumentDashboard? ysq;
  final ClinicalInstrumentDashboard? yami;
  final ClinicalInstrumentDashboard? attachment;
  final ClinicalInstrumentDashboard? yci;
  final ClinicalInstrumentDashboard? yrai;
  final ClinicalParentalDashboard? parental;
  final List<ClinicalDashboardHistoryEntry> history;

  /// Todos os esquemas de todos os instrumentos com status de ativação.
  final List<ConsolidatedSchemaRow> consolidatedSchemas;

  List<ConsolidatedSchemaRow> get activatedSchemas =>
      consolidatedSchemas.where((s) => s.isActivated).toList();

  List<ConsolidatedSchemaRow> get nonActivatedSchemas =>
      consolidatedSchemas.where((s) => !s.isActivated).toList();

  /// Esquemas agrupados nos 5 domínios de Young, em ordem canônica.
  List<ConsolidatedDomainGroup> get consolidatedDomains =>
      buildConsolidatedDomainGroups(consolidatedSchemas);

  /// Modos do YAMI — bloco à parte, fora dos domínios.
  ConsolidatedModeGroup get consolidatedModes =>
      buildConsolidatedModeGroup(consolidatedSchemas);

  bool get hasConsolidatedSchemas => consolidatedSchemas.isNotEmpty;

  int get activatedSchemaCount => activatedSchemas.length;

  bool get hasCaseSummary => !caseSummary.isEmpty;

  bool get hasAnyInstrumentResult =>
      (ysq != null && !ysq!.isEmpty) ||
      (yami != null && !yami!.isEmpty) ||
      (attachment != null && !attachment!.isEmpty) ||
      (yci != null && !yci!.isEmpty) ||
      (yrai != null && !yrai!.isEmpty) ||
      (parental != null && parental!.hasContent);

  bool get hasYsqResult => ysq != null && !ysq!.isEmpty;

  bool get hasYamiResult => yami != null && !yami!.isEmpty;

  bool get hasAttachmentResult => attachment != null && !attachment!.isEmpty;

  bool get hasYciResult => yci != null && !yci!.isEmpty;

  bool get hasYraiResult => yrai != null && !yrai!.isEmpty;

  bool get hasParentalResult => parental != null && parental!.hasContent;
}
