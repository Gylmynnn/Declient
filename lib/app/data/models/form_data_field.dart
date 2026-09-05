import 'dart:convert';
import 'dart:typed_data';

/// Satu field multipart/form-data.
///
/// - type `text`: [value] dikirim sebagai field biasa.
/// - type `file`: isi file dikirim sebagai file dengan [fileName] +
///   [contentType]. [filePath] hanya penanda lokal (dipersist agar request
///   tersimpan bisa dimuat ulang di mesin yang sama).
/// - [fileBytes] transient (tidak diserialisasi); dimuat saat pick file atau
///   lazy dari [filePath] sesaat sebelum send. Hanya [toJson] dengan
///   `includeBytes: true` (payload send) yang menyertakan base64.
class FormDataField {
  final String key;
  final String value;
  final String type; // text | file
  final String fileName;
  final String filePath;
  final int fileSize;
  final String contentType;
  final bool enabled;
  final Uint8List? fileBytes;

  const FormDataField({
    this.key = '',
    this.value = '',
    this.type = 'text',
    this.fileName = '',
    this.filePath = '',
    this.fileSize = 0,
    this.contentType = '',
    this.enabled = true,
    this.fileBytes,
  });

  bool get isFile => type == 'file';
  bool get hasBytes => fileBytes != null;

  FormDataField copyWith({
    String? key,
    String? value,
    String? type,
    String? fileName,
    String? filePath,
    int? fileSize,
    String? contentType,
    bool? enabled,
    Uint8List? fileBytes,
    bool clearBytes = false,
  }) {
    return FormDataField(
      key: key ?? this.key,
      value: value ?? this.value,
      type: type ?? this.type,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      contentType: contentType ?? this.contentType,
      enabled: enabled ?? this.enabled,
      fileBytes: clearBytes ? null : (fileBytes ?? this.fileBytes),
    );
  }

  Map<String, dynamic> toJson({bool includeBytes = false}) => {
        'key': key,
        'value': value,
        'type': type,
        'fileName': fileName,
        'filePath': filePath,
        'fileSize': fileSize,
        'contentType': contentType,
        'enabled': enabled,
        if (includeBytes && fileBytes != null)
          'fileBase64': base64Encode(fileBytes!),
      };

  factory FormDataField.fromJson(Map<String, dynamic> json) {
    return FormDataField(
      key: json['key'] as String? ?? '',
      value: json['value'] as String? ?? '',
      type: json['type'] as String? ?? 'text',
      fileName: json['fileName'] as String? ?? '',
      filePath: json['filePath'] as String? ?? '',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      contentType: json['contentType'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  static List<FormDataField> listFromJson(dynamic json) {
    if (json == null) return [];
    return (json as List)
        .map((e) => FormDataField.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Tebakan content-type dari ekstensi (fallback: octet-stream, sama dengan backend).
String guessContentType(String fileName) {
  final ext = fileName.contains('.')
      ? fileName.split('.').last.toLowerCase()
      : '';
  switch (ext) {
    case 'png':
      return 'image/png';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    case 'svg':
      return 'image/svg+xml';
    case 'pdf':
      return 'application/pdf';
    case 'json':
      return 'application/json';
    case 'xml':
      return 'application/xml';
    case 'csv':
      return 'text/csv';
    case 'txt':
    case 'log':
    case 'md':
      return 'text/plain';
    case 'zip':
      return 'application/zip';
    case 'mp4':
      return 'video/mp4';
    case 'mp3':
      return 'audio/mpeg';
    default:
      return 'application/octet-stream';
  }
}

/// Format ukuran file ramah mata (B / KB / MB).
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
