import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AppRoutes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const dashboard = '/dashboard';
}

enum UserRole { etudiant, entreprise, ecole }

extension UserRoleX on UserRole {
  String get apiValue {
    switch (this) {
      case UserRole.etudiant:
        return 'ETUDIANT';
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
      case UserRole.entreprise:
        return 'Entreprise';
      case UserRole.ecole:
        return 'École';
    }
  }

  String get benefit {
    switch (this) {
      case UserRole.etudiant:
        return 'Stages, alternance et accompagnement IA';
      case UserRole.entreprise:
        return 'Publier des offres et matcher rapidement';
      case UserRole.ecole:
        return 'Valoriser vos programmes et recruter vos talents';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.etudiant:
        return Icons.school_rounded;
      case UserRole.entreprise:
        return Icons.apartment_rounded;
      case UserRole.ecole:
        return Icons.menu_book_rounded;
    }
  }
}

UserRole parseUserRole(String? value) {
  switch (value?.toUpperCase()) {
    case 'ENTREPRISE':
      return UserRole.entreprise;
    case 'ECOLE':
      return UserRole.ecole;
    case 'ETUDIANT':
    default:
      return UserRole.etudiant;
  }
}

class AuthException implements Exception {
  AuthException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

abstract class AuthService {
  Future<void> signup(Map<String, dynamic> payload);

  Future<String> login({required String email, required String password});

  Future<Map<String, dynamic>> getMe();

  Future<Map<String, dynamic>> authorizedGet(String path);

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
  HttpAuthService({
    required this.baseUrl,
    required TokenStorage tokenStorage,
    http.Client? client,
  }) : _tokenStorage = tokenStorage,
       _client = client ?? http.Client();

  final String baseUrl;
  final TokenStorage _tokenStorage;
  final http.Client _client;

  static String get defaultBaseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8082';
    }
    return 'http://localhost:8082';
  }

  @override
  Future<void> signup(Map<String, dynamic> payload) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/auth/signup'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 12));

    _ensureSuccess(response);
  }

  @override
  Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 12));

    final data = _ensureSuccess(response);
    final token = data['token'];
    if (token is! String || token.trim().isEmpty) {
      throw AuthException('Token JWT manquant dans la réponse backend');
    }
    return token;
  }

  @override
  Future<Map<String, dynamic>> getMe() {
    return authorizedGet('/api/users/me');
  }

  @override
  Future<Map<String, dynamic>> authorizedGet(String path) async {
    final token = await _readRequiredToken();
    final response = await _client
        .get(
          Uri.parse('$baseUrl$path'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 12));

    return _ensureSuccess(response);
  }

  @override
  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> payload) async {
    final token = await _readRequiredToken();
    final response = await _client
        .put(
          Uri.parse('$baseUrl/api/users/me'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 12));

    return _ensureSuccess(response);
  }

  @override
  Future<Map<String, dynamic>> updatePack(String packId) async {
    final token = await _readRequiredToken();
    final response = await _client
        .put(
          Uri.parse('$baseUrl/api/users/me/pack'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'packId': packId}),
        )
        .timeout(const Duration(seconds: 12));

    return _ensureSuccess(response);
  }

  @override
  Future<List<Map<String, dynamic>>> getPacks() async {
    final response = await _client
        .get(
          Uri.parse('$baseUrl/api/packs'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = _decodeBody(response);
      throw AuthException(
        _mapErrorMessage(_extractMessage(response, data)),
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    return _normalizeList(decoded);
  }

  @override
  Future<List<Map<String, dynamic>>> getMessages() async {
    final data = await authorizedGet('/api/messages');
    final content = data['content'] ?? data['data'] ?? data['messages'] ?? data;
    return _normalizeList(content);
  }

  @override
  Future<List<Map<String, dynamic>>> getOffers() async {
    final response = await _client
        .get(
          Uri.parse('$baseUrl/api/offers'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = _decodeBody(response);
      throw AuthException(
        _mapErrorMessage(_extractMessage(response, data)),
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    return _normalizeList(decoded);
  }

  @override
  Future<Map<String, dynamic>> uploadProfilePhoto({
    required Uint8List bytes,
    required String fileName,
  }) {
    return _uploadMultipart(
      path: '/api/users/me/media/photos',
      bytes: bytes,
      fileName: fileName,
    );
  }

  @override
  Future<Map<String, dynamic>> uploadJustificatifPdf({
    required Uint8List bytes,
    required String fileName,
  }) {
    return _uploadMultipart(
      path: '/api/users/me/media/justificatifs',
      bytes: bytes,
      fileName: fileName,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> listMyMedia({String? category}) async {
    final token = await _readRequiredToken();
    final uri = Uri.parse('$baseUrl/api/users/me/media').replace(
      queryParameters: category == null ? null : {'category': category},
    );

    final response = await _client
        .get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = _decodeBody(response);
      throw AuthException(
        _mapErrorMessage(_extractMessage(response, data)),
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final content = (decoded is Map<String, dynamic>)
        ? decoded['content'] ??
              decoded['data'] ??
              decoded['media'] ??
              decoded['items'] ??
              decoded
        : decoded;
    return _normalizeList(content);
  }

  @override
  Future<void> deleteMyMedia(String mediaId) async {
    final token = await _readRequiredToken();
    final response = await _client
        .delete(
          Uri.parse('$baseUrl/api/users/me/media/$mediaId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = _decodeBody(response);
      throw AuthException(
        _mapErrorMessage(_extractMessage(response, data)),
        statusCode: response.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> _uploadMultipart({
    required String path,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final token = await _readRequiredToken();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);
    return _ensureSuccess(response);
  }

  Future<String> _readRequiredToken() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.trim().isEmpty) {
      throw AuthException('Session expirée, reconnecte-toi', statusCode: 401);
    }
    return token;
  }

  List<Map<String, dynamic>> _normalizeList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((entry) => entry.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
    }
    if (raw is Map<String, dynamic>) {
      return [raw];
    }
    if (raw is Map) {
      return [raw.map((k, v) => MapEntry(k.toString(), v))];
    }
    return const [];
  }

  Map<String, dynamic> _ensureSuccess(http.Response response) {
    final data = _decodeBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw AuthException(
      _mapErrorMessage(_extractMessage(response, data)),
      statusCode: response.statusCode,
    );
  }

  Map<String, dynamic> _decodeBody(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
      return {'data': decoded};
    } catch (_) {
      return {'message': response.body.trim()};
    }
  }

  String _extractMessage(http.Response response, Map<String, dynamic> data) {
    for (final key in const ['message', 'error', 'details']) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    if (response.body.trim().isNotEmpty) {
      return response.body.trim();
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

class AppState extends ChangeNotifier {
  AppState({
    required AuthService authService,
    required TokenStorage tokenStorage,
  }) : _authService = authService,
       _tokenStorage = tokenStorage;

  final AuthService _authService;
  final TokenStorage _tokenStorage;

  bool _isAuthenticated = false;
  bool _isCheckingSession = false;
  String? _token;
  Map<String, dynamic>? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  bool get isCheckingSession => _isCheckingSession;
  String? get token => _token;
  Map<String, dynamic>? get currentUser => _currentUser;
  UserRole get currentRole => parseUserRole(_currentUser?['role'] as String?);

  Future<bool> restoreSession() async {
    _isCheckingSession = true;
    notifyListeners();

    try {
      final savedToken = await _tokenStorage.readToken();
      if (savedToken == null || savedToken.isEmpty) {
        _reset();
        return false;
      }

      final me = await _authService.getMe();
      _token = savedToken;
      _currentUser = me;
      _isAuthenticated = true;
      return true;
    } on AuthException catch (error) {
      await _clearSessionIfUnauthorized(error);
      _reset();
      return false;
    } catch (_) {
      await _tokenStorage.clearToken();
      _reset();
      return false;
    } finally {
      _isCheckingSession = false;
      notifyListeners();
    }
  }

  Future<void> signup(Map<String, dynamic> payload) {
    return _authService.signup(payload);
  }

  Future<void> login({required String email, required String password}) async {
    final jwt = await _authService.login(email: email, password: password);
    await _tokenStorage.saveToken(jwt);
    try {
      final me = await _authService.getMe();

      _token = jwt;
      _currentUser = me;
      _isAuthenticated = true;
      notifyListeners();
    } on AuthException catch (error) {
      await _clearSessionIfUnauthorized(error);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clearToken();
    _reset();
    notifyListeners();
  }

  Future<Map<String, dynamic>> refreshCurrentUser() async {
    try {
      final me = await _authService.getMe();
      _currentUser = me;
      _isAuthenticated = true;
      notifyListeners();
      return me;
    } on AuthException catch (error) {
      await _clearSessionIfUnauthorized(error);
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> payload,
  ) async {
    try {
      await _authService.updateMe(payload);
      return refreshCurrentUser();
    } on AuthException catch (error) {
      await _clearSessionIfUnauthorized(error);
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> changePack(String packId) async {
    try {
      await _authService.updatePack(packId);
      return refreshCurrentUser();
    } on AuthException catch (error) {
      await _clearSessionIfUnauthorized(error);
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchPacks() {
    return _authService.getPacks();
  }

  Future<List<Map<String, dynamic>>> fetchMessages() {
    return _authService.getMessages();
  }

  Future<List<Map<String, dynamic>>> fetchOffers() {
    return _authService.getOffers();
  }

  Future<Map<String, dynamic>> uploadProfilePhoto({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      return _authService.uploadProfilePhoto(bytes: bytes, fileName: fileName);
    } on AuthException catch (error) {
      await _clearSessionIfUnauthorized(error);
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadJustificatifPdf({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      return _authService.uploadJustificatifPdf(
        bytes: bytes,
        fileName: fileName,
      );
    } on AuthException catch (error) {
      await _clearSessionIfUnauthorized(error);
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchMyMedia({String? category}) async {
    try {
      return _authService.listMyMedia(category: category);
    } on AuthException catch (error) {
      await _clearSessionIfUnauthorized(error);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteMyMedia(String mediaId) async {
    try {
      await _authService.deleteMyMedia(mediaId);
    } on AuthException catch (error) {
      await _clearSessionIfUnauthorized(error);
      notifyListeners();
      rethrow;
    }
  }

  void _reset() {
    _token = null;
    _currentUser = null;
    _isAuthenticated = false;
  }

  Future<void> _clearSessionIfUnauthorized(AuthException error) async {
    if (error.statusCode == 401) {
      await _tokenStorage.clearToken();
      _reset();
    }
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({required AppState notifier, required super.child, super.key})
    : super(notifier: notifier);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope non trouvé dans le contexte.');
    return scope!.notifier!;
  }
}

class RezoApp extends StatefulWidget {
  const RezoApp({super.key, this.authService, this.tokenStorage});

  final AuthService? authService;
  final TokenStorage? tokenStorage;

  @override
  State<RezoApp> createState() => _RezoAppState();
}

class _RezoAppState extends State<RezoApp> {
  late final AppState _appState;

  @override
  void initState() {
    super.initState();
    final tokenStorage = widget.tokenStorage ?? const SecureTokenStorage();
    _appState = AppState(
      authService:
          widget.authService ??
          HttpAuthService(
            baseUrl: HttpAuthService.defaultBaseUrl,
            tokenStorage: tokenStorage,
          ),
      tokenStorage: tokenStorage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      notifier: _appState,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'REZO',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2260FF)),
          scaffoldBackgroundColor: const Color(0xFFF6F8FF),
          useMaterial3: true,
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFD7E3FF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFD7E3FF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF2260FF),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            color: Colors.white,
            margin: EdgeInsets.zero,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFFE5ECFF)),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Color(0xFFCAD8FF)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        initialRoute: AppRoutes.splash,
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case AppRoutes.splash:
              return MaterialPageRoute(builder: (_) => const SplashScreen());
            case AppRoutes.welcome:
              return MaterialPageRoute(builder: (_) => const WelcomeScreen());
            case AppRoutes.onboarding:
              return MaterialPageRoute(
                builder: (_) => const OnboardingScreen(),
              );
            case AppRoutes.login:
              return MaterialPageRoute(
                builder: (_) =>
                    LoginScreen(initialEmail: settings.arguments as String?),
              );
            case AppRoutes.signup:
              return MaterialPageRoute(
                builder: (_) => SignupScreen(
                  initialRole:
                      settings.arguments as UserRole? ?? UserRole.etudiant,
                ),
              );
            case AppRoutes.dashboard:
              if (!_appState.isAuthenticated) {
                return MaterialPageRoute(builder: (_) => const LoginScreen());
              }
              return MaterialPageRoute(builder: (_) => const DashboardScreen());
            default:
              return MaterialPageRoute(builder: (_) => const WelcomeScreen());
          }
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final appState = AppScope.of(context);
    final authenticated = await appState.restoreSession();
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacementNamed(
      authenticated ? AppRoutes.dashboard : AppRoutes.welcome,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2260FF), Color(0xFF5A7FFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RezoLogo(height: 120),
              SizedBox(height: 18),
              Text(
                'Connexion à votre réseau d’opportunités',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'REZO',
      subtitle: 'Votre avenir en un swipe',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFDCE6FF)),
            ),
            child: const Column(
              children: [
                RezoLogo(height: 88),
                SizedBox(height: 10),
                Text(
                  'Étudiants, entreprises et écoles réunis dans un même tunnel fluide.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeroStatChip(label: 'Étudiant'),
                    _HeroStatChip(label: 'Entreprise'),
                    _HeroStatChip(label: 'École'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.login);
            },
            child: const Text('Se connecter'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              Navigator.of(
                context,
              ).pushNamed(AppRoutes.signup, arguments: UserRole.etudiant);
            },
            child: const Text('Créer un compte'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.onboarding);
            },
            child: const Text('Découvrir REZO'),
          ),
        ],
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  static const _slides = [
    (
      Icons.swipe_rounded,
      'Matchez plus vite',
      'Découvrez stages, alternances et opportunités pertinentes selon votre profil.',
    ),
    (
      Icons.forum_rounded,
      'Discutez au bon moment',
      'Messagerie intégrée, feedback en temps réel et parcours sans friction.',
    ),
    (
      Icons.psychology_rounded,
      'Bénéficiez de l’IA',
      'Orientation, recommandations de packs et accompagnement personnalisé.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _slides.length - 1;

    return AuthScaffold(
      title: 'Onboarding',
      subtitle: 'En quelques écrans, découvrez la promesse REZO.',
      child: Column(
        children: [
          SizedBox(
            height: 360,
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (value) => setState(() => _index = value),
              itemCount: _slides.length,
              itemBuilder: (context, index) {
                final slide = _slides[index];
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        Theme.of(context).colorScheme.primaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFDCE6FF)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Étape ${index + 1}/${_slides.length}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            slide.$1,
                            size: 56,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          slide.$2,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.$3,
                          textAlign: TextAlign.center,
                          style: const TextStyle(height: 1.4),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _slides.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _index == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _index == index
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              if (isLast) {
                Navigator.of(context).pushReplacementNamed(AppRoutes.signup);
                return;
              }

              await _controller.nextPage(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
              );
            },
            child: Text(isLast ? 'Commencer' : 'Suivant'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed(AppRoutes.welcome);
            },
            child: const Text('Passer'),
          ),
        ],
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);
    try {
      await AppScope.of(context).login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false);
    } on AuthException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Impossible de se connecter pour le moment');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Connexion',
      subtitle: 'Récupère ton espace REZO en toute sécurité.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _AuthSectionTitle(
              title: 'Connexion rapide',
              subtitle:
                  'Entre ton email et ton mot de passe pour retrouver ton espace.',
            ),
            const SizedBox(height: 12),
            if (_errorMessage != null) ...[
              _InfoBanner(
                message: _errorMessage!,
                color: Colors.red.shade50,
                textColor: Colors.red.shade800,
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Adresse e-mail',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: _validateEmail,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Connexion'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed(AppRoutes.signup);
              },
              child: const Text('Créer un compte'),
            ),
          ],
        ),
      ),
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required this.initialRole});

  final UserRole initialRole;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  late UserRole _selectedRole;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();

  final TextEditingController _niveauEtudeController = TextEditingController();
  final TextEditingController _domaineController = TextEditingController();
  final TextEditingController _competencesController = TextEditingController();
  final TextEditingController _objectifController = TextEditingController();

  final TextEditingController _raisonSocialeController =
      TextEditingController();
  final TextEditingController _secteurController = TextEditingController();
  final TextEditingController _descriptionEntrepriseController =
      TextEditingController();
  final TextEditingController _adresseEntrepriseController =
      TextEditingController();
  final TextEditingController _siteEntrepriseController =
      TextEditingController();
  String _tailleEntreprise = 'PME';

  final TextEditingController _nomEtablissementController =
      TextEditingController();
  final TextEditingController _domainesController = TextEditingController();
  final TextEditingController _diplomesController = TextEditingController();
  final TextEditingController _descriptionEcoleController =
      TextEditingController();
  final TextEditingController _siteEcoleController = TextEditingController();
  String _statutEcole = 'PRIVE';

  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
  }

  @override
  void dispose() {
    for (final controller in [
      _emailController,
      _passwordController,
      _prenomController,
      _nomController,
      _telephoneController,
      _niveauEtudeController,
      _domaineController,
      _competencesController,
      _objectifController,
      _raisonSocialeController,
      _secteurController,
      _descriptionEntrepriseController,
      _adresseEntrepriseController,
      _siteEntrepriseController,
      _nomEtablissementController,
      _domainesController,
      _diplomesController,
      _descriptionEcoleController,
      _siteEcoleController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);
    try {
      await AppScope.of(context).signup(_buildPayload());
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inscription réussie, connecte-toi.')),
      );
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.login,
        arguments: _emailController.text.trim(),
      );
    } on AuthException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Impossible de créer le compte pour le moment');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Map<String, dynamic> _buildPayload() {
    return {
      'email': _emailController.text.trim(),
      'password': _passwordController.text.trim(),
      'role': _selectedRole.apiValue,
      'prenom': _prenomController.text.trim(),
      'nom': _nomController.text.trim(),
      'telephone': _telephoneController.text.trim(),
      'profil': switch (_selectedRole) {
        UserRole.etudiant => {
          'niveauEtude': _niveauEtudeController.text.trim(),
          'domaine': _domaineController.text.trim(),
          if (_splitList(_competencesController.text).isNotEmpty)
            'competences': _splitList(_competencesController.text),
          if (_objectifController.text.trim().isNotEmpty)
            'objectif': _objectifController.text.trim(),
        },
        UserRole.entreprise => {
          'raisonSociale': _raisonSocialeController.text.trim(),
          'secteurActivite': _secteurController.text.trim(),
          'taille': _tailleEntreprise,
          'description': _descriptionEntrepriseController.text.trim(),
          if (_adresseEntrepriseController.text.trim().isNotEmpty)
            'adresse': _adresseEntrepriseController.text.trim(),
          if (_siteEntrepriseController.text.trim().isNotEmpty)
            'siteWeb': _siteEntrepriseController.text.trim(),
        },
        UserRole.ecole => {
          'nomEtablissement': _nomEtablissementController.text.trim(),
          'statut': _statutEcole,
          if (_splitList(_domainesController.text).isNotEmpty)
            'domaines': _splitList(_domainesController.text),
          if (_splitList(_diplomesController.text).isNotEmpty)
            'diplomesDelivres': _splitList(_diplomesController.text),
          if (_descriptionEcoleController.text.trim().isNotEmpty)
            'description': _descriptionEcoleController.text.trim(),
          if (_siteEcoleController.text.trim().isNotEmpty)
            'siteWeb': _siteEcoleController.text.trim(),
        },
      },
    };
  }

  List<String> _splitList(String value) {
    return value
        .split(',')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Créer un compte',
      subtitle: 'Choisis ton rôle puis complète le formulaire adapté.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _AuthSectionTitle(
              title: 'Choisis ton espace',
              subtitle: 'Sélectionne ton rôle pour afficher le bon formulaire.',
            ),
            const SizedBox(height: 12),
            if (_errorMessage != null) ...[
              _InfoBanner(
                message: _errorMessage!,
                color: Colors.red.shade50,
                textColor: Colors.red.shade800,
              ),
              const SizedBox(height: 12),
            ],
            _RoleSelector(
              selectedRole: _selectedRole,
              onChanged: (value) {
                setState(() => _selectedRole = value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _prenomController,
              decoration: const InputDecoration(labelText: 'Prénom contact'),
              validator: (value) => _requiredField(value, 'Le prénom'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(labelText: 'Nom contact'),
              validator: (value) => _requiredField(value, 'Le nom'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telephoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Téléphone'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Adresse e-mail'),
              validator: _validateEmail,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mot de passe'),
              validator: _validatePassword,
            ),
            const SizedBox(height: 16),
            _RoleBenefitCard(role: _selectedRole),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildRoleSpecificSection(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Créer mon compte'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed(AppRoutes.login);
              },
              child: const Text('J’ai déjà un compte'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSpecificSection() {
    switch (_selectedRole) {
      case UserRole.etudiant:
        return Column(
          key: const ValueKey('student-section'),
          children: [
            TextFormField(
              controller: _niveauEtudeController,
              decoration: const InputDecoration(labelText: 'Niveau d’étude'),
              validator: (value) => _requiredField(value, 'Le niveau d’étude'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _domaineController,
              decoration: const InputDecoration(labelText: 'Domaine'),
              validator: (value) => _requiredField(value, 'Le domaine'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _competencesController,
              decoration: const InputDecoration(
                labelText: 'Compétences (séparées par des virgules)',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _objectifController,
              decoration: const InputDecoration(labelText: 'Objectif'),
              maxLines: 2,
            ),
          ],
        );
      case UserRole.entreprise:
        return Column(
          key: const ValueKey('company-section'),
          children: [
            TextFormField(
              controller: _raisonSocialeController,
              decoration: const InputDecoration(labelText: 'Nom entreprise'),
              validator: (value) => _requiredField(value, 'Le nom entreprise'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _secteurController,
              decoration: const InputDecoration(labelText: 'Secteur'),
              validator: (value) => _requiredField(value, 'Le secteur'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _tailleEntreprise,
              decoration: const InputDecoration(labelText: 'Taille'),
              items: const [
                DropdownMenuItem(value: 'MICRO', child: Text('MICRO')),
                DropdownMenuItem(value: 'PME', child: Text('PME')),
                DropdownMenuItem(value: 'ETI', child: Text('ETI')),
                DropdownMenuItem(value: 'GE', child: Text('GE')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _tailleEntreprise = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionEntrepriseController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
              validator: (value) => _requiredField(value, 'La description'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _adresseEntrepriseController,
              decoration: const InputDecoration(labelText: 'Adresse'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _siteEntrepriseController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'Site web'),
              validator: _optionalUrlValidator,
            ),
          ],
        );
      case UserRole.ecole:
        return Column(
          key: const ValueKey('school-section'),
          children: [
            TextFormField(
              controller: _nomEtablissementController,
              decoration: const InputDecoration(labelText: 'Nom établissement'),
              validator: (value) =>
                  _requiredField(value, 'Le nom établissement'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _statutEcole,
              decoration: const InputDecoration(labelText: 'Statut'),
              items: const [
                DropdownMenuItem(value: 'PUBLIC', child: Text('PUBLIC')),
                DropdownMenuItem(value: 'PRIVE', child: Text('PRIVE')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _statutEcole = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _domainesController,
              decoration: const InputDecoration(
                labelText: 'Domaines (séparés par des virgules)',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _diplomesController,
              decoration: const InputDecoration(
                labelText: 'Diplômes délivrés (séparés par des virgules)',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionEcoleController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _siteEcoleController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'Site web'),
              validator: _optionalUrlValidator,
            ),
          ],
        );
    }
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final user = appState.currentUser ?? <String, dynamic>{};
    final role = parseUserRole(user['role'] as String?);
    final fullName = [
      user['prenom'],
      user['nom'],
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' ');

    final tabs = <Widget>[
      _HomeTab(user: user, role: role, fullName: fullName),
      const _MessagesTab(),
      const _MatchesTab(),
      _ProfileTab(
        onLogout: () async {
          await appState.logout();
          if (!context.mounted) return;
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.welcome, (route) => false);
        },
      ),
    ];

    final titles = <String>[
      'Dashboard ${role.apiValue}',
      'Messages',
      'Matching',
      'Profil',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        actions: [
          if (_currentIndex != 3)
            IconButton(
              tooltip: 'Mon profil',
              onPressed: () => setState(() => _currentIndex = 3),
              icon: const Icon(Icons.account_circle_rounded),
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: tabs[_currentIndex],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum_rounded),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.swipe_outlined),
            selectedIcon: Icon(Icons.swipe_rounded),
            label: 'Matching',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.user,
    required this.role,
    required this.fullName,
  });

  final Map<String, dynamic> user;
  final UserRole role;
  final String fullName;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDDE7FF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: Icon(
                      role.icon,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName.isEmpty
                              ? 'Bienvenue'
                              : 'Bienvenue $fullName',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(user['email']?.toString() ?? 'Compte connecté'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _InfoBanner(
                message: switch (role) {
                  UserRole.etudiant =>
                    'Explore des opportunités, complète ton profil et lance tes premiers matchs.',
                  UserRole.entreprise =>
                    'Publie une offre, qualifie des candidats et démarre des conversations utiles.',
                  UserRole.ecole =>
                    'Mets en avant tes formations et attire les bons profils.',
                },
                color: Colors.white,
                textColor: Theme.of(context).colorScheme.onSurface,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Fonctionnalités disponibles',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        const _ChecklistTile(label: 'Accueil et onboarding'),
        const _ChecklistTile(label: 'Signup multi-profils dynamique'),
        const _ChecklistTile(label: 'Login avec gestion des erreurs'),
        const _ChecklistTile(label: 'JWT stocké et session restaurée'),
        const _ChecklistTile(
          label: 'Feedback utilisateur et validation locale',
        ),
      ],
    );
  }
}

class _MessagesTab extends StatelessWidget {
  const _MessagesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        _FeaturePlaceholderCard(
          title: 'Messagerie REZO',
          subtitle: 'Tes conversations apparaîtront ici dès le premier match.',
          icon: Icons.forum_rounded,
          accent: Color(0xFFE8F0FF),
        ),
      ],
    );
  }
}

class _MatchesTab extends StatelessWidget {
  const _MatchesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        _FeaturePlaceholderCard(
          title: 'Zone de matching',
          subtitle: 'Les suggestions personnalisées seront proposées ici.',
          icon: Icons.swipe_rounded,
          accent: Color(0xFFFFF2E1),
        ),
      ],
    );
  }
}

class _ProfileTab extends StatefulWidget {
  const _ProfileTab({required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  bool _loading = false;
  bool _saving = false;
  String? _error;

  List<Map<String, dynamic>> _packs = const [];
  List<Map<String, dynamic>> _messages = const [];
  List<Map<String, dynamic>> _offers = const [];
  List<Map<String, dynamic>> _mediaFiles = const [];
  bool _loadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedOnce) {
      _loadedOnce = true;
      unawaited(_loadProfileData());
    }
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final appState = AppScope.of(context);
      await appState.refreshCurrentUser();
      final results = await Future.wait([
        appState.fetchPacks(),
        appState.fetchMessages(),
        appState.fetchOffers(),
        appState.fetchMyMedia(),
      ]);

      if (!mounted) return;
      setState(() {
        _packs = results[0];
        _messages = results[1];
        _offers = results[2];
        _mediaFiles = results[3];
      });
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
      if (error.statusCode == 401) {
        _showSnack('Session expirée, reconnecte-toi');
        await widget.onLogout();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Impossible de charger le profil');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openEditProfile() async {
    final appState = AppScope.of(context);
    final user = Map<String, dynamic>.from(appState.currentUser ?? const {});
    final updated = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EditProfileSheet(initialUser: user),
    );

    if (updated == null || updated.isEmpty) {
      return;
    }

    setState(() => _saving = true);
    try {
      await appState.updateProfile(updated);
      await _loadProfileData();
      _showSnack('Profil mis à jour');
    } on AuthException catch (error) {
      _showSnack(error.message);
      if (error.statusCode == 401) {
        await widget.onLogout();
      }
    } catch (_) {
      _showSnack('Erreur lors de la sauvegarde du profil');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _openPackSelector() async {
    if (_packs.isEmpty) {
      _showSnack('Aucun pack disponible pour le moment');
      return;
    }

    final selectedPackId = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Choisir un pack',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ..._packs.map((pack) {
              final id = pack['id']?.toString() ?? pack['packId']?.toString();
              if (id == null) {
                return const SizedBox.shrink();
              }
              return Card(
                child: ListTile(
                  title: Text(
                    pack['nom']?.toString() ??
                        pack['name']?.toString() ??
                        'Pack',
                  ),
                  subtitle: Text(
                    pack['description']?.toString() ?? 'Sélectionner ce pack',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).pop(id),
                ),
              );
            }),
          ],
        );
      },
    );

    if (selectedPackId == null) {
      return;
    }
    if (!mounted) {
      return;
    }

    setState(() => _saving = true);
    try {
      await AppScope.of(context).changePack(selectedPackId);
      await _loadProfileData();
      _showSnack('Pack mis à jour');
    } on AuthException catch (error) {
      _showSnack(error.message);
      if (error.statusCode == 401) {
        await widget.onLogout();
      }
    } catch (_) {
      _showSnack('Impossible de changer le pack');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _uploadProfilePhoto() async {
    final picked = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'gif'],
    );

    if (picked == null || picked.files.isEmpty) {
      return;
    }
    if (!mounted) {
      return;
    }

    final file = picked.files.single;
    final bytes = file.bytes;
    final fileName = file.name;
    final maxSize = 8 * 1024 * 1024;

    if (bytes == null || bytes.isEmpty) {
      _showSnack('Impossible de lire le fichier image');
      return;
    }
    if (!_isSupportedImage(fileName)) {
      _showSnack('Format image non supporté (jpeg, png, webp, gif)');
      return;
    }
    if (bytes.length > maxSize) {
      _showSnack('L\'image dépasse la taille maximale autorisée (8MB)');
      return;
    }

    setState(() => _saving = true);
    try {
      final appState = AppScope.of(context);
      final media = await appState.uploadProfilePhoto(
        bytes: bytes,
        fileName: fileName,
      );
      final avatarUrl = media['fileUrl']?.toString();
      if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
        await appState.updateProfile({'avatarUrl': avatarUrl});
      }
      await _loadProfileData();
      _showSnack('Photo de profil mise à jour');
    } on AuthException catch (error) {
      _showSnack(error.message);
      if (error.statusCode == 401) {
        await widget.onLogout();
      }
    } catch (_) {
      _showSnack('Erreur lors de l\'upload de la photo');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _uploadJustificatif() async {
    final picked = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );

    if (picked == null || picked.files.isEmpty) {
      return;
    }
    if (!mounted) {
      return;
    }

    final file = picked.files.single;
    final bytes = file.bytes;
    final fileName = file.name;
    final maxSize = 12 * 1024 * 1024;

    if (bytes == null || bytes.isEmpty) {
      _showSnack('Impossible de lire le fichier PDF');
      return;
    }
    if (!_isPdf(fileName)) {
      _showSnack(
        'Seuls les fichiers PDF sont autorisés pour les justificatifs',
      );
      return;
    }
    if (bytes.length > maxSize) {
      _showSnack('Le PDF dépasse la taille maximale autorisée (12MB)');
      return;
    }

    setState(() => _saving = true);
    try {
      await AppScope.of(
        context,
      ).uploadJustificatifPdf(bytes: bytes, fileName: fileName);
      await _loadProfileData();
      _showSnack('Justificatif ajouté');
    } on AuthException catch (error) {
      _showSnack(error.message);
      if (error.statusCode == 401) {
        await widget.onLogout();
      }
    } catch (_) {
      _showSnack('Erreur lors de l\'upload du justificatif');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _deleteMedia(String mediaId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer ce justificatif ?'),
          content: const Text('Cette action est irréversible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }
    if (!mounted) {
      return;
    }

    setState(() => _saving = true);
    try {
      await AppScope.of(context).deleteMyMedia(mediaId);
      await _loadProfileData();
      _showSnack('Justificatif supprimé');
    } on AuthException catch (error) {
      _showSnack(error.message);
      if (error.statusCode == 401) {
        await widget.onLogout();
      }
    } catch (_) {
      _showSnack('Suppression impossible');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  bool _isSupportedImage(String fileName) {
    final lower = fileName.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');
  }

  bool _isPdf(String fileName) => fileName.toLowerCase().endsWith('.pdf');

  String _toAbsoluteMediaUrl(String? fileUrl) {
    final raw = fileUrl?.trim() ?? '';
    if (raw.isEmpty) {
      return '';
    }
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    return '${HttpAuthService.defaultBaseUrl}$raw';
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final user = appState.currentUser ?? const <String, dynamic>{};
    final profile =
        (user['profil'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    final fullName = [
      user['prenom'],
      user['nom'],
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' ');

    final role = parseUserRole(user['role'] as String?);
    final packName = user['packNom']?.toString() ?? 'FREE';
    final avatarUrl = _toAbsoluteMediaUrl(user['avatarUrl']?.toString());
    final packFeatures =
        (user['packFeatures'] as List?)
            ?.map((item) => item.toString())
            .toList() ??
        const <String>[];
    final justificatifs =
        _mediaFiles
            .where(
              (entry) =>
                  entry['category']?.toString().toUpperCase() ==
                  'JUSTIFICATIF_PDF',
            )
            .toList()
          ..sort((a, b) {
            final left = a['createdAt']?.toString() ?? '';
            final right = b['createdAt']?.toString() ?? '';
            return right.compareTo(left);
          });

    final canManageOffers = user['canManageOffers'] == true;
    final userId = user['id']?.toString();
    final ownedOffers = canManageOffers && userId != null
        ? _offers
              .where(
                (offer) =>
                    offer['ownerUserId']?.toString() == userId ||
                    offer['userId']?.toString() == userId,
              )
              .toList()
        : const <Map<String, dynamic>>[];

    return RefreshIndicator(
      onRefresh: _loadProfileData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (_error != null) ...[
            _InfoBanner(
              message: _error!,
              color: Colors.red.shade50,
              textColor: Colors.red.shade800,
            ),
            const SizedBox(height: 12),
          ],
          _ProfileHeaderCard(
            avatarUrl: avatarUrl,
            fullName: fullName.isEmpty ? 'Mon profil' : fullName,
            email: user['email']?.toString() ?? 'Aucune adresse email',
            roleLabel: role.label,
            packName: packName,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _openEditProfile,
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Modifier le profil'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _openPackSelector,
                  icon: const Icon(Icons.workspace_premium_rounded),
                  label: const Text('Changer de pack'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ProfileSectionCard(
            title: 'Compétences et objectifs',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ChipWrap(
                  items:
                      (profile['competences'] as List?)
                          ?.map((entry) => entry.toString())
                          .toList() ??
                      const [],
                  emptyLabel: 'Aucune compétence renseignée',
                ),
                const SizedBox(height: 10),
                Text(
                  profile['objectif']?.toString() ?? 'Aucun objectif défini',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ProfileSectionCard(
            title: 'Préférences',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Secteurs'),
                const SizedBox(height: 6),
                _ChipWrap(
                  items:
                      (profile['preferencesSecteur'] as List?)
                          ?.map((entry) => entry.toString())
                          .toList() ??
                      const [],
                  emptyLabel: 'Aucune préférence secteur',
                ),
                const SizedBox(height: 10),
                const Text('Lieux'),
                const SizedBox(height: 6),
                _ChipWrap(
                  items:
                      (profile['preferencesLieu'] as List?)
                          ?.map((entry) => entry.toString())
                          .toList() ??
                      const [],
                  emptyLabel: 'Aucune préférence lieu',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ProfileSectionCard(
            title: 'Pack actuel',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  packName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                _ChipWrap(
                  items: packFeatures,
                  emptyLabel: 'Aucune feature déclarée',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ProfileSectionCard(
            title: 'Photo et justificatifs',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _uploadProfilePhoto,
                        icon: const Icon(Icons.add_a_photo_rounded),
                        label: const Text('Photo de profil'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _uploadJustificatif,
                        icon: const Icon(Icons.picture_as_pdf_rounded),
                        label: const Text('Justificatif PDF'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (justificatifs.isEmpty)
                  Text(
                    'Aucun justificatif ajouté',
                    style: TextStyle(color: Colors.grey.shade700),
                  )
                else
                  Column(
                    children: justificatifs.map((media) {
                      final mediaId = media['id']?.toString();
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.description_rounded),
                        title: Text(
                          media['originalFileName']?.toString() ??
                              'Justificatif',
                        ),
                        subtitle: Text(
                          media['createdAt']?.toString() ?? 'Date inconnue',
                        ),
                        trailing: mediaId == null
                            ? null
                            : IconButton(
                                onPressed: _saving
                                    ? null
                                    : () => _deleteMedia(mediaId),
                                icon: const Icon(Icons.delete_outline_rounded),
                              ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ProfileSectionCard(
            title: 'Historique messages',
            child: _SimpleHistoryList(
              entries: _messages,
              titleKey: 'content',
              fallbackTitle: 'Message',
              subtitleBuilder: (entry) =>
                  entry['createdAt']?.toString() ?? 'Date inconnue',
              emptyLabel: 'Aucun message récent',
            ),
          ),
          if (canManageOffers) ...[
            const SizedBox(height: 12),
            _ProfileSectionCard(
              title: 'Historique offres publiées',
              child: _SimpleHistoryList(
                entries: ownedOffers,
                titleKey: 'titre',
                fallbackTitle: 'Offre',
                subtitleBuilder: (entry) =>
                    entry['datePublication']?.toString() ??
                    entry['createdAt']?.toString() ??
                    'Date inconnue',
                emptyLabel: 'Aucune offre publiée',
              ),
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _saving
                ? null
                : () async {
                    await widget.onLogout();
                  },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.avatarUrl,
    required this.fullName,
    required this.email,
    required this.roleLabel,
    required this.packName,
  });

  final String? avatarUrl;
  final String fullName;
  final String email;
  final String roleLabel;
  final String packName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE7FF)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                ? NetworkImage(avatarUrl!)
                : null,
            child: avatarUrl == null || avatarUrl!.isEmpty
                ? const Icon(Icons.person_rounded)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 2),
                Text(email),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TagPill(label: roleLabel),
                    _TagPill(label: 'Pack $packName'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSectionCard extends StatelessWidget {
  const _ProfileSectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3EAFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({required this.items, required this.emptyLabel});

  final List<String> items;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(emptyLabel, style: TextStyle(color: Colors.grey.shade700));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) => _TagPill(label: item)).toList(),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD8E4FF)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _SimpleHistoryList extends StatelessWidget {
  const _SimpleHistoryList({
    required this.entries,
    required this.titleKey,
    required this.fallbackTitle,
    required this.subtitleBuilder,
    required this.emptyLabel,
  });

  final List<Map<String, dynamic>> entries;
  final String titleKey;
  final String fallbackTitle;
  final String Function(Map<String, dynamic>) subtitleBuilder;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Text(emptyLabel, style: TextStyle(color: Colors.grey.shade700));
    }

    return Column(
      children: entries.take(5).map((entry) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.history_rounded),
          title: Text(entry[titleKey]?.toString() ?? fallbackTitle),
          subtitle: Text(subtitleBuilder(entry)),
        );
      }).toList(),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.initialUser});

  final Map<String, dynamic> initialUser;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _prenomController;
  late final TextEditingController _nomController;
  late final TextEditingController _emailController;
  late final TextEditingController _telephoneController;
  late final TextEditingController _avatarController;
  late final TextEditingController _niveauController;
  late final TextEditingController _domaineController;
  late final TextEditingController _competencesController;
  late final TextEditingController _objectifController;
  late final TextEditingController _preferencesSecteurController;
  late final TextEditingController _preferencesLieuController;
  late final TextEditingController _raisonSocialeController;
  late final TextEditingController _secteurActiviteController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _siteWebController;
  late final TextEditingController _nomEtablissementController;

  String _taille = 'PME';
  String _statut = 'PRIVE';

  @override
  void initState() {
    super.initState();
    final profile =
        (widget.initialUser['profil'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    _prenomController = TextEditingController(
      text: widget.initialUser['prenom']?.toString() ?? '',
    );
    _nomController = TextEditingController(
      text: widget.initialUser['nom']?.toString() ?? '',
    );
    _emailController = TextEditingController(
      text: widget.initialUser['email']?.toString() ?? '',
    );
    _telephoneController = TextEditingController(
      text: widget.initialUser['telephone']?.toString() ?? '',
    );
    _avatarController = TextEditingController(
      text: widget.initialUser['avatarUrl']?.toString() ?? '',
    );

    _niveauController = TextEditingController(
      text: profile['niveauEtude']?.toString() ?? '',
    );
    _domaineController = TextEditingController(
      text: profile['domaine']?.toString() ?? '',
    );
    _competencesController = TextEditingController(
      text: (profile['competences'] as List?)?.join(', ') ?? '',
    );
    _objectifController = TextEditingController(
      text: profile['objectif']?.toString() ?? '',
    );
    _preferencesSecteurController = TextEditingController(
      text: (profile['preferencesSecteur'] as List?)?.join(', ') ?? '',
    );
    _preferencesLieuController = TextEditingController(
      text: (profile['preferencesLieu'] as List?)?.join(', ') ?? '',
    );

    _raisonSocialeController = TextEditingController(
      text: profile['raisonSociale']?.toString() ?? '',
    );
    _secteurActiviteController = TextEditingController(
      text: profile['secteurActivite']?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: profile['description']?.toString() ?? '',
    );
    _siteWebController = TextEditingController(
      text: profile['siteWeb']?.toString() ?? '',
    );
    _nomEtablissementController = TextEditingController(
      text: profile['nomEtablissement']?.toString() ?? '',
    );

    _taille = profile['taille']?.toString() ?? 'PME';
    _statut = profile['statut']?.toString() ?? 'PRIVE';
  }

  @override
  void dispose() {
    for (final controller in [
      _prenomController,
      _nomController,
      _emailController,
      _telephoneController,
      _avatarController,
      _niveauController,
      _domaineController,
      _competencesController,
      _objectifController,
      _preferencesSecteurController,
      _preferencesLieuController,
      _raisonSocialeController,
      _secteurActiviteController,
      _descriptionController,
      _siteWebController,
      _nomEtablissementController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = parseUserRole(widget.initialUser['role']?.toString());

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            const Text(
              'Modifier le profil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _prenomController,
              decoration: const InputDecoration(labelText: 'Prénom'),
              validator: (v) => _requiredField(v, 'Le prénom'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(labelText: 'Nom'),
              validator: (v) => _requiredField(v, 'Le nom'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Adresse e-mail'),
              validator: _validateEmail,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _telephoneController,
              decoration: const InputDecoration(labelText: 'Téléphone'),
              validator: _optionalPhoneValidator,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _avatarController,
              decoration: const InputDecoration(labelText: 'URL avatar'),
              validator: _optionalUrlValidator,
            ),
            const SizedBox(height: 14),
            ...switch (role) {
              UserRole.etudiant => _buildStudentFields(),
              UserRole.entreprise => _buildCompanyFields(),
              UserRole.ecole => _buildSchoolFields(),
            },
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) {
                  return;
                }
                Navigator.of(context).pop(_buildPayload(role));
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStudentFields() {
    return [
      TextFormField(
        controller: _niveauController,
        decoration: const InputDecoration(labelText: 'Niveau d’étude'),
        validator: (v) => _requiredField(v, 'Le niveau d’étude'),
      ),
      const SizedBox(height: 10),
      TextFormField(
        controller: _domaineController,
        decoration: const InputDecoration(labelText: 'Domaine'),
        validator: (v) => _requiredField(v, 'Le domaine'),
      ),
      const SizedBox(height: 10),
      TextFormField(
        controller: _competencesController,
        decoration: const InputDecoration(labelText: 'Compétences (csv)'),
        validator: _optionalCsvValidator,
      ),
      const SizedBox(height: 10),
      TextFormField(
        controller: _objectifController,
        decoration: const InputDecoration(labelText: 'Objectif'),
      ),
      const SizedBox(height: 10),
      TextFormField(
        controller: _preferencesSecteurController,
        decoration: const InputDecoration(
          labelText: 'Préférences secteur (csv)',
        ),
        validator: _optionalCsvValidator,
      ),
      const SizedBox(height: 10),
      TextFormField(
        controller: _preferencesLieuController,
        decoration: const InputDecoration(labelText: 'Préférences lieu (csv)'),
        validator: _optionalCsvValidator,
      ),
    ];
  }

  List<Widget> _buildCompanyFields() {
    return [
      TextFormField(
        controller: _raisonSocialeController,
        decoration: const InputDecoration(labelText: 'Raison sociale'),
        validator: (v) => _requiredField(v, 'La raison sociale'),
      ),
      const SizedBox(height: 10),
      TextFormField(
        controller: _secteurActiviteController,
        decoration: const InputDecoration(labelText: 'Secteur d’activité'),
        validator: (v) => _requiredField(v, 'Le secteur'),
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        initialValue: _taille,
        decoration: const InputDecoration(labelText: 'Taille'),
        items: const [
          DropdownMenuItem(value: 'MICRO', child: Text('MICRO')),
          DropdownMenuItem(value: 'PME', child: Text('PME')),
          DropdownMenuItem(value: 'ETI', child: Text('ETI')),
          DropdownMenuItem(value: 'GE', child: Text('GE')),
        ],
        onChanged: (value) => setState(() => _taille = value ?? 'PME'),
      ),
      const SizedBox(height: 10),
      TextFormField(
        controller: _descriptionController,
        decoration: const InputDecoration(labelText: 'Description'),
        validator: (v) => _requiredField(v, 'La description'),
      ),
      const SizedBox(height: 10),
      TextFormField(
        controller: _siteWebController,
        decoration: const InputDecoration(labelText: 'Site web'),
        validator: _optionalUrlValidator,
      ),
    ];
  }

  List<Widget> _buildSchoolFields() {
    return [
      TextFormField(
        controller: _nomEtablissementController,
        decoration: const InputDecoration(labelText: 'Nom établissement'),
        validator: (v) => _requiredField(v, 'Le nom établissement'),
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        initialValue: _statut,
        decoration: const InputDecoration(labelText: 'Statut'),
        items: const [
          DropdownMenuItem(value: 'PUBLIC', child: Text('PUBLIC')),
          DropdownMenuItem(value: 'PRIVE', child: Text('PRIVE')),
        ],
        onChanged: (value) => setState(() => _statut = value ?? 'PRIVE'),
      ),
      const SizedBox(height: 10),
      TextFormField(
        controller: _descriptionController,
        decoration: const InputDecoration(labelText: 'Description'),
      ),
      const SizedBox(height: 10),
      TextFormField(
        controller: _siteWebController,
        decoration: const InputDecoration(labelText: 'Site web'),
        validator: _optionalUrlValidator,
      ),
    ];
  }

  Map<String, dynamic> _buildPayload(UserRole role) {
    final payload = <String, dynamic>{
      'prenom': _prenomController.text.trim(),
      'nom': _nomController.text.trim(),
      'email': _emailController.text.trim(),
      'telephone': _telephoneController.text.trim(),
      'avatarUrl': _avatarController.text.trim(),
      'profil': switch (role) {
        UserRole.etudiant => {
          'niveauEtude': _niveauController.text.trim(),
          'domaine': _domaineController.text.trim(),
          'competences': _csvToList(_competencesController.text),
          'objectif': _objectifController.text.trim(),
          'preferencesSecteur': _csvToList(_preferencesSecteurController.text),
          'preferencesLieu': _csvToList(_preferencesLieuController.text),
        },
        UserRole.entreprise => {
          'raisonSociale': _raisonSocialeController.text.trim(),
          'secteurActivite': _secteurActiviteController.text.trim(),
          'taille': _taille,
          'description': _descriptionController.text.trim(),
          'siteWeb': _siteWebController.text.trim(),
        },
        UserRole.ecole => {
          'nomEtablissement': _nomEtablissementController.text.trim(),
          'statut': _statut,
          'description': _descriptionController.text.trim(),
          'siteWeb': _siteWebController.text.trim(),
        },
      },
    };

    payload.removeWhere((key, value) {
      if (value is String) {
        return value.trim().isEmpty;
      }
      return false;
    });

    final profile =
        (payload['profil'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    profile.removeWhere((key, value) {
      if (value is String) {
        return value.trim().isEmpty;
      }
      if (value is List) {
        return value.isEmpty;
      }
      return false;
    });

    payload['profil'] = profile;
    return payload;
  }

  List<String> _csvToList(String value) {
    return value
        .split(',')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
  }
}

class _FeaturePlaceholderCard extends StatelessWidget {
  const _FeaturePlaceholderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EAFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RezoLogo extends StatelessWidget {
  const RezoLogo({super.key, this.height = 96, this.withBackground = true});

  final double height;
  final bool withBackground;

  @override
  Widget build(BuildContext context) {
    final content = Image.asset(
      'assets/REZO_Logo.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.hub_rounded,
        size: height * 0.55,
        color: Theme.of(context).colorScheme.primary,
      ),
    );

    if (!withBackground) {
      return content;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: content,
    );
  }
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF2F6FF), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: -60,
            right: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF2260FF).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 110,
            left: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF7B8CFF).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (canPop)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE3EAFF)),
                          ),
                          child: IconButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 8),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.86),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE3EAFF)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(subtitle, style: const TextStyle(height: 1.35)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthSectionTitle extends StatelessWidget {
  const _AuthSectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade700, height: 1.3),
        ),
      ],
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  const _HeroStatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE1E9FF)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.selectedRole, required this.onChanged});

  final UserRole selectedRole;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Vous êtes', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: UserRole.values.map((role) {
            final isSelected = role == selectedRole;
            return ChoiceChip(
              selected: isSelected,
              showCheckmark: false,
              avatar: Icon(
                role.icon,
                size: 18,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.primary,
              ),
              label: Text(role.label),
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: Colors.white,
              selectedColor: Theme.of(context).colorScheme.primary,
              side: const BorderSide(color: Color(0xFFD7E3FF)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              onSelected: (_) => onChanged(role),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _RoleBenefitCard extends StatelessWidget {
  const _RoleBenefitCard({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.secondaryContainer,
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE6FF)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              role.icon,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(role.benefit, style: const TextStyle(height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.check_circle_rounded, color: Colors.green),
      title: Text(label),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.message,
    required this.color,
    required this.textColor,
  });

  final String message;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: TextStyle(color: textColor)),
    );
  }
}

String? _validateEmail(String? value) {
  final email = value?.trim() ?? '';
  final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!regex.hasMatch(email)) {
    return 'Veuillez renseigner un email valide';
  }
  return null;
}

String? _validatePassword(String? value) {
  final password = value?.trim() ?? '';
  if (password.length < 8) {
    return '8 caractères minimum';
  }
  return null;
}

String? _requiredField(String? value, String label) {
  if ((value ?? '').trim().isEmpty) {
    return '$label est obligatoire';
  }
  return null;
}

String? _optionalUrlValidator(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(text);
  if (uri == null || !uri.hasScheme) {
    return 'URL invalide';
  }
  return null;
}

String? _optionalPhoneValidator(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return null;
  }

  final regex = RegExp(r'^[+0-9 ]{7,20}$');
  if (!regex.hasMatch(text)) {
    return 'Numéro de téléphone invalide';
  }
  return null;
}

String? _optionalCsvValidator(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return null;
  }

  final items = text
      .split(',')
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList();

  if (items.isEmpty) {
    return 'Format CSV invalide';
  }

  if (items.toSet().length != items.length) {
    return 'Évite les doublons dans la liste';
  }

  final hasShortEntry = items.any((entry) => entry.length < 2);
  if (hasShortEntry) {
    return 'Chaque valeur doit contenir au moins 2 caractères';
  }
  return null;
}

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
  Future<Map<String, dynamic>> authorizedGet(String path) {
    return getMe();
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
