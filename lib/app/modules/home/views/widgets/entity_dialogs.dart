import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_dialog.dart';
import '../../../../core/utils/app_fonts.dart';
import '../../../../core/utils/app_menu.dart';
import '../../../../core/utils/app_snack.dart';
import '../../../../core/utils/method_colors.dart';
import '../../../../data/services/api_service.dart';
import '../../controllers/collection_controller.dart';
import '../../controllers/request_editor_controller.dart';

void showCollectionDialog({String? editId}) {
  final col = Get.find<CollectionController>();
  final nameC = TextEditingController();
  final descC = TextEditingController();
  if (editId != null) {
    final existing = col.collections.firstWhere((c) => c.id == editId);
    nameC.text = existing.name;
    descC.text = existing.description;
  }
  AppDialog.form(
    title: editId == null ? 'New collection' : 'Rename collection',
    subtitle: 'Top-level container for folders & requests.',
    icon: LucideIcons.folderKanban,
    accent: AppColors.green,
    submitText: editId == null ? 'Create' : 'Save',
    onSubmit: () async {
      final name = nameC.text.trim();
      if (name.isEmpty) {
        AppSnack.warning('Collection name is required');
        return;
      }
      if (editId == null) {
        await col.createCollection(name, descC.text.trim());
      } else {
        await col.updateCollection(editId, name, descC.text.trim());
      }
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppField(
          label: 'Name',
          hint: 'Enter name...',
          controller: nameC,
          prefixIcon: LucideIcons.tag,
          accent: AppColors.green,
        ),
        const SizedBox(height: 12),
        AppField(
          label: 'Description',
          hint: 'Optional...',
          controller: descC,
          prefixIcon: LucideIcons.alignLeft,
          accent: AppColors.green,
        ),
      ],
    ),
  );
}

void showFolderDialog({String? editId, String parentId = ''}) {
  final col = Get.find<CollectionController>();
  final nameC = TextEditingController();
  if (editId != null) {
    nameC.text = col.folders.firstWhere((f) => f.id == editId).name;
  }
  AppDialog.form(
    title: editId == null ? 'New folder' : 'Rename folder',
    subtitle: 'Group requests to keep the sidebar organized.',
    icon: LucideIcons.folder,
    accent: AppColors.blue,
    submitText: editId == null ? 'Create' : 'Save',
    onSubmit: () async {
      final name = nameC.text.trim();
      if (name.isEmpty) {
        AppSnack.warning('Folder name is required');
        return;
      }
      if (editId == null) {
        await col.createFolder(name: name, parentId: parentId);
      } else {
        await col.updateFolder(editId, name, '');
      }
    },
    child: AppField(
      label: 'Folder name',
      hint: 'e.g. Auth / Users',
      controller: nameC,
      prefixIcon: LucideIcons.folder,
      accent: AppColors.blue,
    ),
  );
}

void showRequestDialog({String folderId = ''}) {
  final nameC = TextEditingController();
  final urlC = TextEditingController();
  final methods = RequestEditorController.methods;
  final method = methods.first.obs;
  AppDialog.form(
    title: 'New request',
    subtitle: 'Add a request to the sidebar without opening the editor.',
    icon: LucideIcons.zap,
    accent: AppColors.magenta,
    submitText: 'Create',
    onSubmit: () async {
      final name =
          nameC.text.trim().isEmpty ? 'Untitled' : nameC.text.trim();
      await Get.find<CollectionController>().createRequest(
            name: name,
            folderId: folderId,
            method: method.value,
            url: urlC.text.trim(),
          );
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppField(
          label: 'Name',
          hint: 'e.g. Login user',
          controller: nameC,
          prefixIcon: LucideIcons.fileText,
          accent: AppColors.magenta,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Obx(() {
              final m = method.value;
              final c = httpMethodColor(m);
              return Padding(
                padding: const EdgeInsets.only(top: 18),
                child: FancyDropdown<String>(
                  value: m,
                  width: 96,
                  accent: c,
                  textStyle: TextStyle(
                    color: c,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  onChanged: (v) {
                    if (v != null) method.value = v;
                  },
                  items: methods
                      .map((m) => DropdownMenuItem<String>(
                            value: m,
                            child: Text(
                              m,
                              style: TextStyle(
                                color: httpMethodColor(m),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              );
            }),
            const SizedBox(width: 8),
            Expanded(
              child: AppField(
                label: 'URL',
                hint: 'https://api.example.com/...',
                controller: urlC,
                accent: AppColors.magenta,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

void showExportDialog() {
  final api = Get.find<ApiService>();
  AppDialog.form(
    title: 'Export all data',
    subtitle:
        'Native DeClient JSON — collections, folders, requests, environments.',
    icon: LucideIcons.download,
    accent: AppColors.cyan,
    submitText: 'Copy JSON',
    cancelText: 'Close',
    maxWidth: 420,
    onSubmit: () async {
      final data = await api.exportAll();
      await Clipboard.setData(ClipboardData(text: json.encode(data)));
      AppSnack.success('Export copied to clipboard');
    },
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surface),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.clipboard, size: 14, color: AppColors.mutedForeground),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Export result will be automatically copied to clipboard.',
              style: TextStyle(
                color: AppColors.mutedForeground,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

void showPostmanImportDialog() {
  final api = Get.find<ApiService>();
  final col = Get.find<CollectionController>();
  final jsonC = TextEditingController();
  AppDialog.form(
    title: 'Import Postman v2.1',
    subtitle: 'Paste the contents of a Postman collection JSON file below.',
    icon: LucideIcons.upload,
    accent: AppColors.magenta,
    submitText: 'Import',
    maxWidth: 540,
    minHeight: 320,
    onSubmit: () async {
      try {
        final parsed = json.decode(jsonC.text) as Map<String, dynamic>;
        await api.importPostman(parsed);
        await col.fetchCollections();
        AppSnack.success('Postman imported successfully');
      } catch (e) {
        AppSnack.error('Invalid JSON / import failed: $e', title: 'Failed');
      }
    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'JSON',
          style: TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 5),
        Expanded(
          child: Obx(() => TextField(
                controller: jsonC,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(
                  color: AppColors.foreground,
                  fontSize: AppFonts.monoSize,
                  fontFamily: AppFonts.mono,
                ),
                decoration: InputDecoration(
                  hintText: '{"info": {...}, "item": [...]}',
                  hintStyle: TextStyle(
                    color: AppColors.comment,
                    fontSize: AppFonts.monoSize,
                    fontFamily: AppFonts.mono,
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.surface),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.surface),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: AppColors.magenta.withValues(alpha: 0.7),
                        width: 1.4),
                  ),
                ),
              )),
        ),
      ],
    ),
  );
}
