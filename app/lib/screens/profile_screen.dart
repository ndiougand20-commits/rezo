import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../models/user.dart';
import '../models/student.dart';
import '../models/high_schooler.dart';
import '../models/company.dart';
import '../models/university.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // On utilise addPostFrameCallback pour s'assurer que le contexte est pleinement
    // disponible et que l'on ne modifie pas l'état pendant la construction.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      if (authProvider.user != null) {
        profileProvider.loadProfile(authProvider.user!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black54),
            onPressed: () {
              // TODO: Navigation vers l'écran d'édition du profil
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Édition du profil bientôt disponible')),
              );
            },
          ),
        ],
      ),
      body: profileProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : profileProvider.error != null
              ? Center(child: Text('Erreur: ${profileProvider.error}'))
              : _buildProfileContent(authProvider.user!, profileProvider.profile),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigation vers l'écran d'édition du profil
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Édition du profil bientôt disponible')),
          );
        },
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        child: const Icon(Icons.edit),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).pushReplacementNamed('/home');
              break;
            case 1:
              // Déjà sur profil
              break;
            case 2:
              Navigator.of(context).pushReplacementNamed('/chat');
              break;
            case 3:
              Navigator.of(context).pushReplacementNamed('/settings');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(User user, dynamic profile) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header avec avatar et informations de base
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getUserTypeIcon(user.userType),
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 16),
                // Nom complet
                Text(
                  '${user.firstName} ${user.lastName}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                // Type d'utilisateur avec badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getUserTypeLabel(user.userType),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Statut
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      user.isActive ? Icons.check_circle : Icons.cancel,
                      color: user.isActive ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user.isActive ? 'Actif' : 'Inactif',
                      style: TextStyle(
                        color: user.isActive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Informations détaillées
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                // Section Informations personnelles
                _buildSectionCard(
                  title: 'Informations personnelles',
                  icon: Icons.person_outline,
                  children: [
                    _buildInfoTile('Email', user.email, Icons.email),
                    _buildInfoTile('Prénom', user.firstName, Icons.badge),
                    _buildInfoTile('Nom', user.lastName, Icons.badge),
                  ],
                ),

                const SizedBox(height: 16),

                // Section Informations professionnelles
                _buildSectionCard(
                  title: 'Informations professionnelles',
                  icon: Icons.business_center,
                  children: _buildSpecificInfoTiles(user.userType, profile),
                ),
              ],
            ),
          ),

          const SizedBox(height: 80), // Espace pour le FAB
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.black, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.black54, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSpecificInfoTiles(UserType userType, dynamic profile) {
    switch (userType) {
      case UserType.student:
        return _buildStudentInfoTiles(profile as Student);
      case UserType.highSchool:
        return _buildHighSchoolerInfoTiles(profile as HighSchooler);
      case UserType.company:
        return _buildCompanyInfoTiles(profile as Company);
      case UserType.university:
        return _buildUniversityInfoTiles(profile as University);
    }
  }

  List<Widget> _buildStudentInfoTiles(Student student) {
    return [
      _buildInfoTile('ID Étudiant', student.id.toString(), Icons.school),
      _buildInfoTile('ID Utilisateur', student.userId.toString(), Icons.account_circle),
      _buildInfoTile('Statut', 'Étudiant actif', Icons.check_circle_outline),
    ];
  }

  List<Widget> _buildHighSchoolerInfoTiles(HighSchooler highSchooler) {
    return [
      _buildInfoTile('ID Lycéen', highSchooler.id.toString(), Icons.school),
      _buildInfoTile('ID Utilisateur', highSchooler.userId.toString(), Icons.account_circle),
      _buildInfoTile('Statut', 'Lycéen actif', Icons.check_circle_outline),
    ];
  }

  List<Widget> _buildCompanyInfoTiles(Company company) {
    return [
      _buildInfoTile('ID Entreprise', company.id.toString(), Icons.business),
      _buildInfoTile('ID Utilisateur', company.userId.toString(), Icons.account_circle),
      _buildInfoTile('Offres publiées', company.offers.length.toString(), Icons.work),
      if (company.offers.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dernières offres',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              ...company.offers.take(3).map((offer) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.work_outline, size: 16, color: Colors.black54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        offer.title,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
    ];
  }

  List<Widget> _buildUniversityInfoTiles(University university) {
    return [
      _buildInfoTile('ID Université', university.id.toString(), Icons.account_balance),
      _buildInfoTile('ID Utilisateur', university.userId.toString(), Icons.account_circle),
      _buildInfoTile('Formations', university.formations.length.toString(), Icons.book),
      if (university.formations.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Formations disponibles',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              ...university.formations.take(3).map((formation) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.book_outlined, size: 16, color: Colors.black54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        formation.title,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
    ];
  }

  IconData _getUserTypeIcon(UserType userType) {
    switch (userType) {
      case UserType.student:
        return Icons.school;
      case UserType.highSchool:
        return Icons.school;
      case UserType.company:
        return Icons.business;
      case UserType.university:
        return Icons.account_balance;
    }
  }

  String _getUserTypeLabel(UserType userType) {
    switch (userType) {
      case UserType.student:
        return 'Étudiant';
      case UserType.highSchool:
        return 'Lycéen';
      case UserType.company:
        return 'Entreprise';
      case UserType.university:
        return 'Université';
      default:
        return 'Inconnu';
    }
  }
}
