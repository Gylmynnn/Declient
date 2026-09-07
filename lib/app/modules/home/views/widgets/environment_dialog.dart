import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_dialog.dart';
import '../../../../core/utils/app_menu.dart';
import '../../../../core/utils/app_snack.dart';
import '../../controllers/environment_controller.dart';

class EnvironmentDialog extends GetView<EnvironmentController> {
  const EnvironmentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _show(context));
    return const SizedBox.shrink();
  }

  void _show(BuildContext context) {
    AppDialog.form(
      title: 'Environments',
      subtitle:
          'A set of variables for {{key}} substitution in URLs & headers.',
      icon: LucideIcons.boxes,
      accent: AppColors.cyan,
      submitText: 'New environment',
      maxWidth: 540,
      minHeight: 420,
      onSubmit: () async {
        controller.startCreate();
        await Get.dialog(const EnvEditorDialog());
      },
      child: Obx(
        () {
          if (controller.environments.isEmpty) {
            return _EmptyEnvironments();
          }
          return ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: controller.environments.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final env = controller.environments[i];
              final active = controller.activeId.value == env.id;
              return _EnvRow(env: env, active: active);
            },
          );
        },
      ),
    );
  }
}

class _EnvRow extends GetView<EnvironmentController> {
  final dynamic env;
  final bool active;
  const _EnvRow({required this.env, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: active
            ? AppColors.surface.withValues(alpha: 0.8)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.green.withValues(alpha: 0.15)
                  : AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              LucideIcons.globe,
              color: active ? AppColors.green : AppColors.mutedForeground,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        env.name,
                        style: const TextStyle(
                          color: AppColors.foreground,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (active) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'active',
                          style: TextStyle(
                            color: AppColors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${env.variables.length} variables',
                  style: const TextStyle(
                    color: AppColors.comment,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!active)
            TextButton(
              onPressed: () => controller.setActive(env.id),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.green,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Enable', style: TextStyle(fontSize: 12)),
            ),
          FancyMenu(
            icon: LucideIcons.moreHorizontal,
            accent: AppColors.cyan,
            items: [
              FancyMenuItem(
                value: 'edit',
                label: 'Edit',
                icon: LucideIcons.pencil,
                onSelected: () {
                  controller.startEdit(env);
                  Get.dialog(const EnvEditorDialog(editId: null));
                },
              ),
              FancyMenuItem(
                value: 'delete',
                label: 'Delete',
                icon: LucideIcons.trash2,
                danger: true,
                onSelected: () => AppDialog.confirm(
                  title: 'Delete environment?',
                  message: env.name,
                  onConfirm: () => controller.deleteEnvironment(env.id),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyEnvironments extends StatelessWidget {
  const _EmptyEnvironments();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              LucideIcons.boxes,
              size: 20,
              color: AppColors.comment,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'No environments yet',
            style: TextStyle(
              color: AppColors.foreground,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Create an environment to group variables per stage.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.comment, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class EnvEditorDialog extends GetView<EnvironmentController> {
  final String? editId;
  const EnvEditorDialog({super.key, this.editId});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _show(context));
    return const SizedBox.shrink();
  }

  void _show(BuildContext context) {
    AppDialog.form(
      title: editId == null ? 'New environment' : 'Edit environment',
      subtitle: 'Use {{key}} in URLs, headers, and body for substitution.',
      icon: editId == null ? LucideIcons.plus : LucideIcons.pencil,
      accent: AppColors.cyan,
      submitText: 'Save',
      maxWidth: 540,
      minHeight: 420,
      onSubmit: () async {
        final name = controller.nameController.text.trim();
        if (name.isEmpty) {
          AppSnack.warning('Environment name is required');
          return;
        }
        final vars = controller.editingVars
            .where((e) => e.key.trim().isNotEmpty)
            .toList();
        if (editId == null) {
          await controller.createEnvironment(name, vars);
        } else {
          await controller.updateEnvironment(editId!, name, vars);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppField(
            label: 'Environment name',
            hint: 'e.g. Local / Staging',
            controller: controller.nameController,
            prefixIcon: LucideIcons.tag,
            accent: AppColors.cyan,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                LucideIcons.code,
                size: 12,
                color: AppColors.mutedForeground,
              ),
              const SizedBox(width: 6),
              const Text(
                'Variables',
                style: TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: controller.addVar,
                behavior: HitTestBehavior.opaque,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.plus, size: 11, color: AppColors.cyan),
                        SizedBox(width: 4),
                        Text(
                          'Add',
                          style: TextStyle(
                            color: AppColors.cyan,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(() {
              if (controller.editingVars.isEmpty) {
                return Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'No variables yet — click Add',
                    style: TextStyle(color: AppColors.comment, fontSize: 12),
                  ),
                );
              }
              return ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: controller.editingVars.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final v = controller.editingVars[i];
                  return _VarRow(i: i, v: v);
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _VarRow extends GetView<EnvironmentController> {
  final int i;
  final dynamic v;
  const _VarRow({required this.i, required this.v});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 4, 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: Checkbox(
              value: v.enabled,
              onChanged: (val) =>
                  controller.updateVar(i, v.copyWith(enabled: val ?? true)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: AppField(
              hint: 'key, e.g. baseUrl',
              controller: TextEditingController(text: v.key)
                ..selection =
                    TextSelection.collapsed(offset: v.key.length),
              onChanged: (val) =>
                  controller.updateVar(i, v.copyWith(key: val)),
              accent: AppColors.cyan,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: AppField(
              hint: 'value',
              controller: TextEditingController(text: v.value)
                ..selection =
                    TextSelection.collapsed(offset: v.value.length),
              onChanged: (val) =>
                  controller.updateVar(i, v.copyWith(value: val)),
              accent: AppColors.cyan,
            ),
          ),
          IconButton(
            tooltip: 'Delete variable',
            onPressed: () => controller.removeVar(i),
            icon: const Icon(LucideIcons.x, size: 15),
            splashRadius: 14,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}
