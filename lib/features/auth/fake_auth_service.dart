part of 'auth_flow.dart';

class FakeAuthService implements AuthService {
  FakeAuthService({
    this.shouldFailLogin = false,
    this.shouldFailSignup = false,
    this.shouldFailGetMe = false,
    Map<String, dynamic>? seededUser,
  }) : _user = Map<String, dynamic>.from(seededUser ?? _defaultUser);

  final bool shouldFailLogin;
  final bool shouldFailSignup;
  final bool shouldFailGetMe;
  final Map<String, dynamic> _user;
  final List<Map<String, dynamic>> _media = <Map<String, dynamic>>[];

  static const _defaultUser = <String, dynamic>{
    'id': 'user-1',
    'email': 'awa@rezo.sn',
    'prenom': 'Awa',
    'nom': 'Fall',
    'telephone': '+221770000001',
    'role': 'ETUDIANT',
    'packNom': 'FREE',
    'packFeatures': ['MATCHING_BASIC', 'MESSAGERIE_LIMITEE'],
    'canManageOffers': false,
    'profil': {
      'niveauEtude': 'Licence 3',
      'domaine': 'Informatique',
      'competences': ['Flutter', 'Java'],
      'objectif': 'Trouver un stage',
      'preferencesSecteur': ['IT'],
      'preferencesLieu': ['Dakar'],
    },
  };

  @override
  Future<Map<String, dynamic>> getMe() async {
    if (shouldFailGetMe) {
      throw AuthException('Session expirée, reconnecte-toi', statusCode: 401);
    }

    return _cloneMap(_user);
  }

  @override
  Future<String> login({
    required String email,
    required String password,
  }) async {
    if (shouldFailLogin) {
      throw AuthException('Identifiants invalides', statusCode: 401);
    }
    return 'fake-jwt-token';
  }

  @override
  Future<void> signup(Map<String, dynamic> payload) async {
    if (shouldFailSignup) {
      throw AuthException('Cet email est déjà utilisé', statusCode: 409);
    }
  }

  @override
  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> payload) async {
    _user.addAll(payload);
    final incomingProfile = payload['profil'];
    if (incomingProfile is Map) {
      final existing =
          (_user['profil'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      _user['profil'] = {
        ...existing,
        ...incomingProfile.cast<String, dynamic>(),
      };
    }
    return _cloneMap(_user);
  }

  @override
  Future<Map<String, dynamic>> updatePack(String packId) async {
    final selected = (await getPacks()).firstWhere(
      (pack) => (pack['id']?.toString() ?? '') == packId,
      orElse: () => {'id': packId, 'nom': 'CUSTOM', 'features': <String>[]},
    );
    _user['packId'] = selected['id'];
    _user['packNom'] = selected['nom'];
    _user['packFeatures'] = selected['features'] ?? const <String>[];
    return _cloneMap(_user);
  }

  @override
  Future<Map<String, dynamic>> uploadProfilePhoto({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final media = {
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'category': 'PHOTO',
      'originalFileName': fileName,
      'contentType': 'image/*',
      'fileUrl': '/uploads/users/${_user['id']}/photos/$fileName',
      'createdAt': DateTime.now().toIso8601String(),
    };

    _media.removeWhere((entry) => entry['category']?.toString() == 'PHOTO');
    _media.add(media);
    _user['avatarUrl'] = media['fileUrl'];
    return _cloneMap(media);
  }

  @override
  Future<Map<String, dynamic>> uploadJustificatifPdf({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final media = {
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'category': 'JUSTIFICATIF_PDF',
      'originalFileName': fileName,
      'contentType': 'application/pdf',
      'fileUrl': '/uploads/users/${_user['id']}/justificatifs/$fileName',
      'createdAt': DateTime.now().toIso8601String(),
    };
    _media.add(media);
    return _cloneMap(media);
  }

  @override
  Future<List<Map<String, dynamic>>> listMyMedia({String? category}) async {
    final normalizedCategory = category?.trim().toUpperCase();
    return _media
        .where(
          (entry) =>
              normalizedCategory == null ||
              entry['category']?.toString().toUpperCase() == normalizedCategory,
        )
        .map(_cloneMap)
        .toList();
  }

  @override
  Future<void> deleteMyMedia(String mediaId) async {
    final before = _media.length;
    _media.removeWhere((entry) => entry['id']?.toString() == mediaId);
    if (before == _media.length) {
      throw AuthException('Media introuvable', statusCode: 404);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPacks() async {
    return const [
      {
        'id': 'pack-free',
        'nom': 'FREE',
        'description': 'Accès de base',
        'features': ['MATCHING_BASIC'],
      },
      {
        'id': 'pack-pro',
        'nom': 'PRO',
        'description': 'Accès avancé + messagerie illimitée',
        'features': ['MATCHING_ADVANCED', 'MESSAGERIE_ILLIMITEE'],
      },
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> getMessages() async {
    return const [
      {'content': 'Bienvenue sur REZO', 'createdAt': '2026-04-13T10:30:00'},
      {
        'content': 'Ton profil attire déjà des opportunités',
        'createdAt': '2026-04-12T09:15:00',
      },
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> getOffers() async {
    return [
      {
        'ownerUserId': _user['id']?.toString() ?? 'user-1',
        'titre': 'Stage Flutter',
        'datePublication': '2026-04-10T08:00:00',
      },
    ];
  }

  Map<String, dynamic> _cloneMap(Map<String, dynamic> source) {
    return jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
  }
}
