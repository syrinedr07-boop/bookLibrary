# TestBook

Application SwiftUI de recherche de livres via Google Books, en Clean Architecture et MVVM, sans dépendance tierce.

## Fonctionnalités

- Sélection initiale de fiction, recherche avec temporisation de 350 ms.
- Liste des couvertures, titres, auteurs et dates ; fiche de détail et lien Google Books.
- Favoris depuis la liste et la fiche : cœur rouge si sélectionné, second appui pour retirer. Livres enregistrés en JSON dans Application Support et restaurés au lancement.
- Pagination par 20, déduplication, actualisation, états vide/chargement/erreur et nouvelle tentative.
- Protection contre les résultats obsolètes et annulation des recherches liées à la vue.

## Architecture et injection de dépendances

```text
App/TestBookApp → AppContainer (composition)
                        ↓
Presentation : Views → BooksListViewModel
                        ↓
Domain : SearchBooksUseCase → BooksRepository (protocole)
                                     ↑
Data :                    GoogleBooksRepository → HTTPClient → URLSessionHTTPClient → URLSession
```

Le domaine ne dépend ni de SwiftUI, ni de la couche Data. Les DTO et erreurs HTTP restent dans Data. Le ViewModel est isolé sur MainActor. Les dépendances sont injectées par constructeur : cas d’usage dans le ViewModel, repository dans le cas d’usage, client HTTP et clé dans le repository, session dans le client HTTP. AppContainer est le seul endroit qui assemble les implémentations réelles et lit la configuration.

Le protocole `HTTPClient` et son implémentation `URLSessionHTTPClient` sont dans `Data/Networking`. Le client valide les réponses HTTP et renvoie les données brutes ; le repository construit les requêtes Google Books, décode les DTO et traduit les erreurs HTTP en erreurs propres au service. Les erreurs de transport et les annulations sont propagées.

## Clé Google Books

Références : [utilisation et clé API](https://developers.google.com/books/docs/v1/using?hl=fr#APIKey), [premiers pas](https://developers.google.com/books/docs/v1/getting_started?hl=fr).

1. Sélectionner ou créer un projet dans [Google Cloud](https://console.cloud.google.com/).
2. Activer **Books API** dans la bibliothèque d’API.
3. Dans [API et services → Identifiants](https://console.cloud.google.com/apis/credentials), choisir **Créer des identifiants → Clé API**.
4. Restreindre l’accès de la clé à Books API ; configurer les restrictions applicatives compatibles avec le mode d’appel avant distribution.
5. Ouvrir `Configuration/Secrets.xcconfig` (déjà créé localement) et renseigner :

```xcconfig
GOOGLE_BOOKS_API_KEY = votre_cle_google_cloud
```

Sur un nouveau checkout, copier `Configuration/Secrets.xcconfig.example` vers `Configuration/Secrets.xcconfig`. Ce fichier est ignoré par Git. Debug et Release incluent cette configuration ; `AppInfo.plist` transmet la valeur à `AppContainer`. Une variable d’environnement `GOOGLE_BOOKS_API_KEY` du schéma Xcode peut remplacer la valeur pour un lancement local. Ne pas partager un schéma contenant une clé.

La documentation ne fournit aucune clé utilisable : la création nécessite un compte et un projet Google Cloud. Aucun OAuth n’est nécessaire pour rechercher ces livres publics ; la clé identifie le projet et ses quotas. Les requêtes utilisent `https://www.googleapis.com/books/v1/volumes` avec `q`, `startIndex`, `maxResults`, `printType=books` et `key`.

Une clé intégrée à une application peut être extraite du binaire : l’exclusion Git ne la rend pas secrète dans l’application distribuée. Ne pas journaliser les URL contenant la clé.

## Lancement

Ouvrir `TestBook.xcodeproj`, sélectionner le schéma TestBook puis un simulateur iOS 27 et lancer avec Cmd+R. Les versions cibles du projet d’origine ont été conservées. Xcode 27 est installé dans `/Applications/Xcode.app` sur cette machine ; le répertoire développeur global pointe sur les Command Line Tools, d’où le préfixe ci-dessous.

## Tests

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project TestBook.xcodeproj -scheme TestBook \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -derivedDataPath /tmp/TestBookDerivedData \
  -only-testing:TestBookTests test
```

- `TestBookTests/Unit` : normalisation/requête vide, succès, erreur, pagination/doublons, nouvelle tentative, nouvelle recherche, annulation et réponse obsolète ; injection d’un faux client HTTP et mapping des erreurs du repository.
- `TestBookTests/Integration` : chaîne ViewModel → cas d’usage → repository → HTTPClient → URLSession → décodage ; encodage des paramètres, métadonnées absentes, page vide/complète, HTTP 403/429/500, JSON invalide et panne réseau. Le client HTTP est aussi testé directement pour les statuts 2xx/non-2xx, les réponses non HTTP et les erreurs de transport.
- Favoris : tests unitaires de reprise après échec de lecture ou d’écriture, conservation de la sélection et identité par identifiant malgré un changement de métadonnées. Les intégrations de persistance utilisent des répertoires temporaires isolés et vérifient le premier lancement, la création de sous-répertoires, le remplacement par une liste vide et la reprise après réparation d’un fichier corrompu.
- Les intégrations interceptent URLSession via URLProtocol et ne contactent pas Google. Elles ne nécessitent pas de vraie clé et ne vérifient pas la validité d’une clé ou le quota Google.

Aucun push Git n’est effectué par cette tâche.

## Agents de développement

Deux profils locaux sont définis dans `../.codex/agents/` (ouvrir le workspace TestIOS dans Codex) :

- `ios_developer` : code Swift/SwiftUI, Clean MVVM, injection de dépendances et corrections.
- `ios_tester` : tests unitaires et d’intégration, tests UI si nécessaires, exécution et rapport des régressions.

Exemple de demande : « Utilise ios_developer pour ajouter les favoris et ios_tester pour écrire et exécuter les tests associés. »

L’agent principal coordonne leurs échanges. Les contrats sont partagés avant les modifications ; les tests sont exécutés après stabilisation du code. Les profils héritent du modèle et des permissions de la session. Ce sont des configurations réutilisables, pas des processus actifs en permanence. Si les profils ne sont pas disponibles dans la session courante, ouvrir une nouvelle session sur TestIOS. Aucun push Git n’est autorisé.

Format suivi : [documentation officielle des sous-agents Codex](https://learn.chatgpt.com/docs/agent-configuration/subagents).
