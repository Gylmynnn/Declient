import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../data/models/api_request_model.dart';
import '../../../data/models/form_data_field.dart';
import '../../../data/models/key_value.dart';
import '../../../core/utils/app_snack.dart';
import '../../../core/utils/body_chunk.dart';
import '../../../core/utils/json_highlighter.dart';
import '../../../data/services/api_service.dart';
import 'collection_controller.dart';
import 'environment_controller.dart';
import 'history_controller.dart';

class RequestEditorController extends GetxController {
  final ApiService _api = Get.find<ApiService>();

  final RxnString editingRequestId = RxnString();
  final RxString method = 'GET'.obs;
  final RxString bodyType = 'none'.obs;
  final RxString authType = 'none'.obs;

  late final TextEditingController urlController;
  late final TextEditingController nameController;
  late final TextEditingController bodyController;
  late final TextEditingController authTokenController;
  late final TextEditingController authUserController;
  late final TextEditingController authPassController;

  final RxList<KeyValue> params = <KeyValue>[].obs;
  final RxList<KeyValue> headers = <KeyValue>[].obs;

  /// Field multipart/form-data (text + file upload).
  final RxList<FormDataField> formData = <FormDataField>[].obs;

  /// Batas ukuran file per field (20 MB) agar tidak OOM saat base64.
  static const int maxUploadBytes = 20 << 20;

  final Rxn<SendResult> response = Rxn<SendResult>();
  final RxBool isSending = false.obs;
  final RxBool isSaving = false.obs;
  final RxString error = ''.obs;
  final RxInt tabIndex = 0.obs; // 0 params, 1 headers, 2 body, 3 auth
  final RxInt bottomTabIndex = 0.obs; // 0 response, 1 history
  final RxBool prettyPrint = true.obs;

  /// Segmen body tervirtualisasi (anti-freeze untuk response raksasa).
  final RxList<BodySegment> bodySegments = <BodySegment>[].obs;
  final RxBool bodyIsJson = false.obs;
  final RxInt bodyLineCount = 0.obs;
  final RxBool bodyTruncated = false.obs;

  // ---- JSON body editor state (reaktif GetX, tanpa setState) ----
  // Dipakai JsonCodeEditor: focus/scroll dibuat sekali di sini agar lifecycle
  // aman, posisi caret & revisi teks diekspos sebagai Rx untuk Obx.
  late final FocusNode bodyFocusNode;
  late final ScrollController bodyScrollController;
  final Rx<TextSelection> bodySelection =
      const TextSelection.collapsed(offset: -1).obs;
  final RxInt bodyRevision = 0.obs;
  bool _bodyProgrammatic = false;
  String _bodyPrevText = '';
  TextSelection _bodyPrevSelection =
      const TextSelection.collapsed(offset: -1);

  static const _bodyIndent = '  ';
  static const _bodyPairs = {'{': '}', '[': ']', '(': ')', '"': '"', "'": "'"};
  static const _bodyClosers = {'}', ']', ')', '"', "'"};
  static final _quoteOpenerPrev = RegExp(r'^[\s\{\[:,]$');

  /// Scroll vertikal body response. Diekspos agar view + reset posisi
  /// (kembali ke atas tiap response baru) terpusat di sini (GetX).
  late final ScrollController responseBodyVController;

  void refreshBodyLines() {
    final body = response.value?.body ?? '';
    final chunked = buildBodySegments(body, prettyPrint.value);
    bodySegments.assignAll(chunked.segments);
    bodyIsJson.value = chunked.isJson;
    bodyLineCount.value = chunked.lineCount;
    bodyTruncated.value = chunked.segments.length >= kMaxSegments;
    if (responseBodyVController.hasClients) {
      responseBodyVController.jumpTo(0);
    }
  }

  void togglePretty(bool v) {
    prettyPrint.value = v;
    refreshBodyLines();
  }

  /// Format isi body request menjadi JSON rapi (dipakai tombol Pretty).
  /// Mendukung placeholder {{var}} environment. Return true jika berhasil.
  bool formatBodyPretty() {
    final raw = bodyController.text;
    if (raw.trim().isEmpty) {
      AppSnack.info('Body masih kosong');
      return false;
    }
    final formatted = prettyJsonWithVars(raw, indent: '  ');
    if (formatted == null) {
      AppSnack.error('Body bukan JSON valid', title: 'Pretty gagal');
      return false;
    }
    if (formatted == raw) {
      AppSnack.info('Body sudah rapi');
      return true;
    }
    bodyController.text = formatted;
    return true;
  }

  // ---- JSON body smart editing (auto-close, auto-indent, tab) ----
  // Semua di sini (GetX). Listener controller -> update Rx -> Obx rebuild.

  void _onBodyChanged() {
    if (_bodyProgrammatic) return;
    final cur = bodyController.text;
    final sel = bodyController.selection;
    if (!_smartBodyEdit(_bodyPrevText, _bodyPrevSelection, cur, sel)) {
      _bodyPrevText = cur;
      _bodyPrevSelection = sel;
    }
    bodySelection.value = bodyController.selection;
    bodyRevision.value++;
  }

  /// Tangani satu karakter sisipan (auto-close / Enter). True jika teks
  /// diganti secara programmatic.
  bool _smartBodyEdit(
      String prev, TextSelection prevSel, String cur, TextSelection curSel) {
    if (bodyType.value != 'json') return false;
    if (!prevSel.isValid || !curSel.isValid || !prevSel.isCollapsed) {
      return false;
    }
    if (!curSel.isCollapsed) return false;
    if (cur.length != prev.length + 1) return false;
    final offset = curSel.baseOffset;
    if (offset < 1) return false;
    final inserted = cur[offset - 1];
    final caretPrev = prevSel.baseOffset;
    if (offset - 1 != caretPrev) return false; // sisipan di posisi caret
    if (cur.substring(0, offset - 1) != prev.substring(0, caretPrev)) {
      return false;
    }
    if (cur.substring(offset) != prev.substring(caretPrev)) return false;

    if (inserted == '\n') {
      _bodyEnter(prev, caretPrev);
      return true;
    }
    if (_bodyPairs.containsKey(inserted)) {
      return _bodyOpener(prev, caretPrev, inserted);
    }
    if (_bodyClosers.contains(inserted)) {
      return _bodyCloser(prev, caretPrev, inserted);
    }
    return false;
  }

  bool _bodyOpener(String prev, int caret, String opener) {
    final closer = _bodyPairs[opener]!;
    final next = caret < prev.length ? prev[caret] : '';
    final prevChar = caret > 0 ? prev[caret - 1] : '\n';

    if (opener == '"' || opener == "'") {
      if (next == opener) return false; // biarkan _bodyCloser yang skip
      final prevOk = prevChar == '\n' || _quoteOpenerPrev.hasMatch(prevChar);
      final nextOk = next.isEmpty || RegExp(r'[\s\}\],:;\n]').hasMatch(next);
      if (!prevOk || !nextOk) return false;
    } else {
      if (next == closer) return false;
    }

    _applyBodyProgrammatic(
      '${prev.substring(0, caret)}$opener$closer${prev.substring(caret)}',
      caret + 1,
    );
    return true;
  }

  bool _bodyCloser(String prev, int caret, String closer) {
    // Ketik closer yang sama dengan hasil auto-close -> lewati saja.
    if (caret < prev.length && prev[caret] == closer) {
      _applyBodyProgrammatic(prev, caret + 1);
      return true;
    }
    return false;
  }

  void _bodyEnter(String prev, int caret) {
    final lineStart = caret <= 0 ? 0 : prev.lastIndexOf('\n', caret - 1) + 1;
    final lineHead = prev.substring(lineStart, caret);
    final baseIndent = RegExp(r'^[ \t]*').firstMatch(lineHead)?.group(0) ?? '';
    final trimmed = lineHead.trimRight();
    final opensBlock = trimmed.endsWith('{') || trimmed.endsWith('[');
    final extra = opensBlock ? _bodyIndent : '';

    // Enter di antara {|} atau [|]: belah jadi 3 baris ala IDE.
    final next = caret < prev.length ? prev[caret] : '';
    final prevChar = caret > 0 ? prev[caret - 1] : '';
    final betweenPair =
        (prevChar == '{' && next == '}') || (prevChar == '[' && next == ']');

    final before = prev.substring(0, caret);
    final after = prev.substring(caret);
    if (betweenPair) {
      _applyBodyProgrammatic(
        '$before\n$baseIndent$_bodyIndent\n$baseIndent$after',
        caret + 1 + baseIndent.length + _bodyIndent.length,
      );
    } else {
      _applyBodyProgrammatic(
        '$before\n$baseIndent$extra$after',
        caret + 1 + baseIndent.length + extra.length,
      );
    }
  }

  void _applyBodyProgrammatic(String text, int caretOffset) {
    _bodyProgrammatic = true;
    bodyController.value = TextEditingValue(
      text: text,
      selection:
          TextSelection.collapsed(offset: caretOffset.clamp(0, text.length)),
    );
    _bodyPrevText = text;
    _bodyPrevSelection = bodyController.selection;
    _bodyProgrammatic = false;
  }

  void _insertBodyText(String snippet) {
    final v = bodyController.value;
    final sel = v.selection;
    final text = v.text;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    _bodyProgrammatic = true;
    bodyController.value = TextEditingValue(
      text: text.replaceRange(start, end, snippet),
      selection: TextSelection.collapsed(offset: start + snippet.length),
    );
    _bodyPrevText = bodyController.text;
    _bodyPrevSelection = bodyController.selection;
    _bodyProgrammatic = false;
    bodySelection.value = bodyController.selection;
    bodyRevision.value++;
  }

  /// Tab: indent 2 spasi / indent blok seleksi. Shift+Tab: dedent.
  KeyEventResult handleBodyKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.tab) {
      return KeyEventResult.ignored;
    }
    if (HardwareKeyboard.instance.isShiftPressed) {
      dedentBody();
    } else {
      indentBody();
    }
    return KeyEventResult.handled;
  }

  void indentBody() {
    final v = bodyController.value;
    final sel = v.selection;
    final text = v.text;
    if (!sel.isValid || sel.isCollapsed) {
      _insertBodyText(_bodyIndent);
      return;
    }
    final startLine =
        sel.start <= 0 ? 0 : text.lastIndexOf('\n', sel.start - 1) + 1;
    var endLineEnd = text.indexOf('\n', sel.end);
    if (endLineEnd == -1) endLineEnd = text.length;
    final block = text.substring(startLine, endLineEnd);
    final indented = block.split('\n').map((l) => '$_bodyIndent$l').join('\n');
    final added = indented.length - block.length;
    _bodyProgrammatic = true;
    bodyController.value = TextEditingValue(
      text: text.replaceRange(startLine, endLineEnd, indented),
      selection: TextSelection(
          baseOffset: sel.start + _bodyIndent.length,
          extentOffset: sel.end + added),
    );
    _bodyPrevText = bodyController.text;
    _bodyPrevSelection = bodyController.selection;
    _bodyProgrammatic = false;
    bodySelection.value = bodyController.selection;
    bodyRevision.value++;
  }

  void dedentBody() {
    final v = bodyController.value;
    final sel = v.selection;
    final text = v.text;
    final caret = sel.isValid ? sel.start : text.length;
    final lineStart =
        caret <= 0 ? 0 : text.lastIndexOf('\n', caret - 1) + 1;
    final lineEndIdx = text.indexOf('\n', caret);
    final lineEnd = lineEndIdx == -1 ? text.length : lineEndIdx;
    final line = text.substring(lineStart, lineEnd);
    final dedentCount = line.startsWith(_bodyIndent)
        ? 2
        : (line.startsWith(' ') || line.startsWith('\t') ? 1 : 0);
    if (dedentCount == 0) return;
    _bodyProgrammatic = true;
    bodyController.value = TextEditingValue(
      text: text.replaceRange(lineStart, lineStart + dedentCount, ''),
      selection: TextSelection.collapsed(
          offset: (caret - dedentCount).clamp(lineStart, text.length)),
    );
    _bodyPrevText = bodyController.text;
    _bodyPrevSelection = bodyController.selection;
    _bodyProgrammatic = false;
    bodySelection.value = bodyController.selection;
    bodyRevision.value++;
  }

  // ---- Getter reaktif untuk toolbar/gutter editor (dibaca di dalam Obx) ----

  /// Jumlah baris editor (min 1, aman untuk teks kosong).
  int get bodyEditorLineCount {
    final _ = bodyRevision.value;
    final t = bodyController.text;
    return t.isEmpty ? 1 : '\n'.allMatches(t).length + 1;
  }

  /// null = kosong, true = JSON valid, false = invalid.
  bool? get bodyEditorJsonValid {
    final _ = bodyRevision.value;
    if (bodyController.text.trim().isEmpty) return null;
    return isJsonWithVars(bodyController.text);
  }

  /// Posisi kursor 1-based (baris, kolom). Aman untuk offset 0 / invalid.
  (int, int) get bodyEditorCursor {
    final _ = bodyRevision.value;
    final sel = bodySelection.value;
    final text = bodyController.text;
    final safe =
        sel.isValid ? sel.baseOffset.clamp(0, text.length) : text.length;
    final line = text.substring(0, safe).split('\n').length;
    final lastNl = safe <= 0 ? -1 : text.lastIndexOf('\n', safe - 1);
    return (line, safe - lastNl);
  }

  static const methods = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'];

  @override
  void onInit() {
    super.onInit();
    urlController = TextEditingController();
    nameController = TextEditingController();
    bodyController = HighlightedJsonController();
    authTokenController = TextEditingController();
    authUserController = TextEditingController();
    authPassController = TextEditingController();
    bodyFocusNode = FocusNode();
    bodyScrollController = ScrollController();
    responseBodyVController = ScrollController();
    _bodyPrevText = bodyController.text;
    _bodyPrevSelection = bodyController.selection;
    bodyController.addListener(_onBodyChanged);
  }

  @override
  void onClose() {
    bodyController.removeListener(_onBodyChanged);
    urlController.dispose();
    nameController.dispose();
    bodyController.dispose();
    authTokenController.dispose();
    authUserController.dispose();
    authPassController.dispose();
    bodyFocusNode.dispose();
    bodyScrollController.dispose();
    responseBodyVController.dispose();
    super.onClose();
  }

  bool get hasSelection => editingRequestId.value != null;

  void loadFromRequest(ApiRequestModel req) {
    editingRequestId.value = req.id;
    method.value = req.method;
    urlController.text = req.url;
    nameController.text = req.name;
    bodyType.value = req.bodyType;
    bodyController.text = req.body;
    authType.value = req.auth.type;
    authTokenController.text = req.auth.token;
    authUserController.text = req.auth.username;
    authPassController.text = req.auth.password;
    params.assignAll(req.params);
    headers.assignAll(req.headers);
    formData.assignAll(req.formData);
    response.value = null;
    bodySegments.clear();
    error.value = '';
  }

  void clearSelection() {
    editingRequestId.value = null;
    method.value = 'GET';
    urlController.clear();
    nameController.clear();
    bodyController.clear();
    bodyType.value = 'none';
    authType.value = 'none';
    authTokenController.clear();
    authUserController.clear();
    authPassController.clear();
    params.clear();
    headers.clear();
    formData.clear();
    response.value = null;
    error.value = '';
  }

  void newAdhoc() {
    clearSelection();
    if (Get.isRegistered<CollectionController>()) {
      Get.find<CollectionController>().selectedRequestId.value = null;
    }
  }

  // ---- key-value editing ----
  void addParam() => params.add(const KeyValue(key: '', value: ''));
  void addHeader() => headers.add(const KeyValue(key: '', value: ''));
  void removeParam(int i) => params.removeAt(i);
  void removeHeader(int i) => headers.removeAt(i);
  void updateParam(int i, KeyValue v) => params[i] = v;
  void updateHeader(int i, KeyValue v) => headers[i] = v;

  void reorderParams(int oldI, int newI) {
    final it = params.removeAt(oldI);
    params.insert(newI, it);
  }

  void reorderHeaders(int oldI, int newI) {
    final it = headers.removeAt(oldI);
    headers.insert(newI, it);
  }

  // ---- form-data (text + file upload) ----
  void addFormField() =>
      formData.add(const FormDataField(key: '', value: ''));
  void removeFormField(int i) => formData.removeAt(i);
  void updateFormField(int i, FormDataField v) => formData[i] = v;

  /// Dialog pilih file untuk field ke-[i]. Bytes dibaca via
  /// [PlatformFile.readAsBytes] agar siap dikirim sebagai base64.
  Future<void> pickFormFile(int i) async {
    try {
      final files = await FilePicker.pickFiles();
      if (files.isEmpty) return;
      final f = files.first;
      Uint8List bytes;
      try {
        bytes = await f.readAsBytes();
      } catch (e) {
        AppSnack.error('Gagal membaca file: $e');
        return;
      }
      if (bytes.lengthInBytes > maxUploadBytes) {
        AppSnack.warning(
            'File terlalu besar (${formatFileSize(bytes.lengthInBytes)}). Maks ${formatFileSize(maxUploadBytes)}');
        return;
      }
      final segs = (f.path ?? '').split(RegExp(r'[/\\]'));
      final name = f.name.isNotEmpty
          ? f.name
          : (segs.isNotEmpty ? segs.last : 'file');
      formData[i] = formData[i].copyWith(
        type: 'file',
        fileName: name,
        filePath: f.path ?? '',
        fileSize: bytes.lengthInBytes,
        contentType: formData[i].contentType.isNotEmpty
            ? formData[i].contentType
            : guessContentType(name),
        fileBytes: bytes,
      );
    } catch (e) {
      AppSnack.error('Gagal memilih file: $e');
    }
  }

  void clearFormFile(int i) {
    formData[i] = formData[i].copyWith(
      fileName: '',
      filePath: '',
      fileSize: 0,
      clearBytes: true,
    );
  }

  /// Pastikan semua field file yang aktif punya bytes sebelum send: pakai yang
  /// di memori, atau baca ulang dari path (request tersimpan dibuka ulang).
  /// Return false + snackbar jika ada file yang tak terbaca (send dibatalkan).
  Future<bool> _ensureFormFileBytes() async {
    for (var i = 0; i < formData.length; i++) {
      final f = formData[i];
      if (!f.enabled || !f.isFile || f.key.trim().isEmpty) continue;
      if (f.hasBytes) {
        if (f.fileBytes!.lengthInBytes > maxUploadBytes) {
          AppSnack.warning(
              'File "${f.fileName}" melebihi ${formatFileSize(maxUploadBytes)}');
          return false;
        }
        continue;
      }
      if (f.filePath.isEmpty) {
        AppSnack.warning(
            'Field "${f.key}" bertipe file tapi belum ada file. Klik ikon file untuk memilih.');
        return false;
      }
      try {
        final bytes = await File(f.filePath).readAsBytes();
        if (bytes.lengthInBytes > maxUploadBytes) {
          AppSnack.warning(
              'File "${f.fileName}" melebihi ${formatFileSize(maxUploadBytes)}');
          return false;
        }
        formData[i] = f.copyWith(fileBytes: bytes, fileSize: bytes.lengthInBytes);
      } catch (_) {
        AppSnack.error(
            'File "${f.fileName.isNotEmpty ? f.fileName : f.filePath}" tidak ditemukan. Pilih ulang filenya.',
            title: 'Upload gagal');
        return false;
      }
    }
    return true;
  }

  ApiRequestModel _buildModel(String collectionId, String folderId) {
    return ApiRequestModel(
      id: editingRequestId.value ?? '',
      collectionId: collectionId,
      folderId: folderId,
      name: nameController.text.trim().isEmpty ? 'Untitled' : nameController.text.trim(),
      method: method.value,
      url: urlController.text.trim(),
      params: params.toList(),
      headers: headers.toList(),
      bodyType: bodyType.value,
      body: bodyController.text,
      formData: formData.toList(),
      auth: AuthConfig(
        type: authType.value,
        token: authTokenController.text,
        username: authUserController.text,
        password: authPassController.text,
      ),
    );
  }

  Future<void> save() async {
    if (!hasSelection) {
      AppSnack.info('Pilih / buat request di collection dulu untuk menyimpan');
      return;
    }
    try {
      isSaving.value = true;
      error.value = '';
      final col = Get.find<CollectionController>();
      final existing = col.requests.firstWhere((r) => r.id == editingRequestId.value);
      final model = _buildModel(existing.collectionId, existing.folderId).copyWith(id: existing.id);
      final updated = await _api.updateRequest(model);
      final i = col.requests.indexWhere((r) => r.id == updated.id);
      if (i != -1) col.requests[i] = updated;
      AppSnack.success('Request tersimpan', duration: const Duration(seconds: 1));
    } catch (e) {
      error.value = e.toString();
      AppSnack.error('Gagal menyimpan: $e');
    } finally {
      isSaving.value = false;
    }
  }

  String _activeEnvId() {
    if (Get.isRegistered<EnvironmentController>()) {
      return Get.find<EnvironmentController>().activeId.value ?? '';
    }
    return '';
  }

  Future<void> send() async {
    final url = urlController.text.trim();
    if (url.isEmpty) {
      AppSnack.warning('URL tidak boleh kosong');
      return;
    }
    if (bodyType.value == 'multipart' && !await _ensureFormFileBytes()) {
      return;
    }
    try {
      isSending.value = true;
      error.value = '';
      final envId = _activeEnvId();
      SendResult result;
      if (hasSelection) {
        final override = _buildModel('', '').copyWith(name: nameController.text);
        result = await _api.sendRequest(editingRequestId.value!, override: override, environmentId: envId);
      } else {
        result = await _api.sendAdhoc(
          method: method.value,
          url: url,
          params: params.map((e) => e.toJson()).toList(),
          headers: headers.map((e) => e.toJson()).toList(),
          bodyType: bodyType.value,
          body: bodyController.text,
          formData: formData
              .map((e) => e.toJson(includeBytes: true))
              .toList(),
          auth: AuthConfig(
            type: authType.value,
            token: authTokenController.text,
            username: authUserController.text,
            password: authPassController.text,
          ).toJson(),
          environmentId: envId,
        );
      }
      response.value = result;
      refreshBodyLines();
      bottomTabIndex.value = 0;
      if (Get.isRegistered<HistoryController>()) {
        await Get.find<HistoryController>().fetchHistory();
      }
    } catch (e) {
      error.value = e.toString();
      AppSnack.error('Send gagal: $e', title: 'Send gagal');
    } finally {
      isSending.value = false;
    }
  }
}
