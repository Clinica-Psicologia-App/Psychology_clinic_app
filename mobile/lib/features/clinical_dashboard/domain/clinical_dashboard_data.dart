import 'clinical_dashboard_history_entry.dart';
import 'clinical_instrument_dashboard.dart';

class ClinicalDashboardData {
  const ClinicalDashboardData({
    this.ysq,
    this.yami,
    required this.history,
  });

  static const empty = ClinicalDashboardData(history: []);

  final ClinicalInstrumentDashboard? ysq;
  final ClinicalInstrumentDashboard? yami;
  final List<ClinicalDashboardHistoryEntry> history;

  bool get hasAnyInstrumentResult =>
      (ysq != null && !ysq!.isEmpty) || (yami != null && !yami!.isEmpty);

  bool get hasYsqResult => ysq != null && !ysq!.isEmpty;

  bool get hasYamiResult => yami != null && !yami!.isEmpty;
}
