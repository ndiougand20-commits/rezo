import 'package:flutter/material.dart';
import '../models/user.dart';

class UserTypeSelectionScreen extends StatefulWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  State<UserTypeSelectionScreen> createState() => _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState extends State<UserTypeSelectionScreen> {
  UserType? _selectedUserType;

  void _selectUserType(UserType type) {
    setState(() {
      _selectedUserType = type;
    });
  }

  void _continue() {
    if (_selectedUserType != null) {
      Navigator.of(context).pushNamed('/profile_creation', arguments: _selectedUserType);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choisir votre type d\'utilisateur')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Quel type d\'utilisateur êtes-vous ?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _buildUserTypeCard(UserType.student, 'Étudiant', Icons.school),
            const SizedBox(height: 20),
            _buildUserTypeCard(UserType.highSchool, 'Lycéen', Icons.account_balance),
            const SizedBox(height: 20),
            _buildUserTypeCard(UserType.company, 'Entreprise', Icons.business),
            const SizedBox(height: 20),
            _buildUserTypeCard(UserType.university, 'Université', Icons.account_balance_wallet),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _selectedUserType != null ? _continue : null,
              child: const Text('Continuer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeCard(UserType type, String label, IconData icon) {
    bool isSelected = _selectedUserType == type;
    return GestureDetector(
      onTap: () => _selectUserType(type),
      child: Card(
        elevation: isSelected ? 8 : 2,
        color: isSelected ? Colors.blue.shade50 : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: isSelected ? Colors.blue : Colors.grey),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.blue : Colors.black,
                ),
              ),
              const Spacer(),
              if (isSelected) const Icon(Icons.check_circle, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }
}
