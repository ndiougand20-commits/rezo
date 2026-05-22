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

  /// Navigue vers l'onglet Profil quel que soit son index actuel.
  void goToProfile() {
    final i = _visibleTabs.indexWhere((t) => t.kind == _TabKind.profile);
    if (i < 0) return;
    if (!mounted) return;
    setState(() => _currentIndex = i);
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
    final isMatchingTab = current.kind == _TabKind.matching;
    final isProfileTab = current.kind == _TabKind.profile;

    return Scaffold(
      appBar: isMatchingTab
          ? null
          : AppBar(
              title: Text(current.title),
              actions: [
                if (!isProfileTab)
                  IconButton(
                    tooltip: 'Mon profil',
                    onPressed: goToProfile,
                    icon: const Icon(Icons.account_circle_rounded),
                  ),
              ],
            ),
      body: SafeArea(
        top: isMatchingTab,
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
        kind: _TabKind.home,
        title: 'Dashboard',
        label: 'Accueil',
        icon: Icons.grid_view_rounded,
        selectedIcon: Icons.grid_view,
        widget: _HomeTab(
          user: user,
          role: role,
          fullName: fullName,
          onTabSwitch: (index) => setState(() => _currentIndex = index),
          additionalInfo: role == UserRole.etudiant
              ? 'Bienvenue sur votre tableau de bord étudiant. Ici, vous pouvez accéder à vos cours, vos messages, et vos opportunités.'
              : null,
        ),
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
        kind: _TabKind.matching,
        title: 'Matching',
        label: 'Matching',
        icon: Icons.swipe_outlined,
        selectedIcon: Icons.swipe_rounded,
        widget: const _MatchesTab(),
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

    tabs.add(_TabSpec(
      kind: _TabKind.profile,
      title: 'Profil',
      label: 'Profil',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      widget: _ProfileTab(
        onLogout: () async {
          await appState.logout();
          if (!mounted) return; // Ensure mounted before using context
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.welcome, (route) => false);
        },
      ),
    ));

    return tabs;
  }
}

enum _TabKind { home, messages, matching, offers, aiChat, profile }

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
