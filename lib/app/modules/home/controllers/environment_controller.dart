import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../../core/utils/app_snack.dart';
import '../../../data/models/environment_model.dart';
import '../../../data/services/api_service.dart';

class EnvironmentController extends GetxController {
  final ApiService _api = Get.find<ApiService>();

  final RxList<EnvironmentModel> environments = <EnvironmentModel>[].obs;
  final RxnString activeId = RxnString();
  final RxBool isLoading = false.obs;

  // Editor state for dialog
  final RxList<EnvVariable> editingVars = <EnvVariable>[].obs;
  late final TextEditingController nameController;

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController();
    fetchEnvironments();
  }

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }

  EnvironmentModel? get active {
    final id = activeId.value;
    if (id == null || id.isEmpty) return null;
    try {
      return environments.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchEnvironments() async {
    try {
      isLoading.value = true;
      environments.assignAll(await _api.getEnvironments());
      final act = await _api.getActiveEnvironment();
      activeId.value = act?.id;
    } catch (e) {
      AppSnack.error('Gagal memuat environments: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> setActive(String? id) async {
    await _api.setActiveEnvironment(id ?? '');
    activeId.value = (id == null || id.isEmpty) ? null : id;
  }

  Future<void> createEnvironment(String name, List<EnvVariable> vars) async {
    final created = await _api.createEnvironment(name, vars);
    environments.add(created);
    Get.back();
  }

  Future<void> updateEnvironment(String id, String name, List<EnvVariable> vars) async {
    final updated = await _api.updateEnvironment(id, name, vars);
    final i = environments.indexWhere((e) => e.id == id);
    if (i != -1) environments[i] = updated;
    Get.back();
  }

  Future<void> deleteEnvironment(String id) async {
    await _api.deleteEnvironment(id);
    environments.removeWhere((e) => e.id == id);
    if (activeId.value == id) activeId.value = null;
    Get.back();
  }

  void startCreate() {
    nameController.clear();
    editingVars.assignAll([const EnvVariable(key: '', value: '')]);
  }

  void startEdit(EnvironmentModel env) {
    nameController.text = env.name;
    editingVars.assignAll(env.variables.isEmpty ? [const EnvVariable(key: '', value: '')] : List.of(env.variables));
  }

  void addVar() => editingVars.add(const EnvVariable(key: '', value: ''));
  void removeVar(int i) => editingVars.removeAt(i);
  void updateVar(int i, EnvVariable v) => editingVars[i] = v;
}
