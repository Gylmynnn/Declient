import 'package:declient/app/data/models/environment_model.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_menu.dart';
import '../../../../routes/app_pages.dart';
import '../../controllers/collection_controller.dart';
import '../../controllers/environment_controller.dart';
import '../../controllers/history_controller.dart';
import '../../controllers/request_editor_controller.dart';
import 'entity_dialogs.dart';
import 'environment_dialog.dart';

class TopBar extends GetView<EnvironmentController> {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final CollectionController col = Get.find<CollectionController>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.background,
      child: Row(
        children: [
          const Icon(LucideIcons.zap, color: AppColors.blue, size: 22),
          const SizedBox(width: 8),
          const Text(
            'DeClient',
            style: TextStyle(
              color: AppColors.foreground,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          _EnvSelector(),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Kelola environments',
            onPressed: () => Get.dialog(const EnvironmentDialog()),
            icon: const Icon(LucideIcons.slidersHorizontal, size: 19),
          ),
          IconButton(
            tooltip: 'History',
            onPressed: () {
              Get.find<RequestEditorController>().bottomTabIndex.value = 1;
              Get.find<HistoryController>().fetchHistory();
            },
            icon: const Icon(LucideIcons.history, size: 19),
          ),
          const SizedBox(width: 4),
          _ImportExportMenu(),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Get.toNamed(Routes.SETTINGS),
            icon: const Icon(LucideIcons.settings, size: 19),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => Get.find<RequestEditorController>().newAdhoc(),
            icon: const Icon(LucideIcons.plus, size: 17),
            label: const Text('New Request'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(width: 8),
          Obx(() {
            final ed = Get.find<RequestEditorController>();
            return ElevatedButton.icon(
              onPressed: ed.isSending.value ? null : ed.send,
              icon: ed.isSending.value
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.send, size: 16),
              label: Text(ed.hasSelection ? 'Send & Save' : 'Send'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            );
          }),
          const SizedBox(width: 8),
          Obx(() {
            final ed = Get.find<RequestEditorController>();
            if (!ed.hasSelection) return const SizedBox.shrink();
            return ElevatedButton.icon(
              onPressed: ed.isSaving.value ? null : ed.save,
              icon: const Icon(LucideIcons.save, size: 16),
              label: const Text('Save'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            );
          }),
          Obx(
            () => col.isLoading.value
                ? const Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _EnvSelector extends GetView<EnvironmentController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final RxList<EnvironmentModel> items = controller.environments;
      final String? active = controller.activeId.value;
      return FancyDropdown<String?>(
        icon: LucideIcons.boxes,
        value: active,
        hint: 'No Environment',
        width: 280,
        accent: AppColors.green,
        onChanged: controller.setActive,
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('No Environment'),
          ),
          ...items.map(
            (e) => DropdownMenuItem<String?>(value: e.id, child: Text(e.name)),
          ),
        ],
      );
    });
  }
}

class _ImportExportMenu extends GetView<CollectionController> {
  @override
  Widget build(BuildContext context) {
    return FancyMenu(
      icon: LucideIcons.arrowLeftRight,
      tooltip: 'Import / Export',
      accent: AppColors.blue,
      items: [
        FancyMenuItem(
          value: 'export',
          label: 'Export (JSON)',
          icon: LucideIcons.download,
          onSelected: showExportDialog,
        ),
        FancyMenuItem(
          value: 'postman',
          label: 'Import Postman v2.1',
          icon: LucideIcons.upload,
          onSelected: showPostmanImportDialog,
        ),
      ],
    );
  }
}
