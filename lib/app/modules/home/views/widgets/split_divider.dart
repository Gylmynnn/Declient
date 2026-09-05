import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';

/// Divider yang bisa di-drag untuk resize panel, ala VS Code.
/// [axis] menentukan arah drag: Axis.vertical = garis horizontal (drag atas-bawah),
/// Axis.horizontal = garis vertikal (drag kiri-kanan).
/// Stateless + full GetX-friendly: hover memakai InkWell bawaan Material.
class SplitDivider extends StatelessWidget {
  final Axis axis;
  final void Function(DragUpdateDetails) onDrag;
  const SplitDivider({super.key, required this.axis, required this.onDrag});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: onDrag,
      onVerticalDragUpdate: onDrag,
      child: MouseRegion(
        cursor: axis == Axis.vertical
            ? SystemMouseCursors.resizeUpDown
            : SystemMouseCursors.resizeLeftRight,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            hoverColor: AppColors.blue.withValues(alpha: 0.25),
            highlightColor: AppColors.blue.withValues(alpha: 0.35),
            splashColor: Colors.transparent,
            child: Container(
              width: axis == Axis.vertical ? double.infinity : 9,
              height: axis == Axis.vertical ? 9 : double.infinity,
              alignment: Alignment.center,
              child: Container(
                width: axis == Axis.vertical ? double.infinity : 1,
                height: axis == Axis.vertical ? 1 : double.infinity,
                color: AppColors.surface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
