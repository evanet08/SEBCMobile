import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';
import '../services/api_service.dart';

/// Auth Provider — gestion de l'état d'authentification
class AuthProvider with ChangeNotifier {
  static final AuthProvider instance = AuthProvider._();
  AuthProvider._();

  final _api = ApiService();
  final _storage = const FlutterSecureStorage();

  Membre? _membre;
  bool _isLoading = false;
  String? _error;

  Membre? get membre => _membre;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _membre != null;
  String? get error => _error;

  Future<bool> checkSession() async {
    final token = await _api.getSession();
    if (token == null) return false;
    final data = await _storage.read(key: 'membre_data');
    if (data != null) {
      _membre = Membre.fromJson(jsonDecode(data));
      Contact.setCurrentMembreId(_membre!.id);
      notifyListeners();
      return true;
    }
    // Try refreshing profile
    final result = await _api.getProfile();
    if (result['success'] == true && result['membre'] != null) {
      _membre = Membre.fromJson(result['membre']);
      Contact.setCurrentMembreId(_membre!.id);
      await _storage.write(key: 'membre_data', value: jsonEncode(result['membre']));
      notifyListeners();
      return true;
    }
    await _api.clearSession();
    return false;
  }

  Future<Map<String, dynamic>> checkEmail(String email) async {
    _setLoading(true);
    final r = await _api.checkEmail(email);
    _setLoading(false);
    return r;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _setLoading(true);
    final r = await _api.login(email, password);
    if (r['success'] == true) {
      if (r['session_token'] != null) await _api.setSession(r['session_token']);
      if (r['membre'] != null) {
        _membre = Membre.fromJson(r['membre']);
        Contact.setCurrentMembreId(_membre!.id);
        await _storage.write(key: 'membre_data', value: jsonEncode(r['membre']));
      }
    }
    _setLoading(false);
    notifyListeners();
    return r;
  }

  Future<void> logout() async {
    await _api.logout();
    await _api.clearSession();
    _membre = null;
    notifyListeners();
  }

  void setMembreFromJson(Map<String, dynamic> json) {
    _membre = Membre.fromJson(json);
    Contact.setCurrentMembreId(_membre!.id);
    _storage.write(key: 'membre_data', value: jsonEncode(json));
    notifyListeners();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    _error = null;
    notifyListeners();
  }
}
