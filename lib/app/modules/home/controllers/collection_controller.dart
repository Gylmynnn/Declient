import 'package:get/get.dart';
import '../../../core/utils/app_snack.dart';
import '../../../data/models/collection_model.dart';
import '../../../data/models/folder_model.dart';
import '../../../data/models/api_request_model.dart';
import '../../../data/services/api_service.dart';
import 'request_editor_controller.dart';

class CollectionController extends GetxController {
  final ApiService _api = Get.find<ApiService>();

  final RxList<CollectionModel> collections = <CollectionModel>[].obs;
  final RxList<FolderModel> folders = <FolderModel>[].obs;
  final RxList<ApiRequestModel> requests = <ApiRequestModel>[].obs;

  final RxnString selectedCollectionId = RxnString();
  final RxnString selectedRequestId = RxnString();
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;

  final RxSet<String> expandedCollections = <String>{}.obs;
  final RxSet<String> expandedFolders = <String>{}.obs;

  void toggleCollection(String id) {
    if (!expandedCollections.add(id)) expandedCollections.remove(id);
  }

  void toggleFolder(String id) {
    if (!expandedFolders.add(id)) expandedFolders.remove(id);
  }

  @override
  void onInit() {
    super.onInit();
    fetchCollections();
  }

  List<ApiRequestModel> get rootRequests =>
      requests.where((r) => r.folderId.isEmpty && _match(r.name)).toList();

  List<FolderModel> get rootFolders =>
      folders.where((f) => f.parentId.isEmpty && _match(f.name)).toList();

  List<FolderModel> subFolders(String parentId) =>
      folders.where((f) => f.parentId == parentId && _match(f.name)).toList();

  List<ApiRequestModel> folderRequests(String folderId) =>
      requests.where((r) => r.folderId == folderId && _match(r.name)).toList();

  bool _match(String name) {
    if (searchQuery.value.isEmpty) return true;
    return name.toLowerCase().contains(searchQuery.value.toLowerCase());
  }

  CollectionModel? get selectedCollection {
    final id = selectedCollectionId.value;
    if (id == null) return null;
    try {
      return collections.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  void updateSearch(String v) => searchQuery.value = v;

  Future<void> fetchCollections() async {
    try {
      isLoading.value = true;
      final items = await _api.getCollections();
      collections.assignAll(items);
      if (selectedCollectionId.value == null && items.isNotEmpty) {
        await selectCollection(items.first.id);
      } else if (selectedCollectionId.value != null) {
        await _loadDetail(selectedCollectionId.value!);
      }
    } catch (e) {
      AppSnack.error('Gagal memuat collections: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectCollection(String id) async {
    selectedCollectionId.value = id;
    selectedRequestId.value = null;
    await _loadDetail(id);
  }

  Future<void> _loadDetail(String collectionId) async {
    try {
      final detail = await _api.getCollectionDetail(collectionId);
      folders.assignAll(detail.folders);
      requests.assignAll(detail.requests);
    } catch (e) {
      AppSnack.error('Gagal memuat detail: $e');
    }
  }

  Future<void> refreshCurrent() async {
    final id = selectedCollectionId.value;
    if (id != null) await _loadDetail(id);
  }

  Future<void> createCollection(String name, String description) async {
    final created = await _api.createCollection(name, description);
    collections.add(created);
    await selectCollection(created.id);
    Get.back();
    AppSnack.success('Collection "$name" dibuat');
  }

  Future<void> updateCollection(String id, String name, String description) async {
    final updated = await _api.updateCollection(id, name, description);
    final i = collections.indexWhere((c) => c.id == id);
    if (i != -1) collections[i] = updated;
    Get.back();
  }

  Future<void> deleteCollection(String id) async {
    await _api.deleteCollection(id);
    collections.removeWhere((c) => c.id == id);
    if (selectedCollectionId.value == id) {
      selectedCollectionId.value = null;
      folders.clear();
      requests.clear();
      if (collections.isNotEmpty) await selectCollection(collections.first.id);
    }
    Get.back();
  }

  Future<void> createFolder({required String name, String parentId = '', String description = ''}) async {
    final colId = selectedCollectionId.value;
    if (colId == null) return;
    final created = await _api.createFolder(collectionId: colId, parentId: parentId, name: name, description: description);
    folders.add(created);
    Get.back();
  }

  Future<void> updateFolder(String id, String name, String description) async {
    final updated = await _api.updateFolder(id, name, description);
    final i = folders.indexWhere((f) => f.id == id);
    if (i != -1) folders[i] = updated;
    Get.back();
  }

  Future<void> deleteFolder(String id) async {
    await _api.deleteFolder(id);
    await refreshCurrent();
    Get.back();
  }

  Future<void> createRequest({required String name, String folderId = '', String method = 'GET', String url = ''}) async {
    final colId = selectedCollectionId.value;
    if (colId == null) return;
    final created = await _api.createRequest(ApiRequestModel(
      id: '',
      collectionId: colId,
      folderId: folderId,
      name: name,
      method: method,
      url: url,
    ));
    requests.add(created);
    selectRequest(created.id);
    Get.back();
  }

  Future<void> deleteRequest(String id) async {
    await _api.deleteRequest(id);
    requests.removeWhere((r) => r.id == id);
    if (selectedRequestId.value == id) {
      selectedRequestId.value = null;
      if (Get.isRegistered<RequestEditorController>()) {
        Get.find<RequestEditorController>().clearSelection();
      }
    }
    Get.back();
  }

  void selectRequest(String id) {
    selectedRequestId.value = id;
    ApiRequestModel? found;
    try {
      found = requests.firstWhere((r) => r.id == id);
    } catch (_) {
      found = null;
    }
    if (found != null && Get.isRegistered<RequestEditorController>()) {
      Get.find<RequestEditorController>().loadFromRequest(found);
    }
  }

  Future<void> duplicateRequest(String id) async {
    ApiRequestModel? src;
    try {
      src = requests.firstWhere((r) => r.id == id);
    } catch (_) {
      return;
    }
    final copy = await _api.createRequest(src.copyWith(id: '', name: '${src.name} (copy)'));
    requests.add(copy);
    selectRequest(copy.id);
    AppSnack.success('Request diduplikat', duration: const Duration(seconds: 1));
  }

  Future<void> moveRequest(String id, String folderId) async {
    ApiRequestModel? src;
    try {
      src = requests.firstWhere((r) => r.id == id);
    } catch (_) {
      return;
    }
    if (src.folderId == folderId) return;
    final updated = await _api.updateRequest(src.copyWith(folderId: folderId));
    final i = requests.indexWhere((r) => r.id == id);
    if (i != -1) requests[i] = updated;
    AppSnack.success('Request dipindah', duration: const Duration(seconds: 1));
  }
}
