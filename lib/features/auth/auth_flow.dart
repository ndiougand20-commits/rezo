import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

part 'services.dart';
part 'state.dart';
part 'app_shell.dart';
part 'splash_screen.dart';
part 'welcome_screen.dart';
part 'onboarding_screen.dart';
part 'login_screen.dart';
part 'signup_screen.dart';
part 'dashboard_screen.dart';
part 'matches_tab.dart';
part 'home_tab.dart';
part 'messages_tab.dart';
part 'profile_tab.dart';
part 'widgets.dart';
part 'validators.dart';
part 'fake_auth_service.dart';

class AppRoutes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const dashboard = '/dashboard';
}

class AuthException implements Exception {
  const AuthException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

enum UserRole { etudiant, lyceen, emploi, entreprise, ecole }

extension UserRoleX on UserRole {
  String get apiValue {
    switch (this) {
      case UserRole.etudiant:
        return 'ETUDIANT';
      case UserRole.lyceen:
        return 'LYCEEN';
      case UserRole.emploi:
        return 'EMPLOI';
      case UserRole.entreprise:
        return 'ENTREPRISE';
      case UserRole.ecole:
        return 'ECOLE';
    }
  }

  String get label {
    switch (this) {
      case UserRole.etudiant:
        return 'Étudiant';
      case UserRole.lyceen:
        return 'Lycéen';
      case UserRole.emploi:
        return 'Emploi';
      case UserRole.entreprise:
        return 'Entreprise';
      case UserRole.ecole:
        return 'École de formation';
    }
  }

  String get benefit {
    switch (this) {
      case UserRole.etudiant:
        return 'Trouve un stage, une alternance ou un premier emploi pertinent.';
      case UserRole.lyceen:
        return 'Découvre les écoles et formations adaptées à ton projet post-bac.';
      case UserRole.emploi:
        return 'Accède à des opportunités ciblées selon ton expérience et ton objectif.';
      case UserRole.entreprise:
        return 'Identifie plus vite les profils compatibles avec tes besoins de recrutement.';
      case UserRole.ecole:
        return 'Valorise tes formations et attire les bons candidats.';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.etudiant:
        return Icons.school_rounded;
      case UserRole.lyceen:
        return Icons.auto_stories_rounded;
      case UserRole.emploi:
        return Icons.work_rounded;
      case UserRole.entreprise:
        return Icons.apartment_rounded;
      case UserRole.ecole:
        return Icons.account_balance_rounded;
    }
  }
}

UserRole parseUserRole(String? value) {
  switch ((value ?? '').trim().toUpperCase()) {
    case 'LYCEEN':
      return UserRole.lyceen;
    case 'EMPLOI':
      return UserRole.emploi;
    case 'ENTREPRISE':
      return UserRole.entreprise;
    case 'ECOLE':
      return UserRole.ecole;
    case 'ETUDIANT':
    default:
      return UserRole.etudiant;
  }
}
