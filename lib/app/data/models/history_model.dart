class HistoryModel {
  final String id;
  final String requestId;
  final String requestName;
  final String method;
  final String url;
  final String resolvedUrl;
  final int statusCode;
  final int durationMs;
  final int size;
  final DateTime? createdAt;

  HistoryModel({
    required this.id,
    this.requestId = '',
    required this.requestName,
    required this.method,
    required this.url,
    this.resolvedUrl = '',
    required this.statusCode,
    required this.durationMs,
    required this.size,
    this.createdAt,
  });

  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    return HistoryModel(
      id: json['id'] as String? ?? '',
      requestId: json['requestId'] as String? ?? '',
      requestName: json['requestName'] as String? ?? '',
      method: json['method'] as String? ?? 'GET',
      url: json['url'] as String? ?? '',
      resolvedUrl: json['resolvedUrl'] as String? ?? '',
      statusCode: (json['statusCode'] as num?)?.toInt() ?? 0,
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v as String);
    } catch (_) {
      return null;
    }
  }
}
