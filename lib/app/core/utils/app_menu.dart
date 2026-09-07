import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'app_colors.dart';

/// Styled dropdown trigger + menu. Bungkus nilai dengan Obx di sisi caller
/// supaya widget rebuild saat Rx berubah (lihat juga font reactivity fix).
class FancyDropdown<T> extends StatefulWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final IconData? icon;
  final double? width;
  final double height;
  final EdgeInsetsGeometry contentPadding;
  final Color accent;
  final bool compact;

  const FancyDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.textStyle,
    this.hintStyle,
    this.icon,
    this.width,
    this.height = 40,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 8,
    ),
    this.accent = AppColors.green,
    this.compact = true,
  });

  @override
  State<FancyDropdown<T>> createState() => _FancyDropdownState<T>();
}

class _FancyDropdownState<T> extends State<FancyDropdown<T>> {
  bool _hover = false;

  String _labelFor(T? v) {
    for (final it in widget.items) {
      if (it.value == v) {
        final child = it.child;
        if (child is Text) return child.data ?? '';
        return child.toString();
      }
    }
    return widget.hint ?? '';
  }

  bool _hasValue(T? v) {
    for (final it in widget.items) {
      if (it.value == v) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = _hasValue(widget.value);
    final label = hasValue ? _labelFor(widget.value) : (widget.hint ?? '');
    final labelStyle =
        (hasValue ? widget.textStyle : widget.hintStyle) ??
        TextStyle(
          color: hasValue ? AppColors.foreground : AppColors.comment,
          fontSize: widget.compact ? 12 : 13,
          fontWeight: FontWeight.w500,
        );

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            // hoverColor: AppColors.surface.withValues(alpha: 0.4),
            // highlightColor: widget.accent.withValues(alpha: 0.08),
            // splashColor: widget.accent.withValues(alpha: 0.12),
            onTap: () => _open(context),
            child: Container(
              padding: widget.contentPadding,
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: widget.compact ? 13 : 15,
                      color: widget.accent,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      style: labelStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    LucideIcons.chevronDown,
                    size: 13,
                    color: _hover ? widget.accent : AppColors.mutedForeground,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final pos = box.localToGlobal(Offset.zero, ancestor: overlay);
    final size = box.size;

    final picked = await showMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(
        pos.dx,
        pos.dy + size.height + 4,
        overlay.size.width - (pos.dx + size.width),
        overlay.size.height - pos.dy,
      ),
      color: AppColors.backgroundDark,
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      items: widget.items
          .map(
            (it) => PopupMenuItem<T>(
              value: it.value,
              height: 46,
              padding: EdgeInsets.zero,
              child: _MenuRow(
                label: it.child is Text
                    ? (it.child as Text).data ?? ''
                    : it.child.toString(),
                selected: it.value == widget.value,
                accent: widget.accent,
              ),
            ),
          )
          .toList(),
    );

    if (picked != null && widget.onChanged != null) widget.onChanged!(picked);
  }
}

class FancyMenu extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final List<FancyMenuItem> items;
  final Color accent;

  const FancyMenu({
    super.key,
    required this.icon,
    required this.items,
    this.tooltip,
    this.accent = AppColors.green,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: tooltip,
      icon: Icon(icon, size: 20, color: AppColors.mutedForeground),
      splashRadius: 18,
      offset: const Offset(0, 6),
      color: AppColors.backgroundDark,
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (v) {
        final picked = items.firstWhere((e) => e.value == v);
        picked.onSelected();
      },
      itemBuilder: (BuildContext _) => items
          .map(
            (e) => PopupMenuItem<String>(
              value: e.value,
              height: 44,
              padding: EdgeInsets.zero,
              child: _MenuRow(
                icon: e.icon,
                label: e.label,
                danger: e.danger,
                accent: accent,
              ),
            ),
          )
          .toList(),
    );
  }
}

class FancyMenuItem {
  final String value;
  final String label;
  final IconData? icon;
  final bool danger;
  final VoidCallback onSelected;
  const FancyMenuItem({
    required this.value,
    required this.label,
    required this.onSelected,
    this.icon,
    this.danger = false,
  });
}

class _MenuRow extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final bool danger;
  final Color accent;
  const _MenuRow({
    required this.label,
    this.icon,
    this.selected = false,
    this.danger = false,
    this.accent = AppColors.green,
  });

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.danger
        ? AppColors.red
        : widget.selected
        ? widget.accent
        : AppColors.foreground;
    // final bg = _hover
    //     ? (widget.danger
    //           ? AppColors.red.withValues(alpha: 0.10)
    //           : widget.accent.withValues(alpha: 0.10))
    //     : Colors.transparent;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        // color: bg,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        width: 330,
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 14, color: color),
              const SizedBox(width: 8),
            ] else if (widget.selected) ...[
              Icon(LucideIcons.check, size: 14, color: widget.accent),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: widget.selected || widget.danger
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
