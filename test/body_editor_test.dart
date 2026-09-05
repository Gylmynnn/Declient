import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:declient/app/data/services/api_service.dart';
import 'package:declient/app/modules/home/controllers/request_editor_controller.dart';
import 'package:declient/app/modules/home/views/widgets/json_code_editor.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    if (!Get.isRegistered<ApiService>()) Get.put(ApiService(), permanent: true);
  });

  tearDown(() {
    if (Get.isRegistered<RequestEditorController>()) {
      Get.delete<RequestEditorController>(force: true);
    }
  });

  RequestEditorController makeController() {
    final c = RequestEditorController();
    Get.put(c);
    c.bodyType.value = 'json';
    return c;
  }

  Future<void> pumpEditor(WidgetTester tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: JsonCodeEditor())),
    );
    await tester.pump();
  }

  testWidgets('body kosong + caret 0 tidak crash (RangeError fix)', (tester) async {
    final c = makeController();
    await pumpEditor(tester);
    // Paksa seleksi ke offset 0 (pemicu crash sebelumnya).
    c.bodyController.selection = const TextSelection.collapsed(offset: 0);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('empty'), findsOneWidget);
    expect(find.text('Ln 1, Col 1'), findsOneWidget);
  });

  testWidgets('body kosong terbuka langsung tanpa crash', (tester) async {
    makeController();
    await pumpEditor(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('mengetik JSON valid menampilkan status valid', (tester) async {
    final c = makeController();
    await pumpEditor(tester);
    await tester.enterText(find.byType(TextField), '{"id": 21}');
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('valid JSON'), findsOneWidget);
    expect(c.bodyEditorLineCount, 1);
  });

  test('auto-close { menjadi {} (controller)', () {
    final c = makeController();
    // Warm-up: fokus editor (seleksi valid di offset 0).
    c.bodyController.value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
    );
    // Simulasi ketik '{' di editor kosong.
    c.bodyController.value = const TextEditingValue(
      text: '{',
      selection: TextSelection.collapsed(offset: 1),
    );
    expect(c.bodyController.text, '{}');
    expect(c.bodyController.selection.baseOffset, 1);
  });

  test('Enter di awal teks tidak crash + ikut indent', () {
    final c = makeController();
    c.bodyController.value = const TextEditingValue(
      text: '  "a": 1',
      selection: TextSelection.collapsed(offset: 0),
    );
    // Simulasi tekan Enter di offset 0.
    c.bodyController.value = const TextEditingValue(
      text: '\n  "a": 1',
      selection: TextSelection.collapsed(offset: 1),
    );
    expect(c.bodyController.text.startsWith('\n  '), true);
  });

  test('Enter di antara {} membelah 3 baris', () {
    final c = makeController();
    c.bodyController.value = const TextEditingValue(
      text: '{}',
      selection: TextSelection.collapsed(offset: 1),
    );
    // Simulasi tekan Enter di antara { dan }.
    c.bodyController.value = const TextEditingValue(
      text: '{\n}',
      selection: TextSelection.collapsed(offset: 2),
    );
    expect(c.bodyController.text, '{\n  \n}');
  });

  test('bodyEditorCursor aman untuk semua posisi batas', () {
    final c = makeController();
    expect(c.bodyEditorCursor, (1, 1)); // kosong + seleksi invalid
    c.bodyController.selection = const TextSelection.collapsed(offset: 0);
    expect(c.bodyEditorCursor, (1, 1));
    c.bodyController.text = 'ab\ncd';
    c.bodyController.selection = const TextSelection.collapsed(offset: 5);
    expect(c.bodyEditorCursor, (2, 3));
  });
}
