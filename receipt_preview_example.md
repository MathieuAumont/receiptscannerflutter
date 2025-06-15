# Aperçu d'une Facture - Receipt Scanner Flutter

## Interface de détail d'un reçu

Voici à quoi ressemble l'écran de détail d'une facture une fois qu'un reçu est ajouté :

### En-tête de l'écran
- **AppBar** avec titre "Détails du reçu"
- Bouton retour (flèche gauche)
- Menu contextuel (3 points) avec options :
  - ✏️ Modifier
  - 🗑️ Supprimer

### Carte d'en-tête du reçu
**Design** : Carte blanche avec coins arrondis et ombre légère

**Contenu** :
- **Icône de catégorie** : Cercle coloré avec emoji (ex: 🛍️ pour Shopping)
- **Nom du magasin** : "Metro Plus" (en gros titre)
- **Date** : "Vendredi, 15 décembre 2024" (en gris)
- **Badge de catégorie** : "Shopping" avec fond coloré

### Carte des articles
**Titre** : "Articles"

**Liste des items** :
```
Lait 2% - Qty: 2          $6.98
Pain tranché - Qty: 1     $3.49
Pommes Gala - Qty: 1      $4.25
Fromage cheddar - Qty: 1  $7.99
```

### Carte de résumé financier
**Titre** : "Summary"

**Détails** :
```
Sous-total             $22.71
TPS (5%)               $1.14
TVQ (9.975%)           $2.27
─────────────────────────────
Total                  $26.12
```

### Carte des notes (si présente)
**Titre** : "Notes"
**Contenu** : "Épicerie hebdomadaire - promotion sur le fromage"

## Caractéristiques visuelles

### Couleurs et thème
- **Fond** : Gris très clair (#F5F5F5)
- **Cartes** : Blanc avec ombre subtile
- **Couleur principale** : Bleu (#007AFF)
- **Texte principal** : Noir
- **Texte secondaire** : Gris (#666666)

### Typographie
- **Nom du magasin** : Titre large et gras
- **Montants** : Police monospace pour l'alignement
- **Total** : Mis en évidence en couleur principale

### Espacement et layout
- **Marges** : 16px autour du contenu
- **Espacement entre cartes** : 16px
- **Padding interne des cartes** : 16px
- **Coins arrondis** : 12px sur toutes les cartes

### Interactions
- **Scroll vertical** pour voir tout le contenu
- **Boutons d'action** dans le menu contextuel
- **Navigation** fluide avec animations

## États possibles

### Avec données complètes
- Toutes les sections sont visibles
- Calculs automatiques corrects
- Catégorie avec icône colorée

### Données minimales
- Seules les sections essentielles (en-tête, total)
- Pas de notes si non renseignées
- Articles basiques sans détails

### Métadonnées OCR (si scanné)
- Badge "Scanné" avec confiance du traitement
- Horodatage du traitement
- Version du moteur OCR utilisé

L'interface est conçue pour être claire, lisible et permettre une consultation rapide des informations importantes de chaque reçu.