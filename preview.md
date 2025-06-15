# Page Principale - Receipt Scanner Flutter

## Structure actuelle de l'écran principal

### Navigation en bas (BottomNavigationBar)
- **6 onglets** avec icônes :
  - 🏠 Accueil (Home)
  - 📷 Scanner (bouton central mis en évidence)
  - ➕ Ajouter manuellement
  - 💰 Budget
  - 📊 Rapports
  - ⚙️ Paramètres

### Contenu de l'onglet Accueil (actuellement affiché)

#### En-tête
- **AppBar** avec le titre "Receipt Scanner"
- Couleur de fond blanche avec texte noir

#### Cartes de statistiques (en haut)
Deux cartes côte à côte :
1. **Budget Total**
   - Affiche le montant total du budget mensuel
   - Format : $0.00 (actuellement vide car pas de budget défini)

2. **Dépenses du mois**
   - Affiche les dépenses du mois en cours
   - Format : $0.00 (actuellement vide car pas de reçus)

#### Section "Reçus récents"
- **Titre** : "Reçus récents" avec un bouton "Voir tout"
- **État actuel** : Carte vide avec message
  - Icône d'horloge grise
  - Titre : "Aucun reçu"
  - Sous-titre : "Commencez par scanner un reçu ou en ajouter un manuellement"

### Fonctionnalités de rafraîchissement
- **Pull-to-refresh** activé pour recharger les données

### Thème et design
- **Couleur principale** : Bleu (#007AFF)
- **Cartes** : Fond blanc avec coins arrondis et ombre légère
- **Typographie** : Police système avec hiérarchie claire
- **Espacement** : Marges de 16px autour du contenu

### État actuel
L'application est fonctionnelle mais vide car :
- Aucun reçu n'a été ajouté
- Aucun budget n'a été configuré
- Les données sont stockées localement avec SharedPreferences

L'interface est prête à recevoir des données une fois que l'utilisateur commencera à :
1. Scanner des reçus avec l'appareil photo
2. Ajouter des reçus manuellement
3. Configurer des budgets par catégorie