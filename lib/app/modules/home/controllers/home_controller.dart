import 'package:get/get.dart';

class HomeController extends GetxController {
  final RxInt rightTabIndex = 0.obs; // 0 response/history panel handled by editor, keep for future
  final RxDouble sidebarWidth = 300.0.obs;

  /// false = editor atas + response bawah, true = editor kiri + response kanan.
  final RxBool verticalSplit = false.obs;

  /// Porsi response terhadap area editor+response (0.2 - 0.8).
  final RxDouble responseFraction = 0.42.obs;

  void setRightTab(int i) => rightTabIndex.value = i;

  void toggleSplit() => verticalSplit.value = !verticalSplit.value;

  void setResponseFraction(double v) =>
      responseFraction.value = v.clamp(0.2, 0.8);

  void setSidebarWidth(double v) =>
      sidebarWidth.value = v.clamp(220.0, 480.0);
}
