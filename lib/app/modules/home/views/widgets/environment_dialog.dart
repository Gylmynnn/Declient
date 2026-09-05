import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_dialog.dart';
import '../../../../core/utils/app_snack.dart';
import '../../controllers/environment_controller.dart';

class EnvironmentDialog extends GetView<EnvironmentController> {
  const EnvironmentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Environments',
        style: TextStyle(color: AppColors.foreground),
      ),
      content: SizedBox(
        width: 520,
        height: 420,
        child: Obx(
          () => ListView.builder(
            itemCount: controller.environments.length,
            itemBuilder: (_, i) {
              final env = controller.environments[i];
              final active = controller.activeId.value == env.id;
              return Card(
                child: ListTile(
                  leading: Icon(
                    LucideIcons.globe,
                    color: active ? AppColors.green : AppColors.comment,
                    size: 20,
                  ),
                  title: Text(
                    env.name,
                    style: const TextStyle(
                      color: AppColors.foreground,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    '${env.variables.length} variables${active ? " • active" : ""}',
                    style: const TextStyle(
                      color: AppColors.comment,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!active)
                        TextButton(
                          onPressed: () => controller.setActive(env.id),
                          child: const Text('Aktifkan'),
                        ),
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: () {
                          controller.startEdit(env);
                          Get.dialog(EnvEditorDialog(editId: env.id));
                        },
                        icon: const Icon(LucideIcons.pencil, size: 17),
                      ),
                      IconButton(
                        tooltip: 'Hapus',
                        onPressed: () => AppDialog.confirm(
                          title: 'Hapus environment?',
                          message: env.name,
                          onConfirm: () {
                            controller.deleteEnvironment(env.id);
                          },
                        ),
                        icon: const Icon(
                          LucideIcons.trash2,
                          size: 17,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Tutup')),
        ElevatedButton.icon(
          onPressed: () {
            controller.startCreate();
            Get.dialog(const EnvEditorDialog());
          },
          icon: const Icon(LucideIcons.plus, size: 16),
          label: const Text('Baru'),
        ),
      ],
    );
  }
}

class EnvEditorDialog extends GetView<EnvironmentController> {
  final String? editId;
  const EnvEditorDialog({super.key, this.editId});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        editId == null ? 'Environment baru' : 'Edit environment',
        style: const TextStyle(color: AppColors.foreground),
      ),
      content: SizedBox(
        width: 520,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: controller.nameController,
              style: const TextStyle(color: AppColors.foreground, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Nama environment, mis. Local / Staging',
              ),
            ),
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Variables  (pakai {{key}} di URL/headers/body)',
                style: TextStyle(color: AppColors.comment, fontSize: 12),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Obx(
                () => ListView.builder(
                  itemCount: controller.editingVars.length,
                  itemBuilder: (_, i) {
                    final v = controller.editingVars[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Checkbox(
                            value: v.enabled,
                            onChanged: (val) => controller.updateVar(
                              i,
                              v.copyWith(enabled: val ?? true),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              key: ValueKey('env-k-$i'),
                              controller: TextEditingController(text: v.key)
                                ..selection = TextSelection.collapsed(
                                  offset: v.key.length,
                                ),
                              onChanged: (val) =>
                                  controller.updateVar(i, v.copyWith(key: val)),
                              style: const TextStyle(
                                color: AppColors.foreground,
                                fontSize: 13,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'key, mis. baseUrl',
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              key: ValueKey('env-v-$i'),
                              controller: TextEditingController(text: v.value)
                                ..selection = TextSelection.collapsed(
                                  offset: v.value.length,
                                ),
                              onChanged: (val) => controller.updateVar(
                                i,
                                v.copyWith(value: val),
                              ),
                              style: const TextStyle(
                                color: AppColors.foreground,
                                fontSize: 13,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'value',
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => controller.removeVar(i),
                            icon: const Icon(LucideIcons.x, size: 17),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: controller.addVar,
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Add variable'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () {
            final name = controller.nameController.text.trim();
            if (name.isEmpty) {
              AppSnack.warning('Nama environment wajib diisi');
              return;
            }
            final vars = controller.editingVars
                .where((e) => e.key.trim().isNotEmpty)
                .toList();
            if (editId == null) {
              controller.createEnvironment(name, vars);
            } else {
              controller.updateEnvironment(editId!, name, vars);
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
