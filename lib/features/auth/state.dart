part of 'auth_flow.dart';

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
