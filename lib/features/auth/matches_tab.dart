part of 'auth_flow.dart';

class _MatchesTab extends StatefulWidget {
  const _MatchesTab();

  @override
  State<_MatchesTab> createState() => _MatchesTabState();
}

class _MatchesTabState extends State<_MatchesTab> {
  int _currentIndex = 0;
  int _likedCount = 0;
  int _passedCount = 0;

  Offset _dragOffset = Offset.zero;
  double _dragAngle = 0;
  bool _isDragging = false;

  void _onPanStart(DragStartDetails _) {
    setState(() => _isDragging = true);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
      _dragAngle = _dragOffset.dx / 300 * 0.3;
    });
  }

  void _onPanEnd(DragEndDetails _, int total) {
    final dx = _dragOffset.dx;
    if (dx.abs() > 100) {
      _swipe(liked: dx > 0, total: total);
    }
    setState(() {
      _dragOffset = Offset.zero;
      _dragAngle = 0;
      _isDragging = false;
    });
  }

  void _swipe({required bool liked, required int total}) {
    final nextIndex = _currentIndex + 1;
    setState(() {
      if (liked) {
        _likedCount += 1;
      } else {
        _passedCount += 1;
      }
      _currentIndex = nextIndex.clamp(0, total);
      _dragOffset = Offset.zero;
      _dragAngle = 0;
      _isDragging = false;
    });

    if (!mounted) return;

    final message =
        liked ? 'Ajout\u00e9 \u00e0 tes favoris' : 'Suggestion ignor\u00e9e';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  void _resetSession() {
    setState(() {
      _currentIndex = 0;
      _likedCount = 0;
      _passedCount = 0;
    });
  }

  void _showMatchDetail(_MockMatch match) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _MatchDetailSheet(match: match),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AppScope.of(context).currentUser ?? const <String, dynamic>{};
    final role = parseUserRole(user['role'] as String?);
    final profile =
        (user['profil'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final recommendations = _buildRecommendations(
      role: role,
      user: user,
      profile: profile,
    );

    if (recommendations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swipe_rounded, size: 64,
                  color: Theme.of(context).colorScheme.primary.withAlpha(80)),
              const SizedBox(height: 16),
              const Text(
                'Compl\u00e8te ton profil pour\nd\u00e9bloquer les suggestions',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    final hasCurrent = _currentIndex < recommendations.length;
    final current = hasCurrent ? recommendations[_currentIndex] : null;
    final remaining = recommendations.length - _currentIndex;

    return Column(
      children: [
        // Stats bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MiniStat(
                icon: Icons.local_fire_department_rounded,
                value: hasCurrent ? '$remaining' : '0',
                color: const Color(0xFFFF9800),
              ),
              const SizedBox(width: 24),
              _MiniStat(
                icon: Icons.favorite_rounded,
                value: '$_likedCount',
                color: const Color(0xFFE91E63),
              ),
              const SizedBox(width: 24),
              _MiniStat(
                icon: Icons.close_rounded,
                value: '$_passedCount',
                color: const Color(0xFF90A4AE),
              ),
            ],
          ),
        ),

        // Swipe area
        Expanded(
          child: current != null
              ? _buildSwipeCard(current, recommendations.length)
              : _buildSessionEnd(recommendations.length),
        ),

        // Action buttons
        if (current != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 0, 40, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CircleActionButton(
                  icon: Icons.close_rounded,
                  color: const Color(0xFFFF5252),
                  size: 64,
                  onPressed: () =>
                      _swipe(liked: false, total: recommendations.length),
                ),
                _CircleActionButton(
                  icon: Icons.info_outline_rounded,
                  color: const Color(0xFF000000),
                  size: 48,
                  onPressed: () => _showMatchDetail(current),
                ),
                _CircleActionButton(
                  icon: Icons.favorite_rounded,
                  color: const Color(0xFF4CAF50),
                  size: 64,
                  onPressed: () =>
                      _swipe(liked: true, total: recommendations.length),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 0, 40, 24),
            child: ElevatedButton.icon(
              onPressed: _resetSession,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Rejouer'),
            ),
          ),
      ],
    );
  }

  Widget _buildSwipeCard(_MockMatch match, int total) {
    final swipeProgress = (_dragOffset.dx / 150).clamp(-1.0, 1.0);
    final likeOpacity = swipeProgress > 0 ? swipeProgress : 0.0;
    final passOpacity = swipeProgress < 0 ? -swipeProgress : 0.0;

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: (d) => _onPanEnd(d, total),
      child: Center(
        child: AnimatedContainer(
          duration:
              _isDragging ? Duration.zero : const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          transform: Matrix4.identity()
            ..setTranslationRaw(_dragOffset.dx, _dragOffset.dy, 0)
            ..rotateZ(_dragAngle),
          transformAlignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Round profile card
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      match.accent,
                      Theme.of(context).colorScheme.primaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: const Color(0xFFE0E0E0),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: match.accent.withAlpha(60),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Initials
                    Text(
                      _initials(match.title),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Name
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        match.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Subtitle
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        match.subtitle,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Score badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(200),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${match.score}% compatible',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Type pill at top
              Positioned(
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFD0D0D0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    match.typeLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              // LIKE overlay
              if (likeOpacity > 0)
                Positioned(
                  top: 20,
                  left: 20,
                  child: Opacity(
                    opacity: likeOpacity,
                    child: Transform.rotate(
                      angle: -0.3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF4CAF50),
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'LIKE',
                          style: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // NOPE overlay
              if (passOpacity > 0)
                Positioned(
                  top: 20,
                  right: 20,
                  child: Opacity(
                    opacity: passOpacity,
                    child: Transform.rotate(
                      angle: 0.3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFFF5252),
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'NOPE',
                          style: TextStyle(
                            color: Color(0xFFFF5252),
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionEnd(int total) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '$total profils parcourus',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_likedCount aim\u00e9s  \u2022  $_passedCount pass\u00e9s',
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  List<_MockMatch> _buildRecommendations({
    required UserRole role,
    required Map<String, dynamic> user,
    required Map<String, dynamic> profile,
  }) {
    final domain =
        profile['domaine']?.toString() ??
        profile['secteurActivite']?.toString() ??
        'Informatique';
    final objective =
        profile['objectif']?.toString() ??
        profile['objectifPostbac']?.toString() ??
        'D\u00e9couvrir les meilleures opportunit\u00e9s';

    switch (role) {
      case UserRole.etudiant:
        return [
          _MockMatch(
            title: 'Stage Flutter Product Builder',
            subtitle: 'Startup SaaS \u2022 Dakar \u2022 Stage 6 mois',
            score: 92,
            owner: 'Nova Tech',
            location: 'Dakar',
            typeLabel: 'STAGE',
            accent: const Color(0xFFF0F0F0),
            tags: ['Flutter', domain, 'Product'],
            reasons: [
              'domaine compatible',
              '2 comp\u00e9tences en commun',
              'objectif coh\u00e9rent',
            ],
            description:
                'Une opportunit\u00e9 orient\u00e9e mobile et produit pour construire une vraie exp\u00e9rience terrain.',
          ),
          _MockMatch(
            title: 'Alternance Data & IA appliqu\u00e9e',
            subtitle: 'Cabinet innovation \u2022 Remote hybride',
            score: 84,
            owner: 'Insight Lab',
            location: 'Remote',
            typeLabel: 'ALTERNANCE',
            accent: const Color(0xFFE8E8E8),
            tags: ['Python', 'Data', objective],
            reasons: [
              'objectif professionnel proche',
              'localisation pr\u00e9f\u00e9r\u00e9e',
              'fort potentiel d\u2019\u00e9volution',
            ],
            description:
                'Un parcours id\u00e9al pour muscler ton profil technique et ton exposition m\u00e9tier.',
          ),
        ];
      case UserRole.lyceen:
        return [
          _MockMatch(
            title: 'Licence Informatique - Parcours d\u00e9veloppeur',
            subtitle: '\u00c9cole sup\u00e9rieure \u2022 Bac+3 \u2022 Admission sur dossier',
            score: 90,
            owner: 'Institut Num\u00e9ria',
            location: 'Abidjan',
            typeLabel: 'FORMATION',
            accent: const Color(0xFFEEEEEE),
            tags: ['Post-bac', 'Programmation', 'Orientation'],
            reasons: [
              'orientation compatible',
              'projet post-bac coh\u00e9rent',
              'centres d\u2019int\u00e9r\u00eat align\u00e9s',
            ],
            description:
                'Une proposition pens\u00e9e pour un profil attir\u00e9 par le num\u00e9rique et la progression par projets.',
          ),
          _MockMatch(
            title: 'Bachelor Business & Tech',
            subtitle: '\u00c9cole priv\u00e9e \u2022 Parcours hybride',
            score: 76,
            owner: 'Campus Horizon',
            location: 'Cotonou',
            typeLabel: 'FORMATION',
            accent: const Color(0xFFF0F0F0),
            tags: ['Post-bac', 'Innovation', 'Projet'],
            reasons: [
              'bonne projection m\u00e9tier',
              'programme accessible',
              'd\u00e9couverte progressive des sp\u00e9cialisations',
            ],
            description:
                'Une option plus large pour garder plusieurs portes ouvertes apr\u00e8s le bac.',
          ),
        ];
      case UserRole.emploi:
        return [
          _MockMatch(
            title: 'D\u00e9veloppeur full stack confirm\u00e9',
            subtitle: 'CDI \u2022 Produit digital \u2022 Paris',
            score: 88,
            owner: 'Kora Digital',
            location: 'Paris',
            typeLabel: 'EMPLOI',
            accent: const Color(0xFFE8E8E8),
            tags: [domain, 'CDI', 'Remote partiel'],
            reasons: [
              'exp\u00e9riences compatibles',
              'secteur align\u00e9',
              'objectif professionnel coh\u00e9rent',
            ],
            description:
                'Un poste qui valorise l\u2019exp\u00e9rience existante tout en offrant une vraie marge de progression.',
          ),
          _MockMatch(
            title: 'Product engineer mobile',
            subtitle: 'Scale-up \u2022 Mobile \u2022 T\u00e9l\u00e9travail',
            score: 81,
            owner: 'Wave Product',
            location: 'T\u00e9l\u00e9travail',
            typeLabel: 'EMPLOI',
            accent: const Color(0xFFF0F0F0),
            tags: ['Produit', 'Mobile', 'Impact'],
            reasons: [
              'stack coh\u00e9rente',
              'r\u00f4le compatible avec le profil',
              'environnement de travail attractif',
            ],
            description:
                'Une opportunit\u00e9 orient\u00e9e livraison produit et impact direct sur les utilisateurs.',
          ),
        ];
      case UserRole.entreprise:
        return [
          _MockMatch(
            title: 'A\u00efcha Ndiaye',
            subtitle:
                'Profil tech \u2022 Flutter / Backend \u2022 Disponible en 30 jours',
            score: 91,
            owner: 'Candidate matching',
            location: 'Dakar',
            typeLabel: 'PROFIL',
            accent: const Color(0xFFEEEEEE),
            tags: ['Flutter', 'API', 'Stage/CDI'],
            reasons: [
              'comp\u00e9tences proches de vos besoins',
              'mobilit\u00e9 compatible',
              'bon potentiel de conversion',
            ],
            description:
                'Une candidate pertinente pour pr\u00e9parer la future vue de recrutement entreprise.',
          ),
          _MockMatch(
            title: 'Moussa Traor\u00e9',
            subtitle: 'Profil data \u2022 Python / SQL \u2022 Exp\u00e9rience junior',
            score: 78,
            owner: 'Candidate matching',
            location: 'Abidjan',
            typeLabel: 'PROFIL',
            accent: const Color(0xFFF0F0F0),
            tags: ['Python', 'SQL', 'Data'],
            reasons: [
              'secteur compatible',
              'profil \u00e9volutif',
              'bonne couverture des besoins cl\u00e9s',
            ],
            description:
                'Un profil \u00e0 garder sous la main pour les prochains besoins data ou analytics.',
          ),
        ];
      case UserRole.ecole:
        return [
          _MockMatch(
            title: 'Profil orient\u00e9 ing\u00e9nierie logicielle',
            subtitle: 'Terminale \u2022 app\u00e9tence num\u00e9rique \u2022 post-bac cibl\u00e9',
            score: 89,
            owner: 'Candidat orientation',
            location: 'Lom\u00e9',
            typeLabel: 'CANDIDAT',
            accent: const Color(0xFFEEEEEE),
            tags: ['Orientation', 'Programmation', 'Admission'],
            reasons: [
              'objectif post-bac align\u00e9',
              'programme compatible',
              'fort potentiel d\u2019ad\u00e9quation',
            ],
            description:
                'Une premi\u00e8re simulation du type de profil que ton \u00e9tablissement pourrait souhaiter attirer.',
          ),
          _MockMatch(
            title: 'Profil business & num\u00e9rique',
            subtitle: 'Bac+2 \u2022 reconversion \u2022 forte motivation',
            score: 74,
            owner: 'Candidat orientation',
            location: 'Cotonou',
            typeLabel: 'CANDIDAT',
            accent: const Color(0xFFF0F0F0),
            tags: ['Reconversion', 'Formation', 'Business'],
            reasons: [
              'profil atypique int\u00e9ressant',
              'bonne coh\u00e9rence avec une offre hybride',
              'fort engagement projet\u00e9',
            ],
            description:
                'Un profil utile pour pr\u00e9parer la future logique d\u2019attraction et d\u2019admission.',
          ),
        ];
    }
  }
}

// Supporting widgets

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: color.withAlpha(60), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(30),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.45),
      ),
    );
  }
}

class _MockMatch {
  const _MockMatch({
    required this.title,
    required this.subtitle,
    required this.score,
    required this.owner,
    required this.location,
    required this.typeLabel,
    required this.accent,
    required this.tags,
    required this.reasons,
    required this.description,
  });

  final String title;
  final String subtitle;
  final int score;
  final String owner;
  final String location;
  final String typeLabel;
  final Color accent;
  final List<String> tags;
  final List<String> reasons;
  final String description;
}

class _MatchDetailSheet extends StatelessWidget {
  const _MatchDetailSheet({required this.match});

  final _MockMatch match;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Avatar circle
            Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      match.accent,
                      Theme.of(context).colorScheme.primaryContainer,
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    _initials(match.title),
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${match.score}% compatible',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              match.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              match.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            _ProfileSectionCard(
              title: 'Description',
              child: Text(
                match.description,
                style: const TextStyle(height: 1.45),
              ),
            ),
            const SizedBox(height: 12),
            _ProfileSectionCard(
              title: 'Informations',
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.business_center_rounded,
                    label: 'Propos\u00e9 par',
                    value: match.owner,
                  ),
                  _DetailRow(
                    icon: Icons.location_on_rounded,
                    label: 'Localisation',
                    value: match.location,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _ProfileSectionCard(
              title: 'Tags',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    match.tags.map((t) => _TagPill(label: t)).toList(),
              ),
            ),
            const SizedBox(height: 12),
            _ProfileSectionCard(
              title: 'Pourquoi cette suggestion',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: match.reasons
                    .map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              size: 18,
                              color:
                                  Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(r)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Text('$label : ',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
