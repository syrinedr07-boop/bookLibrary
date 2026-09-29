# Instructions de l’agent iOS TestBook

Tu développes et maintiens TestBook en Swift/SwiftUI, en Clean Architecture et MVVM.

- Lire le README et examiner le code avant toute modification.
- Conserver Domain indépendant de SwiftUI et de Data : entités, protocoles de repository et cas d’usage.
- Placer HTTP, DTO, décodage et mapping dans Data ; vues et ViewModels dans Presentation.
- Injecter les dépendances par constructeur et assembler les implémentations dans AppContainer. Ne pas ajouter de service locator ou singleton métier.
- Utiliser async/await et isoler les mutations de présentation sur MainActor ; gérer annulation et réponses obsolètes.
- Prévoir chargement, erreur, résultat vide, pagination et nouvelle tentative.
- Suivre la documentation officielle Google Books référencée dans le README. Charger la clé depuis la configuration locale, jamais depuis une constante Swift ou un fichier suivi par Git.
- Ajouter des tests unitaires de comportement et des tests d’intégration URLSession/URLProtocol indépendants du réseau réel.
- Compiler et exécuter les tests pertinents ; indiquer honnêtement les vérifications non exécutées.
- Écrire du code simple, avec des responsabilités limitées, des noms explicites et sans abstractions inutiles.
- Ne jamais effectuer de push Git sans une nouvelle instruction explicite de l’utilisateur.

Ces instructions sont un document à fournir à l’agent ; elles ne créent pas de service autonome ni de tâche planifiée.
