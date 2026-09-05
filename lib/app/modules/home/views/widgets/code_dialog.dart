import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_fonts.dart';
import '../../../../core/utils/app_snack.dart';
import '../../controllers/request_editor_controller.dart';
import 'segmented_tabs.dart';

class CodeDialog extends GetView<RequestEditorController> {
  const CodeDialog({super.key});

  String _fullUrl() {
    final base = controller.urlController.text.trim();
    final enabled = controller.params.where((p) => p.enabled && p.key.isNotEmpty).toList();
    if (enabled.isEmpty) return base;
    final qs = enabled.map((p) => '${Uri.encodeQueryComponent(p.key)}=${Uri.encodeQueryComponent(p.value)}').join('&');
    return base.contains('?') ? '$base&$qs' : '$base?$qs';
  }

  Map<String, String> _headers() {
    final out = <String, String>{};
    for (final h in controller.headers) {
      if (h.enabled && h.key.isNotEmpty) out[h.key] = h.value;
    }
    if (controller.authType.value == 'bearer' && controller.authTokenController.text.isNotEmpty) {
      out['Authorization'] = 'Bearer ${controller.authTokenController.text}';
    }
    return out;
  }

  String _curl() {
    final b = StringBuffer()..write("curl -X ${controller.method.value} '${_fullUrl()}'");
    for (final e in _headers().entries) {
      b.write(" \\\n  -H '${e.key}: ${e.value}'");
    }
    if (controller.authType.value == 'basic') {
      b.write(" \\\n  -u '${controller.authUserController.text}:${controller.authPassController.text}'");
    }
    if (controller.bodyType.value == 'multipart') {
      for (final f in controller.formData) {
        if (!f.enabled || f.key.trim().isEmpty) continue;
        if (f.isFile) {
          final name = f.fileName.isNotEmpty ? f.fileName : 'file';
          final type = f.contentType.isNotEmpty ? f.contentType : 'application/octet-stream';
          b.write(" \\\n  -F '${f.key}=@$name;type=$type'");
        } else {
          final v = f.value.replaceAll("'", "'\\''");
          b.write(" \\\n  -F '${f.key}=$v'");
        }
      }
      return b.toString();
    }
    if (controller.bodyController.text.isNotEmpty &&
        controller.method.value != 'GET' &&
        controller.method.value != 'HEAD') {
      final escaped = controller.bodyController.text.replaceAll("'", "'\\''");
      b.write(" \\\n  -d '$escaped'");
    }
    return b.toString();
  }

  String _dart() {
    final b = StringBuffer()
      ..writeln("import 'package:http/http.dart' as http;")
      ..writeln()
      ..writeln('void main() async {');
    final headers = _headers();
    if (controller.bodyType.value == 'multipart') {
      b.writeln("  final request = http.MultipartRequest('${controller.method.value}', Uri.parse('${_fullUrl()}'));");
      if (headers.isNotEmpty) {
        b.writeln('  request.headers.addAll({');
        for (final e in headers.entries) {
          b.writeln("    '${e.key}': '${e.value}',");
        }
        b.writeln('  });');
      }
      for (final f in controller.formData) {
        if (!f.enabled || f.key.trim().isEmpty) continue;
        if (f.isFile) {
          final name = f.fileName.isNotEmpty ? f.fileName : 'file';
          b.writeln("  request.files.add(await http.MultipartFile.fromPath('${f.key}', '/path/to/$name'));");
        } else {
          b.writeln("  request.fields['${f.key}'] = '${f.value.replaceAll("'", "\\'")}';");
        }
      }
      b.writeln('  final streamed = await request.send();');
      b.writeln('  final res = await http.Response.fromStream(streamed);');
      b.writeln('  print(res.statusCode);');
      b.writeln('  print(res.body);');
      b.writeln('}');
      return b.toString();
    }
    if (headers.isNotEmpty) {
      b.writeln('  final headers = <String, String>{');
      for (final e in headers.entries) {
        b.writeln("    '${e.key}': '${e.value}',");
      }
      b.writeln('  };');
    }
    final hasBody = controller.bodyController.text.isNotEmpty &&
        controller.method.value != 'GET' &&
        controller.method.value != 'HEAD';
    b.write('  final res = await http.${controller.method.value.toLowerCase()}(');
    b.write("Uri.parse('${_fullUrl()}')");
    if (headers.isNotEmpty) b.write(', headers: headers');
    if (hasBody) {
      final escaped = controller.bodyController.text.replaceAll("'", "\\'").replaceAll('\n', '\\n');
      b.write(", body: '$escaped'");
    }
    b.writeln(');');
    b.writeln('  print(res.statusCode);');
    b.writeln('  print(res.body);');
    b.writeln('}');
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final lang = 'cURL'.obs;
    return AlertDialog(
      title: const Text('Generate code', style: TextStyle(color: AppColors.foreground)),
      content: SizedBox(
        width: 560,
        height: 380,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(() => Row(
                  children: [
                    SegmentedTabs(
                      labels: const ['cURL', 'Dart'],
                      current: lang.value == 'cURL' ? 0 : 1,
                      onTap: (i) => lang.value = i == 0 ? 'cURL' : 'Dart',
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Copy',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: lang.value == 'cURL' ? _curl() : _dart()));
                        AppSnack.success('Snippet disalin', duration: const Duration(seconds: 1));
                      },
                      icon: const Icon(LucideIcons.copy, size: 18),
                    ),
                  ],
                )),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.backgroundDark, borderRadius: BorderRadius.circular(8)),
                child: Obx(() => SingleChildScrollView(
                      child: SelectableText(
                        lang.value == 'cURL' ? _curl() : _dart(),
                        style: TextStyle(color: AppColors.foreground, fontSize: AppFonts.monoSize, fontFamily: AppFonts.mono),
                      ),
                    )),
              ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Get.back(), child: const Text('Tutup'))],
    );
  }
}
