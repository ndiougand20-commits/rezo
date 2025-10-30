# TODO - Développement Frontend Flutter pour Rezo

## Étape 1 : Mettre à jour pubspec.yaml avec dépendances
- [x] Ajouter http, provider, flutter_card_swiper, shared_preferences, intl
- [x] Exécuter flutter pub get
- [x] Tester build avec flutter build apk
- [x] Commiter les changements

## Étape 2 : Créer modèles Flutter
- [x] Créer classes Dart pour User, Student, HighSchooler, Company, University, Offer, Formation
- [x] Basées sur les schémas backend
- [x] Commiter

## Étape 3 : Créer service API
- [x] Classe pour requêtes HTTP vers backend
- [x] Méthodes pour GET/POST vers localhost:8000
- [x] Commiter

## Étape 4 : Implémenter authentification
- [x] Écrans login/register avec sélection type utilisateur
- [x] Ajouter endpoints backend si nécessaire (auth avec JWT)
- [x] Commiter

## Étape 5 : Ajouter sélection type utilisateur et profils
- [x] Écran pour choisir type, puis création/édition de profil
- [x] Commiter

## Étape 6 : Implémenter écrans de swipe
- [x] Swipe pour offres (étudiants) et formations (lycéens)
- [x] Appels API pour récupérer données
- [x] Commiter

## Étape 7 : Ajouter écrans de profils
- [x] Visualisation/édition de profils utilisateur, entreprise, université
- [x] Commiter

## Étape 8 : Implémenter messagerie
- [x] Écrans de chat
- [x] Ajouter modèle Message et endpoints backend si nécessaire
- [x] Commiter

## Étape 9 : Ajouter notifications et matching
- [ ] Ajouter modèle Match et device_token dans backend/models.py
- [ ] Ajouter schémas pour Match dans backend/schemas.py
- [ ] Ajouter CRUD pour Match dans backend/crud.py
- [ ] Ajouter endpoints pour liking et device token dans backend/main.py
- [ ] Ajouter firebase-admin à backend/requirements.txt et intégrer FCM
- [ ] Ajouter firebase_messaging à app/pubspec.yaml
- [ ] Créer modèle Match dans app/lib/models/match.dart
- [ ] Mettre à jour ApiService pour liking et device token
- [ ] Mettre à jour SwipeProvider pour appeler API sur swipe right
- [ ] Créer NotificationProvider pour gérer notifications
- [ ] Commiter

## Étape 10 : Tester et polir
- [ ] Intégration complète, tests UI, corrections bugs
- [ ] Commiter final
