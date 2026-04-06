# Terrarihome — Document de Game Design

## 1. Vue d'ensemble

**Genre** : Puzzle de placement de cartes / progression idle
**Moteur** : Godot 4.5
**Plateformes** : PC + Mobile
**Style graphique** : Pixel art / retro
**Langues** : Francais & Anglais
**Concept** : Construire et faire pousser un terrarium en placant des plantes sur une grille, en creant des combos malins, et en faisant des prestiges pour debloquer du nouveau contenu.

### Boucle de jeu

```
Placer des plantes sur la grille → Marquer des points via les combos d'adjacence
        ↓                                    ↓
Acheter des packs de cartes ← ← ← ← Points gagnes
        ↓
   Prestige (50+ pts)
        ↓
 Debloquer des ameliorations → Meilleur etat de depart → Placer des plantes...
```

Le jeu est **libre** — pas de structure de tours. Les joueurs placent des cartes, achetent des packs et font des prestiges quand ils veulent. Le jeu se termine quand le joueur achete l'**amelioration de prestige finale** sur la branche principale, qui necessite que toutes les autres branches soient completees.

---

## 2. Systeme de Grille

### Grille de base
- **18 colonnes x 8 lignes** (orientation paysage)
- Les cases sont soit **vides**, **occupees** (par une plante), ou **bloquees** (par du terrain/trou de pelle)
- Les plantes ne peuvent pas chevaucher des cases occupees ou bloquees

### Adjacence
- **Orthogonale uniquement** (haut, bas, gauche, droite — 4 voisins par case)
- Les diagonales ne comptent PAS
- Chaque case d'une plante multi-cases verifie l'adjacence **independamment**

Exemple : Une Carotte (2 cases verticales) a jusqu'a **6 voisins uniques** (4 pour la case du haut + 4 pour celle du bas - 2 partagees = 6 uniques, mais le scoring verifie chaque case separement, donc un voisin partage declenche deux fois — une pour le haut, une pour le bas).

### Extension de grille (Prestige)
De nouveaux **patchs de grille** peuvent etre debloques via le prestige, places a cote de la grille principale. Chaque patch introduit un **biome** avec des proprietes uniques :

| Biome | Proprietes |
|-------|-----------|
| Standard | Pas d'effets speciaux |
| Rocheux | Contient des **cases rocheuses** — bloquees, impossible de planter |
| Riviere | Contient des **cases riviere** — bloquees, mais donnent **+1 permanent a tous les gains futurs** des cases adjacentes (comme l'engrais) |
| *A co-designer...* | |

**Taille des patchs** : 6x4 cases (24 cases par extension).
**Disposition du terrain** : Aleatoire a chaque prestige (les rochers et rivieres sont places aleatoirement dans le patch). Chaque run est different.
**Placement des patchs** : Adjacents a la grille principale ou a un patch existant.

---

## 3. Systeme de Plantes

### Modele de donnees
Chaque plante a :
- **Nom** (FR + EN)
- **Forme** : tableau de decalages de cases depuis l'origine `(0,0)` — **orientation fixe, pas de rotation**
- **Types** : un ou plusieurs tags (Legume, Plante, Champi, Racine...)
- **Regle de combo** : comment la plante marque des points
- **Mode de scoring** : `bidirectionnel` (par defaut) ou `au_placement_uniquement`

### Tags de types

| Tag | Icone | Description |
|-----|-------|-------------|
| Legume | 🥕 | Legumes |
| Plante | 🌱 | Plantes/herbes generiques |
| Champi | 🍄‍🟫 | Champignons non-toxiques |
| Champi Toxique | 🍄 | Champignons toxiques *(contenu futur)* |
| Racine | 🪾 | Legumes-racines |

### Plantes de base (disponibles au depart)

#### Carotte x2
```
[X]
[X]
```
- **Forme** : `[(0,0), (0,1)]` (vertical 1x2)
- **Types** : Legume 🥕
- **Combo** : +1 point par case adjacente de type Legume 🥕
- **Scoring** : Bidirectionnel
- **Copies de depart** : 2

#### Herberaude x2
```
[X]
```
- **Forme** : `[(0,0)]` (case unique)
- **Types** : Plante 🌱
- **Combo** : +1 point fixe au placement (pas d'adjacence)
- **Scoring** : Au placement uniquement (bonus fixe, pas de re-declenchement)
- **Copies de depart** : 2

#### Boutomate x1
```
[X][X]
```
- **Forme** : `[(0,0), (1,0)]` (horizontal 2x1)
- **Types** : Legume 🥕
- **Combo** : +1 point par case adjacente de type Legume 🥕 OU de type Plante 🌱
- **Scoring** : Bidirectionnel
- **Copies de depart** : 1

### Plantes de prestige (a debloquer)

#### Truffe
```
[X][X]
[X][X]
```
- **Forme** : `[(0,0), (1,0), (0,1), (1,1)]` (carre 2x2)
- **Types** : Champi 🍄‍🟫
- **Combo** : +1 point par case adjacente de type Champi 🍄‍🟫 (exclut les Champi Toxique 🍄)
- **Scoring** : Bidirectionnel

#### Gingembre Tourne-Vent
```
   [X]
[X][X][X]
   [X]
```
- **Forme** : `[(1,0), (0,1), (1,1), (2,1), (1,2)]` (croix/plus, 5 cases)
- **Types** : Legume 🥕, Racine 🪾
- **Combo** : **Modificateur** — toutes les cases adjacentes de type Legume 🥕 gagnent un **multiplicateur x2 sur les points futurs**. Ne double PAS retroactivement les points existants. Ne double PAS les autres multiplicateurs (empilement additif, pas multiplicatif).
- **Scoring** : Modificateur applique au placement (bidirectionnel pour l'effet modificateur)

#### Champi-mi-gnon
```
[X]
```
- **Forme** : `[(0,0)]` (case unique)
- **Types** : Champi 🍄‍🟫
- **Combo** : +1 point par **case occupee** adjacente (tout type, toute plante)
- **Scoring** : **Au placement uniquement** — ne re-score PAS quand de nouvelles plantes sont placees a cote

### Plantes de base supplementaires (dans les packs de depart)

Ces plantes sont disponibles des le debut dans les packs de depart.

#### Persil Piquant
```
[X][X][X]
```
- **Forme** : `[(0,0), (1,0), (2,0)]` (horizontal 3x1)
- **Types** : Plante 🌱
- **Combo** : +1 pt par case adjacente de type Plante 🌱
- **Scoring** : Bidirectionnel
- **Compost** : 2

#### Cactus Epineux
```
[X]
```
- **Forme** : `[(0,0)]` (case unique)
- **Types** : Plante 🌱
- **Combo** : +1 pt par case **vide** adjacente (recompense l'isolation, 0-4 pts selon le placement)
- **Scoring** : Au placement uniquement
- **Compost** : 1

#### Basilic Royal
```
[X]
[X][X]
```
- **Forme** : `[(0,0), (0,1), (1,1)]` (petit L, 3 cases)
- **Types** : Plante 🌱, Legume 🥕
- **Combo** : +1 pt par case adjacente de type Legume 🥕
- **Scoring** : Bidirectionnel
- **Compost** : 2

#### Patate Douce
```
[X][X]
[X]
```
- **Forme** : `[(0,0), (1,0), (0,1)]` (L, 3 cases)
- **Types** : Legume 🥕, Racine 🪾
- **Combo** : +1 pt par case adjacente de type Racine 🪾
- **Scoring** : Bidirectionnel
- **Compost** : 2

#### Radis Rose
```
[X]
```
- **Forme** : `[(0,0)]` (case unique)
- **Types** : Legume 🥕, Racine 🪾
- **Combo** : +2 pts fixe au placement
- **Scoring** : Au placement uniquement
- **Compost** : 1

### Plantes de prestige (a debloquer)

Ces plantes sont debloquees via l'arbre de prestige et apparaissent dans les packs correspondants.

#### Mousse Lunaire
```
[X][X]
```
- **Forme** : `[(0,0), (1,0)]` (horizontal 2x1)
- **Types** : Plante 🌱
- **Combo** : +1 pt par case adjacente de type Plante 🌱 OU Champi 🍄‍🟫
- **Scoring** : Bidirectionnel
- **Compost** : 2

#### Morille Doree
```
[X]
[X]
[X]
```
- **Forme** : `[(0,0), (0,1), (0,2)]` (vertical 1x3)
- **Types** : Champi 🍄‍🟫
- **Combo** : +1 pt par case adjacente de type Champi 🍄‍🟫
- **Scoring** : Bidirectionnel
- **Compost** : 2

#### Pleurote Cascade
```
[X]
[X][X]
   [X]
```
- **Forme** : `[(0,0), (0,1), (1,1), (1,2)]` (S/zigzag, 4 cases)
- **Types** : Champi 🍄‍🟫
- **Combo** : +1 pt par case adjacente de type Champi 🍄‍🟫 OU Plante 🌱
- **Scoring** : Bidirectionnel
- **Compost** : 3

#### Navet Tournoyant
```
[X]
[X]
```
- **Forme** : `[(0,0), (0,1)]` (vertical 1x2)
- **Types** : Racine 🪾, Legume 🥕
- **Combo** : **Modificateur** — les cases adjacentes de type Racine 🪾 gagnent **+1 a tous les gains futurs** (comme l'engrais mais uniquement pour les Racines). Non retroactif.
- **Scoring** : Modificateur bidirectionnel
- **Compost** : 2

#### Ail des Ours
```
   [X]
[X][X][X]
```
- **Forme** : `[(1,0), (0,1), (1,1), (2,1)]` (T inversé, 4 cases)
- **Types** : Legume 🥕, Racine 🪾
- **Combo** : +1 pt par case adjacente de type Legume 🥕 OU Racine 🪾
- **Scoring** : Bidirectionnel
- **Compost** : 3

#### Fougere d'Or
```
[X]
[X]
[X]
[X]
```
- **Forme** : `[(0,0), (0,1), (0,2), (0,3)]` (vertical 1x4)
- **Types** : Plante 🌱
- **Combo** : +1 pt par case adjacente de type Plante 🌱. +1 pt bonus si adjacente a une case riviere.
- **Scoring** : Bidirectionnel
- **Compost** : 3

#### Fraise Sauvage
```
[X][X]
[X][X]
[X]
```
- **Forme** : `[(0,0), (1,0), (0,1), (1,1), (0,2)]` (5 cases, forme de goutte)
- **Types** : Legume 🥕, Plante 🌱
- **Combo** : +1 pt par case adjacente de type Legume 🥕 OU Plante 🌱
- **Scoring** : Bidirectionnel
- **Compost** : 4

### Valeurs de compost des plantes de base

| Plante | Compost |
|--------|---------|
| Herberaude | 1 |
| Carotte | 1 |
| Boutomate | 2 |
| Truffe | 2 |
| Champi-mi-gnon | 1 |
| Gingembre Tourne-Vent | 3 |

### Plantes futures (contenu futur)

> **A DESIGNER PLUS TARD** :
> - Champignons toxiques 🍄 (la distinction existe dans les regles de la Truffe)
> - Fleurs (nouveau type ?)
> - Plantes legendaires a formes tres complexes

---

## 4. Moteur de Scoring

### Flux de scoring au placement

Quand une plante est placee a la position P :

```
PHASE 1 — MODIFICATEURS (d'abord)
1. Si la nouvelle plante est un modificateur (Gingembre, Navet Tournoyant) :
   → Appliquer ses effets aux cases adjacentes eligibles
2. Si des plantes existantes sont des modificateurs adjacents a la nouvelle plante :
   → Appliquer leurs effets aux cases de la nouvelle plante

PHASE 2 — SCORING (ensuite, avec tous les modifs actifs)
3. Pour chaque case C de la plante nouvellement placee :
   a. Verifier les 4 voisins orthogonaux de C
   b. Appliquer la regle de combo de la NOUVELLE plante contre chaque voisin
   c. Calculer les points (en tenant compte des modifs x2, +1 engrais, +1 riviere)

4. Pour chaque plante existante adjacente a la nouvelle plante :
   a. Pour chaque case C de la plante EXISTANTE :
      b. Verifier si une case de la NOUVELLE plante est adjacente a C
      c. Si oui, appliquer la regle de combo de la plante EXISTANTE
      d. Calculer les points (avec modifs actifs sur cette case)
   (Ignorer si le mode de scoring est "au_placement_uniquement")
```

**Regle importante** : Les modificateurs s'appliquent AVANT le scoring. Quand on pose un Gingembre a cote d'une Carotte, la Carotte re-score avec le x2 deja actif.

### Scoring de l'Arrosoir

L'arrosoir re-declenche les plantes mais **sans cascade** :
1. Identifier toutes les plantes ayant au moins 1 case dans la zone
2. Chaque plante identifiee re-score toutes ses cases (meme celles hors de la zone)
3. Les re-scores ne declenchent PAS de re-score bidirectionnel chez les voisins
4. Les modificateurs actifs (x2, engrais, riviere) s'appliquent normalement

### Grille pleine

Si la grille est pleine et la main est pleine, le joueur **doit faire un prestige** (s'il a 50+ pts). Si le joueur n'a pas 50 pts et ne peut plus rien placer, la partie est bloquee — situation normalement evitee par la grande taille de la grille (144+ cases).

### Exemples de scoring

**Exemple 1 : Deux Carottes cote a cote**
```
[A][B]
[A][B]
```
Carotte A placee en premier (0 Legumes adjacents → 0 points bonus).
Carotte B placee a cote de A :
- Case haute de B : 1 case Legume adjacente (haut de A) → +1 pt
- Case basse de B : 1 case Legume adjacente (bas de A) → +1 pt
- A re-score (bidirectionnel) :
  - Case haute de A : 1 case Legume adjacente (haut de B) → +1 pt
  - Case basse de A : 1 case Legume adjacente (bas de B) → +1 pt
- **Total de ce placement : 4 points**

**Exemple 2 : Boutomate a cote d'Herberaude**
```
[H][B][B]
```
Herberaude placee en premier : +1 pt fixe.
Boutomate placee a cote d'Herberaude :
- Case gauche de B : 1 case Plante 🌱 adjacente (H) → +1 pt
- Case droite de B : 0 cibles adjacentes → 0 pt
- Herberaude ne re-score PAS (bonus fixe, pas de combo d'adjacence)
- **Total du placement de Boutomate : 1 point**

**Exemple 3 : Modificateur Gingembre**
```
      [G]
[C][G][G][G]
[C]   [G]
```
Gingembre place a cote d'une Carotte existante :
- Le Gingembre applique le modificateur x2 aux cases de la Carotte adjacentes (les deux cases de la Carotte sont adjacentes au Gingembre)
- A partir de maintenant, quand la Carotte marque des points via ses combos, ces points sont doubles
- Si un autre Legume est place plus tard a cote de la Carotte : la Carotte marque 1pt x 2 = 2pt par case Legume adjacente

### Empilement des modificateurs

- Plusieurs Gingembre x2 : **empilement additif** — 1 Gingembre = x2, 2 Gingembres = x3, 3 Gingembres = x4, etc.

- L'engrais +1 s'empile additivement (2 zones superposees = +2)

---

## 5. Main & Cartes

### Main
- **Main de depart** : 2 Carotte + 2 Herberaude + 1 Boutomate (5 cartes)
- **Taille de main max** : 5 (ameliorable via prestige)
- Si la main est pleine, **impossible d'acheter des packs** (il faut placer des cartes d'abord)
- Les cartes se placent en glissant depuis la main vers la grille

### Defausse
- **Pas de defausse** au debut du jeu
- **Poubelle** (deblocage prestige) : permet de defausser des cartes sans benefice
- **Composteur** (amelioration prestige de la Poubelle) : defausser donne des **points selon la puissance de la carte** (ex: Herberaude = 1pt, Carotte = 2pts, Gingembre = 3pts). Chaque plante a une valeur de compost definie.

---

## 6. Systeme de Packs

### Boutique
- **3 emplacements de pack** toujours visibles
- Quand un pack est achete, son emplacement est **remplace par un nouveau pack aleatoire** (tire parmi tous les packs debloques)
- Les **doublons sont possibles** (deux Legumes Frais en meme temps, par exemple)
- La boutique est **reinitalisee au prestige** (3 nouveaux packs tires aleatoirement)
- Les packs sont thematiques et existent en differents niveaux

### Proprietes d'un pack
| Propriete | Description |
|-----------|-------------|
| Nom | Nom thematique (ex: "Legumes Frais") |
| Theme | Determine quelles plantes peuvent apparaitre |
| Cout de base | Prix de depart (3, 4, 5 pour les niveaux initiaux) |
| Nombre de cartes | Combien de cartes (3 pour les pas chers, plus pour les chers) |
| Niveau | Economique / Standard / Premium / Legendaire |
| Inflation du prix | Combien le prix global augmente apres achat (+1 a +5) |

### Systeme de prix
- Chaque pack a un **cout de base**
- Chaque **emplacement** de la boutique a un **bonus de prix** commencant a 0
- Prix du pack = cout de base + bonus de l'emplacement
- Quand un pack est achete : le bonus de **cet emplacement** += valeur d'inflation du pack achete
- Les autres emplacements ne sont PAS affectes (seul le nouveau pack qui remplace est plus cher)
  - Pack economique : +1
  - Pack standard : +2
  - Pack premium : +3
  - Pack legendaire : +5

### Catalogue complet des packs

Chaque pack peut aussi contenir un **outil bonus** (carte supplementaire, ne compte pas dans le nombre de cartes du pack). Probabilite d'outil bonus : 15% (Pelle 40%, Engrais 40%, Arrosoir 20%). Les outils n'apparaissent que si le joueur a debloque l'outil correspondant via prestige.

#### Packs de depart (toujours disponibles)

**Legumes Frais** — Economique
| Cout | Cartes | Inflation | Contenu |
|------|--------|-----------|---------|
| 3 | 3 | +1 | Carotte (50%), Boutomate (30%), Radis Rose (20%) |

**Herbes du Jardin** — Economique
| Cout | Cartes | Inflation | Contenu |
|------|--------|-----------|---------|
| 3 | 3 | +1 | Herberaude (50%), Persil Piquant (30%), Cactus Epineux (20%) |

**Potager Mixte** — Standard
| Cout | Cartes | Inflation | Contenu |
|------|--------|-----------|---------|
| 4 | 3 | +2 | Carotte (25%), Herberaude (25%), Boutomate (25%), Basilic Royal (25%) |

#### Packs de prestige (a debloquer)

**Champignons Delicieux** — Standard *(requis : Spores de Champignon)*
| Cout | Cartes | Inflation | Contenu |
|------|--------|-----------|---------|
| 4 | 3 | +2 | Champi-mi-gnon (40%), Truffe (35%), Morille Doree (25%) |

**Racines Profondes** — Standard *(requis : Decouverte des Racines)*
| Cout | Cartes | Inflation | Contenu |
|------|--------|-----------|---------|
| 5 | 3 | +2 | Patate Douce (30%), Navet Tournoyant (25%), Radis Rose (25%), Ail des Ours (20%) |

**Sous-Bois Mystique** — Premium *(requis : Packs Avances)*
| Cout | Cartes | Inflation | Contenu |
|------|--------|-----------|---------|
| 6 | 4 | +3 | Mousse Lunaire (25%), Pleurote Cascade (25%), Fougere d'Or (25%), Morille Doree (25%) |

**Festin du Chef** — Premium *(requis : Packs Avances)*
| Cout | Cartes | Inflation | Contenu |
|------|--------|-----------|---------|
| 7 | 4 | +3 | Basilic Royal (25%), Ail des Ours (25%), Persil Piquant (25%), Fraise Sauvage (25%) |

**Recolte Legendaire** — Legendaire *(requis : Recolte Legendaire dans l'arbre de prestige)*
| Cout | Cartes | Inflation | Contenu |
|------|--------|-----------|---------|
| 10 | 5 | +5 | Gingembre Tourne-Vent (20%), Fraise Sauvage (20%), Pleurote Cascade (20%), Ail des Ours (20%), Fougere d'Or (20%) |

### Resolution du contenu d'un pack
Quand un pack est achete :
1. Determiner combien de cartes donner (selon le nombre de cartes du pack)
2. Pour chaque carte : tirer selon la table de contenu du pack (probabilites ponderees)
3. Ajouter les cartes a la main du joueur
4. Si la main deborderait : bloquer l'achat (impossible d'acheter si la main est pleine)

### Loupe / Rayons X (Prestige)
- **Loupe** : en survolant un pack, montre quels **types** de plantes peuvent apparaitre et leurs chances
- **Rayons X** (amelioration) : montre les **cartes exactes** du pack avant achat

---

## 7. Systeme d'Outils

### Vue d'ensemble
- Les outils sont **consommables** (usage unique)
- Apparaissent en **bonus aleatoire** dans les packs normaux (un pack de 3 cartes peut devenir 4 si un outil est inclus)
- **Rarete** : Pelle et Engrais sont plus communs, l'Arrosoir est rare
- Stockes dans un **inventaire d'outils separe** (pas dans la main)
- L'inventaire d'outils a une **taille limitee** (ameliorable via prestige)
- Les outils sont **bloques** au debut — debloques via prestige

### Outils

#### Pelle
- **Effet** : Retirer une plante plantee de la grille, remettre la carte en main
- **Zone** : 1x1 → 3x3 → 5x5 (ameliorable via prestige)
- **Effet secondaire** : Laisse un **trou** (case bloquee) la ou la plante a ete deracinee
- **Amelioration prestige** : Supprime l'effet secondaire du trou (arrachage propre)
- **Utilisation** : Selectionner la pelle → cliquer sur la grille → toutes les plantes dans la zone sont remises en main

- **Chevauchement partiel** : Si au moins **une case** d'une plante est dans la zone de la pelle, la **plante entiere** est retiree et remise en main.

#### Sac d'Engrais
- **Effet** : Placer sur une case. Toutes les cases dans la zone gagnent **+1 a tous les gains de points futurs**
- **Zone** : 3x3 → 5x5 → ... (ameliorable via prestige)
- **Empilement** : Les zones d'engrais multiples s'empilent additivement
- **Duree** : Permanent (dure jusqu'au reset de prestige)
- **Utilisation** : Selectionner l'engrais → cliquer sur une case → la zone est appliquee

#### Arrosoir
- **Effet** : Placer sur une case. Toutes les plantes avec au moins une case dans la zone **re-declenchent entierement leurs combos**
- **Zone** : 3x3 → 5x5 → ... (ameliorable via prestige)
- **Regle cle** : Si meme **une seule case** d'une plante multi-cases est dans la zone arrosee, la **plante entiere** re-score toutes ses cases
- **Utilisation** : Selectionner l'arrosoir → cliquer sur une case → les plantes affectees se re-declenchent
- **Scoring** : Utilise le meme flux de scoring que le placement (verification des adjacences, application des modificateurs)

---

## 8. Systeme de Prestige

### Declenchement du prestige
- Disponible quand le solde de points actuel >= 50
- **Points de prestige gagnes** = partie_entiere(points_actuels / 50)
- Depenser des points en packs **reduit** le potentiel de prestige (solde actuel, pas total gagne)
- Tension strategique : acheter des packs pour scorer plus, ou garder ses points pour un prestige plus eleve

### Reset de prestige
- **Efface** : toutes les plantes sur la grille, toutes les cartes en main, tous les outils en inventaire
- **Efface** : le modificateur de prix global des packs (remis a 0)
- **Conserve** : les points de prestige, toutes les ameliorations achetees, le contenu debloque
- **Etat de depart** : depend des ameliorations de prestige (par defaut : 2 Carotte + 2 Herberaude + 1 Boutomate)

### Arbre de Prestige

L'arbre de prestige a des **branches** groupees par fonctionnalite. Chaque branche est un **sous-arbre** avec des dependances entre les noeuds. La **branche principale** contient l'objectif final et necessite que toutes les autres branches soient completees.

**Budget total : 21 points de prestige** (~10-15 prestiges pour finir le jeu)

```
                  [TERRARIUM PARFAIT ★]
                          |
                  [Jardinier Expert]
                          |
        ┌─────────┬───────┼────────┬─────────┐
   [Grille &   [Plantes [Main   [Outils  [Savoir]
   Biomes]    & Packs]  & Cartes] & Inv]
    4 pts       4 pts    4 pts    4 pts    3 pts
```

#### Branche : Grille & Biomes (4 pts)

```
Parcelle Herbeuse (1) ──┬── Terrain Rocheux (1)
                        └── Riviere (2)
```

| Noeud | Cout | Prerequis | Effet |
|-------|------|-----------|-------|
| Parcelle Herbeuse | 1 | — | Extension de grille (biome standard, pas d'effets speciaux) |
| Terrain Rocheux | 1 | Parcelle Herbeuse | Extension biome rocheux (contient des cases rochers bloquees) |
| Riviere | 2 | Parcelle Herbeuse | Extension biome riviere (cases bloquees mais +1 permanent aux cases adjacentes) |

#### Branche : Plantes & Packs (4 pts)

```
Spores de Champignon (1) ── Packs Avances (1) ──┐
                                                  ├── Recolte Legendaire (1)
Decouverte des Racines (1) ──────────────────────┘
```

| Noeud | Cout | Prerequis | Effet |
|-------|------|-----------|-------|
| Spores de Champignon | 1 | — | Debloque les Champis (Truffe, Champi-mi-gnon, Morille Doree, Pleurote Cascade) + pack Champignons Delicieux |
| Decouverte des Racines | 1 | — | Debloque les Racines (Gingembre, Patate Douce, Navet, Radis Rose, Ail des Ours) + pack Racines Profondes |
| Packs Avances | 1 | Spores | Debloque les packs Sous-Bois Mystique et Festin du Chef |
| Recolte Legendaire | 1 | Packs Avances + Decouverte | Debloque le pack legendaire Recolte Legendaire |

#### Branche : Main & Cartes (4 pts)

```
Poubelle (1) ── Composteur (1)

Main +1 (1) ── Starter Bonus (1)
```

| Noeud | Cout | Prerequis | Effet |
|-------|------|-----------|-------|
| Poubelle | 1 | — | Debloque la defausse (sans benefice) |
| Composteur | 1 | Poubelle | La defausse donne des points selon la valeur compost de la carte |
| Main +1 | 1 | — | Taille de main 5 → 6 |
| Starter Bonus | 1 | Main +1 | +1 carte aleatoire dans la main de depart (6 cartes au lieu de 5) |

#### Branche : Outils & Inventaire (4 pts)

```
Ceinture d'Outils (1) ──┬── Pelle (1) ───┐
                         │                 ├── Arrosoir (1)
                         └── Engrais (1) ──┘
```

| Noeud | Cout | Prerequis | Effet |
|-------|------|-----------|-------|
| Ceinture d'Outils | 1 | — | Debloque l'inventaire d'outils (2 emplacements) |
| Pelle | 1 | Ceinture | Debloque la pelle (1x1, laisse un trou) |
| Engrais | 1 | Ceinture | Debloque le sac d'engrais (zone 3x3) |
| Arrosoir | 1 | Pelle + Engrais | Debloque l'arrosoir (zone 3x3) |

#### Branche : Savoir (3 pts)

```
Encyclopedie (1) ── Loupe (1) ── Rayons X (1)
```

| Noeud | Cout | Prerequis | Effet |
|-------|------|-----------|-------|
| Encyclopedie | 1 | — | Liste des plantes decouvertes avec leurs regles |
| Loupe | 1 | Encyclopedie | Survoler un pack montre les types de plantes + probabilites |
| Rayons X | 1 | Loupe | Voir le contenu exact d'un pack avant achat |

#### Branche Principale (2 pts)

| Noeud | Cout | Prerequis | Effet |
|-------|------|-----------|-------|
| Jardinier Expert | 1 | Toutes les branches completees | Deblocage esthetique + bonus de scoring global |
| Terrarium Parfait ★ | 1 | Jardinier Expert | **FIN DU JEU** — cutscene/animation speciale montrant le terrarium complet dans toute sa splendeur |

> **Note** : Les ameliorations d'outils (taille pelle 3x3/5x5, arrachage propre, taille engrais 5x5, taille arrosoir 5x5) pourront etre ajoutees dans une mise a jour future comme noeuds supplementaires dans la branche Outils.

---

## 9. Design UI/UX

### Disposition de l'ecran (Paysage)

```
┌──────────────────────────────────────────┐
│  [Score: 42]  [Prestige ★]  [Parametres] │  <- Barre du haut
├──────────────────────────────────────────┤
│                                          │
│          GRILLE 18 x 8                   │  <- Zone de jeu principale
│          (glisser les cartes ici)        │
│                                          │
├──────────────────────────────────────────┤
│ [Carte][Carte][Carte][Carte][Carte][Out] │  <- Main + Inventaire outils
├──────────────────────────────────────────┤
│ [Pack 1: 3pts] [Pack 2: 4pts] [Pack 3]  │  <- Boutique
└──────────────────────────────────────────┘
```

### Ecrans
1. **Menu principal** : Nouvelle Partie, Continuer, Parametres, Langue
2. **Ecran de jeu** : Grille + Main + Boutique + Score (tout visible)
3. **Arbre de prestige** : Navigation plein ecran dans l'arbre (tap/clic sur les noeuds)
4. **Encyclopedie** : Liste des plantes decouvertes avec leurs regles
5. **Parametres** : Choix de langue, son, gestion des sauvegardes

### Adaptations mobiles
- Zones de tap plus larges pour les cases et les cartes
- Pinch-to-zoom sur la grille
- Main en barre defilable en bas
- Boutique en panneau repliable ou tiroir swipe-up
- Arbre de prestige : pinch-zoom + navigation pan

### Feedback & Juice
- **Placement** : animation de snap satisfaisante + effet de particules
- **Scoring** : "+N" flottants qui montent depuis les cases scorees, compteur de combo
- **Ouverture de pack** : animation de revelation de cartes (retournement une par une)
- **Prestige** : animation dramatique de reset (les plantes se dissolvent/s'envolent, transition d'ecran)
- **Deblocages** : effet de celebration quand on achete des noeuds de prestige

---

## 10. Systeme de Sauvegarde

- **Sauvegarde automatique** apres chaque action significative (placement, achat, prestige)
- Donnees sauvegardees : etat de la grille, main, inventaire d'outils, points, points de prestige, ameliorations debloquees, etat de la boutique, modificateur de prix global, progression de l'encyclopedie
- Un seul emplacement de sauvegarde (avec option de reset)
- Format : JSON ou fichier ressource Godot

---

## 11. Localisation

Toutes les chaines visibles dans un fichier de localisation (systeme CSV ou `.tres` integre a Godot).

Chaines cles :
- Noms de plantes, descriptions, explications de combos
- Noms de packs, descriptions
- Noms de noeuds de prestige, descriptions
- Labels d'interface, boutons, tooltips
- Texte de tutoriel/aide

| Cle | FR | EN |
|-----|----|----|
| plant_carotte | Carotte | Carrot |
| plant_herberaude | Herberaude | Herberaude |
| plant_boutomate | Boutomate | Boutomate |
| plant_truffe | Truffe | Truffle |
| plant_gingembre | Gingembre Tourne-Vent | Pinwheel Ginger |
| plant_champimignon | Champi-mi-gnon | Champi-mi-gnon |
| type_legume | Legume | Vegetable |
| type_plante | Plante | Plant |
| type_champi | Champi | Mushroom |
| type_racine | Racine | Root |
| pack_legumes_frais | Legumes Frais | Fresh Veggies |
| pack_champignons | Champignons Delicieux | Delicious Mushrooms |

> **A DESIGNER** : Certains noms de plantes sont des jeux de mots francais — decider lesquels garder tels quels en anglais (Herberaude, Boutomate, Champi-mi-gnon) vs traduire.

---

## 12. Questions de Design Ouvertes

### Resolues
- ~~Empilement Gingembre~~ → Additif (x2, x3, x4...)
- ~~Composteur~~ → Points selon valeur compost de la carte
- ~~Pelle chevauchement~~ → Retire la plante entiere si au moins 1 case dans la zone
- ~~Bonus riviere~~ → +1 permanent (comme engrais)
- ~~Packs d'outils~~ → Bonus aleatoire dans les packs normaux (15% chance)
- ~~Catalogue des packs~~ → 8 packs designs (3 de base + 5 prestige)
- ~~Arbre de prestige~~ → Sous-arbre, 20 pts total, 5 branches + principale
- ~~Objectif final~~ → Terrarium Parfait (cutscene)

### Encore ouvertes
1. **Champignons toxiques 🍄** : Mecaniques a designer quand on ajoutera du contenu
2. **Traduction des noms EN** : A voir plus tard (jeux de mots francais)
3. ~~Taille des patchs~~ → 6 colonnes par patch (implementé)
4. ~~Disposition terrain~~ → Aleatoire a chaque prestige (implementé)
5. **Ameliorations d'outils** : Tailles superieures (3x3, 5x5), arrachage propre — a ajouter dans une MAJ
6. **Equilibrage fin** : Probabilites exactes des packs, valeurs compost, scoring — a affiner en playtestant
7. **Plantes futures** : Le fils en inventera plus, les 12 supplementaires actuelles sont temporaires
8. **Ecran de victoire** : Quand "Terrarium Parfait" est achete, pas de cutscene/ecran de fin encore
