import 'package:get/get.dart';
import '../../../core/utils/app_snack.dart';
import '../../../data/models/history_model.dart';
import '../../../data/services/api_service.dart';

class HistoryController extends GetxController {
  final ApiService _api = Get.find<ApiService>();

  final RxList<HistoryModel> history = <HistoryModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    try {
      isLoading.value = true;
      history.assignAll(await _api.getHistory(limit: 50));
    } catch (e) {
      AppSnack.error('Gagal memuat history: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> clear() async {
    await _api.clearHistory();
    history.clear();
    Get.back();
  }
}
