import 'package:get/get.dart';
import '../../../data/services/api_service.dart';
import '../controllers/collection_controller.dart';
import '../controllers/environment_controller.dart';
import '../controllers/history_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/request_editor_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ApiService>(ApiService(), permanent: true);
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<EnvironmentController>(() => EnvironmentController());
    Get.lazyPut<HistoryController>(() => HistoryController());
    Get.lazyPut<RequestEditorController>(() => RequestEditorController());
    Get.lazyPut<CollectionController>(() => CollectionController());
  }
}
