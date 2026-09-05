import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:declient/app/data/models/api_request_model.dart';
import 'package:declient/app/data/models/form_data_field.dart';
import 'package:declient/app/modules/home/views/widgets/form_data_editor.dart';

void main() {
  test('FormDataField JSON round-trip tanpa bytes', () {
    const f = FormDataField(
      key: 'avatar',
      type: 'file',
      fileName: 'a.png',
      filePath: '/tmp/a.png',
      fileSize: 4,
      contentType: 'image/png',
    );
    final rt =
        FormDataField.fromJson(Map<String, dynamic>.from(f.toJson()));
    expect(rt.key, 'avatar');
    expect(rt.type, 'file');
    expect(rt.fileName, 'a.png');
    expect(rt.filePath, '/tmp/a.png');
    expect(rt.fileSize, 4);
    expect(rt.hasBytes, false);
    // Tanpa includeBytes tidak ada base64 (storage tetap ramping).
    expect(f.toJson().containsKey('fileBase64'), false);
  });

  test('FormDataField toJson includeBytes untuk payload send', () {
    final f = FormDataField(
      key: 'avatar',
      type: 'file',
      fileName: 'a.png',
      fileBytes: Uint8List.fromList([0x89, 0x50]),
    );
    final m = f.toJson(includeBytes: true);
    expect(m['fileBase64'], 'iVA=');
  });

  test('ApiRequestModel formData round-trip + default kosong', () {
    final req = ApiRequestModel(
      id: '1',
      collectionId: 'c',
      name: 'Upload',
      bodyType: 'multipart',
      formData: const [FormDataField(key: 'n', value: 'budi')],
    );
    final rt = ApiRequestModel.fromJson(req.toJson());
    expect(rt.bodyType, 'multipart');
    expect(rt.formData.length, 1);
    expect(rt.formData.first.value, 'budi');

    final legacy = ApiRequestModel.fromJson({'id': '2', 'collectionId': 'c'});
    expect(legacy.formData, isEmpty);
  });

  test('guessContentType + formatFileSize', () {
    expect(guessContentType('a.PNG'), 'image/png');
    expect(guessContentType('doc.pdf'), 'application/pdf');
    expect(guessContentType('data.json'), 'application/json');
    expect(guessContentType('noext'), 'application/octet-stream');
    expect(formatFileSize(512), '512 B');
    expect(formatFileSize(2048), '2.0 KB');
    expect(formatFileSize(3 * 1024 * 1024), '3.0 MB');
  });

  testWidgets('FormDataEditor render kosong + baris text/file', (tester) async {
    final items = <FormDataField>[
      const FormDataField(key: 'name', value: 'budi'),
      FormDataField(
        key: 'avatar',
        type: 'file',
        fileName: 'a.png',
        fileSize: 2048,
        fileBytes: Uint8List.fromList([1, 2, 3]),
      ),
    ].obs;
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: FormDataEditor(
            items: items,
            onAdd: () {},
            onRemove: (_) {},
            onUpdate: (i, v) => items[i] = v,
            onPickFile: (_) async {},
            onClearFile: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Add field'), findsOneWidget);
    expect(find.text('name'), findsOneWidget);
    expect(find.textContaining('a.png'), findsOneWidget);
    expect(find.textContaining('2.0 KB'), findsOneWidget);
  });
}
