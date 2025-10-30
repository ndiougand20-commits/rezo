import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/token.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;

  final ApiService _apiService = ApiService();

  Future<void> login(String email, String password) async {
    try {
      Token tokenResponse = await _apiService.login(email, password);
      _token = tokenResponse.accessToken;
      _user = tokenResponse.user;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> register(User user, String password) async {
    try {
      User createdUser = await _apiService.createUser(user, password);
      _user = createdUser;
      // After register, login automatically
      await login(user.email, password);
    } catch (e) {
      rethrow;
    }
  }

  void logout() {
    _user = null;
    _token = null;
    notifyListeners();
  }
}
