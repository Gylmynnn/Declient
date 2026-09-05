import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';
import '../../../core/utils/app_colors.dart';
import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(28),
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Kembali',
                      onPressed: () => Get.back(),
                      icon: const Icon(LucideIcons.arrowLeft, size: 20),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'SETTINGS',
                      style: TextStyle(
                        color: AppColors.foreground,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _Section(
                  icon: LucideIcons.type,
                  title: 'Font Antarmuka',
                  subtitle: 'Font untuk seluruh teks UI',
                  child: Obx(
                    () => _FontDropdown(
                      value: controller.uiFont.value,
                      onChanged: (v) {
                        if (v != null) controller.setUiFont(v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _Section(
                  icon: LucideIcons.code,
                  title: 'Font Monospace',
                  subtitle: 'URL, body editor, response & snippet kode',
                  child: Obx(
                    () => _FontDropdown(
                      value: controller.monoFont.value,
                      onChanged: (v) {
                        if (v != null) controller.setMonoFont(v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _Section(
                  icon: LucideIcons.type,
                  title: 'Ukuran Font UI',
                  subtitle: 'Skala seluruh teks antarmuka',
                  child: Obx(
                    () => Row(
                      children: [
                        Expanded(
                          child: Slider(
                            min: 0.85,
                            max: 1.3,
                            divisions: 9,
                            value: controller.uiScale.value,
                            onChanged: controller.setUiScale,
                          ),
                        ),
                        SizedBox(
                          width: 52,
                          child: Text(
                            '${(controller.uiScale.value * 100).round()}%',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: AppColors.foreground,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _Section(
                  icon: LucideIcons.braces,
                  title: 'Ukuran Font Kode',
                  subtitle: 'Body editor, response & snippet',
                  child: Obx(
                    () => Row(
                      children: [
                        Expanded(
                          child: Slider(
                            min: 10,
                            max: 18,
                            divisions: 8,
                            value: controller.codeSize.value,
                            onChanged: controller.setCodeSize,
                          ),
                        ),
                        SizedBox(
                          width: 52,
                          child: Text(
                            '${controller.codeSize.value.round()} px',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: AppColors.foreground,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Obx(
                    () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Preview',
                          style: TextStyle(
                            color: AppColors.comment,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'GET https://{{baseUrl}}/users?page=1',
                          style: TextStyle(
                            color: AppColors.foreground,
                            fontSize: controller.codeSize.value + 2,
                            fontFamily: controller.monoFont.value ==
                                    SettingsController.system
                                ? null
                                : controller.monoFont.value,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'DeClient — Postman sederhana dengan GetX',
                          style: TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Pilihan tersimpan otomatis dan diterapkan langsung.',
                  style: TextStyle(color: AppColors.comment, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  const _Section({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: AppColors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.foreground,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.comment,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _FontDropdown extends StatelessWidget {
  final String value;
  final void Function(String?) onChanged;
  const _FontDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: AppColors.backgroundDark,
      style: const TextStyle(color: AppColors.foreground, fontSize: 14),
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: SettingsController.fontOptions
          .map((f) => DropdownMenuItem(value: f, child: Text(f)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
