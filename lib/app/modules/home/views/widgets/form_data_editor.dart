import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../data/models/form_data_field.dart';

/// Editor multipart/form-data: rows key + tipe (Text/File) + value/file.
///
/// Stateless murni (GetX): state dipegang RxList di controller, aksi lewat
/// callback. File dipilih via controller.pickFormFile (file_picker).
class FormDataEditor extends StatelessWidget {
  final RxList<FormDataField> items;
  final VoidCallback onAdd;
  final void Function(int) onRemove;
  final void Function(int, FormDataField) onUpdate;
  final Future<void> Function(int) onPickFile;
  final void Function(int) onClearFile;

  const FormDataEditor({
    super.key,
    required this.items,
    required this.onAdd,
    required this.onRemove,
    required this.onUpdate,
    required this.onPickFile,
    required this.onClearFile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text(
              'Text dikirim sebagai field, File dikirim sebagai upload (maks 20 MB/file).',
              style: TextStyle(color: AppColors.comment, fontSize: 11),
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (items.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.upload,
                        size: 32, color: AppColors.comment),
                    SizedBox(height: 8),
                    Text('Belum ada field — klik Add field',
                        style: TextStyle(
                            color: AppColors.comment, fontSize: 12)),
                  ],
                ),
              );
            }
            return ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: items.length,
              onReorderItem: (oldI, newI) {
                if (oldI == newI) return;
                final it = items.removeAt(oldI);
                items.insert(newI.clamp(0, items.length), it);
              },
              itemBuilder: (_, i) {
                final f = items[i];
                return Padding(
                  key: ValueKey('form-$i-${f.key}-${f.type}-${f.enabled}'),
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      ReorderableDragStartListener(
                        index: i,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(LucideIcons.gripVertical,
                              size: 17, color: AppColors.comment),
                        ),
                      ),
                      Checkbox(
                        value: f.enabled,
                        onChanged: (v) =>
                            onUpdate(i, f.copyWith(enabled: v ?? true)),
                      ),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: TextEditingController(text: f.key)
                            ..selection = TextSelection.collapsed(
                                offset: f.key.length),
                          onChanged: (v) =>
                              onUpdate(i, f.copyWith(key: v)),
                          style: const TextStyle(
                              color: AppColors.foreground, fontSize: 13),
                          decoration: const InputDecoration(
                              hintText: 'key',
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 9)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.surface),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: f.type,
                            dropdownColor: AppColors.backgroundDark,
                            style: const TextStyle(
                                color: AppColors.mutedForeground, fontSize: 12),
                            items: const [
                              DropdownMenuItem(
                                  value: 'text', child: Text('Text')),
                              DropdownMenuItem(
                                  value: 'file', child: Text('File')),
                            ],
                            onChanged: (v) {
                              if (v != null) onUpdate(i, f.copyWith(type: v));
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(flex: 3, child: _ValueCell(field: f, index: i, onUpdate: onUpdate, onPickFile: onPickFile, onClearFile: onClearFile)),
                      IconButton(
                          onPressed: () => onRemove(i),
                          icon: const Icon(LucideIcons.x, size: 17)),
                    ],
                  ),
                );
              },
            );
          }),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Add field')),
        ),
      ],
    );
  }
}

class _ValueCell extends StatelessWidget {
  final FormDataField field;
  final int index;
  final void Function(int, FormDataField) onUpdate;
  final Future<void> Function(int) onPickFile;
  final void Function(int) onClearFile;

  const _ValueCell({
    required this.field,
    required this.index,
    required this.onUpdate,
    required this.onPickFile,
    required this.onClearFile,
  });

  @override
  Widget build(BuildContext context) {
    final f = field;
    if (!f.isFile) {
      return TextField(
        controller: TextEditingController(text: f.value)
          ..selection = TextSelection.collapsed(offset: f.value.length),
        onChanged: (v) => onUpdate(index, f.copyWith(value: v)),
        style: const TextStyle(color: AppColors.foreground, fontSize: 13),
        decoration: const InputDecoration(
            hintText: 'value (bisa pakai {{var}})',
            contentPadding:
                EdgeInsets.symmetric(horizontal: 10, vertical: 9)),
      );
    }
    final hasFile = f.fileName.isNotEmpty;
    final missing = hasFile && !f.hasBytes;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: missing ? AppColors.yellow : AppColors.surface),
      ),
      child: Row(
        children: [
          Icon(
            missing ? LucideIcons.triangleAlert : LucideIcons.paperclip,
            size: 15,
            color: missing ? AppColors.yellow : AppColors.mutedForeground,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              !hasFile
                  ? 'Pilih file…'
                  : missing
                      ? '${f.fileName} • klik untuk pilih ulang'
                      : '${f.fileName} • ${formatFileSize(f.fileSize)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: !hasFile
                    ? AppColors.comment
                    : missing
                        ? AppColors.yellow
                        : AppColors.foreground,
                fontSize: 12,
              ),
            ),
          ),
          InkWell(
            onTap: () => onPickFile(index),
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(LucideIcons.folderOpen,
                  size: 15, color: AppColors.blue),
            ),
          ),
          if (hasFile)
            InkWell(
              onTap: () => onClearFile(index),
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(LucideIcons.x,
                    size: 15, color: AppColors.mutedForeground),
              ),
            ),
        ],
      ),
    );
  }
}
