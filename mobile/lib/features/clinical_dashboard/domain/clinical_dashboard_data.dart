import 'clinical_case_summary.dart';
import 'clinical_dashboard_callouts.dart';
import 'clinical_dashboard_history_entry.dart';
import 'clinical_instrument_dashboard.dart';
import 'clinical_parental_dashboard.dart';

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
  });

  static const empty = ClinicalDashboardData(
    patientName: 'Paciente',
    caseSummary: ClinicalCaseSummary.empty,
    callouts: [],
    history: [],
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
