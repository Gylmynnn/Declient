import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/app_menu.dart';
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
            constraints: const BoxConstraints(maxWidth: 960),
            child: ListView(
              padding: const EdgeInsets.all(28),
              children: [
                _Header(onReset: controller.resetDefaults),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 680;
                    if (narrow) return _NarrowBento(controller: controller);
                    return _WideBento(controller: controller);
                  },
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(
                      LucideIcons.badgeCheck,
                      size: 14,
                      color: AppColors.green,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pilihan tersimpan otomatis dan diterapkan langsung ke seluruh aplikasi.',
                        style: TextStyle(
                          color: AppColors.comment,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Header: tombol kembali + judul + pill autosave + reset.
class _Header extends StatelessWidget {
  final VoidCallback onReset;
  const _Header({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            tooltip: 'Kembali',
            onPressed: () => Get.back(),
            icon: const Icon(LucideIcons.arrowLeft, size: 18),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SETTINGS',
                style: TextStyle(
                  color: AppColors.foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Personalisasi font & skala — layout bento',
                style: TextStyle(color: AppColors.comment, fontSize: 12.5),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.zap, size: 12, color: AppColors.green),
              SizedBox(width: 6),
              Text(
                'Autosave',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Reset ke bawaan',
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onReset,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                LucideIcons.rotateCcw,
                size: 16,
                color: AppColors.mutedForeground,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bento untuk layar lebar: 2 kolom dengan span bervariasi.
class _WideBento extends StatelessWidget {
  final SettingsController controller;
  const _WideBento({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Baris 1: dua kartu font berdampingan (span 1:1)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _BentoCard(
                icon: LucideIcons.type,
                accent: AppColors.magenta,
                title: 'Font Antarmuka',
                subtitle: 'Font for all UI text',
                badge: 'UI',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _UiFontDropdown(controller: controller),
                    const SizedBox(height: 12),
                    _AaPreview(
                      controller: controller,
                      mono: false,
                      accent: AppColors.magenta,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BentoCard(
                icon: LucideIcons.code2,
                accent: AppColors.cyan,
                title: 'Font Monospace',
                subtitle: 'URL, body editor & snippet',
                badge: 'CODE',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MonoFontDropdown(controller: controller),
                    const SizedBox(height: 12),
                    _AaPreview(
                      controller: controller,
                      mono: true,
                      accent: AppColors.cyan,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Baris 2: bento tak seimbang — skala UI lebih lebar dari kode
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: _BentoCard(
                icon: LucideIcons.scaling,
                accent: AppColors.green,
                title: 'Ukuran Font UI',
                subtitle: 'Skala seluruh teks antarmuka',
                child: _ScaleSlider(controller: controller),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: _BentoCard(
                icon: LucideIcons.braces,
                accent: AppColors.yellow,
                title: 'Ukuran Font Kode',
                subtitle: 'Editor, response & snippet',
                child: _CodeSlider(controller: controller),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Baris 3: preview besar + kolom samping bertumpuk (ciri khas bento)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 8,
              child: _BentoCard(
                icon: LucideIcons.monitorSmartphone,
                accent: AppColors.blue,
                title: 'Live Preview',
                subtitle: 'Hasil aktual di aplikasi',
                badge: 'LIVE',
                tall: true,
                child: _PreviewBody(controller: controller),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  _BentoCard(
                    icon: LucideIcons.layers,
                    accent: AppColors.blue,
                    title: 'Ringkasan',
                    subtitle: 'Konfigurasi aktif',
                    child: _Summary(controller: controller),
                  ),
                  const SizedBox(height: 12),
                  _BentoCard(
                    icon: LucideIcons.sparkles,
                    accent: AppColors.magenta,
                    title: 'Aksi Cepat',
                    subtitle: 'Kelola preferensi',
                    child: _QuickActions(controller: controller),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Bento untuk layar sempit: satu kolom, preview tetap paling menonjol.
class _NarrowBento extends StatelessWidget {
  final SettingsController controller;
  const _NarrowBento({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BentoCard(
          icon: LucideIcons.monitorSmartphone,
          accent: AppColors.blue,
          title: 'Live Preview',
          subtitle: 'Hasil aktual di aplikasi',
          badge: 'LIVE',
          child: _PreviewBody(controller: controller),
        ),
        const SizedBox(height: 12),
        _BentoCard(
          icon: LucideIcons.type,
          accent: AppColors.magenta,
          title: 'Font Antarmuka',
          subtitle: 'Font for all UI text',
          child: _UiFontDropdown(controller: controller),
        ),
        const SizedBox(height: 12),
        _BentoCard(
          icon: LucideIcons.code2,
          accent: AppColors.cyan,
          title: 'Font Monospace',
          subtitle: 'URL, body editor & snippet',
          child: _MonoFontDropdown(controller: controller),
        ),
        const SizedBox(height: 12),
        _BentoCard(
          icon: LucideIcons.scaling,
          accent: AppColors.green,
          title: 'Ukuran Font UI',
          subtitle: 'Skala seluruh teks antarmuka',
          child: _ScaleSlider(controller: controller),
        ),
        const SizedBox(height: 12),
        _BentoCard(
          icon: LucideIcons.braces,
          accent: AppColors.yellow,
          title: 'Ukuran Font Kode',
          subtitle: 'Editor, response & snippet',
          child: _CodeSlider(controller: controller),
        ),
        const SizedBox(height: 12),
        _BentoCard(
          icon: LucideIcons.layers,
          accent: AppColors.blue,
          title: 'Ringkasan',
          subtitle: 'Konfigurasi aktif',
          child: _Summary(controller: controller),
        ),
        const SizedBox(height: 12),
        _BentoCard(
          icon: LucideIcons.sparkles,
          accent: AppColors.magenta,
          title: 'Aksi Cepat',
          subtitle: 'Kelola preferensi',
          child: _QuickActions(controller: controller),
        ),
      ],
    );
  }
}

/// Kartu dasar bento: rounded, flat, aksen ikon + badge opsional.
class _BentoCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final String? badge;
  final Widget child;
  final bool tall;

  const _BentoCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.child,
    this.badge,
    this.tall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(tall ? 20 : 18),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surface.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: accent),
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
                        fontWeight: FontWeight.w700,
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
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      color: accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── Isi tiap tile ─────────────────────────────────────────────

class _UiFontDropdown extends StatelessWidget {
  final SettingsController controller;
  const _UiFontDropdown({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => FancyDropdown<String>(
        key: ValueKey('ui-${controller.uiFont.value}'),
        icon: LucideIcons.aLargeSmall,
        value: controller.uiFont.value,
        width: double.infinity,
        accent: AppColors.green,
        onChanged: (v) {
          if (v != null) controller.setUiFont(v);
        },
        items: SettingsController.fontOptions
            .map((f) => DropdownMenuItem<String>(value: f, child: Text(f)))
            .toList(),
      ),
    );
  }
}

class _MonoFontDropdown extends StatelessWidget {
  final SettingsController controller;
  const _MonoFontDropdown({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => FancyDropdown<String>(
        key: ValueKey('mono-${controller.monoFont.value}'),
        icon: LucideIcons.code,
        value: controller.monoFont.value,
        width: double.infinity,
        accent: AppColors.green,
        onChanged: (v) {
          if (v != null) controller.setMonoFont(v);
        },
        items: SettingsController.fontOptions
            .map((f) => DropdownMenuItem<String>(value: f, child: Text(f)))
            .toList(),
      ),
    );
  }
}

/// Preview huruf besar "Ag" ala bento — menunjukkan font + skala terpilih.
class _AaPreview extends StatelessWidget {
  final SettingsController controller;
  final bool mono;
  final Color accent;
  const _AaPreview({
    required this.controller,
    required this.mono,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final family = mono
          ? (controller.monoFont.value == SettingsController.system
                ? null
                : controller.monoFont.value)
          : (controller.uiFont.value == SettingsController.system
                ? null
                : controller.uiFont.value);
      final size = mono
          ? controller.codeSize.value + 14
          : 34 * controller.uiScale.value;
      final label = mono ? controller.monoFont.value : controller.uiFont.value;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              mono ? '{ }' : 'Ag',
              style: TextStyle(
                fontFamily: family,
                fontSize: size.clamp(20, 48).toDouble(),
                fontWeight: FontWeight.w700,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.foreground,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    mono
                        ? '${controller.codeSize.value.round()} px'
                        : '${(controller.uiScale.value * 100).round()}% scale',
                    style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _ScaleSlider extends StatelessWidget {
  final SettingsController controller;
  const _ScaleSlider({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final pct = (controller.uiScale.value * 100).round();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$pct',
                style: const TextStyle(
                  color: AppColors.foreground,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 4),
                child: Text(
                  '%',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'min 85 — max 130',
                style: TextStyle(
                  color: AppColors.comment.withValues(alpha: 0.9),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.green,
              inactiveTrackColor: AppColors.surface,
              thumbColor: AppColors.green,
              overlayColor: AppColors.green.withValues(alpha: 0.15),
              trackHeight: 6,
            ),
            child: Slider(
              min: 0.85,
              max: 1.3,
              divisions: 9,
              value: controller.uiScale.value,
              onChanged: controller.setUiScale,
            ),
          ),
        ],
      );
    });
  }
}

class _CodeSlider extends StatelessWidget {
  final SettingsController controller;
  const _CodeSlider({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final px = controller.codeSize.value.round();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$px',
                style: const TextStyle(
                  color: AppColors.foreground,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 4),
                child: Text(
                  'px',
                  style: TextStyle(
                    color: AppColors.yellow,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.yellow,
              inactiveTrackColor: AppColors.surface,
              thumbColor: AppColors.yellow,
              overlayColor: AppColors.yellow.withValues(alpha: 0.15),
              trackHeight: 6,
            ),
            child: Slider(
              min: 10,
              max: 18,
              divisions: 8,
              value: controller.codeSize.value,
              onChanged: controller.setCodeSize,
            ),
          ),
          Text(
            'Aa Bb Cc 0123 {};',
            style: TextStyle(
              fontFamily: controller.monoFont.value == SettingsController.system
                  ? null
                  : controller.monoFont.value,
              fontSize: controller.codeSize.value,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      );
    });
  }
}

/// Tile preview besar: mock request bar + snippet, semua reaktif.
class _PreviewBody extends StatelessWidget {
  final SettingsController controller;
  const _PreviewBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final monoFamily = controller.monoFont.value == SettingsController.system
          ? null
          : controller.monoFont.value;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mock request bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'GET',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'https://{{baseUrl}}/users?page=1',
                      style: TextStyle(
                        color: AppColors.foreground,
                        fontSize: controller.codeSize.value + 1,
                        fontFamily: monoFamily,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'DeClient — A simple Postman alternative built with GetX',
              style: TextStyle(
                color: AppColors.mutedForeground,
                fontSize: 13 * controller.uiScale.value,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '{\n  "page": 1,\n  "limit": 20\n}',
                style: TextStyle(
                  fontFamily: monoFamily,
                  fontSize: controller.codeSize.value,
                  color: AppColors.cyan,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'PREVIEW',
              style: TextStyle(
                color: AppColors.comment,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _Summary extends StatelessWidget {
  final SettingsController controller;
  const _Summary({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rows = [
        ('UI Font', controller.uiFont.value, AppColors.magenta),
        ('Mono', controller.monoFont.value, AppColors.cyan),
        (
          'UI Scale',
          '${(controller.uiScale.value * 100).round()}%',
          AppColors.green,
        ),
        ('Code', '${controller.codeSize.value.round()} px', AppColors.yellow),
      ];
      return Column(
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 64,
                    child: Text(
                      r.$1,
                      style: const TextStyle(
                        color: AppColors.comment,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      r.$2,
                      style: const TextStyle(
                        color: AppColors.foreground,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: r.$3,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }
}

class _QuickActions extends StatelessWidget {
  final SettingsController controller;
  const _QuickActions({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: controller.resetDefaults,
          icon: const Icon(LucideIcons.rotateCcw, size: 14),
          label: const Text(
            'Reset ke bawaan',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.foreground,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Get.back(),
          icon: const Icon(LucideIcons.check, size: 14),
          label: const Text(
            'Selesai',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.green,
            side: BorderSide(color: AppColors.green.withValues(alpha: 0.4)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}
