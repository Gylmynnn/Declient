import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../core/utils/app_logger.dart';
import '../models/api_request_model.dart';
import '../models/collection_model.dart';
import '../models/environment_model.dart';
import '../models/folder_model.dart';
import '../models/history_model.dart';

class ApiService extends GetxService {
  final String baseUrl;

  ApiService({this.baseUrl = 'http://localhost:9001'});

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  void _check(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw Exception('Request failed ${res.statusCode}: ${res.body}');
  }

  dynamic _decode(http.Response res) {
    if (res.body.isEmpty) return null;
    return json.decode(res.body);
  }

  // ---------- Collections ----------
  Future<List<CollectionModel>> getCollections() async {
    final uri = Uri.parse('$baseUrl/api/collections');
    AppLogger.info('[Api] GET $uri');
    final res = await http.get(uri);
    _check(res);
    final list = _decode(res) as List;
    return list.map((e) => CollectionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CollectionModel> createCollection(String name, String description) async {
    final uri = Uri.parse('$baseUrl/api/collections');
    final res = await http.post(uri, headers: _headers, body: json.encode({'name': name, 'description': description}));
    _check(res);
    return CollectionModel.fromJson(_decode(res) as Map<String, dynamic>);
  }

  Future<CollectionModel> updateCollection(String id, String name, String description) async {
    final uri = Uri.parse('$baseUrl/api/collections/$id');
    final res = await http.put(uri, headers: _headers, body: json.encode({'name': name, 'description': description}));
    _check(res);
    return CollectionModel.fromJson(_decode(res) as Map<String, dynamic>);
  }

  Future<void> deleteCollection(String id) async {
    final res = await http.delete(Uri.parse('$baseUrl/api/collections/$id'));
    if (res.statusCode != 204) _check(res);
  }

  Future<CollectionDetail> getCollectionDetail(String id) async {
    final res = await http.get(Uri.parse('$baseUrl/api/collections/$id'));
    _check(res);
    final map = _decode(res) as Map<String, dynamic>;
    return CollectionDetail.fromJson(map);
  }

  // ---------- Folders ----------
  Future<List<FolderModel>> getFolders(String collectionId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/collections/$collectionId/folders'));
    _check(res);
    final list = _decode(res) as List;
    return list.map((e) => FolderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<FolderModel> createFolder({required String collectionId, String parentId = '', required String name, String description = ''}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/collections/$collectionId/folders'),
      headers: _headers,
      body: json.encode({'collectionId': collectionId, 'parentId': parentId, 'name': name, 'description': description}),
    );
    _check(res);
    return FolderModel.fromJson(_decode(res) as Map<String, dynamic>);
  }

  Future<FolderModel> updateFolder(String id, String name, String description) async {
    final res = await http.put(Uri.parse('$baseUrl/api/folders/$id'),
        headers: _headers, body: json.encode({'name': name, 'description': description}));
    _check(res);
    return FolderModel.fromJson(_decode(res) as Map<String, dynamic>);
  }

  Future<void> deleteFolder(String id) async {
    final res = await http.delete(Uri.parse('$baseUrl/api/folders/$id'));
    if (res.statusCode != 204) _check(res);
  }

  // ---------- Requests ----------
  Future<List<ApiRequestModel>> getRequests(String collectionId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/collections/$collectionId/requests'));
    _check(res);
    final list = _decode(res) as List;
    return list.map((e) => ApiRequestModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ApiRequestModel> createRequest(ApiRequestModel req) async {
    final res = await http.post(Uri.parse('$baseUrl/api/requests'), headers: _headers, body: json.encode(req.toJson()));
    _check(res);
    return ApiRequestModel.fromJson(_decode(res) as Map<String, dynamic>);
  }

  Future<ApiRequestModel> updateRequest(ApiRequestModel req) async {
    final res = await http.put(Uri.parse('$baseUrl/api/requests/${req.id}'),
        headers: _headers, body: json.encode(req.toJson()));
    _check(res);
    return ApiRequestModel.fromJson(_decode(res) as Map<String, dynamic>);
  }

  Future<void> deleteRequest(String id) async {
    final res = await http.delete(Uri.parse('$baseUrl/api/requests/$id'));
    if (res.statusCode != 204) _check(res);
  }

  Future<SendResult> sendRequest(String id, {ApiRequestModel? override, String environmentId = ''}) async {
    final body = <String, dynamic>{'environmentId': environmentId};
    if (override != null) {
      body.addAll({
        'method': override.method,
        'url': override.url,
        'params': override.params.map((e) => e.toJson()).toList(),
        'headers': override.headers.map((e) => e.toJson()).toList(),
        'bodyType': override.bodyType,
        'body': override.body,
        'formData': override.formData
            .map((e) => e.toJson(includeBytes: true))
            .toList(),
        'auth': override.auth.toJson(),
      });
    }
    final res = await http.post(Uri.parse('$baseUrl/api/requests/$id/send'), headers: _headers, body: json.encode(body));
    _check(res);
    return SendResult.fromJson(_decode(res) as Map<String, dynamic>);
  }

  Future<SendResult> sendAdhoc({
    required String method,
    required String url,
    required List<Map<String, dynamic>> params,
    required List<Map<String, dynamic>> headers,
    required String bodyType,
    required String body,
    List<Map<String, dynamic>> formData = const [],
    required Map<String, dynamic> auth,
    String environmentId = '',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/send'),
      headers: _headers,
      body: json.encode({
        'method': method,
        'url': url,
        'params': params,
        'headers': headers,
        'bodyType': bodyType,
        'body': body,
        'formData': formData,
        'auth': auth,
        'environmentId': environmentId,
      }),
    );
    _check(res);
    return SendResult.fromJson(_decode(res) as Map<String, dynamic>);
  }

  // ---------- Environments ----------
  Future<List<EnvironmentModel>> getEnvironments() async {
    final res = await http.get(Uri.parse('$baseUrl/api/environments'));
    _check(res);
    final list = _decode(res) as List;
    return list.map((e) => EnvironmentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<EnvironmentModel> createEnvironment(String name, List<EnvVariable> vars) async {
    final res = await http.post(Uri.parse('$baseUrl/api/environments'),
        headers: _headers,
        body: json.encode({'name': name, 'variables': vars.map((e) => e.toJson()).toList()}));
    _check(res);
    return EnvironmentModel.fromJson(_decode(res) as Map<String, dynamic>);
  }

  Future<EnvironmentModel> updateEnvironment(String id, String name, List<EnvVariable> vars) async {
    final res = await http.put(Uri.parse('$baseUrl/api/environments/$id'),
        headers: _headers,
        body: json.encode({'name': name, 'variables': vars.map((e) => e.toJson()).toList()}));
    _check(res);
    return EnvironmentModel.fromJson(_decode(res) as Map<String, dynamic>);
  }

  Future<void> deleteEnvironment(String id) async {
    final res = await http.delete(Uri.parse('$baseUrl/api/environments/$id'));
    if (res.statusCode != 204) _check(res);
  }

  Future<EnvironmentModel?> getActiveEnvironment() async {
    final res = await http.get(Uri.parse('$baseUrl/api/environments/active'));
    _check(res);
    final map = _decode(res) as Map<String, dynamic>;
    if (map['active'] == null) return null;
    return EnvironmentModel.fromJson(map['active'] as Map<String, dynamic>);
  }

  Future<void> setActiveEnvironment(String id) async {
    final res = await http.post(Uri.parse('$baseUrl/api/environments/active'),
        headers: _headers, body: json.encode({'id': id}));
    _check(res);
  }

  // ---------- History ----------
  Future<List<HistoryModel>> getHistory({int limit = 50}) async {
    final res = await http.get(Uri.parse('$baseUrl/api/history?limit=$limit'));
    _check(res);
    final list = _decode(res) as List;
    return list.map((e) => HistoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> clearHistory() async {
    final res = await http.delete(Uri.parse('$baseUrl/api/history'));
    if (res.statusCode != 204) _check(res);
  }

  // ---------- Transfer ----------
  Future<Map<String, dynamic>> exportAll() async {
    final res = await http.get(Uri.parse('$baseUrl/api/export'));
    _check(res);
    return _decode(res) as Map<String, dynamic>;
  }

  Future<CollectionModel> importPostman(Map<String, dynamic> postmanJson) async {
    final res = await http.post(Uri.parse('$baseUrl/api/import?format=postman'),
        headers: _headers, body: json.encode(postmanJson));
    _check(res);
    return CollectionModel.fromJson(_decode(res) as Map<String, dynamic>);
  }

  Future<void> importNative(Map<String, dynamic> dump) async {
    final res = await http.post(Uri.parse('$baseUrl/api/import/native'), headers: _headers, body: json.encode(dump));
    _check(res);
  }
}

class CollectionDetail {
  final CollectionModel collection;
  final List<FolderModel> folders;
  final List<ApiRequestModel> requests;

  CollectionDetail({required this.collection, required this.folders, required this.requests});

  factory CollectionDetail.fromJson(Map<String, dynamic> json) {
    return CollectionDetail(
      collection: CollectionModel.fromJson(json['collection'] as Map<String, dynamic>),
      folders: ((json['folders'] as List?) ?? []).map((e) => FolderModel.fromJson(e as Map<String, dynamic>)).toList(),
      requests: ((json['requests'] as List?) ?? []).map((e) => ApiRequestModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
