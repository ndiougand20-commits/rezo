import 'package:flutter/material.dart';
import '../models/offer.dart';
import '../models/formation.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class SwipeProvider with ChangeNotifier {
  List<dynamic> _items = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService _apiService = ApiService();

  Future<void> loadItems(UserType userType) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (userType == UserType.student || userType == UserType.highSchool) {
        if (userType == UserType.student) {
          _items = await _apiService.getOffers();
        } else {
          _items = await _apiService.getFormations();
        }
      } else {
        // Pour entreprises et universités, pas de swipe pour l'instant
        _items = [];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void onSwipeRight(dynamic item) {
    // Pour l'instant, juste un print. Plus tard, appeler l'API pour postuler ou montrer intérêt
    if (item is Offer) {
      print('Postulé à l\'offre: ${item.title}');
    } else if (item is Formation) {
      print('Intérêt pour la formation: ${item.title}');
    }
  }

  void onSwipeLeft(dynamic item) {
    // Swipe gauche : passer
    if (item is Offer) {
      print('Passé l\'offre: ${item.title}');
    } else if (item is Formation) {
      print('Passé la formation: ${item.title}');
    }
  }
}
