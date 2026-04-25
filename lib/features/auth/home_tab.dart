part of 'auth_flow.dart';

class _DashboardMetricTile extends StatelessWidget {
  const _DashboardMetricTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
    );
  }
}

class _DashboardActionCard extends StatelessWidget {
  const _DashboardActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD0D0D0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(height: 1.35)),
                  if (onTap != null) ...[                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Aller',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoadmapStepTile extends StatelessWidget {
  const _RoadmapStepTile({
    required this.index,
    required this.title,
    required this.subtitle,
  });

  final int index;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardItem {
  const _DashboardItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

class _DashboardActionItem {
  const _DashboardActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.targetTab,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final int? targetTab;
}

class _RoadmapItem {
  const _RoadmapItem({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.user,
    required this.role,
    required this.fullName,
    this.onTabSwitch,
  });

  final Map<String, dynamic> user;
  final UserRole role;
  final String fullName;
  final ValueChanged<int>? onTabSwitch;

  @override
  Widget build(BuildContext context) {
    final profile =
        (user['profil'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final welcomeName = fullName.trim().isEmpty ? 'sur REZO' : fullName.trim();
    final highlights = _buildHighlights(profile);
    final quickActions = _buildQuickActions();
    final roadmap = _buildRoadmap();

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
            border: Border.all(color: const Color(0xFFD0D0D0)),
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
                          'Bienvenue $welcomeName',
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TagPill(label: role.label),
                  _TagPill(label: user['packNom']?.toString() ?? 'Pack FREE'),
                ],
              ),
              const SizedBox(height: 14),
              _InfoBanner(
                message: switch (role) {
                  UserRole.etudiant =>
                    'Explore des opportunités, complète ton profil et lance tes premiers matchs.',
                  UserRole.lyceen =>
                    'Clarifie ton orientation, découvre les formations pertinentes et prépare ton post-bac.',
                  UserRole.emploi =>
                    'Cible les bonnes offres, mets en avant ton expérience et contacte les recruteurs.',
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
        _ProfileSectionCard(
          title: 'Vue d’ensemble',
          child: Column(
            children: highlights
                .map(
                  (item) => _DashboardMetricTile(
                    icon: item.icon,
                    title: item.title,
                    subtitle: item.subtitle,
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        _ProfileSectionCard(
          title: 'Actions prioritaires',
          child: Column(
            children: quickActions
                .map(
                  (item) => _DashboardActionCard(
                    icon: item.icon,
                    title: item.title,
                    subtitle: item.subtitle,
                    accent: item.accent,
                    onTap: item.targetTab != null
                        ? () => onTabSwitch?.call(item.targetTab!)
                        : null,
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        _ProfileSectionCard(
          title: 'Parcours REZO',
          child: Column(
            children: roadmap
                .asMap()
                .entries
                .map(
                  (entry) => _RoadmapStepTile(
                    index: entry.key + 1,
                    title: entry.value.title,
                    subtitle: entry.value.subtitle,
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        _ProfileSectionCard(
          title: 'Complétude du profil',
          child: _ProfileCompletenessIndicator(profile: profile, role: role),
        ),
      ],
    );
  }

  List<_DashboardItem> _buildHighlights(Map<String, dynamic> profile) {
    switch (role) {
      case UserRole.etudiant:
        return [
          _DashboardItem(
            icon: Icons.school_rounded,
            title: profile['niveauEtude']?.toString() ?? 'Niveau à compléter',
            subtitle: 'Ton niveau d’étude actuel',
          ),
          _DashboardItem(
            icon: Icons.psychology_alt_rounded,
            title: profile['domaine']?.toString() ?? 'Domaine à compléter',
            subtitle: 'Le domaine qui guide tes recommandations',
          ),
          _DashboardItem(
            icon: Icons.flag_rounded,
            title: profile['objectif']?.toString() ?? 'Objectif à préciser',
            subtitle: 'Ce que tu recherches en priorité',
          ),
        ];
      case UserRole.lyceen:
        return [
          _DashboardItem(
            icon: Icons.auto_stories_rounded,
            title:
                profile['classeActuelle']?.toString() ?? 'Classe à compléter',
            subtitle: 'Ta situation scolaire actuelle',
          ),
          _DashboardItem(
            icon: Icons.explore_rounded,
            title:
                profile['orientationSouhaitee']?.toString() ??
                'Orientation à préciser',
            subtitle: 'Le parcours qui t’attire le plus',
          ),
          _DashboardItem(
            icon: Icons.track_changes_rounded,
            title:
                profile['objectifPostbac']?.toString() ??
                'Projet post-bac à compléter',
            subtitle: 'Ton objectif après le lycée',
          ),
        ];
      case UserRole.emploi:
        return [
          _DashboardItem(
            icon: Icons.work_history_rounded,
            title:
                profile['experiences']?.toString() ?? 'Expérience à compléter',
            subtitle: 'Ton expérience la plus pertinente',
          ),
          _DashboardItem(
            icon: Icons.domain_rounded,
            title:
                profile['secteurActivite']?.toString() ?? 'Secteur à compléter',
            subtitle: 'Le secteur d’activité visé',
          ),
          _DashboardItem(
            icon: Icons.rocket_launch_rounded,
            title: profile['objectif']?.toString() ?? 'Objectif à compléter',
            subtitle: 'Ta prochaine étape professionnelle',
          ),
        ];
      case UserRole.entreprise:
        return [
          _DashboardItem(
            icon: Icons.apartment_rounded,
            title:
                profile['secteurEntreprise']?.toString() ??
                'Secteur à compléter',
            subtitle: 'Le secteur de ton entreprise',
          ),
          _DashboardItem(
            icon: Icons.groups_rounded,
            title:
                profile['tailleEntreprise']?.toString() ?? 'Taille à compléter',
            subtitle: 'La taille de structure visée par REZO',
          ),
          _DashboardItem(
            icon: Icons.campaign_rounded,
            title:
                profile['besoinsRecrutement']?.toString() ??
                'Besoins à préciser',
            subtitle: 'Les recrutements prioritaires à préparer',
          ),
        ];
      case UserRole.ecole:
        return [
          _DashboardItem(
            icon: Icons.account_balance_rounded,
            title: profile['nomEcole']?.toString() ?? 'Nom à compléter',
            subtitle: 'Nom de l’établissement',
          ),
          _DashboardItem(
            icon: Icons.menu_book_rounded,
            title: profile['filieres']?.toString() ?? 'Filières à renseigner',
            subtitle: 'Les filières mises en avant',
          ),
          _DashboardItem(
            icon: Icons.workspace_premium_rounded,
            title: profile['diplomes']?.toString() ?? 'Diplômes à renseigner',
            subtitle: 'Les diplômes délivrés',
          ),
        ];
    }
  }

  List<_DashboardActionItem> _buildQuickActions() {
    switch (role) {
      case UserRole.etudiant:
        return const [
          _DashboardActionItem(
            icon: Icons.edit_note_rounded,
            title: 'Compléter le profil',
            subtitle:
                'Ajoute ton domaine, ton niveau et ton objectif pour fiabiliser les futurs matchs.',
            accent: Color(0xFFF0F0F0),
            targetTab: 3,
          ),
          _DashboardActionItem(
            icon: Icons.swipe_rounded,
            title: 'Explorer les opportunités',
            subtitle:
                'Découvre les suggestions de stages, alternances et emplois dans l’onglet Matching.',
            accent: Color(0xFFE8E8E8),
            targetTab: 2,
          ),
        ];
      case UserRole.lyceen:
        return const [
          _DashboardActionItem(
            icon: Icons.explore_rounded,
            title: 'Préciser ton orientation',
            subtitle:
                'Renseigne ton projet post-bac pour guider les futures suggestions.',
            accent: Color(0xFFEEEEEE),
            targetTab: 3,
          ),
          _DashboardActionItem(
            icon: Icons.school_rounded,
            title: 'Comparer les formations',
            subtitle:
                'Explore les écoles et parcours proposés dans l’onglet Matching.',
            accent: Color(0xFFF0F0F0),
            targetTab: 2,
          ),
        ];
      case UserRole.emploi:
        return const [
          _DashboardActionItem(
            icon: Icons.badge_rounded,
            title: 'Valoriser ton parcours',
            subtitle:
                'Ajoute tes expériences et tes compétences pour remonter dans les recommandations.',
            accent: Color(0xFFE8E8E8),
            targetTab: 3,
          ),
          _DashboardActionItem(
            icon: Icons.work_outline_rounded,
            title: 'Préparer les candidatures',
            subtitle:
                'Consulte les offres compatibles dans l’onglet Matching.',
            accent: Color(0xFFF0F0F0),
            targetTab: 2,
          ),
        ];
      case UserRole.entreprise:
        return const [
          _DashboardActionItem(
            icon: Icons.post_add_rounded,
            title: 'Préparer une offre',
            subtitle:
                'Décris ton besoin pour que la future recherche de profils soit plus précise.',
            accent: Color(0xFFEEEEEE),
            targetTab: 3,
          ),
          _DashboardActionItem(
            icon: Icons.people_alt_rounded,
            title: 'Qualifier les candidats',
            subtitle:
                'Découvre les profils triés selon tes critères dans l’onglet Matching.',
            accent: Color(0xFFF0F0F0),
            targetTab: 2,
          ),
        ];
      case UserRole.ecole:
        return const [
          _DashboardActionItem(
            icon: Icons.school_rounded,
            title: 'Mettre en avant les formations',
            subtitle:
                'Complète tes filières et diplômes pour mieux ressortir dans le matching.',
            accent: Color(0xFFEEEEEE),
            targetTab: 3,
          ),
          _DashboardActionItem(
            icon: Icons.groups_2_rounded,
            title: 'Attirer les bons profils',
            subtitle:
                'Explore les candidats cohérents dans l’onglet Matching.',
            accent: Color(0xFFE8E8E8),
            targetTab: 2,
          ),
        ];
    }
  }

  List<_RoadmapItem> _buildRoadmap() {
    switch (role) {
      case UserRole.etudiant:
        return const [
          _RoadmapItem(
            title: '1. Profil solide',
            subtitle:
                'Ton profil guide les recommandations de stage, alternance ou emploi.',
          ),
          _RoadmapItem(
            title: '2. Matching ciblé',
            subtitle:
                'Les opportunités les plus proches de ton objectif seront mises en avant.',
          ),
          _RoadmapItem(
            title: '3. Conversation utile',
            subtitle:
                'Une fois l’intérêt confirmé, la messagerie prendra le relais.',
          ),
        ];
      case UserRole.lyceen:
        return const [
          _RoadmapItem(
            title: '1. Clarifier le projet',
            subtitle:
                'REZO t’aide à transformer une intention en parcours réaliste.',
          ),
          _RoadmapItem(
            title: '2. Comparer les écoles',
            subtitle:
                'Les formations compatibles seront classées par pertinence.',
          ),
          _RoadmapItem(
            title: '3. Passer à l’action',
            subtitle:
                'Tu pourras ensuite contacter ou suivre les établissements qui t’intéressent.',
          ),
        ];
      case UserRole.emploi:
        return const [
          _RoadmapItem(
            title: '1. Mettre à jour le parcours',
            subtitle:
                'Tes expériences et compétences servent de base au scoring.',
          ),
          _RoadmapItem(
            title: '2. Trier les offres',
            subtitle:
                'REZO fera remonter les postes qui collent vraiment à ton objectif.',
          ),
          _RoadmapItem(
            title: '3. Entrer en contact',
            subtitle:
                'Une fois le matching confirmé, la messagerie fluidifiera la suite.',
          ),
        ];
      case UserRole.entreprise:
        return const [
          _RoadmapItem(
            title: '1. Définir le besoin',
            subtitle:
                'Le besoin de recrutement conditionnera le futur score des profils.',
          ),
          _RoadmapItem(
            title: '2. Recevoir les bons profils',
            subtitle:
                'Les candidats les plus compatibles seront affichés en priorité.',
          ),
          _RoadmapItem(
            title: '3. Convertir en échange',
            subtitle:
                'La conversation commencera dès qu’un intérêt réciproque sera détecté.',
          ),
        ];
      case UserRole.ecole:
        return const [
          _RoadmapItem(
            title: '1. Structurer l’offre',
            subtitle:
                'Tes filières et diplômes permettront d’expliquer ton positionnement.',
          ),
          _RoadmapItem(
            title: '2. Attirer les bons candidats',
            subtitle:
                'Les profils scolaires ou en reconversion seront priorisés selon leur cohérence.',
          ),
          _RoadmapItem(
            title: '3. Accompagner la décision',
            subtitle:
                'La suite du produit facilitera la prise de contact et le suivi.',
          ),
        ];
    }
  }
}

class _ProfileCompletenessIndicator extends StatelessWidget {
  const _ProfileCompletenessIndicator({
    required this.profile,
    required this.role,
  });

  final Map<String, dynamic> profile;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final fields = _requiredFields();
    final filled = fields.where((f) {
      final value = profile[f.key];
      if (value == null) return false;
      if (value is String && value.trim().isEmpty) return false;
      if (value is List && value.isEmpty) return false;
      return true;
    }).length;
    final total = fields.length;
    final ratio = total > 0 ? filled / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE0E0E0),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$filled / $total',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...fields.map((f) {
          final value = profile[f.key];
          final isFilled = value != null &&
              (value is! String || value.trim().isNotEmpty) &&
              (value is! List || value.isNotEmpty);
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  isFilled
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: isFilled
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFBDBDBD),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    f.label,
                    style: TextStyle(
                      color: isFilled ? Colors.black87 : Colors.black54,
                      decoration:
                          isFilled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  List<_ProfileField> _requiredFields() {
    switch (role) {
      case UserRole.etudiant:
        return const [
          _ProfileField('niveauEtude', 'Niveau d\u2019étude'),
          _ProfileField('domaine', 'Domaine / filière'),
          _ProfileField('competences', 'Compétences clés'),
          _ProfileField('objectif', 'Objectif de recherche'),
          _ProfileField('preferencesSecteur', 'Préférences secteur'),
        ];
      case UserRole.lyceen:
        return const [
          _ProfileField('classeActuelle', 'Classe actuelle'),
          _ProfileField('orientationSouhaitee', 'Orientation souhaitée'),
          _ProfileField('objectifPostbac', 'Objectif post-bac'),
          _ProfileField('centresInteret', 'Centres d\u2019intérêt'),
        ];
      case UserRole.emploi:
        return const [
          _ProfileField('experiences', 'Expériences'),
          _ProfileField('secteurActivite', 'Secteur d\u2019activité'),
          _ProfileField('objectif', 'Objectif professionnel'),
          _ProfileField('competences', 'Compétences clés'),
        ];
      case UserRole.entreprise:
        return const [
          _ProfileField('secteurEntreprise', 'Secteur d\u2019activité'),
          _ProfileField('tailleEntreprise', 'Taille de l\u2019entreprise'),
          _ProfileField('besoinsRecrutement', 'Besoins recrutement'),
          _ProfileField('descriptionEntreprise', 'Description'),
        ];
      case UserRole.ecole:
        return const [
          _ProfileField('nomEcole', 'Nom de l\u2019établissement'),
          _ProfileField('filieres', 'Filières proposées'),
          _ProfileField('diplomes', 'Diplômes délivrés'),
          _ProfileField('descriptionEcole', 'Description'),
        ];
    }
  }
}

class _ProfileField {
  const _ProfileField(this.key, this.label);
  final String key;
  final String label;
}
