part of 'auth_flow.dart';

class _ReportTab extends StatefulWidget {
  const _ReportTab({required this.role});

  final UserRole role;

  @override
  State<_ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<_ReportTab> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _stats = const <String, dynamic>{};

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

    final cards = <_ReportCardData>[
      _ReportCardData(
        label: 'Matchs',
        value: _n('matchCount').toString(),
        icon: Icons.favorite_rounded,
      ),
      _ReportCardData(
        label: 'Likes reçus',
        value: _n('likesReceived').toString(),
        icon: Icons.thumb_up_alt_rounded,
      ),
      _ReportCardData(
        label: 'Messages non lus',
        value: _n('unreadMessages').toString(),
        icon: Icons.mark_chat_unread_rounded,
      ),
    ];

    if (widget.role == UserRole.entreprise || widget.role == UserRole.ecole) {
      cards.add(
        _ReportCardData(
          label: 'Offres dispo',
          value: _n('offerCount').toString(),
          icon: Icons.work_rounded,
        ),
      );
    }

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
          const Text(
            'Vue synthétique de ton activité.',
            style: TextStyle(color: Colors.black54),
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
              childAspectRatio: 1.2,
            ),
            itemBuilder: (_, i) => _ReportCard(data: cards[i]),
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
  });

  final String label;
  final String value;
  final IconData icon;
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
        ],
      ),
    );
  }
}
