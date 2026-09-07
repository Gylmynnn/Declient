import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/app_colors.dart';
import '../controllers/home_controller.dart';
import 'widgets/collection_sidebar.dart';
import 'widgets/request_editor.dart';
import 'widgets/response_panel.dart';
import 'widgets/split_divider.dart';
import 'widgets/top_bar.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const TopBar(),
            const Divider(height: 1),
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints cons) => Obx(() {
                  final vertical = controller.verticalSplit.value;
                  final f = controller.responseFraction.value;
                  final editorFlex = ((1 - f) * 1000).round();
                  final responseFlex = (f * 1000).round();
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: controller.sidebarWidth.value,
                        child: const CollectionSidebar(),
                      ),
                      SplitDivider(
                        axis: Axis.horizontal,
                        onDrag: (d) => controller.setSidebarWidth(
                          controller.sidebarWidth.value + d.delta.dx,
                        ),
                      ),
                      Expanded(
                        child: vertical
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: editorFlex,
                                    child: const RequestEditor(),
                                  ),
                                  SplitDivider(
                                    axis: Axis.horizontal,
                                    onDrag: (d) =>
                                        controller.setResponseFraction(
                                          controller.responseFraction.value -
                                              d.delta.dx / cons.maxWidth,
                                        ),
                                  ),
                                  Expanded(
                                    flex: responseFlex,
                                    child: const ResponsePanel(),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: editorFlex,
                                    child: const RequestEditor(),
                                  ),
                                  SplitDivider(
                                    axis: Axis.vertical,
                                    onDrag: (d) =>
                                        controller.setResponseFraction(
                                          controller.responseFraction.value -
                                              d.delta.dy / cons.maxHeight,
                                        ),
                                  ),
                                  Expanded(
                                    flex: responseFlex,
                                    child: const ResponsePanel(),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
