import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rezo/features/auth/auth_flow.dart';
import 'package:rezo/main.dart';

void main() {
  group('Auth tunnel UX', () {
    testWidgets('welcome screen exposes onboarding and auth CTAs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MyApp(
          authService: FakeAuthService(),
          tokenStorage: MemoryTokenStorage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Votre avenir en un swipe'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);
      expect(find.text('Créer un compte'), findsOneWidget);
    });

    testWidgets('signup validation shows feedback for invalid fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignupScreen(initialRole: UserRole.etudiant),
        ),
      );
      await tester.pumpAndSettle();

      final formState = tester.state<FormState>(find.byType(Form).first);
      expect(formState.validate(), isFalse);
      await tester.pump();

      expect(find.text('Veuillez renseigner un email valide'), findsOneWidget);
      expect(find.text('8 caractères minimum'), findsOneWidget);
    });

    testWidgets('login success stores token and redirects to dashboard', (
      WidgetTester tester,
    ) async {
      final storage = MemoryTokenStorage();

      await tester.pumpWidget(
        MyApp(authService: FakeAuthService(), tokenStorage: storage),
      );
      await tester.pumpAndSettle();

      final loginCta = find.widgetWithText(ElevatedButton, 'Se connecter');
      await tester.ensureVisible(loginCta);
      await tester.tap(loginCta, warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Adresse e-mail'),
        'awa@rezo.sn',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe'),
        'SecurePass123!',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Connexion'));
      await tester.pumpAndSettle();

      expect(await storage.readToken(), equals('fake-jwt-token'));
      expect(find.textContaining('Dashboard'), findsOneWidget);
      expect(find.textContaining('ETUDIANT'), findsOneWidget);
    });

    testWidgets('session persisted opens dashboard on app launch', (
      WidgetTester tester,
    ) async {
      final storage = MemoryTokenStorage();
      await storage.saveToken('persisted-jwt');

      await tester.pumpWidget(
        MyApp(authService: FakeAuthService(), tokenStorage: storage),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Dashboard'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('dashboard route is protected when user is not authenticated', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MyApp(
          authService: FakeAuthService(),
          tokenStorage: MemoryTokenStorage(),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(WelcomeScreen));
      Navigator.of(context).pushNamed(AppRoutes.dashboard);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Connexion'), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);
    });

    testWidgets('profile edit updates visible data immediately', (
      WidgetTester tester,
    ) async {
      final storage = MemoryTokenStorage();

      await tester.pumpWidget(
        MyApp(authService: FakeAuthService(), tokenStorage: storage),
      );
      await tester.pumpAndSettle();

      final loginCta = find.widgetWithText(ElevatedButton, 'Se connecter');
      await tester.ensureVisible(loginCta);
      await tester.tap(loginCta, warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Adresse e-mail'),
        'awa@rezo.sn',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe'),
        'SecurePass123!',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connexion'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();

      final dashboardContext = tester.element(find.byType(DashboardScreen));
      await AppScope.of(dashboardContext).updateProfile({'prenom': 'Nina'});
      await tester.pumpAndSettle();

      expect(find.textContaining('Nina'), findsWidgets);
    });

    testWidgets('changing pack updates current pack badge', (
      WidgetTester tester,
    ) async {
      final storage = MemoryTokenStorage();

      await tester.pumpWidget(
        MyApp(authService: FakeAuthService(), tokenStorage: storage),
      );
      await tester.pumpAndSettle();

      final loginCta = find.widgetWithText(ElevatedButton, 'Se connecter');
      await tester.ensureVisible(loginCta);
      await tester.tap(loginCta, warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Adresse e-mail'),
        'awa@rezo.sn',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe'),
        'SecurePass123!',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connexion'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();

      final dashboardContext = tester.element(find.byType(DashboardScreen));
      await AppScope.of(dashboardContext).changePack('pack-pro');
      await tester.pumpAndSettle();

      expect(find.textContaining('Pack PRO'), findsOneWidget);
    });

    testWidgets('profile edit blocks invalid phone format', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MyApp(
          authService: FakeAuthService(),
          tokenStorage: MemoryTokenStorage(),
        ),
      );
      await tester.pumpAndSettle();

      final loginCta = find.widgetWithText(ElevatedButton, 'Se connecter');
      await tester.ensureVisible(loginCta);
      await tester.tap(loginCta, warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Adresse e-mail'),
        'awa@rezo.sn',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe'),
        'SecurePass123!',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connexion'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.account_circle_rounded));
      await tester.pumpAndSettle();

      final editCta = find.widgetWithText(ElevatedButton, 'Modifier le profil');
      await tester.ensureVisible(editCta);
      await tester.tap(editCta, warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Téléphone'),
        '12',
      );
      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isFalse);
      await tester.pump();

      expect(find.text('Numéro de téléphone invalide'), findsOneWidget);
    });

    testWidgets('matching tab shows suggestions and reacts to swipe actions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MyApp(
          authService: FakeAuthService(),
          tokenStorage: MemoryTokenStorage(),
        ),
      );
      await tester.pumpAndSettle();

      final loginCta = find.widgetWithText(ElevatedButton, 'Se connecter');
      await tester.ensureVisible(loginCta);
      await tester.tap(loginCta, warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Adresse e-mail'),
        'awa@rezo.sn',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe'),
        'SecurePass123!',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connexion'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Matching'));
      await tester.pumpAndSettle();

      // New swipe-based design: score badge + circular action buttons
      expect(find.textContaining('% compatible'), findsWidgets);

      // Tap the like (favorite) circular action button (last of 2 favorite icons)
      final likeButtons = find.byIcon(Icons.favorite_rounded);
      expect(likeButtons, findsWidgets);
      await tester.tap(likeButtons.last);
      await tester.pumpAndSettle();

      expect(find.textContaining('Ajout\u00e9 \u00e0 tes favoris'), findsOneWidget);
    });
  });
}
