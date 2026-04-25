part of 'auth_flow.dart';

abstract class AuthService {
  Future<void> signup(Map<String, dynamic> payload);

  Future<String> login({required String email, required String password});

  Future<Map<String, dynamic>> getMe();

  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> payload);

  Future<Map<String, dynamic>> updatePack(String packId);

  Future<List<Map<String, dynamic>>> getPacks();

  Future<List<Map<String, dynamic>>> getMessages();

  Future<List<Map<String, dynamic>>> getOffers();

  Future<Map<String, dynamic>> uploadProfilePhoto({
    required Uint8List bytes,
    required String fileName,
  });

  Future<Map<String, dynamic>> uploadJustificatifPdf({
    required Uint8List bytes,
    required String fileName,
  });

  Future<List<Map<String, dynamic>>> listMyMedia({String? category});

  Future<void> deleteMyMedia(String mediaId);
}

class HttpAuthService implements AuthService {
  HttpAuthService({required this.baseUrl, required this.tokenStorage});

  static const defaultBaseUrl = kIsWeb
      ? 'http://localhost:8082'
      : 'http://10.0.2.2:8082';

  final String baseUrl;
  final TokenStorage tokenStorage;

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    return Uri.parse('$baseUrl$path').replace(queryParameters: queryParameters);
  }

  Future<Map<String, String>> _headers({bool authenticated = false}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (authenticated) {
      final token = await tokenStorage.readToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  dynamic _decodeBody(http.Response response) {
    if (response.body.trim().isEmpty) {
      return null;
    }
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return response.body;
    }
  }

  T _requireSuccess<T>(
    http.Response response,
    T Function(dynamic body) onSuccess,
  ) {
    final body = _decodeBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return onSuccess(body);
    }
    throw AuthException(
      _extractErrorMessage(response),
      statusCode: response.statusCode,
    );
  }

  Map<String, dynamic> _asMap(dynamic body) {
    if (body is Map<String, dynamic>) {
      return body;
    }
    if (body is Map) {
      return body.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asList(dynamic body) {
    if (body is List) {
      return body
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  dynamic _extractData(dynamic body) {
    if (body is Map && body.containsKey('data')) {
      return body['data'];
    }
    return body;
  }

  Future<Map<String, dynamic>> _sendMultipart({
    required String path,
    required String fieldName,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    final token = await tokenStorage.readToken();
    request.headers['Accept'] = 'application/json';
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(
      http.MultipartFile.fromBytes(fieldName, bytes, filename: fileName),
    );
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _requireSuccess(response, (body) => _asMap(_extractData(body)));
  }

  @override
  Future<void> signup(Map<String, dynamic> payload) async {
    final response = await http.post(
      _uri('/auth/register'),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    _requireSuccess<void>(response, (_) {});
  }

  @override
  Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      _uri('/auth/login'),
      headers: await _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _requireSuccess<String>(response, (body) {
      final data = _asMap(_extractData(body));
      final token =
          data['token']?.toString() ??
          data['jwt']?.toString() ??
          data['accessToken']?.toString() ??
          '';
      if (token.isEmpty) {
        throw const AuthException('Réponse de connexion invalide');
      }
      return token;
    });
  }

  @override
  Future<Map<String, dynamic>> getMe() async {
    final response = await http.get(
      _uri('/auth/me'),
      headers: await _headers(authenticated: true),
    );
    return _requireSuccess(response, (body) => _asMap(_extractData(body)));
  }

  @override
  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> payload) async {
    final response = await http.put(
      _uri('/auth/me'),
      headers: await _headers(authenticated: true),
      body: jsonEncode(payload),
    );
    return _requireSuccess(response, (body) => _asMap(_extractData(body)));
  }

  @override
  Future<Map<String, dynamic>> updatePack(String packId) async {
    final response = await http.patch(
      _uri('/auth/me/pack'),
      headers: await _headers(authenticated: true),
      body: jsonEncode({'packId': packId}),
    );
    return _requireSuccess(response, (body) => _asMap(_extractData(body)));
  }

  @override
  Future<List<Map<String, dynamic>>> getPacks() async {
    final response = await http.get(
      _uri('/packs'),
      headers: await _headers(authenticated: true),
    );
    return _requireSuccess(response, (body) => _asList(_extractData(body)));
  }

  @override
  Future<List<Map<String, dynamic>>> getMessages() async {
    final response = await http.get(
      _uri('/messages'),
      headers: await _headers(authenticated: true),
    );
    return _requireSuccess(response, (body) => _asList(_extractData(body)));
  }

  @override
  Future<List<Map<String, dynamic>>> getOffers() async {
    final response = await http.get(
      _uri('/offres'),
      headers: await _headers(authenticated: true),
    );
    return _requireSuccess(response, (body) => _asList(_extractData(body)));
  }

  @override
  Future<Map<String, dynamic>> uploadProfilePhoto({
    required Uint8List bytes,
    required String fileName,
  }) {
    return _sendMultipart(
      path: '/auth/me/photo',
      fieldName: 'file',
      bytes: bytes,
      fileName: fileName,
    );
  }

  @override
  Future<Map<String, dynamic>> uploadJustificatifPdf({
    required Uint8List bytes,
    required String fileName,
  }) {
    return _sendMultipart(
      path: '/auth/me/justificatifs',
      fieldName: 'file',
      bytes: bytes,
      fileName: fileName,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> listMyMedia({String? category}) async {
    final response = await http.get(
      _uri('/auth/me/media', category == null ? null : {'category': category}),
      headers: await _headers(authenticated: true),
    );
    return _requireSuccess(response, (body) => _asList(_extractData(body)));
  }

  @override
  Future<void> deleteMyMedia(String mediaId) async {
    final response = await http.delete(
      _uri('/auth/me/media/$mediaId'),
      headers: await _headers(authenticated: true),
    );
    _requireSuccess<void>(response, (_) {});
  }

  String _extractErrorMessage(http.Response response) {
    final body = _decodeBody(response);
    if (body is Map) {
      final message =
          body['message']?.toString() ??
          body['error']?.toString() ??
          body['detail']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return _mapErrorMessage(message);
      }
    }

    if (response.body.trim().isNotEmpty) {
      return _mapErrorMessage(response.body.trim());
    }

    return 'Une erreur réseau est survenue';
  }

  String _mapErrorMessage(String rawMessage) {
    final message = rawMessage.trim();
    final lower = message.toLowerCase();

    if (lower.contains('email deja utilise')) {
      return 'Cet email est déjà utilisé';
    }
    if (lower.contains('incorrect')) {
      return 'Identifiants invalides';
    }
    if (lower.contains('champ profil obligatoire')) {
      return 'Merci de remplir tous les champs obligatoires';
    }
    if (lower.contains('non authentifie') || lower.contains('jwt')) {
      return 'Session expirée, reconnecte-toi';
    }
    if (lower.contains('aucun fichier recu')) {
      return 'Aucun fichier reçu';
    }
    if (lower.contains('format image non supporte')) {
      return 'Format image non supporté (jpeg, png, webp, gif)';
    }
    if (lower.contains('image depasse') || lower.contains('8mb')) {
      return 'L\'image dépasse la taille maximale autorisée (8MB)';
    }
    if (lower.contains('pdf') && lower.contains('autorises')) {
      return 'Seuls les fichiers PDF sont autorisés pour les justificatifs';
    }
    if (lower.contains('pdf depasse') || lower.contains('12mb')) {
      return 'Le PDF dépasse la taille maximale autorisée (12MB)';
    }

    return message;
  }
}

abstract class TokenStorage {
  Future<void> saveToken(String token);

  Future<String?> readToken();

  Future<void> clearToken();
}

class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage();

  static const _key = 'auth_token';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  Future<void> saveToken(String token) {
    return _storage.write(key: _key, value: token);
  }

  @override
  Future<String?> readToken() {
    return _storage.read(key: _key);
  }

  @override
  Future<void> clearToken() {
    return _storage.delete(key: _key);
  }
}

class MemoryTokenStorage implements TokenStorage {
  String? _token;

  @override
  Future<void> clearToken() async {
    _token = null;
  }

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> saveToken(String token) async {
    _token = token;
  }
}
