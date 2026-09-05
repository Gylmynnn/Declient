import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_fonts.dart';
import '../../../../core/utils/json_highlighter.dart';
import '../../controllers/request_editor_controller.dart';

/// Editor body JSON reaktif murni (StatelessWidget + Obx, tanpa setState).
///
/// - syntax highlighting (via [HighlightedJsonController.buildTextSpan])
/// - tombol Pretty (format, lewat controller)
/// - auto-close bracket/quote, auto-indent Enter, Tab/Shift+Tab
///   (semua state & logika hidup di [RequestEditorController])
/// - gutter nomor baris + status Ln/Col + indikator JSON valid
class JsonCodeEditor extends GetView<RequestEditorController> {
  const JsonCodeEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final fontSize = AppFonts.monoSize + 1;
      final bc = controller.bodyController;
      if (bc is HighlightedJsonController) bc.fontSize = fontSize;
      final lineHeight = fontSize * 1.7;
      final text = bc.text;
      final lineCount = controller.bodyEditorLineCount;
      final valid = controller.bodyEditorJsonValid;
      final (ln, col) = controller.bodyEditorCursor;

      final accent = valid == null
          ? AppColors.comment
          : valid
              ? AppColors.green
              : AppColors.red;

      return Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surface),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Toolbar mini: status + pretty
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 6, 2),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    valid == null
                        ? 'empty'
                        : valid
                            ? 'valid JSON'
                            : 'invalid JSON',
                    style: TextStyle(color: accent, fontSize: 11),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Ln $ln, Col $col',
                    style: const TextStyle(
                        color: AppColors.comment, fontSize: 11),
                  ),
                  const Spacer(),
                  Tooltip(
                    message: 'Ratakan / format JSON (Pretty)',
                    child: TextButton.icon(
                      onPressed: text.trim().isEmpty
                          ? null
                          : controller.formatBodyPretty,
                      icon: const Icon(LucideIcons.sparkles, size: 14),
                      label:
                          const Text('Pretty', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => controller.bodyFocusNode.requestFocus(),
                child: Scrollbar(
                  controller: controller.bodyScrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: controller.bodyScrollController,
                    padding: const EdgeInsets.fromLTRB(0, 8, 8, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Gutter nomor baris
                        SizedBox(
                          width: 46,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (var i = 1; i <= lineCount; i++)
                                SizedBox(
                                  height: lineHeight,
                                  child: Text(
                                    '$i',
                                    style: TextStyle(
                                      color: i == ln
                                          ? AppColors.mutedForeground
                                          : AppColors.comment,
                                      fontSize: fontSize - 1,
                                      height: 1.7,
                                      fontFamily: AppFonts.mono,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Focus(
                            onKeyEvent: controller.handleBodyKey,
                            child: TextSelectionTheme(
                              data: TextSelectionThemeData(
                                selectionColor:
                                    AppColors.blue.withValues(alpha: 0.35),
                                cursorColor: AppColors.blue,
                                selectionHandleColor: AppColors.blue,
                              ),
                              child: TextField(
                                controller: controller.bodyController,
                                focusNode: controller.bodyFocusNode,
                                maxLines: null,
                                expands: false,
                                scrollPhysics:
                                    const NeverScrollableScrollPhysics(),
                                textAlignVertical: TextAlignVertical.top,
                                cursorColor: AppColors.blue,
                                style: TextStyle(
                                  color: AppColors.foreground,
                                  fontSize: fontSize,
                                  fontFamily: AppFonts.mono,
                                  height: 1.7,
                                ),
                                decoration: const InputDecoration(
                                  hintText: '{\n  "key": "value"\n}',
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
