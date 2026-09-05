import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:declient/app/core/utils/json_highlighter.dart';

String _flatten(TextSpan span) {
  if (span.text != null) return span.text!;
  final b = StringBuffer();
  span.children?.forEach((c) {
    if (c is TextSpan) b.write(_flatten(c));
  });
  return b.toString();
}

void main() {
  test('pretty compact json', () {
    final out = prettyJsonWithVars('{"id":21,"title":"Samsung s 22 ultra"}');
    expect(out, isNotNull);
    expect(out!, contains('\n  "id": 21,'));
  });

  test('pretty keeps {{var}} placeholder', () {
    final out = prettyJsonWithVars('{"url":"{{baseUrl}}/users","n":1}');
    expect(out, isNotNull);
    expect(out!, contains('{{baseUrl}}'));
    expect(out, contains('"n": 1'));
  });

  test('pretty keeps bare {{var}} value', () {
    final out = prettyJsonWithVars('{"a": {{count}}, "b": 2}');
    expect(out, isNotNull);
    expect(out!, contains('{{count}}'));
  });

  test('pretty invalid returns null', () {
    expect(prettyJsonWithVars('not json {{{'), isNull);
    expect(prettyJsonWithVars('{"a":}'), isNull);
  });

  test('highlight covers full text exactly', () {
    const samples = [
      '{"id": 21,\n"title": "Samsung s 22 ultra",\n"price": 200.0}',
      '{"url": "{{baseUrl}}/x", "ok": true, "n": null}',
      '{{standalone}}',
      'plain text {{{ no json',
      '',
    ];
    for (final s in samples) {
      expect(_flatten(highlightJson(s)), s, reason: 'coverage for: $s');
    }
  });

  test('colon after key is not part of key span', () {
    final span = highlightJson('{"a": 1}');
    final flat = _flatten(span);
    expect(flat, '{"a": 1}');
    // key span should not include colon
    var foundKey = false;
    void walk(TextSpan sp) {
      if (sp.text == '"a"') foundKey = true;
      sp.children?.forEach((c) => walk(c as TextSpan));
    }
    walk(span);
    expect(foundKey, true);
  });
}
