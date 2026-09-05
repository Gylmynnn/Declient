class EnvVariable {
  final String key;
  final String value;
  final bool enabled;

  const EnvVariable({required this.key, required this.value, this.enabled = true});

  EnvVariable copyWith({String? key, String? value, bool? enabled}) {
    return EnvVariable(
      key: key ?? this.key,
      value: value ?? this.value,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {'key': key, 'value': value, 'enabled': enabled};

  factory EnvVariable.fromJson(Map<String, dynamic> json) {
    return EnvVariable(
      key: json['key'] as String? ?? '',
      value: json['value'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

class EnvironmentModel {
  final String id;
  final String name;
  final List<EnvVariable> variables;

  EnvironmentModel({required this.id, required this.name, List<EnvVariable>? variables})
      : variables = variables ?? const [];

  EnvironmentModel copyWith({String? name, List<EnvVariable>? variables}) {
    return EnvironmentModel(id: id, name: name ?? this.name, variables: variables ?? this.variables);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'variables': variables.map((e) => e.toJson()).toList(),
      };

  factory EnvironmentModel.fromJson(Map<String, dynamic> json) {
    final raw = json['variables'] as List? ?? [];
    return EnvironmentModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      variables: raw.map((e) => EnvVariable.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
