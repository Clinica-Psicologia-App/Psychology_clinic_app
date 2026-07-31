class ClinicFeatureEntitlement {
  const ClinicFeatureEntitlement({
    required this.featureKey,
    required this.featureName,
    required this.isEnabled,
    this.limitValue,
    this.notes,
  });

  final String featureKey;
  final String featureName;
  final bool isEnabled;
  final int? limitValue;
  final String? notes;

  factory ClinicFeatureEntitlement.fromJson(Map<String, dynamic> json) {
    return ClinicFeatureEntitlement(
      featureKey: json['feature_key'] as String,
      featureName: json['feature_name'] as String,
      isEnabled: json['is_enabled'] as bool? ?? false,
      limitValue: json['limit_value'] as int?,
      notes: json['notes'] as String?,
    );
  }
}

class ClinicFeatureEntitlements {
  const ClinicFeatureEntitlements(this._items);

  final Map<String, ClinicFeatureEntitlement> _items;

  bool isEnabled(String featureKey, {bool defaultValue = true}) {
    return _items[featureKey]?.isEnabled ?? defaultValue;
  }

  int? limitFor(String featureKey) => _items[featureKey]?.limitValue;

  static const empty = ClinicFeatureEntitlements({});
}
