# Terrarihome — Game Design Document

## 1. Game Overview

**Genre**: Card-placement puzzle / idle progression
**Engine**: Godot 4.5
**Platforms**: PC + Mobile
**Art Style**: Pixel art / retro
**Languages**: French & English
**Core Fantasy**: Build and grow a terrarium by placing plants on a grid, creating clever combos, and prestiging to unlock new content.

### Core Loop

```
Place plants on grid → Score points from adjacency combos
        ↓                          ↓
Buy card packs ← ← ← ← ←  Points earned
        ↓
   Prestige (50+ pts)
        ↓
 Unlock upgrades → Better starting state → Place plants...
```

The game is **free-form** — no turn structure. Players place cards, buy packs, and prestige whenever they choose. The game ends when the player purchases the **final prestige upgrade** on the main branch, which requires all other branches to be completed first.

---

## 2. Grid System

### Base Grid
- **18 columns × 8 rows** (landscape orientation)
- Cells are either **empty**, **occupied** (by a plant), or **blocked** (by terrain/shovel hole)
- Plants cannot overlap occupied or blocked cells

### Adjacency
- **Orthogonal only** (up, down, left, right — 4 neighbors per cell)
- Diagonal cells are NOT adjacent
- Each cell of a multi-cell plant checks adjacency **independently**

Example: A Carotte (2 vertical cells) has up to **6 unique neighbors** (4 for top cell + 4 for bottom cell - 2 shared = 6 unique, but scoring checks each cell separately, so a shared neighbor triggers twice — once for top, once for bottom).

### Grid Expansion (Prestige)
New **grid patches** can be unlocked via prestige, placed adjacent to the main grid. Each patch introduces a **biome** with unique properties:

| Biome | Properties |
|-------|-----------|
| Standard | No special effects |
| Rocky | Contains **rock cells** — blocked, cannot plant |
| Riverside | Contains **river cells** — blocked, but give bonus points to adjacent plants |
| *More to co-design* | |

> **CO-DESIGN**: Patch sizes, specific biome bonuses/maluses, number of patches available, visual themes.

---

## 3. Plant System

### Plant Data Model
Each plant has:
- **Name** (FR + EN)
- **Shape**: array of cell offsets from origin `(0,0)` — **fixed orientation, no rotation**
- **Types**: one or more type tags (Légume, Plante, Champi, Racine...)
- **Combo Rule**: how this plant scores points
- **Scoring Mode**: `bidirectional` (default) or `on_place_only`

### Type Tags

| Tag | Icon | Description |
|-----|------|-------------|
| Légume | 🥕 | Vegetables |
| Plante | 🌱 | Generic plants/herbs |
| Champi | 🍄‍🟫 | Non-toxic mushrooms |
| Champi Toxique | 🍄 | Toxic mushrooms *(future content)* |
| Racine | 🪾 | Root vegetables |

### Base Plants (available from start)

#### Carotte ×2
```
[X]
[X]
```
- **Shape**: `[(0,0), (0,1)]` (vertical 1×2)
- **Types**: Légume 🥕
- **Combo**: +1 point per adjacent cell with type Légume 🥕
- **Scoring**: Bidirectional
- **Starting copies**: 2

#### Herberaude ×2
```
[X]
```
- **Shape**: `[(0,0)]` (single cell)
- **Types**: Plante 🌱
- **Combo**: +1 point flat when placed (no adjacency)
- **Scoring**: On place only (flat bonus, no re-trigger)
- **Starting copies**: 2

#### Boutomate ×1
```
[X][X]
```
- **Shape**: `[(0,0), (1,0)]` (horizontal 2×1)
- **Types**: Légume 🥕
- **Combo**: +1 point per adjacent cell with type Légume 🥕 OR type Plante 🌱
- **Scoring**: Bidirectional
- **Starting copies**: 1

### Prestige Plants (unlockable)

#### Truffe
```
[X][X]
[X][X]
```
- **Shape**: `[(0,0), (1,0), (0,1), (1,1)]` (2×2 square)
- **Types**: Champi 🍄‍🟫
- **Combo**: +1 point per adjacent cell with type Champi 🍄‍🟫 (excludes Champi Toxique 🍄)
- **Scoring**: Bidirectional

#### Gingembre Tourne-Vent
```
   [X]
[X][X][X]
   [X]
```
- **Shape**: `[(1,0), (0,1), (1,1), (2,1), (1,2)]` (plus/cross, 5 cells)
- **Types**: Légume 🥕, Racine 🪾
- **Combo**: **Modifier** — all adjacent cells with type Légume 🥕 gain a **×2 multiplier on future points**. Does NOT retroactively double existing points. Does NOT double other multipliers (additive, not multiplicative stacking).
- **Scoring**: Modifier applied on placement (bidirectional for the modifier effect)

#### Champi-mi-gnon
```
[X]
```
- **Shape**: `[(0,0)]` (single cell)
- **Types**: Champi 🍄‍🟫
- **Combo**: +1 point per adjacent **occupied cell** (any type, any plant)
- **Scoring**: **On place only** — does NOT re-score when new plants are placed next to it

### Additional Plants

> **CO-DESIGN**: More plants to design for each type category. Ideas to explore:
> - More Racine plants (combos with Racine type)
> - Toxic mushrooms (negative effects? block combos? high risk/reward?)
> - Flowers (new type? aesthetic bonus?)
> - Vines/creepers (grow over time?)
> - Rare/legendary plants (complex shapes, powerful combos)

---

## 4. Scoring Engine

### Placement Scoring Flow

When a plant is placed at position P:

```
1. For each cell C of the newly placed plant:
   a. Check all 4 orthogonal neighbors of C
   b. Apply the NEW plant's combo rule against each neighbor
   c. Score points accordingly

2. For each existing plant adjacent to any cell of the new plant:
   a. For each cell C of the EXISTING plant:
      b. Check if any cell of the NEW plant is orthogonally adjacent to C
      c. If yes, apply the EXISTING plant's combo rule against the new cell
      d. Score points accordingly
   (Skip if existing plant's scoring mode is "on_place_only")

3. Apply modifiers:
   - Gingembre ×2: if the scoring cell has a ×2 modifier, double the points gained
   - Fertilizer +1: if the scoring cell is in a fertilizer zone, add +1 to points gained
```

### Scoring Examples

**Example 1: Two Carrots side by side**
```
[A][B]
[A][B]
```
Carrot A is placed first (0 adjacent Légumes → 0 bonus points).
Carrot B is placed next to A:
- B's top cell: 1 adjacent Légume cell (A's top) → +1 pt
- B's bottom cell: 1 adjacent Légume cell (A's bottom) → +1 pt
- A re-scores (bidirectional):
  - A's top cell: 1 adjacent Légume cell (B's top) → +1 pt
  - A's bottom cell: 1 adjacent Légume cell (B's bottom) → +1 pt
- **Total from this placement: 4 points**

**Example 2: Boutomate next to Herberaude**
```
[H][B][B]
```
Herberaude placed first: +1 pt flat.
Boutomate placed next to Herberaude:
- B left cell: 1 adjacent Plante 🌱 cell (H) → +1 pt
- B right cell: 0 adjacent targets → 0 pt
- Herberaude does NOT re-score (flat bonus, no adjacency combo)
- **Total from Boutomate placement: 1 point**

**Example 3: Gingembre modifier**
```
      [G]
[C][G][G][G]
[C]   [G]
```
Gingembre placed next to existing Carrot:
- Gingembre applies ×2 modifier to Carrot's adjacent cells (both cells of Carrot are adjacent to Gingembre)
- From now on, when Carrot scores points from combos, those points are doubled
- If another Légume is later placed next to Carrot: Carrot scores 1pt × 2 = 2pt per adjacent Légume cell

### Modifier Stacking

- Multiple Gingembre ×2: points are doubled per Gingembre (×2, ×4, ×8...) — OR additive (+2, +4, +6...)? 

> **CO-DESIGN**: Decide on modifier stacking rules. Multiplicative stacking can lead to extreme scores. Recommend additive: "×2 per Gingembre" means 1 Gingembre = ×2, 2 Gingembres = ×3, etc.

- Fertilizer +1 stacks additively (2 overlapping zones = +2)

---

## 5. Hand & Cards

### Hand
- **Starting hand**: 2 Carotte + 2 Herberaude + 1 Boutomate (5 cards)
- **Hand size limit**: 5 (upgradeable via prestige)
- If hand is full, **cannot buy packs** (must place cards first)
- Cards are placed by dragging from hand onto grid

### Discard
- **No discard ability** at game start
- **Bin** (prestige unlock): allows discarding cards for no benefit
- **Composter** (prestige upgrade from Bin): discarding gives rewards

> **CO-DESIGN**: Composter rewards — points per discard? Chance to get a card back? Compost resource for a new mechanic?

---

## 6. Pack System

### Shop
- **3 pack slots** always visible
- When a pack is purchased, its slot is **replaced by a new random pack**
- Packs are themed and come in different tiers

### Pack Properties
| Property | Description |
|----------|-------------|
| Name | Themed name (e.g., "Légumes Frais") |
| Theme | Determines which plants can appear |
| Base Cost | Starting price (3, 4, 5 for initial tiers) |
| Card Count | How many cards (3 for cheap, more for expensive) |
| Tier | Cheap / Standard / Premium / Legendary |
| Price Inflation | How much global price increases after buying (+1 to +5) |

### Price System
- Each pack has a **base cost**
- There is a **global price modifier** starting at 0
- Pack price = base cost + global price modifier
- When a pack is purchased: global modifier += pack's inflation value
  - Cheap pack: +1
  - Standard pack: +2
  - Premium pack: +3
  - Legendary pack: +5

### Pack Tiers & Themes

| Pack Name | Theme | Tier | Base Cost | Cards | Inflation | Contents |
|-----------|-------|------|-----------|-------|-----------|----------|
| Légumes Frais | Légumes | Cheap | 3 | 3 | +1 | Carotte, Boutomate |
| Herbes du Jardin | Plantes | Cheap | 3 | 3 | +1 | Herberaude, ??? |
| Champignons Délicieux | Champis | Standard | 4 | 3 | +2 | Truffe, Champi-mi-gnon |
| *More to design...* | | | | | | |

> **CO-DESIGN**: Full pack list, contents with probability weights, how many packs exist per tier, tool packs (dedicated vs mixed), legendary packs.

### Pack Content Resolution
When a pack is purchased:
1. Determine how many cards to give (based on pack card count)
2. For each card: roll against the pack's content table (weighted probabilities)
3. Add cards to player's hand
4. If hand would overflow: block purchase (cannot buy if hand is full)

### Magnifying Glass / X-Ray (Prestige)
- **Magnifying Glass**: when hovering a pack, shows which plant **types** can appear and their odds
- **X-Ray** (upgrade): shows the **exact cards** in the pack before buying

---

## 7. Tool System

### Overview
- Tools are **consumable** (single use)
- Found in **packs** (random chance, or dedicated tool packs)
- Stored in a **separate tool inventory** (not in hand)
- Tool inventory has a **size limit** (upgradeable via prestige)
- Tools are **locked** at game start — unlocked via prestige

### Tools

#### Shovel (Pelle)
- **Effect**: Remove a planted plant from the grid, return the card to hand
- **Area**: 1×1 → 3×3 → 5×5 (upgradeable via prestige)
- **Side effect**: Leaves a **hole** (blocked cell) where the plant was dug out
- **Prestige upgrade**: Remove hole side effect (clean dig)
- **Usage**: Select shovel → click on grid → all plants in area are returned to hand

> **CO-DESIGN**: When shovel is 3×3, does it return ALL plants in the area? What about partial overlaps (plant has cells inside and outside the shovel area)?

#### Fertilizer Bag (Sac d'Engrais)
- **Effect**: Place on a cell. All cells in area gain **+1 to all future point gains**
- **Area**: 3×3 → 5×5 → ... (upgradeable via prestige)
- **Stacking**: Multiple fertilizer zones stack additively
- **Duration**: Permanent (lasts until prestige reset)
- **Usage**: Select fertilizer → click on grid cell → zone is applied

#### Watering Can (Arrosoir)
- **Effect**: Place on a cell. All plants with at least one cell in the area **fully re-score their combos**
- **Area**: 3×3 → 5×5 → ... (upgradeable via prestige)
- **Key rule**: If even **one cell** of a multi-cell plant is in the watered area, the **entire plant** re-scores all its cells
- **Usage**: Select watering can → click on grid cell → affected plants re-trigger
- **Scoring**: Uses the same scoring flow as placement (checking all adjacencies, applying modifiers)

---

## 8. Prestige System

### Triggering Prestige
- Available when current point balance ≥ 50
- **Prestige points earned** = floor(current_points / 50)
- Spending points on packs **reduces** prestige potential (current balance, not total earned)
- Strategic tension: buy packs to score more, or save points to prestige higher

### Prestige Reset
- **Clears**: all plants on grid, all cards in hand, all tools in inventory
- **Clears**: global pack price modifier (resets to 0)
- **Keeps**: prestige points, all purchased prestige upgrades, unlocked content
- **Starting state**: depends on prestige upgrades (default: 2 Carotte + 2 Herberaude + 1 Boutomate)

### Prestige Tree

The prestige tree has **branches** grouped by feature. Each branch has multiple **nodes** (upgrades) with increasing costs. The **main branch** contains the final goal and requires all other branches to be completed.

```
                    [FINAL GOAL]
                         |
                    [Main Branch]
                         |
        ┌────────┬───────┼───────┬────────┐
   [Grid &    [Plants  [Hand   [Tools  [Knowledge]
   Biomes]   & Packs]  & Cards] & Inv]
```

#### Branch: Grid & Biomes

| Node | Cost | Effect |
|------|------|--------|
| Garden Patch 1 | 1 | Unlock first grid expansion (standard biome) |
| Rocky Terrain | 2 | Unlock rocky biome patch |
| Riverside | 2 | Unlock riverside biome patch |
| Garden Patch 2 | 3 | Unlock second grid expansion |
| *More...* | | |

#### Branch: Plants & Packs

| Node | Cost | Effect |
|------|------|--------|
| Mushroom Spores | 1 | Unlock Champi plants (Truffe, Champi-mi-gnon) |
| Champignons Délicieux Pack | 1 | Unlock mushroom pack in shop |
| Root Discovery | 2 | Unlock Racine plants (Gingembre Tourne-Vent) |
| *More packs & plants...* | | |

#### Branch: Hand & Cards

| Node | Cost | Effect |
|------|------|--------|
| Bin | 1 | Unlock discard ability |
| Hand +1 | 1 | Hand size 5 → 6 |
| Composter | 2 | Upgrade bin: discarding gives rewards |
| Bonus Starter | 2 | +1 card in starting hand |
| Hand +2 | 2 | Hand size 6 → 7 |
| *More...* | | |

#### Branch: Tools & Inventory

| Node | Cost | Effect |
|------|------|--------|
| Tool Belt | 1 | Unlock tool inventory (1 slot) |
| Shovel | 1 | Unlock shovel tool (appears in packs) |
| Tool Belt +1 | 1 | Tool inventory 1 → 2 slots |
| Fertilizer | 2 | Unlock fertilizer tool |
| Shovel Size+ | 2 | Shovel area 1×1 → 3×3 |
| Watering Can | 2 | Unlock watering can tool |
| Clean Dig | 2 | Shovel no longer leaves holes |
| *More upgrades...* | | |

#### Branch: Knowledge

| Node | Cost | Effect |
|------|------|--------|
| Encyclopedia | 1 | Unlock plant encyclopedia (view discovered plants + rules) |
| Magnifying Glass | 1 | Hover packs to see plant types + odds |
| X-Ray | 2 | See exact pack contents before buying |

#### Main Branch

| Node | Cost | Requirement | Effect |
|------|------|-------------|--------|
| *Intermediate nodes...* | | | |
| Final Goal | ? | All other branches complete | Ends the game / victory |

> **CO-DESIGN**: 
> - Exact costs for all nodes (balancing)
> - Main branch intermediate nodes
> - Final goal theme/flavor (what does "winning" look like?)
> - Branch ordering (are nodes linear within a branch, or do they have their own sub-tree?)
> - Total prestige points needed to complete everything (determines game length)

---

## 9. UI/UX Design

### Screen Layout (Landscape)

```
┌──────────────────────────────────────────┐
│  [Score: 42]  [Prestige ★]  [Settings]   │  <- Top bar
├──────────────────────────────────────────┤
│                                          │
│          18 × 8 GRID                     │  <- Main play area
│          (drag cards here)               │
│                                          │
├──────────────────────────────────────────┤
│  [Card][Card][Card][Card][Card]  [Tools] │  <- Hand + Tool inventory
├──────────────────────────────────────────┤
│  [Pack 1: 3pts] [Pack 2: 4pts] [Pack 3] │  <- Shop
└──────────────────────────────────────────┘
```

### Screens
1. **Main Menu**: New Game, Continue, Settings, Language
2. **Game Screen**: Grid + Hand + Shop + Score (all visible)
3. **Prestige Tree**: Full-screen tree navigation (tap/click nodes)
4. **Encyclopedia**: List of discovered plants with rules
5. **Settings**: Language toggle, sound, save management

### Mobile Adaptations
- Larger touch targets for cells and cards
- Pinch-to-zoom on grid
- Hand as a scrollable tray at bottom
- Shop as a collapsible panel or swipe-up drawer
- Prestige tree: pinch-zoom + pan navigation

### Feedback & Juice
- **Placement**: satisfying snap animation + particle effect
- **Scoring**: floating "+N" numbers rising from scored cells, combo counter
- **Pack opening**: card reveal animation (flip cards one by one)
- **Prestige**: dramatic reset animation (plants dissolve/float away, screen transitions)
- **Unlocks**: celebration effect when buying prestige nodes

---

## 10. Save System

- **Auto-save** after every significant action (placement, purchase, prestige)
- Save data includes: grid state, hand, tool inventory, points, prestige points, unlocked upgrades, pack shop state, global price modifier, encyclopedia progress
- Single save slot (with option to reset)
- Save format: JSON or Godot resource file

---

## 11. Localization

All user-facing strings in a localization file (Godot's built-in CSV or `.tres` translation system).

Key strings:
- Plant names, descriptions, combo explanations
- Pack names, descriptions
- Prestige node names, descriptions
- UI labels, buttons, tooltips
- Tutorial/help text

| Key | FR | EN |
|-----|----|----|
| plant_carotte | Carotte | Carrot |
| plant_herberaude | Herberaude | Herberaude |
| plant_boutomate | Boutomate | Boutomate |
| plant_truffe | Truffe | Truffle |
| plant_gingembre | Gingembre Tourne-Vent | Pinwheel Ginger |
| plant_champimignon | Champi-mi-gnon | Champi-mi-gnon |
| type_legume | Légume | Vegetable |
| type_plante | Plante | Plant |
| type_champi | Champi | Mushroom |
| type_racine | Racine | Root |
| pack_legumes_frais | Légumes Frais | Fresh Veggies |
| pack_champignons | Champignons Délicieux | Delicious Mushrooms |

> **CO-DESIGN**: Some plant names are French wordplay — decide which to keep as-is in English (Herberaude, Boutomate, Champi-mi-gnon) vs translate.

---

## 12. Open Design Questions

Summary of all items marked for co-design:

1. **Additional plants**: More Légumes, Plantes, Champis, Racines, new types (Flowers? Vines?)
2. **Toxic mushrooms**: Mechanics for the Champi Toxique 🍄 type
3. **Pack list**: Full catalog of packs with contents and probability weights
4. **Biome details**: Specific biomes, their sizes, bonuses, maluses
5. **Prestige tree balancing**: Node costs, total prestige points for full completion
6. **Main branch & final goal**: What intermediate nodes exist? What is the victory condition flavor?
7. **Modifier stacking**: Gingembre ×2 — multiplicative or additive with multiple?
8. **Composter rewards**: What does discarding into composter give?
9. **Shovel multi-cell**: How does 3×3+ shovel handle partial plant overlaps?
10. **Plant name translations**: Keep French wordplay or translate?
11. **Tool packs**: Dedicated tool packs, or tools mixed into plant packs?
12. **River bonus**: How many points does river adjacency give?
