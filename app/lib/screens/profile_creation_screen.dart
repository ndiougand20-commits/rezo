// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../models/student.dart';
import '../models/high_schooler.dart';
import '../models/company.dart';
import '../models/university.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ProfileCreationScreen extends StatefulWidget {
  const ProfileCreationScreen({super.key});

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // 1. Ajouter un controller pour le nouveau champ
  final _passwordConfirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    // Ne pas oublier de le "dispose" aussi
    _passwordConfirmController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-fill email if available from auth provider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.email != null) {
      _emailController.text = authProvider.user!.email;
    }
  }

  void _createProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userType = ModalRoute.of(context)!.settings.arguments as UserType;
      User newUser = User(
        id: 0,
        email: _emailController.text,
        userType: userType,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        isActive: true,
      );

      // 3. Mettre à jour l'appel pour inclure la confirmation du mot de passe
      await Provider.of<AuthProvider>(context, listen: false).register(
        newUser,
        _passwordController.text,
        _passwordConfirmController.text, // Argument manquant ajouté
      );

      // NOTE : Cette partie est maintenant redondante car le backend
      // crée le profil spécifique en même temps que l'utilisateur.
      // Vous pouvez la commenter ou la supprimer.
      // await _createSpecificProfile(userType);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la création du profil: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Cette fonction n'est plus nécessaire si votre backend gère la création
  // du profil spécifique (Student, Company, etc.) en même temps que l'User.
  Future<void> _createSpecificProfile(UserType userType) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user!.id;

    switch (userType) {
      case UserType.student:
        await ApiService().createStudent(Student(id: 0, userId: userId));
        break;
      case UserType.highSchool:
        await ApiService().createHighSchooler(HighSchooler(id: 0, userId: userId));
        break;
      case UserType.company:
        await ApiService().createCompany(Company(id: 0, userId: userId, offers: []));
        break;
      case UserType.university:
        await ApiService().createUniversity(University(id: 0, userId: userId, formations: []));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userType = ModalRoute.of(context)!.settings.arguments as UserType;

    return Scaffold(
      appBar: AppBar(title: const Text('Créer votre profil')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          // Remplacé par un ListView pour éviter les problèmes de débordement
          child: ListView(
            children: [
              Text(
                'Inscription en tant que ${userType.name.toUpperCase()}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'Prénom'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre prénom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Veuillez entrer un email valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Mot de passe'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Le mot de passe doit contenir au moins 6 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              // 2. Ajouter le champ de confirmation du mot de passe
              TextFormField(
                controller: _passwordConfirmController,
                decoration: const InputDecoration(labelText: 'Confirmer le mot de passe'),
                obscureText: true,
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Les mots de passe ne correspondent pas';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _createProfile,
                      child: const Text('Créer le profil'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
