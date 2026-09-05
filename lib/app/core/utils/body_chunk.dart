import 'dart:convert';

/// Satu segmen visual body response. Baris super panjang dipecah agar
/// layout per paragraf tetap murah (anti-freeze untuk body raksasa).
class BodySegment {
  /// Nomor baris asli (1-based). Null untuk potongan lanjutan.
  final int? lineNo;
  final String text;
  const BodySegment({required this.lineNo, required this.text});
}

class ChunkedBody {
  final List<BodySegment> segments;
  final bool isJson;
  final int lineCount;
  const ChunkedBody({required this.segments, required this.isJson, required this.lineCount});
}

/// Maksimal karakter per segmen visual. Satu paragraf Flutter dengan
/// ratusan ribu karakter membuat layout macet, jadi baris panjang di-chunk.
const int kMaxSegmentChars = 2000;

/// Maksimal total segmen yang disimpan (5MB backend ≈ 2500 segmen @2k char).
const int kMaxSegments = 4000;

ChunkedBody buildBodySegments(String raw, bool pretty) {
  if (raw.isEmpty) {
    return const ChunkedBody(segments: [], isJson: false, lineCount: 0);
  }
  dynamic decoded;
  var isJson = false;
  try {
    decoded = json.decode(raw);
    isJson = true;
  } catch (_) {
    isJson = false;
  }
  var text = raw;
  if (isJson && pretty) {
    try {
      text = const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      text = raw;
    }
  }
  final lines = text.split('\n');
  final out = <BodySegment>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.length <= kMaxSegmentChars) {
      out.add(BodySegment(lineNo: i + 1, text: line));
    } else {
      var start = 0;
      var first = true;
      while (start < line.length) {
        final end = (start + kMaxSegmentChars).clamp(0, line.length);
        out.add(BodySegment(
          lineNo: first ? i + 1 : null,
          text: line.substring(start, end),
        ));
        first = false;
        start = end;
      }
    }
    if (out.length >= kMaxSegments) break;
  }
  return ChunkedBody(
    segments: out,
    isJson: isJson,
    lineCount: lines.length,
  );
}
