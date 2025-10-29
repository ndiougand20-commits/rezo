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
- [ ] Écran pour choisir type, puis création/édition de profil
- [ ] Commiter

## Étape 6 : Implémenter écrans de swipe
- [ ] Swipe pour offres (étudiants) et formations (lycéens)
- [ ] Appels API pour récupérer données
- [ ] Commiter

## Étape 7 : Ajouter écrans de profils
- [ ] Visualisation/édition de profils utilisateur, entreprise, université
- [ ] Commiter

## Étape 8 : Implémenter messagerie
- [ ] Écrans de chat
- [ ] Ajouter modèle Message et endpoints backend si nécessaire
- [ ] Commiter

## Étape 9 : Ajouter notifications et matching
- [ ] Intégrer notifications push, logique de matching
- [ ] Commiter

## Étape 10 : Tester et polir
- [ ] Intégration complète, tests UI, corrections bugs
- [ ] Commiter final
