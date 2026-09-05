import 'dart:convert';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_fonts.dart';

TextStyle _mono(double s) =>
    TextStyle(fontSize: s, height: 1.7, fontFamily: AppFonts.mono, color: AppColors.foreground);
TextStyle _keyStyle(double s) =>
    TextStyle(fontSize: s, height: 1.7, fontFamily: AppFonts.mono, color: AppColors.blue, fontWeight: FontWeight.w600);
TextStyle _stringStyle(double s) =>
    TextStyle(fontSize: s, height: 1.7, fontFamily: AppFonts.mono, color: AppColors.green);
TextStyle _numberStyle(double s) =>
    TextStyle(fontSize: s, height: 1.7, fontFamily: AppFonts.mono, color: AppColors.yellow);
TextStyle _boolStyle(double s) =>
    TextStyle(fontSize: s, height: 1.7, fontFamily: AppFonts.mono, color: AppColors.magenta);
TextStyle _varStyle(double s) =>
    TextStyle(fontSize: s, height: 1.7, fontFamily: AppFonts.mono, color: AppColors.cyan, fontWeight: FontWeight.w700);
TextStyle _punctStyle(double s) =>
    TextStyle(fontSize: s, height: 1.7, fontFamily: AppFonts.mono, color: AppColors.mutedForeground);

final _token = RegExp(
  r'"(\\u[a-fA-F0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\{\{[^}]*\}\}|\b(true|false)\b|\bnull\b|-?\d+(\.\d+)?([eE][+-]?\d+)?',
);

final _varInString = RegExp(r'\{\{[^}]*\}\}');

/// Pecah string "..." (termasuk kutip) menjadi segmen biasa + {{var}} cyan.
List<TextSpan> _stringSpans(String quoted, TextStyle stringStyle, TextStyle varStyle) {
  if (quoted.length < 2) return [TextSpan(text: quoted, style: stringStyle)];
  final inner = quoted.substring(1, quoted.length - 1);
  final matches = _varInString.allMatches(inner).toList();
  if (matches.isEmpty) return [TextSpan(text: quoted, style: stringStyle)];
  final out = <TextSpan>[TextSpan(text: '"', style: stringStyle)];
  var last = 0;
  for (final m in matches) {
    if (m.start > last) {
      out.add(TextSpan(text: inner.substring(last, m.start), style: stringStyle));
    }
    out.add(TextSpan(text: m.group(0), style: varStyle));
    last = m.end;
  }
  if (last < inner.length) {
    out.add(TextSpan(text: inner.substring(last), style: stringStyle));
  }
  out.add(TextSpan(text: '"', style: stringStyle));
  return out;
}

TextSpan highlightJson(String source, {double size = 12}) {
  final spans = <TextSpan>[];
  var last = 0;
  for (final m in _token.allMatches(source)) {
    if (m.start > last) {
      spans.add(TextSpan(text: source.substring(last, m.start), style: _punctStyle(size)));
    }
    final tok = m.group(0)!;
    if (tok.startsWith('{{')) {
      spans.add(TextSpan(text: tok, style: _varStyle(size)));
    } else if (tok.startsWith('"')) {
      // Pisahkan colon dari key agar ':' memakai warna punct, bukan biru.
      final colonIdx = tok.lastIndexOf(':');
      final isKey = colonIdx != -1 && tok.substring(colonIdx).trim() == ':';
      if (isKey) {
        final quotePart = tok.substring(0, colonIdx).trimRight();
        final colonPart = tok.substring(colonIdx);
        final gap = tok.substring(quotePart.length, colonIdx);
        spans.addAll(_stringSpans(quotePart, _keyStyle(size), _varStyle(size)));
        if (gap.isNotEmpty) {
          spans.add(TextSpan(text: gap, style: _punctStyle(size)));
        }
        spans.add(TextSpan(text: colonPart, style: _punctStyle(size)));
      } else {
        spans.addAll(_stringSpans(tok, _stringStyle(size), _varStyle(size)));
      }
    } else if (tok == 'true' || tok == 'false' || tok == 'null') {
      spans.add(TextSpan(text: tok, style: _boolStyle(size)));
    } else {
      spans.add(TextSpan(text: tok, style: _numberStyle(size)));
    }
    last = m.end;
  }
  if (last < source.length) {
    spans.add(TextSpan(text: source.substring(last), style: _punctStyle(size)));
  }
  if (spans.isEmpty) return TextSpan(text: source, style: _mono(size));
  return TextSpan(children: spans, style: _mono(size));
}

/// Controller yang mewarnai teks JSON langsung di dalam TextField
/// (via buildTextSpan) sehingga caret & selection tetap native.
class HighlightedJsonController extends TextEditingController {
  HighlightedJsonController({super.text});

  double fontSize = 13;

  /// Batas highlight: body raksasa (>60k char) ditampilkan plain agar
  /// tiap keystroke tidak me-regex seluruh teks.
  static const int kMaxHighlightChars = 60000;

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    if (text.length > kMaxHighlightChars) {
      return TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, height: 1.7, fontFamily: AppFonts.mono, color: AppColors.foreground),
      );
    }
    return highlightJson(text, size: fontSize);
  }
}

/// Pretty-print JSON dengan toleransi placeholder {{var}}.
///
/// {{var}} bukan JSON valid, jadi sementara diganti token dummy sebelum
/// decode, lalu dikembalikan lagi setelah diformat. Return null jika input
/// bukan JSON (biar caller bisa menampilkan pesan error).
String? prettyJsonWithVars(String raw, {String indent = '  '}) {
  if (raw.trim().isEmpty) return raw;
  // Petakan status in-string per index agar masking tidak merusak string
  // yang mengandung placeholder ("{{baseUrl}}/users").
  final inStr = List<bool>.filled(raw.length + 1, false);
  var inString = false;
  var escape = false;
  for (var i = 0; i < raw.length; i++) {
    final c = raw[i];
    if (inString) {
      if (escape) {
        escape = false;
      } else if (c == '\\') {
        escape = true;
      } else if (c == '"') {
        inString = false;
      }
    } else if (c == '"') {
      inString = true;
    }
    inStr[i + 1] = inString;
  }
  final placeholders = <String>[];
  final bare = <bool>[];
  final masked = raw.replaceAllMapped(RegExp(r'\{\{[^{}]*\}\}'), (m) {
    final i = placeholders.length;
    placeholders.add(m.group(0)!);
    final inside = inStr[m.start];
    bare.add(!inside);
    return inside ? '__DECLIENT_VAR_${i}__' : '"__DECLIENT_VAR_${i}__"';
  });
  dynamic decoded;
  try {
    decoded = json.decode(masked);
  } catch (_) {
    return null;
  }
  String out;
  try {
    out = const JsonEncoder.withIndent('  ').convert(decoded);
    if (indent != '  ') {
      out = out.replaceAll('  ', indent);
    }
  } catch (_) {
    return null;
  }
  for (var i = 0; i < placeholders.length; i++) {
    if (bare[i]) {
      // Nilai bare ({{count}} tanpa kutip): kembalikan tanpa kutip.
      // Hasilnya bukan JSON valid, tapi setia pada input user.
      out = out.replaceAll('"__DECLIENT_VAR_${i}__"', placeholders[i]);
    } else {
      out = out.replaceAll('__DECLIENT_VAR_${i}__', placeholders[i]);
    }
  }
  return out;
}

/// Cek cepat apakah teks (dengan kemungkinan {{var}}) adalah JSON valid.
bool isJsonWithVars(String raw) => prettyJsonWithVars(raw) != null;
