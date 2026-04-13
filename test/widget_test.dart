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
        MyApp(
          authService: FakeAuthService(),
          tokenStorage: MemoryTokenStorage(),
        ),
      );
      await tester.pumpAndSettle();

      final signupCta = find.widgetWithText(OutlinedButton, 'Créer un compte');
      await tester.ensureVisible(signupCta);
      await tester.tap(signupCta, warnIfMissed: false);
      await tester.pumpAndSettle();

      final formState = tester.state<FormState>(find.byType(Form));
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
  });
}
