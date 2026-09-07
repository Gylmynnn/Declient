import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_dialog.dart';
import '../../../../core/utils/app_fonts.dart';
import '../../../../core/utils/app_snack.dart';
import 'response_body_view.dart';
import '../../../../core/utils/method_colors.dart';
import '../../controllers/history_controller.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/request_editor_controller.dart';
import 'segmented_tabs.dart';

class ResponsePanel extends GetView<RequestEditorController> {
  const ResponsePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(
            () => Row(
              children: [
                SegmentedTabs(
                  labels: const ['Response', 'History'],
                  current: controller.bottomTabIndex.value,
                  onTap: (i) {
                    controller.bottomTabIndex.value = i;
                    if (i == 1) Get.find<HistoryController>().fetchHistory();
                  },
                ),
                const Spacer(),
                if (controller.bottomTabIndex.value == 0 &&
                    controller.response.value != null)
                  Flexible(
                    child: Obx(() {
                      final r = controller.response.value!;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DetaskBadge(
                            text: '${r.statusCode}',
                            color: httpStatusColor(r.statusCode),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${r.durationMs}ms • ${r.size}B',
                              style: const TextStyle(
                                color: AppColors.mutedForeground,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                const SizedBox(width: 4),
                Obx(() {
                  final home = Get.find<HomeController>();
                  return IconButton(
                    tooltip: home.verticalSplit.value
                        ? 'Split horizontal (top-bottom)'
                        : 'Split vertical (left-right)',
                    onPressed: home.toggleSplit,
                    icon: Icon(
                      home.verticalSplit.value
                          ? LucideIcons.splitSquareHorizontal
                          : LucideIcons.splitSquareVertical,
                      size: 18,
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(() {
              if (controller.bottomTabIndex.value == 1) {
                return const HistoryPanel();
              }
              if (controller.isSending.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final res = controller.response.value;
              if (res == null) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.rocket,
                        size: 36,
                        color: AppColors.comment,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No response yet. Click Send to execute the request.',
                        style: TextStyle(
                          color: AppColors.comment,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (res.resolvedUrl.isNotEmpty)
                    SelectableText(
                      '→ ${res.resolvedUrl}',
                      style: TextStyle(
                        color: AppColors.comment,
                        fontSize: 11,
                        fontFamily: AppFonts.mono,
                      ),
                    ),
                  const SizedBox(height: 6),
                  if (res.headers.isNotEmpty)
                    SizedBox(
                      height: 70,
                      child: ListView(
                        children: res.headers.entries
                            .map(
                              (e) => SelectableText(
                                '${e.key}: ${e.value}',
                                style: TextStyle(
                                  color: AppColors.mutedForeground,
                                  fontSize: 11,
                                  fontFamily: AppFonts.mono,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  const Divider(height: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.surface),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Body',
                                style: TextStyle(
                                  color: AppColors.comment,
                                  fontSize: 11,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: 'Copy body',
                                onPressed: () {
                                  Clipboard.setData(
                                      ClipboardData(text: res.body));
                                  AppSnack.success(
                                    'Body copied to clipboard',
                                    duration: const Duration(seconds: 1),
                                  );
                                },
                                icon: const Icon(
                                  LucideIcons.copy,
                                  size: 15,
                                ),
                              ),
                              Obx(
                                () => Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Obx(
                                      () => Text(
                                        controller.bodyTruncated.value
                                            ? '${controller.bodyLineCount.value} lines (truncated)'
                                            : '${controller.bodyLineCount.value} lines',
                                        style: const TextStyle(
                                          color: AppColors.comment,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Pretty',
                                      style: TextStyle(
                                        color: AppColors.comment,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Switch(
                                      value: controller.prettyPrint.value,
                                      onChanged: controller.togglePretty,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Expanded(child: ResponseBodyView()),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class HistoryPanel extends GetView<HistoryController> {
  const HistoryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Text(
              'Last 50 executions',
              style: TextStyle(color: AppColors.comment, fontSize: 12),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => AppDialog.confirm(
                title: 'Clear history?',
                message: 'All execution history will be deleted.',
                onConfirm: controller.clear,
              ),
              icon: const Icon(LucideIcons.trash2, size: 16),
              label: const Text('Clear', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.history.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.history,
                      size: 36,
                      color: AppColors.comment,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Empty history',
                      style: TextStyle(
                        color: AppColors.comment,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              itemCount: controller.history.length,
              itemBuilder: (_, i) {
                final h = controller.history[i];
                return ListTile(
                  dense: true,
                  leading: SizedBox(
                    width: 46,
                    child: Text(
                      h.method,
                      style: const TextStyle(
                        color: AppColors.blue,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text(
                    h.requestName,
                    style: const TextStyle(
                      color: AppColors.foreground,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${h.statusCode} • ${h.durationMs}ms • ${h.resolvedUrl.isEmpty ? h.url : h.resolvedUrl}',
                    style: const TextStyle(
                      color: AppColors.comment,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}
