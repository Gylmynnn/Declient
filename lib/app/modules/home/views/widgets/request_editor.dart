import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_fonts.dart';
import '../../../../core/utils/app_menu.dart';
import '../../../../core/utils/method_colors.dart';
import '../../../../data/models/key_value.dart';
import '../../controllers/request_editor_controller.dart';
import 'code_dialog.dart';
import 'form_data_editor.dart';
import 'json_code_editor.dart';
import 'segmented_tabs.dart';

class RequestEditor extends GetView<RequestEditorController> {
  const RequestEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(() => Text(
                controller.hasSelection ? (controller.nameController.text.isEmpty ? 'Request' : controller.nameController.text) : 'New Request (unsaved)',
                style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
              )),
          const SizedBox(height: 6),
          Row(
            children: [
              Obx(() {
                    final m = controller.method.value;
                    final c = httpMethodColor(m);
                    return FancyDropdown<String>(
                      value: m,
                      width: 92,
                      accent: c,
                      textStyle: TextStyle(
                        color: c,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      hintStyle: const TextStyle(
                        color: AppColors.comment,
                        fontSize: 13,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      onChanged: (v) {
                        if (v != null) controller.method.value = v;
                      },
                      items: RequestEditorController.methods
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
                    );
                  }),
              const SizedBox(width: 8),
              Expanded(
                child: Obx(() => TextField(
                      controller: controller.urlController,
                      style: TextStyle(
                          color: AppColors.foreground,
                          fontSize: 13,
                          fontFamily: AppFonts.mono),
                      decoration: const InputDecoration(
                        hintText: 'https://{{baseUrl}}/users?page=1',
                        prefixIcon: Icon(
                          LucideIcons.globe,
                          size: 17,
                          color: AppColors.comment,
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    )),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller.nameController,
            style: const TextStyle(color: AppColors.foreground, fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Request name (to be saved in collection)',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          Obx(() => Row(
                children: [
                  SegmentedTabs(
                    labels: const ['Params', 'Headers', 'Body', 'Auth'],
                    current: controller.tabIndex.value,
                    onTap: (i) => controller.tabIndex.value = i,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Generate code (cURL / Dart)',
                    onPressed: () => Get.dialog(const CodeDialog()),
                    icon: const Icon(LucideIcons.code, size: 18),
                  ),
                ],
              )),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(() {
              switch (controller.tabIndex.value) {
                case 0:
                  return KeyValueEditor(
                    items: controller.params,
                    onAdd: controller.addParam,
                    onRemove: controller.removeParam,
                    onUpdate: controller.updateParam,
                    onReorder: controller.reorderParams,
                    keyHint: 'key',
                    valueHint: 'value',
                  );
                case 1:
                  return KeyValueEditor(
                    items: controller.headers,
                    onAdd: controller.addHeader,
                    onRemove: controller.removeHeader,
                    onUpdate: controller.updateHeader,
                    onReorder: controller.reorderHeaders,
                    keyHint: 'header',
                    valueHint: 'value',
                  );
                case 2:
                  return _BodyTab();
                default:
                  return _AuthTab();
              }
            }),
          ),
        ],
      ),
    );
  }
}

class KeyValueEditor extends StatelessWidget {
  final RxList<KeyValue> items;
  final VoidCallback onAdd;
  final void Function(int) onRemove;
  final void Function(int, KeyValue) onUpdate;
  final void Function(int, int) onReorder;
  final String keyHint;
  final String valueHint;
  const KeyValueEditor({
    super.key,
    required this.items,
    required this.onAdd,
    required this.onRemove,
    required this.onUpdate,
    required this.onReorder,
    required this.keyHint,
    required this.valueHint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Obx(() {
            if (items.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.list,
                        size: 32, color: AppColors.comment),
                    SizedBox(height: 8),
                    Text('No rows yet — click Add row',
                        style: TextStyle(
                            color: AppColors.comment, fontSize: 12)),
                  ],
                ),
              );
            }
            return ReorderableListView.builder(
                buildDefaultDragHandles: false,
                itemCount: items.length,
                onReorderItem: (oldI, newI) => onReorder(oldI, newI),
                itemBuilder: (_, i) {
                  final kv = items[i];
                  return Padding(
                    key: ValueKey('row-$i-${kv.key}-${kv.value}-${kv.enabled}'),
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: i,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2),
                            child: Icon(LucideIcons.gripVertical, size: 17, color: AppColors.comment),
                          ),
                        ),
                        Checkbox(
                          value: kv.enabled,
                          onChanged: (v) => onUpdate(i, kv.copyWith(enabled: v ?? true)),
                        ),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: TextEditingController(text: kv.key)
                              ..selection = TextSelection.collapsed(offset: kv.key.length),
                            onChanged: (v) => onUpdate(i, kv.copyWith(key: v)),
                            style: const TextStyle(color: AppColors.foreground, fontSize: 13),
                            decoration: InputDecoration(hintText: keyHint, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: TextEditingController(text: kv.value)
                              ..selection = TextSelection.collapsed(offset: kv.value.length),
                            onChanged: (v) => onUpdate(i, kv.copyWith(value: v)),
                            style: const TextStyle(color: AppColors.foreground, fontSize: 13),
                            decoration: InputDecoration(hintText: valueHint, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9)),
                          ),
                        ),
                        IconButton(onPressed: () => onRemove(i), icon: const Icon(LucideIcons.x, size: 17)),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(onPressed: onAdd, icon: const Icon(LucideIcons.plus, size: 16), label: const Text('Add row')),
        ),
      ],
    );
  }
}

class _BodyTab extends GetView<RequestEditorController> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(() => FancyDropdown<String>(
              icon: LucideIcons.package,
              value: controller.bodyType.value,
              accent: AppColors.magenta,
              onChanged: (v) {
                if (v != null) controller.bodyType.value = v;
              },
              items: const [
                DropdownMenuItem(value: 'none', child: Text('none')),
                DropdownMenuItem(value: 'json', child: Text('JSON')),
                DropdownMenuItem(value: 'raw', child: Text('raw / text')),
                DropdownMenuItem(value: 'form', child: Text('form-urlencoded')),
                DropdownMenuItem(
                    value: 'multipart',
                    child: Text('form-data (file upload)')),
              ],
            )),
        const SizedBox(height: 8),
        Expanded(
          child: Obx(() {
            if (controller.bodyType.value == 'none') {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.surface),
                ),
                child: const Center(
                  child: Text(
                    'No body — select JSON / raw / form / form-data to fill the body.',
                    style: TextStyle(color: AppColors.comment, fontSize: 12),
                  ),
                ),
              );
            }
            if (controller.bodyType.value == 'multipart') {
              return FormDataEditor(
                key: const ValueKey('body-multipart'),
                items: controller.formData,
                onAdd: controller.addFormField,
                onRemove: controller.removeFormField,
                onUpdate: controller.updateFormField,
                onPickFile: controller.pickFormFile,
                onClearFile: controller.clearFormFile,
              );
            }
            return JsonCodeEditor(
              key: ValueKey('body-${controller.bodyType.value}'),
            );
          }),
        ),
      ],
    );
  }
}

class _AuthTab extends GetView<RequestEditorController> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Obx(() => FancyDropdown<String>(
              icon: LucideIcons.shield,
              value: controller.authType.value,
              accent: AppColors.yellow,
              onChanged: (v) {
                if (v != null) controller.authType.value = v;
              },
              items: const [
                DropdownMenuItem(value: 'none', child: Text('No auth')),
                DropdownMenuItem(value: 'bearer', child: Text('Bearer token')),
                DropdownMenuItem(value: 'basic', child: Text('Basic auth')),
              ],
            )),
        const SizedBox(height: 10),
        Obx(() {
          if (controller.authType.value == 'bearer') {
            return TextField(
              controller: controller.authTokenController,
              style: const TextStyle(color: AppColors.foreground, fontSize: 13),
              decoration: const InputDecoration(hintText: 'Token (bisa pakai {{var}})', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            );
          }
          if (controller.authType.value == 'basic') {
            return Column(
              children: [
                TextField(
                  controller: controller.authUserController,
                  style: const TextStyle(color: AppColors.foreground, fontSize: 13),
                  decoration: const InputDecoration(hintText: 'Username', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller.authPassController,
                  obscureText: true,
                  style: const TextStyle(color: AppColors.foreground, fontSize: 13),
                  decoration: const InputDecoration(hintText: 'Password', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                ),
              ],
            );
          }
          return const Text('Tidak memakai auth.', style: TextStyle(color: AppColors.comment, fontSize: 13));
        }),
      ],
    );
  }
}
