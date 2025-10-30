import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/student.dart';
import '../models/high_schooler.dart';
import '../models/company.dart';
import '../models/university.dart';
import '../services/api_service.dart';

class ProfileProvider with ChangeNotifier {
  dynamic _profile;
  bool _isLoading = false;
  String? _error;

  dynamic get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService _apiService = ApiService();

  Future<void> loadProfile(User user) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      switch (user.userType) {
        case UserType.student:
          _profile = await _apiService.getStudentByUserId(user.id);
          break;
        case UserType.highSchool:
          _profile = await _apiService.getHighSchoolerByUserId(user.id);
          break;
        case UserType.company:
          _profile = await _apiService.getCompanyByUserId(user.id);
          break;
        case UserType.university:
          _profile = await _apiService.getUniversityByUserId(user.id);
          break;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearProfile() {
    _profile = null;
    _error = null;
    notifyListeners();
  }
}
