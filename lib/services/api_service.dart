import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/api_config.dart';

/// SEBC Mobile — Service API centralisé
class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  final _storage = const FlutterSecureStorage();
  String? _sessionToken;

  Future<void> setSession(String token) async {
    _sessionToken = token;
    await _storage.write(key: 'session_token', value: token);
  }

  Future<String?> getSession() async {
    _sessionToken ??= await _storage.read(key: 'session_token');
    return _sessionToken;
  }

  Future<void> clearSession() async {
    _sessionToken = null;
    await _storage.delete(key: 'session_token');
    await _storage.delete(key: 'membre_id');
    await _storage.delete(key: 'membre_data');
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_sessionToken != null) 'X-Session-Token': _sessionToken!,
  };

  // ═══ HTTP Helpers ═══
  Future<Map<String, dynamic>> post(String url, Map<String, dynamic> body) async {
    try {
      final r = await http.post(Uri.parse(url), headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      return jsonDecode(r.body);
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  Future<Map<String, dynamic>> get(String url, {Map<String, String>? params}) async {
    try {
      var uri = Uri.parse(url);
      if (params != null) uri = uri.replace(queryParameters: params);
      final r = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      return jsonDecode(r.body);
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  Future<Map<String, dynamic>> uploadFile(String url, File file, Map<String, String> fields) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      if (_sessionToken != null) request.headers['X-Session-Token'] = _sessionToken!;
      fields.forEach((k, v) => request.fields[k] = v);
      request.files.add(await http.MultipartFile.fromPath('attachment', file.path));
      final resp = await request.send().timeout(const Duration(seconds: 30));
      final body = await resp.stream.bytesToString();
      return jsonDecode(body);
    } catch (e) {
      return {'success': false, 'error': 'Erreur upload: $e'};
    }
  }

  // ═══ AUTH ═══
  Future<Map<String, dynamic>> checkEmail(String email) =>
      post(ApiConfig.checkEmail, {'email': email});

  Future<Map<String, dynamic>> login(String email, String password) =>
      post(ApiConfig.login, {'email': email, 'mot_de_passe': password});

  Future<Map<String, dynamic>> requestOtp(String email) =>
      post(ApiConfig.requestOtp, {'email': email});

  Future<Map<String, dynamic>> verifyOtp(String email, String code) =>
      post(ApiConfig.verifyOtp, {'email': email, 'code': code});

  Future<Map<String, dynamic>> setPasswordApi(String email, String password) =>
      post(ApiConfig.setPassword, {'email': email, 'mot_de_passe': password});

  Future<Map<String, dynamic>> logout() => post(ApiConfig.logout, {});

  // ═══ CANDIDATURE ═══
  Future<Map<String, dynamic>> checkParrain(String contact) =>
      post(ApiConfig.checkParrain, {'email_ou_telephone': contact});

  Future<Map<String, dynamic>> submitCandidature(Map<String, dynamic> data) =>
      post(ApiConfig.submitCandidature, data);

  // ═══ MEMBRE ═══
  Future<Map<String, dynamic>> getProfile() => get(ApiConfig.membreProfile);

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) =>
      post(ApiConfig.membreUpdateProfile, data);

  Future<Map<String, dynamic>> getAyantsDroits() => get(ApiConfig.membreAyantsDroits);

  Future<Map<String, dynamic>> validerFilleul(int filleulId) =>
      post(ApiConfig.validerFilleul, {'filleul_id': filleulId});

  Future<Map<String, dynamic>> relancerParrain() =>
      post(ApiConfig.relancerParrain, {});

  // ═══ COMMUNICATION ═══
  Future<Map<String, dynamic>> getContacts() => get(ApiConfig.commContacts);

  Future<Map<String, dynamic>> getThreads() => get(ApiConfig.commThreads);

  Future<Map<String, dynamic>> getMessages(String threadId) =>
      get(ApiConfig.commMessages, params: {'thread_id': threadId});

  Future<Map<String, dynamic>> sendMessage(Map<String, dynamic> data) =>
      post(ApiConfig.commSend, data);

  Future<Map<String, dynamic>> sendFileMessage(File file, Map<String, String> fields) =>
      uploadFile(ApiConfig.commSendFile, file, fields);

  Future<Map<String, dynamic>> getUnreadCount() => get(ApiConfig.commUnread);

  Future<Map<String, dynamic>> startVisio(String threadId, String contactName) =>
      get(ApiConfig.commVisio, params: {'thread_id': threadId, 'contact_name': contactName});

  Future<Map<String, dynamic>> createGroup(Map<String, dynamic> data) =>
      post(ApiConfig.commGroupCreate, data);

  Future<Map<String, dynamic>> deleteGroup(int groupId) =>
      post(ApiConfig.commGroupDelete, {'id': groupId});

  // ═══ MEETINGS ═══
  Future<Map<String, dynamic>> getMeetings() => get(ApiConfig.meetingsList);

  Future<Map<String, dynamic>> createMeeting(Map<String, dynamic> data) =>
      post(ApiConfig.meetingsCreate, data);

  Future<Map<String, dynamic>> cancelMeeting(int meetingId) =>
      post(ApiConfig.meetingsCancel, {'id': meetingId});

  Future<Map<String, dynamic>> joinMeeting(String token) =>
      get(ApiConfig.meetingsJoin, params: {'token': token});

  // ═══ REF DATA ═══
  Future<Map<String, dynamic>> getRefData() => get(ApiConfig.refData);
}
