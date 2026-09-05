class KeyValue {
  final String key;
  final String value;
  final bool enabled;

  const KeyValue({required this.key, required this.value, this.enabled = true});

  KeyValue copyWith({String? key, String? value, bool? enabled}) {
    return KeyValue(
      key: key ?? this.key,
      value: value ?? this.value,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {'key': key, 'value': value, 'enabled': enabled};

  factory KeyValue.fromJson(Map<String, dynamic> json) {
    return KeyValue(
      key: json['key'] as String? ?? '',
      value: json['value'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  static List<KeyValue> listFromJson(dynamic json) {
    if (json == null) return [];
    return (json as List).map((e) => KeyValue.fromJson(e as Map<String, dynamic>)).toList();
  }
}
