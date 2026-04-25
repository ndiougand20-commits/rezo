part of 'auth_flow.dart';

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
              border: Border.all(color: const Color(0xFFD0D0D0)),
            ),
            child: const Column(
              children: [
                RezoLogo(height: 88),
                SizedBox(height: 10),
                Text(
                  'Étudiants, lycéens, profils emploi, entreprises et écoles réunis dans un même espace.',
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
                    _HeroStatChip(label: 'Lycéen'),
                    _HeroStatChip(label: 'Emploi'),
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
