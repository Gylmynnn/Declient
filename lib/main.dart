import 'package:declient/app/core/utils/app_theme.dart';
import 'package:declient/app/core/utils/app_title.dart';
import 'package:declient/app/modules/settings/controllers/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/routes/app_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await hideTitleBar();
  Get.put<SettingsController>(SettingsController(), permanent: true);

  runApp(const RootApp());
}

class RootApp extends GetView<SettingsController> {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "DeClient",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(),
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      defaultTransition: Transition.fade,
      builder: (BuildContext context, Widget? child) {
        return Obx(() {
          final double scale = controller.uiScale.value;
          final MediaQueryData mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          );
        });
      },
    );
  }
}
