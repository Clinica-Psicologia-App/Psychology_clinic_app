import 'library_work.dart';

/// Uma indicação de obra ao paciente (psicólogo → paciente), já com a obra
/// embutida (campos seguros do paciente).
class LibraryIndication {
  const LibraryIndication({
    required this.id,
    required this.work,
    required this.status,
    this.objective,
    this.scope,
    this.indicatedAt,
    this.watchedAt,
    this.activation,
    this.shareResponses = false,
    this.patientResponses,
  });

  final String id;
  final LibraryWork work;

  /// Sugerido | Indicado | Em andamento | Assistido | Discutido | Pausado.
  final String status;
  final String? objective;
  final String? scope;
  final DateTime? indicatedAt;
  final DateTime? watchedAt;
  final int? activation;
  final bool shareResponses;
  final Map<String, dynamic>? patientResponses;

  bool get isInProgress => status == 'Em andamento' || status == 'Pausado';
  bool get isWatched => status == 'Assistido' || status == 'Discutido';
  bool get isNew => status == 'Indicado' || status == 'Sugerido';

  factory LibraryIndication.fromJson(Map<String, dynamic> json) {
    return LibraryIndication(
      id: json['indication_id'] as String,
      work: LibraryWork.fromJson(
        Map<String, dynamic>.from(json['work'] as Map),
      ),
      status: json['status'] as String? ?? 'Indicado',
      objective: json['objective'] as String?,
      scope: json['scope'] as String?,
      indicatedAt: _parse(json['indicated_at']),
      watchedAt: _parse(json['watched_at']),
      activation: (json['activation_0_10'] as num?)?.toInt(),
      shareResponses: json['share_responses'] as bool? ?? false,
      patientResponses: json['patient_responses'] is Map
          ? Map<String, dynamic>.from(json['patient_responses'] as Map)
          : null,
    );
  }

  static DateTime? _parse(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}
