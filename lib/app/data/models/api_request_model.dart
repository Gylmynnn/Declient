import 'form_data_field.dart';
import 'key_value.dart';

class AuthConfig {
  final String type; // none | bearer | basic
  final String token;
  final String username;
  final String password;

  const AuthConfig({this.type = 'none', this.token = '', this.username = '', this.password = ''});

  AuthConfig copyWith({String? type, String? token, String? username, String? password}) {
    return AuthConfig(
      type: type ?? this.type,
      token: token ?? this.token,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toJson() => {'type': type, 'token': token, 'username': username, 'password': password};

  factory AuthConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AuthConfig();
    return AuthConfig(
      type: json['type'] as String? ?? 'none',
      token: json['token'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
    );
  }
}

class ApiRequestModel {
  final String id;
  final String collectionId;
  final String folderId;
  final String name;
  final String description;
  final String method;
  final String url;
  final List<KeyValue> params;
  final List<KeyValue> headers;
  final String bodyType; // none | raw | json | text | form | multipart
  final String body;
  final List<FormDataField> formData;
  final AuthConfig auth;

  ApiRequestModel({
    required this.id,
    required this.collectionId,
    this.folderId = '',
    required this.name,
    this.description = '',
    this.method = 'GET',
    this.url = '',
    List<KeyValue>? params,
    List<KeyValue>? headers,
    this.bodyType = 'none',
    this.body = '',
    List<FormDataField>? formData,
    this.auth = const AuthConfig(),
  })  : params = params ?? const [],
        headers = headers ?? const [],
        formData = formData ?? const [];

  ApiRequestModel copyWith({
    String? id,
    String? collectionId,
    String? folderId,
    String? name,
    String? description,
    String? method,
    String? url,
    List<KeyValue>? params,
    List<KeyValue>? headers,
    String? bodyType,
    String? body,
    List<FormDataField>? formData,
    AuthConfig? auth,
  }) {
    return ApiRequestModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      folderId: folderId ?? this.folderId,
      name: name ?? this.name,
      description: description ?? this.description,
      method: method ?? this.method,
      url: url ?? this.url,
      params: params ?? this.params,
      headers: headers ?? this.headers,
      bodyType: bodyType ?? this.bodyType,
      body: body ?? this.body,
      formData: formData ?? this.formData,
      auth: auth ?? this.auth,
    );
  }

  Map<String, dynamic> toJson({bool includeFileBytes = false}) => {
        'id': id,
        'collectionId': collectionId,
        'folderId': folderId,
        'name': name,
        'method': method,
        'url': url,
        'params': params.map((e) => e.toJson()).toList(),
        'headers': headers.map((e) => e.toJson()).toList(),
        'bodyType': bodyType,
        'body': body,
        'formData': formData
            .map((e) => e.toJson(includeBytes: includeFileBytes))
            .toList(),
        'auth': auth.toJson(),
      };

  factory ApiRequestModel.fromJson(Map<String, dynamic> json) {
    return ApiRequestModel(
      id: json['id'] as String? ?? '',
      collectionId: json['collectionId'] as String? ?? '',
      folderId: json['folderId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      method: (json['method'] as String? ?? 'GET').toUpperCase(),
      url: json['url'] as String? ?? '',
      params: KeyValue.listFromJson(json['params']),
      headers: KeyValue.listFromJson(json['headers']),
      bodyType: json['bodyType'] as String? ?? 'none',
      body: json['body'] as String? ?? '',
      formData: FormDataField.listFromJson(json['formData']),
      auth: AuthConfig.fromJson(json['auth'] as Map<String, dynamic>?),
    );
  }
}

class SendResult {
  final int statusCode;
  final Map<String, String> headers;
  final String body;
  final int durationMs;
  final int size;
  final String resolvedUrl;

  SendResult({
    required this.statusCode,
    required this.headers,
    required this.body,
    required this.durationMs,
    required this.size,
    required this.resolvedUrl,
  });

  factory SendResult.fromJson(Map<String, dynamic> json) {
    final rawHeaders = json['headers'] as Map? ?? {};
    return SendResult(
      statusCode: json['statusCode'] as int? ?? 0,
      headers: rawHeaders.map((k, v) => MapEntry(k.toString(), v.toString())),
      body: json['body'] as String? ?? '',
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 0,
      resolvedUrl: json['resolvedUrl'] as String? ?? '',
    );
  }
}
