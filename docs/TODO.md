# 📋 TODO — Modifications Backend & Frontend REZO

**Statut:** En cours de planification  
**Total:** 48 tâches (19 backend + 29 frontend)

---

## 🔴 Backend (19 tâches)

### Phase 1: Supprimer le rôle EMPLOI (Tâches 1-4)

- [x] **T1** Backend: Supprimer `UserRole.EMPLOI` de l'enum
  - **Fichier:** `src/main/java/com/rezo/entities/enums/UserRole.java`
  - **Action:** Retirer la ligne `EMPLOI,`
  - **Détail:** Garder seulement: ETUDIANT, LYCEEN, ENTREPRISE, ECOLE, ADMIN

- [x] **T2** Backend: Supprimer cas EMPLOI dans `PackRules.isCandidateRole()`
  - **Fichier:** `src/main/java/com/rezo/backend/service/PackRules.java`
  - **Action:** Modifier la méthode pour retirer `role == UserRole.EMPLOI`
  - **Avant:** `return role == UserRole.ETUDIANT || role == UserRole.LYCEEN || role == UserRole.EMPLOI;`
  - **Après:** `return role == UserRole.ETUDIANT || role == UserRole.LYCEEN;`

- [x] **T3** Backend: Supprimer cas EMPLOI dans `AuthController.parseRole()`
  - **Fichier:** `src/main/java/com/rezo/backend/controller/AuthController.java`
  - **Action:** Retirer le `case "EMPLOI"` de la méthode parseRole()
  - **Détail:** Lancer une exception si la chaîne n'est pas reconnue

- [x] **T4** Backend: Supprimer cas EMPLOI dans MatchController et OfferController
  - **Fichier:** `src/main/java/com/rezo/backend/controller/MatchController.java`
  - **Action:** Vérifier les appels à parseRole() ou enums, retirer les références
  - **Fichier:** `src/main/java/com/rezo/backend/controller/OfferController.java`
  - **Action:** Même chose

---

### Phase 2: Créer le matching Lycéen → Formations (Tâches 5-7)

- [x] **T5** Backend: Créer `GET /api/match/school-recommendations` (Lycéen)
  - **Fichier:** `src/main/java/com/rezo/backend/controller/MatchController.java`
  - **Méthode:** `getSchoolRecommendations(Principal principal, @RequestParam(name = "includeSwiped", defaultValue = "false") boolean includeSwiped, @RequestParam(name = "secteur", required = false) String secteur)`
  - **Logique:**
    - Authentifier le user et vérifier rôle LYCEEN
    - Charger toutes les offres de type FORMATION (où ownerEcole != null)
    - Récupérer les swipes déjà faits par le user (via SwipeRepository)
    - Scorer chaque offre en croisant: centresInteret (lycéen) vs domaines (école), objectifPostbac vs diplomesDelivres
    - Filtrer par secteur si fourni
    - Exclure les swipées sauf si includeSwiped=true
    - Retourner MatchRecommendationsResponse (top 10 par score)
  - **Réutiliser:** Adapter `buildSnapshot()`, `scoreOffer()`, `buildTrace()` existants

- [x] **T6** Backend: Créer entité `ProfileSwipe`
  - **Fichier:** Créer `src/main/java/com/rezo/entities/ProfileSwipe.java`
  - **Champs:**
    ```
    UUID id
    User swiper (ManyToOne) — l'école/entreprise
    User targetUser (ManyToOne) — l'étudiant/lycéen
    SwipeAction action
    LocalDateTime createdAt
    ```
  - **Unique constraint:** (swiper_id, target_user_id)

- [x] **T7** Backend: Créer repository `ProfileSwipeRepository`
  - **Fichier:** Créer `src/main/java/com/rezo/repositories/ProfileSwipeRepository.java`
  - **Méthodes:**
    ```
    Optional<ProfileSwipe> findBySwiperandTargetUser(UUID swiperId, UUID targetUserId);
    List<UUID> findTargetUserIdsBySwiperId(UUID swiperId);
    List<ProfileSwipe> findByTargetUserId(UUID targetUserId);
    ```

---

### Phase 3: Créer le matching par profils pour École/Entreprise (Tâches 8-10)

- [x] **T8** Backend: Créer `GET /api/match/profile-recommendations` (École/Entreprise)
  - **Fichier:** `src/main/java/com/rezo/backend/controller/MatchController.java`
  - **Méthode:** `getProfileRecommendations(Principal principal, @RequestParam(name = "includeSwiped", defaultValue = "false") boolean includeSwiped)`
  - **Logique:**
    - Authentifier et vérifier rôle ECOLE ou ENTREPRISE
    - Pour ENTREPRISE: charger ETUDIANT dont domaine/competences ⊆ secteurActivite entreprise
    - Pour ECOLE: charger ETUDIANT + LYCEEN dont preferencesSecteur/centresInteret ∩ domaines école
    - Récupérer les profileSwipes déjà faits
    - Scorer et trier par score (top 10)
    - Retourner structure: `{ recommendations: [{ userId, prenom, nom, avatarUrl, niveauEtude, domaine, competences, mediaFiles, score }], trace: {...} }`
  - **MediaFiles:** Inclure URL des fichiers (CV, Diplômes, etc.)

- [x] **T9** Backend: Créer `POST /api/match/profile-swipe`
  - **Fichier:** `src/main/java/com/rezo/backend/controller/MatchController.java`
  - **Endpoint:** `POST /api/match/profile-swipe`
  - **Body:** `{ "targetUserId": "uuid", "action": "LIKE" | "DISLIKE" }`
  - **Logique:** 
    - Authentifier (doit être ECOLE ou ENTREPRISE)
    - Vérifier targetUser existe et est ETUDIANT/LYCEEN
    - Créer ou update ProfileSwipe
    - Retourner le ProfileSwipe créé/updaté

- [x] **T10** Backend: Créer `GET /api/match/mutual` (matches mutuels)
  - **Fichier:** `src/main/java/com/rezo/backend/controller/MatchController.java`
  - **Endpoint:** `GET /api/match/mutual`
  - **Logique:**
    - Authentifier
    - Si ETUDIANT/LYCEEN: récupérer les offres où il a LIKE ET le ownerEntreprise/ownerEcole a profile-swipe LIKE sur lui
    - Si ECOLE/ENTREPRISE: récupérer les profils où il a profile-swipe LIKE ET l'étudiant a LIKE une offre
    - Retourner: `{ mutualMatches: [{ otherUserId, otherUserName, avatarUrl, offerTitle, matchedAt }] }`

---

### Phase 4: Matchcount + Messagerie restreinte (Tâches 11-12)

- [x] **T11** Backend: Ajouter `matchCount` à `UserMeResponse` et `/api/users/me`
  - **Fichier:** `src/main/java/com/rezo/backend/dto/user/UserMeResponse.java`
  - **Action:** Ajouter champ `long matchCount;`
  - **Fichier:** `src/main/java/com/rezo/backend/controller/UserController.java` — méthode `getMe()`
  - **Action:** Calculer le nombre de matches mutuels et le passer à UserMeResponse

- [x] **T12** Backend: Restreindre messagerie aux paires matchées
  - **Fichier:** `src/main/java/com/rezo/backend/controller/MessageController.java` — méthode `sendMessage()`
  - **Action:** Après vérification du pack, vérifier qu'il existe un match mutuel entre sender et receiver
  - **Exception:** ADMIN peut bypasser cette vérification
  - **Logique:** Appeler la méthode `isMutualMatch(senderId, receiverId)` avant de créer le message

---

### Phase 5: Médias des offres (Tâches 13-14)

- [x] **T13** Backend: Ajouter `pdfUrl` à entity `Offer` et DTOs
  - **Fichier:** `src/main/java/com/rezo/entities/Offer.java`
  - **Action:** Ajouter champ: `@Column(length = 500) private String pdfUrl;`
  - **Fichier:** `src/main/java/com/rezo/backend/dto/offer/OfferRequest.java`
  - **Action:** Ajouter champ `String pdfUrl;`
  - **Fichier:** `src/main/java/com/rezo/backend/dto/offer/OfferResponse.java`
  - **Action:** Ajouter champ `String pdfUrl;`

- [x] **T14** Backend: Créer `POST /api/offers/{id}/media` pour upload PDF
  - **Fichier:** `src/main/java/com/rezo/backend/controller/OfferController.java`
  - **Endpoint:** `POST /api/offers/{id}/media`
  - **Params:** MultipartFile file
  - **Logique:**
    - Authentifier, vérifier propriétaire de l'offre
    - Valider que c'est un PDF
    - Upload (via UserMediaStorageService ou S3)
    - Mettre à jour Offer.pdfUrl
    - Retourner l'URL du PDF

---

### Phase 6: Médias et validations (Tâches 15-16)

- [x] **T15** Backend: Valider catégories `UserMediaFile` dans UserMediaController
  - **Fichier:** `src/main/java/com/rezo/backend/controller/UserMediaController.java`
  - **Action:** Ajouter validation stricte des catégories:
    ```
    PHOTO (image/*) — tous
    CV (application/pdf) — ETUDIANT
    LM (application/pdf) — ETUDIANT
    DIPLOME (application/pdf) — ETUDIANT
    BULLETIN (application/pdf) — LYCEEN
    JUSTIFICATIF_RECONN (application/pdf) — ECOLE
    JUSTIFICATIF_ENTREPRISE (application/pdf) — ENTREPRISE
    OFFER_BROCHURE (application/pdf) — ECOLE, ENTREPRISE
    ```
  - **Action:** Valider à l'upload que la catégorie demandée correspond au rôle du user

- [x] **T16** Backend: Créer `ChatSupportController` avec `POST /api/chat`
  - **Fichier:** Créer `src/main/java/com/rezo/backend/controller/ChatSupportController.java`
  - **Endpoint:** `POST /api/chat`
  - **Body:** `{ "message": "...", "sessionId": "uuid", "context": "..." }`
  - **Logique:**
    - Authentifier
    - Enregistrer le userMessage dans ChatSupport
    - Appeler une API IA réelle (OpenAI, Mistral) ou retourner une réponse simulée TODO
    - Retourner `{ userMessage, iaResponse, sessionId }`
  - **Endpoint:** `GET /api/chat/history?sessionId={uuid}` — retourner l'historique

---

### Phase 7: Stats + Sécurité (Tâches 17-19)

- [x] **T17** Backend: Créer `GET /api/users/me/stats`
  - **Fichier:** Créer `src/main/java/com/rezo/backend/dto/user/UserStatsResponse.java` OU ajouter dans UserController
  - **Endpoint:** `GET /api/users/me/stats`
  - **Response:**
    ```json
    {
      "matchCount": 3,
      "likesSent": 12,
      "likesReceived": 5,
      "offerCount": 2,
      "unreadMessages": 1
    }
    ```
  - **Logique:** Calculer chaque stat depuis les repositories

- [x] **T18** Backend: Protéger `DELETE /api/auth/users` avec `@Profile("dev")`
  - **Fichier:** `src/main/java/com/rezo/backend/controller/AuthController.java`
  - **Action:** Ajouter `@Profile("dev")` avant la méthode `deleteAllUsers()`
  - **Même action:** Pour `DELETE /api/auth/users/by-email/{email}`

- [x] **T19** Backend: Unifier `/api/features/access-summary` format réponse
  - **Fichier:** `src/main/java/com/rezo/backend/controller/FeatureAccessController.java`
  - **Action:** Modifier la réponse de `/api/features/access-summary` pour retourner:
    ```json
    {
      "messaging": { "allowed": true, "reason": null },
      "chat-ai": { "allowed": false, "reason": "Pack insuffisant", "requiredPack": "Premium" }
    }
    ```
  - **Détail:** Le frontend consolide cette structure

---

## 🟢 Frontend (29 tâches)

### Phase 1: Supprimer le rôle EMPLOI (Tâches 20-23)

- [x] **T20** Frontend: Supprimer `UserRole.emploi` de l'enum
  - **Fichier:** `lib/features/auth/auth_flow.dart`
  - **Action:** Retirer `emploi,` de l'enum UserRole
  - **Ligne:** ~50

- [x] **T21** Frontend: Supprimer cas EMPLOI des extensions UserRole
  - **Fichier:** `lib/features/auth/auth_flow.dart`
  - **Action:** Retirer les `case UserRole.emploi:` de:
    - Extension `UserRoleX` — `apiValue` getter
    - Extension `UserRoleX` — `displayName` getter
    - Extension `UserRoleX` — `dashboardTitle` getter
    - Extension `UserRoleX` — `dashboardSubtitle` getter

- [x] **T22** Frontend: Supprimer formulaire EMPLOI de signup
  - **Fichier:** `lib/features/auth/signup_screen.dart`
  - **Action:** Retirer le `case UserRole.emploi` de `_buildPayload()`
  - **Détail:** Les controllers niveauEtude, etc. restent pour étudiant

- [x] **T23** Frontend: Supprimer option EMPLOI du role selector welcome
  - **Fichier:** `lib/features/auth/auth_flow.dart` (ou welcome_screen.dart si séparé)
  - **Action:** Retirer le bouton/option "En recherche d'emploi" (EMPLOI)
  - **Détail:** Garder seulement 4 options: Étudiant, Lycéen, École, Entreprise

---

### Phase 2: Services — Profils & Stats (Tâches 24-28)

- [x] **T24** Frontend: Ajouter `fetchProfileRecommendations()` dans AuthService interface
  - **Fichier:** `lib/features/auth/services.dart`
  - **Action:** Ajouter méthode abstraite:
    ```dart
    Future<Map<String, dynamic>> fetchProfileRecommendations();
    ```

- [x] **T25** Frontend: Implémenter `fetchProfileRecommendations()` dans HttpAuthService
  - **Fichier:** `lib/features/auth/services.dart`
  - **Action:** Implémenter pour appeler `GET /api/match/profile-recommendations`
  - **Retour:** Parse et retourne la réponse JSON

- [x] **T26** Frontend: Ajouter `recordProfileSwipe()` dans AuthService interface
  - **Fichier:** `lib/features/auth/services.dart`
  - **Action:** Ajouter méthode abstraite:
    ```dart
    Future<Map<String, dynamic>> recordProfileSwipe({
      required String targetUserId,
      required String action, // "LIKE" | "DISLIKE"
    });
    ```

- [x] **T27** Frontend: Implémenter `recordProfileSwipe()` dans HttpAuthService
  - **Fichier:** `lib/features/auth/services.dart`
  - **Action:** Implémenter pour appeler `POST /api/match/profile-swipe`
  - **Body:** JSON avec targetUserId et action

- [x] **T28** Frontend: Exposer fetchProfileRecommendations() et recordProfileSwipe() dans state.dart
  - **Fichier:** `lib/features/auth/state.dart` — classe AppState
  - **Action:** Ajouter deux méthodes qui delegent au _authService

---

### Phase 3: UI — Matching Profils (Tâches 29-30)

- [x] **T29** Frontend: Implémenter `_mapProfileRecommendations()` dans matches_tab.dart
  - **Fichier:** `lib/features/auth/matches_tab.dart`
  - **Logique:** Transformer la réponse `{ recommendations: [...] }` en liste de `_MatchItem`
  - **Afficher:**
    - Photo profil (avatarUrl)
    - Nom, prénom
    - Niveau d'étude / domaine
    - Compétences (tags)
    - Score de correspondance
    - Badge CV/Bulletins si médias présents

- [x] **T30** Frontend: Ajouter logique matching profils dans matches_tab.dart
  - **Fichier:** `lib/features/auth/matches_tab.dart` — `_loadRecommendations()`
  - **Action:** Ajouter branche:
    ```dart
    if (role == UserRole.ecole || role == UserRole.entreprise) {
      final data = await appState.fetchProfileRecommendations();
      mapped = _mapProfileRecommendations(data);
    }
    ```
  - **Détail:** La logique de swipe (`recordProfileSwipe`) reste similaire à `recordSwipe`

---

### Phase 4: UI — Lycéen Secteurs + Matches Mutuels (Tâches 31-35)

- [x] **T31** Frontend: Ajouter filtre secteur pour Lycéen dans matches_tab.dart
  - **Fichier:** `lib/features/auth/matches_tab.dart`
  - **UI:** Ajouter Row de chips au-dessus de la pile (Informatique, Médecine, Droit, etc.)
  - **Action:** Stocker `_selectedSecteur` dans State
  - **Reload:** Recharger les recommendations si le secteur change

- [x] **T32** Frontend: Mettre à jour `fetchSchoolRecommendations()` pour support secteur
  - **Fichier:** `lib/features/auth/services.dart`
  - **Action:** Modifier signature:
    ```dart
    Future<Map<String, dynamic>> fetchSchoolRecommendations({String? secteur});
    ```
  - **Passer:** le secteur en query param `?secteur=...` si fourni

- [x] **T33** Frontend: Ajouter `fetchMutualMatches()` dans AuthService interface
  - **Fichier:** `lib/features/auth/services.dart`
  - **Action:** Ajouter méthode abstraite:
    ```dart
    Future<List<Map<String, dynamic>>> fetchMutualMatches();
    ```

- [x] **T34** Frontend: Implémenter `fetchMutualMatches()` dans HttpAuthService
  - **Fichier:** `lib/features/auth/services.dart`
  - **Action:** Appeler `GET /api/match/mutual` et parser la réponse

- [x] **T35** Frontend: Filtrer conversations aux paires matchées dans messages_tab.dart
  - **Fichier:** `lib/features/auth/messages_tab.dart` — `_MessagesTabState`
  - **Action:** Dans `_bootstrap()`, charger matches mutuels via `fetchMutualMatches()`
  - **Filtre:** Lors du build, afficher les conversations qui correspondent à un match mutuel
  - **Indicateur:** Ajouter badge "Match" sur les paires matchées

---

### Phase 5: Stats Dashboard (Tâches 36-39)

- [x] **T36** Frontend: Ajouter `fetchMyStats()` dans AuthService interface
  - **Fichier:** `lib/features/auth/services.dart`
  - **Action:** Ajouter méthode abstraite:
    ```dart
    Future<Map<String, dynamic>> fetchMyStats();
    ```

- [x] **T37** Frontend: Implémenter `fetchMyStats()` dans HttpAuthService
  - **Fichier:** `lib/features/auth/services.dart`
  - **Action:** Appeler `GET /api/users/me/stats` et retourner

- [x] **T38** Frontend: Exposer `fetchMyStats()` dans state.dart
  - **Fichier:** `lib/features/auth/state.dart` — classe AppState
  - **Action:** Ajouter méthode qui delegue au _authService

- [x] **T39** Frontend: Brancher vraies stats dans home_tab.dart
  - **Fichier:** `lib/features/auth/home_tab.dart` — `_HomeTabState._loadDynamicData()`
  - **Action:** Appeler `appState.fetchMyStats()`
  - **Update:** Remplacer les valeurs fictives des `_StatCard` par `stats['matchCount']`, `stats['likesReceived']`, `stats['unreadMessages']`

---

### Phase 6: Documents Offres (Tâche 40)

- [x] **T40** Frontend: Ajouter upload PDF offres dans offers_tab.dart
  - **Fichier:** `lib/features/auth/offers_tab.dart` — `_OfferFormSheet`
  - **Action:** Ajouter un bouton "Joindre un PDF" (brochure/fiche de poste)
  - **Package:** Utiliser `file_picker` ou `file_picker_mobile`
  - **Upload:** Après création/édition offre, appeler `POST /api/offers/{id}/media`
  - **UI:** Afficher vignette "📄 PDF joint" si PDF déjà présent

---

### Phase 7: Documents Profil par Rôle (Tâches 41-44)

- [x] **T41** Frontend: Ajouter sections CV/LM/Diplômes dans profile_tab.dart (Étudiant)
  - **Fichier:** `lib/features/auth/profile_tab.dart` — `_ProfileTabState`
  - **Sections:**
    - **CV** (catégorie `CV`): 1 PDF max, remplace l'ancien
    - **Lettre de motivation** (catégorie `LM`): 1 PDF max
    - **Justificatifs de diplômes** (catégorie `DIPLOME`): liste de PDFs, multi-upload
  - **Action:** Créer helper `_buildDocSection(String title, String category, bool multiUpload, UserRole role)`

- [x] **T42** Frontend: Ajouter sections Bulletins/Justificatifs dans profile_tab.dart (Lycéen)
  - **Fichier:** `lib/features/auth/profile_tab.dart`
  - **Sections:**
    - **Bulletins scolaires** (catégorie `BULLETIN`): multi-upload
    - **Justificatifs divers** (catégorie `JUSTIFICATIF_RECONN`): multi-upload

- [x] **T43** Frontend: Ajouter sections Justificatifs/Photo dans profile_tab.dart (École)
  - **Fichier:** `lib/features/auth/profile_tab.dart`
  - **Sections:**
    - **Justificatifs de reconnaissance** (catégorie `JUSTIFICATIF_RECONN`): PDFs
    - **Photo de l'établissement** (catégorie `PHOTO`): image (remplace logoUrl si uploadée)

- [x] **T44** Frontend: Ajouter sections Justificatifs/Photo dans profile_tab.dart (Entreprise)
  - **Fichier:** `lib/features/auth/profile_tab.dart`
  - **Sections:**
    - **Justificatifs d'entreprise** (catégorie `JUSTIFICATIF_ENTREPRISE`): KBIS, etc.
    - **Photo/Logo entreprise** (catégorie `PHOTO`): image

---

### Phase 8: Chat IA Réel (Tâches 45-47)

- [x] **T45** Frontend: Ajouter `sendChatMessage()` dans AuthService interface
  - **Fichier:** `lib/features/auth/services.dart`
  - **Action:** Ajouter méthode abstraite:
    ```dart
    Future<Map<String, dynamic>> sendChatMessage({
      required String message,
      required String sessionId,
      String? context,
    });
    ```

- [x] **T46** Frontend: Implémenter `sendChatMessage()` dans HttpAuthService
  - **Fichier:** `lib/features/auth/services.dart`
  - **Action:** Appeler `POST /api/chat` avec message, sessionId, context
  - **Retour:** Parse et retourne `{ userMessage, iaResponse, sessionId }`

- [x] **T47** Frontend: Connecter chat réel dans ai_chat_tab.dart
  - **Fichier:** `lib/features/auth/ai_chat_tab.dart` — `_AiChatTabState._handleSubmit()`
  - **Action:** Remplacer la simulation locale par appel réel:
    ```dart
    final response = await appState.sendChatMessage(
      message: _inputController.text,
      sessionId: _currentSessionId,
      context: _context,
    );
    ```
  - **Garder:** Le cache SharedPreferences pour l'historique local

---

### Phase 9: Nettoyage (Tâche 48)

- [x] **T48** Frontend: Corriger UTF-8 corrompus dans _mapOfferRecommendations()
  - **Fichier:** `lib/features/auth/matches_tab.dart` — `_mapOfferRecommendations()`
  - **Remplacer:**
    - `â€"` → `—` (tiret)
    - `Ã©` → `é` (e accent)
    - `â€"` → `—` autres occurrences
  - **Racine du problème:** PowerShell Set-Content avec BOM UTF-8 — vérifier qu'on n'aura pas ce problème à nouveau

---

## 📊 Vue d'ensemble

| Phase | Backend | Frontend | Total |
|-------|---------|----------|-------|
| 1 — Supprimer EMPLOI | 4 | 4 | 8 |
| 2 — Matching Lycéen | 3 | 0 | 3 |
| 3 — Matching Profils | 3 | 2 | 5 |
| 4 — Matchcount + Messagerie | 2 | 3 | 5 |
| 5 — Médias Offres | 2 | 1 | 3 |
| 6 — Validations + IA | 2 | 0 | 2 |
| 7 — Stats + Sécurité | 3 | 5 | 8 |
| 8 — Chat IA | 0 | 3 | 3 |
| 9 — Nettoyage | 0 | 1 | 1 |
| **Total** | **19** | **29** | **48** |

---

## ✅ Checklist d'avant-livraison

- [ ] Toutes les tâches backend compilent sans erreur (`mvn clean compile`)
- [ ] Toutes les tâches frontend compilent sans warning (`flutter analyze`)
- [ ] Tests unitaires ajoutés pour endpoints critiques (matching, stats, messagerie)
- [ ] Vérifier que les caractères UTF-8 s'affichent correctement (offres, noms, etc.)
- [ ] Tester le flux complet pour chaque rôle (signup → dashboard → matching → messages)
- [ ] Vérifier les permissions et les restrictions de rôle
- [ ] Vérifier que les endpoints `/api/features/access-summary` retournent le bon format

---

**Dernière mise à jour:** 2025-07-09  
**Priorité:** 🔴 Critique > 🟠 Important > 🟡 Améliorations > 🟢 Non bloquant
