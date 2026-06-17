part of 'auth_flow.dart';

class _ReportTab extends StatefulWidget {
  const _ReportTab({
    required this.role,
    super.key,
  });

  final UserRole role;

  @override
  State<_ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<_ReportTab> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _stats = const <String, dynamic>{};
  DateTime? _lastRefreshAt;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final appState = AppScope.of(context);
      final stats = await appState.fetchMyStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _lastRefreshAt = DateTime.now();
        _loading = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les rapports';
        _loading = false;
      });
    }
  }

  int _n(String key) => (_stats[key] as num?)?.toInt() ?? 0;

  String _ratio(int numerator, int denominator) {
    if (denominator <= 0) return '0%';
    final value = ((numerator / denominator) * 100).round();
    return '$value%';
  }

  String _lastRefreshLabel() {
    final ts = _lastRefreshAt;
    if (ts == null) return 'Mise à jour en attente';
    final hh = ts.hour.toString().padLeft(2, '0');
    final mm = ts.minute.toString().padLeft(2, '0');
    return 'Mis à jour à $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 46),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final matchCount = _n('matchCount');
    final likesReceived = _n('likesReceived');
    final likesSent = _n('likesSent');
    final unreadMessages = _n('unreadMessages');
    final offerCount = _n('offerCount');
    final interactions = likesSent + likesReceived + matchCount;
    final cards = <_ReportCardData>[
      _ReportCardData(
        label: 'Matchs',
        value: '$matchCount',
        icon: Icons.favorite_rounded,
        helper: 'Connexions mutuelles',
      ),
      _ReportCardData(
        label: 'Likes reçus',
        value: '$likesReceived',
        icon: Icons.thumb_up_alt_rounded,
        helper: 'Attractivité de ton profil',
      ),
      _ReportCardData(
        label: 'Messages non lus',
        value: '$unreadMessages',
        icon: Icons.mark_chat_unread_rounded,
        helper: unreadMessages == 0 ? 'Boîte de réception saine' : 'À traiter rapidement',
      ),
      _ReportCardData(
        label: 'Likes envoyés',
        value: '$likesSent',
        icon: Icons.outbound_rounded,
        helper: 'Activité de prospection',
      ),
    ];

    if (widget.role == UserRole.entreprise || widget.role == UserRole.ecole) {
      cards.add(
        _ReportCardData(
          label: 'Offres dispo',
          value: '$offerCount',
          icon: Icons.work_rounded,
          helper: 'Opportunités publiées',
        ),
      );
    }

    final insights = <String>[
      'Taux de conversion likes envoyés -> matchs: ${_ratio(matchCount, likesSent)}',
      'Part des messages en attente: ${_ratio(unreadMessages, (unreadMessages + matchCount + likesReceived).clamp(1, 1000000))}',
      'Volume d’interactions: $interactions',
      if (widget.role == UserRole.entreprise || widget.role == UserRole.ecole)
        'Offres actives dans le pipeline: $offerCount',
    ];

    final quickActions = <String>[
      if (unreadMessages > 0)
        'Réponds à tes conversations non lues pour accélérer les matchs.',
      if (likesSent == 0)
        'Lance quelques likes ciblés pour amorcer de nouvelles opportunités.',
      if (likesReceived > likesSent)
        'Ton profil attire bien: pense à convertir ces signaux en échanges.',
      if (widget.role == UserRole.entreprise || widget.role == UserRole.ecole)
        offerCount == 0
            ? 'Publie au moins une offre pour améliorer ta visibilité.'
            : 'Mets à jour tes offres pour garder un flux de candidats pertinent.',
      if (unreadMessages == 0 && likesSent > 0)
        'Très bon rythme: maintiens cette cadence sur la semaine.',
    ];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Rapport',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Vue détaillée de ton activité et de ta performance.',
            style: TextStyle(color: Colors.black.withValues(alpha: 0.58)),
          ),
          const SizedBox(height: 8),
          Text(
            _lastRefreshLabel(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.46),
            ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            itemCount: cards.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.08,
            ),
            itemBuilder: (_, i) => _ReportCard(data: cards[i]),
          ),
          const SizedBox(height: 16),
          _ReportPanel(
            title: 'Indicateurs avancés',
            icon: Icons.analytics_outlined,
            children: insights
                .map((line) => _ReportBullet(text: line))
                .toList(),
          ),
          const SizedBox(height: 10),
          _ReportPanel(
            title: 'Actions recommandées',
            icon: Icons.bolt_rounded,
            children: quickActions.isEmpty
                ? const [
                    _ReportBullet(
                      text: 'Aucune alerte pour le moment. Continue sur ce rythme.',
                    ),
                  ]
                : quickActions
                      .map((line) => _ReportBullet(text: line))
                      .toList(),
          ),
        ],
      ),
    );
  }
}

class _ReportCardData {
  const _ReportCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.helper,
  });

  final String label;
  final String value;
  final IconData icon;
  final String helper;
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.data});

  final _ReportCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E2E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, size: 18),
          ),
          const Spacer(),
          Text(
            data.value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 3),
          Text(
            data.helper,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}

class _ReportPanel extends StatelessWidget {
  const _ReportPanel({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E3E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _ReportBullet extends StatelessWidget {
  const _ReportBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
