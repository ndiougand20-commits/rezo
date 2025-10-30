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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    if (authProvider.user != null) {
      profileProvider.loadProfile(authProvider.user!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: profileProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
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
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).pushReplacementNamed('/home');
              break;
            case 1:
              Navigator.of(context).pushNamed('/chat');
              break;
            case 2:
              // Déjà sur profile
              break;
            case 3:
              authProvider.logout();
              profileProvider.clearProfile();
              Navigator.of(context).pushReplacementNamed('/login');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Déconnexion',
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(User user, dynamic profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informations de base
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informations personnelles',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16.0),
                  _buildInfoRow('Nom', '${user.firstName} ${user.lastName}'),
                  _buildInfoRow('Email', user.email),
                  _buildInfoRow('Type', _getUserTypeLabel(user.userType)),
                  _buildInfoRow('Statut', user.isActive ? 'Actif' : 'Inactif'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16.0),

          // Informations spécifiques au type d'utilisateur
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informations professionnelles',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16.0),
                  _buildSpecificInfo(user.userType, profile),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildSpecificInfo(UserType userType, dynamic profile) {
    switch (userType) {
      case UserType.student:
        return _buildStudentInfo(profile as Student);
      case UserType.highSchool:
        return _buildHighSchoolerInfo(profile as HighSchooler);
      case UserType.company:
        return _buildCompanyInfo(profile as Company);
      case UserType.university:
        return _buildUniversityInfo(profile as University);
    }
  }

  Widget _buildStudentInfo(Student student) {
    return Column(
      children: [
        _buildInfoRow('ID Étudiant', student.id.toString()),
        _buildInfoRow('ID Utilisateur', student.userId.toString()),
        const Text('Informations supplémentaires à venir...'),
      ],
    );
  }

  Widget _buildHighSchoolerInfo(HighSchooler highSchooler) {
    return Column(
      children: [
        _buildInfoRow('ID Lycéen', highSchooler.id.toString()),
        _buildInfoRow('ID Utilisateur', highSchooler.userId.toString()),
        const Text('Informations supplémentaires à venir...'),
      ],
    );
  }

  Widget _buildCompanyInfo(Company company) {
    return Column(
      children: [
        _buildInfoRow('ID Entreprise', company.id.toString()),
        _buildInfoRow('ID Utilisateur', company.userId.toString()),
        _buildInfoRow('Offres publiées', company.offers?.length.toString() ?? '0'),
        const Text('Informations supplémentaires à venir...'),
      ],
    );
  }

  Widget _buildUniversityInfo(University university) {
    return Column(
      children: [
        _buildInfoRow('ID Université', university.id.toString()),
        _buildInfoRow('ID Utilisateur', university.userId.toString()),
        _buildInfoRow('Formations', university.formations?.length.toString() ?? '0'),
        const Text('Informations supplémentaires à venir...'),
      ],
    );
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
