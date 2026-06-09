part of 'auth_flow.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  /// Liste des onglets visibles, calculée à chaque build selon le rôle
  /// et les permissions de l'utilisateur courant.
  late List<_TabSpec> _visibleTabs;

  void goToTab(int index) {
    if (!mounted) return;
    setState(() => _currentIndex = index.clamp(0, _visibleTabs.length - 1));
  }

  /// Ouvre la page profil via l'icône en haut.
  void goToProfile() {
    if (!mounted) return;
    final appState = AppScope.of(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Profil')),
          body: SafeArea(
            child: _ProfileTab(
              onLogout: () async {
                await appState.logout();
                if (!mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.roleChoice,
                  (route) => false,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final user = appState.currentUser ?? <String, dynamic>{};
    final role = parseUserRole(user['role'] as String?);
    final fullName = [
      user['prenom'],
      user['nom'],
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' ');

    _visibleTabs = _buildTabs(
      appState: appState,
      user: user,
      role: role,
      fullName: fullName,
    );

    if (_currentIndex >= _visibleTabs.length) {
      _currentIndex = 0;
    }

    final current = _visibleTabs[_currentIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text(current.title),
        actions: [
          IconButton(
            tooltip: 'Mon profil',
            onPressed: goToProfile,
            icon: const Icon(Icons.account_circle_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(
            key: ValueKey(_currentIndex),
            child: current.widget,
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        destinations: _visibleTabs
            .map(
              (t) => NavigationDestination(
                icon: Icon(t.icon),
                selectedIcon: Icon(t.selectedIcon),
                label: t.label,
              ),
            )
            .toList(),
      ),
    );
  }

  List<_TabSpec> _buildTabs({
    required AppState appState,
    required Map<String, dynamic> user,
    required UserRole role,
    required String fullName,
  }) {
    final tabs = <_TabSpec>[
      _TabSpec(
        kind: _TabKind.matching,
        title: 'Matching',
        label: 'Matching',
        icon: Icons.swipe_outlined,
        selectedIcon: Icons.swipe_rounded,
        widget: const _MatchesTab(),
      ),
      _TabSpec(
        kind: _TabKind.messages,
        title: 'Messages',
        label: 'Messages',
        icon: Icons.forum_outlined,
        selectedIcon: Icons.forum_rounded,
        widget: const _MessagesTab(),
      ),
      _TabSpec(
        kind: _TabKind.report,
        title: 'Rapport',
        label: 'Rapport',
        icon: Icons.insights_outlined,
        selectedIcon: Icons.insights_rounded,
        widget: _ReportTab(role: role),
      ),
    ];

    if (role == UserRole.ecole || role == UserRole.entreprise) {
      tabs.add(const _TabSpec(
        kind: _TabKind.offers,
        title: 'Mes offres',
        label: 'Offres',
        icon: Icons.work_outline_rounded,
        selectedIcon: Icons.work_rounded,
        widget: _OffersTab(),
      ));
    }

    if (user['canUseAiChat'] == true) {
      tabs.add(const _TabSpec(
        kind: _TabKind.aiChat,
        title: 'Chat IA',
        label: 'IA',
        icon: Icons.smart_toy_outlined,
        selectedIcon: Icons.smart_toy_rounded,
        widget: _AiChatTab(),
      ));
    }

    return tabs;
  }
}

enum _TabKind { messages, matching, offers, aiChat, report }

class _TabSpec {
  const _TabSpec({
    required this.kind,
    required this.title,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.widget,
  });

  final _TabKind kind;
  final String title;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget widget;
}
