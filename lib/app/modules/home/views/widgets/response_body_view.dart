import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_fonts.dart';
import '../../../../core/utils/json_highlighter.dart';
import '../../controllers/request_editor_controller.dart';

/// Body response tervirtualisasi: tiap segmen satu item ListView sehingga
/// body puluhan ribu baris tidak mem-freeze UI. Highlight dihitung lazily
/// hanya untuk segmen yang terlihat.
///
/// Baris dibiarkan wrap dengan tinggi natural (tanpa itemExtent) agar baris
/// panjang tidak tumpuk/bergeser saat scroll. Scroll vertikal dikendalikan
/// [RequestEditorController.responseBodyVController] dan direset ke atas
/// setiap response baru.
class ResponseBodyView extends GetView<RequestEditorController> {
  const ResponseBodyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final segs = controller.bodySegments;
      if (segs.isEmpty) {
        return const Center(
          child: Text(
            '(empty body)',
            style: TextStyle(color: AppColors.comment, fontSize: 12),
          ),
        );
      }
      final isJson = controller.bodyIsJson.value;
      final size = AppFonts.monoSize;
      return Scrollbar(
        controller: controller.responseBodyVController,
        thumbVisibility: true,
        child: ListView.builder(
          controller: controller.responseBodyVController,
          itemCount: segs.length,
          itemBuilder: (_, i) {
            final seg = segs[i];
            return Padding(
              padding: EdgeInsets.only(top: i == 0 ? 2 : 0, bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(
                      seg.lineNo?.toString() ?? '',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: AppColors.comment,
                        fontSize: size - 1,
                        height: 1.7,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SelectableText.rich(
                      isJson
                          ? highlightJson(seg.text.isEmpty ? ' ' : seg.text, size: size)
                          : TextSpan(
                              text: seg.text.isEmpty ? ' ' : seg.text,
                              style: TextStyle(
                                color: AppColors.foreground,
                                fontSize: size,
                                fontFamily: AppFonts.mono,
                                height: 1.7,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}
