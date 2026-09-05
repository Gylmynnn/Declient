import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_fonts.dart';
import '../../../../core/utils/app_snack.dart';
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
  Get.dialog(
    AlertDialog(
      title: Text(editId == null ? 'Collection baru' : 'Rename collection',
          style: const TextStyle(color: AppColors.foreground)),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameC, style: const TextStyle(color: AppColors.foreground), decoration: const InputDecoration(hintText: 'Nama collection')),
            const SizedBox(height: 8),
            TextField(controller: descC, style: const TextStyle(color: AppColors.foreground), decoration: const InputDecoration(hintText: 'Deskripsi (opsional)')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () {
            final name = nameC.text.trim();
            if (name.isEmpty) return;
            if (editId == null) {
              col.createCollection(name, descC.text.trim());
            } else {
              col.updateCollection(editId, name, descC.text.trim());
            }
          },
          child: const Text('Simpan'),
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
  Get.dialog(
    AlertDialog(
      title: Text(editId == null ? 'Folder baru' : 'Rename folder', style: const TextStyle(color: AppColors.foreground)),
      content: SizedBox(
        width: 340,
        child: TextField(controller: nameC, style: const TextStyle(color: AppColors.foreground), decoration: const InputDecoration(hintText: 'Nama folder')),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () {
            final name = nameC.text.trim();
            if (name.isEmpty) return;
            if (editId == null) {
              col.createFolder(name: name, parentId: parentId);
            } else {
              col.updateFolder(editId, name, '');
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}

void showRequestDialog({String folderId = ''}) {
  final nameC = TextEditingController();
  final urlC = TextEditingController();
  final methods = RequestEditorController.methods;
  final method = methods.first.obs;
  Get.dialog(
    AlertDialog(
      title: const Text('Request baru', style: TextStyle(color: AppColors.foreground)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameC, style: const TextStyle(color: AppColors.foreground), decoration: const InputDecoration(hintText: 'Nama request')),
            const SizedBox(height: 8),
            Row(
              children: [
                Obx(() => DropdownButton<String>(
                      value: method.value,
                      dropdownColor: AppColors.backgroundDark,
                      items: methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (v) {
                        if (v != null) method.value = v;
                      },
                    )),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(controller: urlC, style: const TextStyle(color: AppColors.foreground, fontSize: 13), decoration: const InputDecoration(hintText: 'https://api...')),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () {
            final name = nameC.text.trim().isEmpty ? 'Untitled' : nameC.text.trim();
            Get.find<CollectionController>().createRequest(name: name, folderId: folderId, method: method.value, url: urlC.text.trim());
          },
          child: const Text('Buat'),
        ),
      ],
    ),
  );
}

void showExportDialog() {
  final api = Get.find<ApiService>();
  Get.dialog(
    AlertDialog(
      title: const Text('Export semua data', style: TextStyle(color: AppColors.foreground)),
      content: const SizedBox(
        width: 380,
        child: Text('JSON native DeClient (collections, folders, requests, environments) akan disalin ke clipboard.',
            style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () async {
            final data = await api.exportAll();
            await Clipboard.setData(ClipboardData(text: json.encode(data)));
            Get.back();
            AppSnack.success('Hasil export disalin ke clipboard');
          },
          child: const Text('Copy JSON'),
        ),
      ],
    ),
  );
}

void showPostmanImportDialog() {
  final api = Get.find<ApiService>();
  final col = Get.find<CollectionController>();
  final jsonC = TextEditingController();
  Get.dialog(
    AlertDialog(
      title: const Text('Import Postman v2.1', style: TextStyle(color: AppColors.foreground)),
      content: SizedBox(
        width: 480,
        height: 320,
        child: Column(
          children: [
            const Text('Paste isi file Postman collection JSON di bawah.',
                style: TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: jsonC,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(color: AppColors.foreground, fontSize: AppFonts.monoSize, fontFamily: AppFonts.mono),
                decoration: const InputDecoration(hintText: '{"info": {...}, "item": [...]}'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () async {
            try {
              final parsed = json.decode(jsonC.text) as Map<String, dynamic>;
              await api.importPostman(parsed);
              await col.fetchCollections();
              Get.back();
              AppSnack.success('Import Postman berhasil');
            } catch (e) {
              AppSnack.error('JSON tidak valid / import gagal: $e', title: 'Gagal');
            }
          },
          child: const Text('Import'),
        ),
      ],
    ),
  );
}
