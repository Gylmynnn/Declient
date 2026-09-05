import 'package:flutter_test/flutter_test.dart';
import 'package:declient/app/core/utils/body_chunk.dart';
import 'package:declient/app/core/utils/json_highlighter.dart';
import 'package:declient/app/data/models/api_request_model.dart';
import 'package:declient/app/data/models/collection_model.dart';
import 'package:declient/app/data/models/environment_model.dart';
import 'package:declient/app/data/models/key_value.dart';

void main() {
  test('KeyValue JSON round-trip', () {
    const kv = KeyValue(key: 'a', value: 'b');
    final rt = KeyValue.fromJson(kv.toJson());
    expect(rt.key, 'a');
    expect(rt.value, 'b');
    expect(rt.enabled, true);
  });

  test('ApiRequestModel defaults + JSON round-trip', () {
    final req = ApiRequestModel(id: '1', collectionId: 'c', name: 'Tes', method: 'get', url: 'https://{{baseUrl}}/x');
    expect(req.method, 'get');
    final rt = ApiRequestModel.fromJson(req.toJson());
    expect(rt.url, 'https://{{baseUrl}}/x');
    expect(rt.auth.type, 'none');
  });

  test('highlightJson splits tokens, plain text safe', () {
    final span = highlightJson('{"a": 1, "b": true, "c": null, "d": "x"}');
    expect(span.children!.length, greaterThan(4));
    final plain = highlightJson('not json at all {{{');
    expect(plain.children!.length, 1);
  });

  test('buildBodySegments: empty, json pretty, long-line chunking', () {
    final empty = buildBodySegments('', true);
    expect(empty.segments, isEmpty);
    expect(empty.isJson, false);

    final js = buildBodySegments('{"a":1,"b":[1,2]}', true);
    expect(js.isJson, true);
    expect(js.lineCount, greaterThan(1));
    expect(js.segments.every((s) => s.text.length <= kMaxSegmentChars), true);

    final long = 'x' * (kMaxSegmentChars * 2 + 100);
    final chunked = buildBodySegments(long, true);
    expect(chunked.isJson, false);
    expect(chunked.segments.length, 3);
    expect(chunked.segments.first.lineNo, 1);
    expect(chunked.segments[1].lineNo, isNull);

    final raw = buildBodySegments('{"a":1}', false);
    expect(raw.segments.length, 1);
    expect(raw.segments.first.text, '{"a":1}');
  });

  test('CollectionModel + EnvironmentModel parsing', () {
    final c = CollectionModel.fromJson({'id': 'c1', 'name': 'API'});
    expect(c.name, 'API');
    final e = EnvironmentModel.fromJson({
      'id': 'e1',
      'name': 'Local',
      'variables': [
        {'key': 'baseUrl', 'value': 'http://localhost', 'enabled': true},
      ],
    });
    expect(e.variables.first.key, 'baseUrl');
  });
}
