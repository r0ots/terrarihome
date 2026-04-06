# Terrarihome

Terrarium card-placement puzzle game. Designed by user's son, built with Godot 4.5.

## Game Summary

Place plants on an 18x8 grid, score points via adjacency combos, buy card packs, prestige to unlock content. Free-form (no turns). Ends when "Terrarium Parfait" prestige node is purchased.

Full rules: `docs/gdd_fr.md` (source of truth, French).

## Architecture

Godot 4.5, GDScript, pixel art. Targets PC + Mobile.

### Project Structure

```
scenes/
  game/game.tscn              # Main game scene (grid + hand + shop + tools + top bar)
  main_menu/                   # Placeholder
  prestige/prestige_tree.tscn  # Full-screen prestige tree overlay

scripts/
  autoload/
    game_manager.gd            # Singleton: points, prestige, hand, tools, upgrades
    save_manager.gd            # Singleton: JSON save/load with grid + tools + shop serialization
  data/
    plant_data.gd              # PlantData Resource class
    plant_database.gd          # Static registry of 18 plants (lazy init)
    plant_icons.gd             # Static registry of 16x16 pixel art ImageTextures (lazy init)
    pack_data.gd               # PackData Resource class
    pack_database.gd           # Static registry of 8 packs (lazy init)
    prestige_node.gd           # PrestigeNode Resource class
    prestige_database.gd       # Static registry of 20 prestige nodes (lazy init)
  grid/
    grid_data.gd               # Pure data model (RefCounted): cells, plants, modifiers, grid expansion
  scoring/
    scoring_engine.gd          # Pure logic (RefCounted): placement scoring, retrigger
  game/
    game.gd                    # Main controller: wires all systems together
    grid_view.gd               # Visual grid: _draw(), hover preview, tool overlays, plant icons
    hand_view.gd               # Hand UI: card panels with shape preview + hover info
    shop_view.gd               # Shop UI: 3 pack slots, purchase, loupe/x-ray hover, tool bonus
    tool_bar.gd                # Tool inventory UI: select/deselect tools
    encyclopedia.gd            # Full-screen plant catalog
    floating_text.gd           # "+N" score popup animation
  prestige/
    prestige_tree.gd           # Prestige tree UI: branches, nodes, dependencies, unlock flow
```

### Key Patterns

- **Data = Resource classes** (`PlantData`, `PackData`, `PrestigeNode`) with `@export` fields
- **Databases = static registries** with lazy `_ensure_init()`, return typed Resources
- **GameManager uses setter pattern**: `points` and `prestige_points` auto-emit signals on change
- **Full static typing**: all params, returns, locals, loop vars. `StringName` for all IDs.
- **Scoring engine**: Phase 1 = apply modifiers, Phase 2 = score. Bidirectional. Per-cell. No cascade on retrigger.
- **Grid is pure data** (`GridData` RefCounted), visuals are separate (`GridView` Node2D with `_draw()`)
- **Warm terrarium theme**: earth tones, amber accents, cream text throughout
- **Per-slot pack pricing**: each shop slot tracks its own price bonus (not global)

### Scoring Rules (critical for correctness)

- Orthogonal adjacency only (4 dirs)
- Each cell of a multi-cell plant checks independently
- Bidirectional: new plant scores AND neighbors re-score (unless `on_place_only`)
- Modifiers apply BEFORE scoring (Gingembre x2 is active for re-scores)
- Gingembre x2 stacks additively: 1=x2, 2=x3, 3=x4
- Watering can retrigger: no cascade (no bidirectional chain)
- Score floating text aggregated per cell (not per scoring event)

### Prestige Tree (21 PP total, 6 branches)

- Grille & Biomes (4): parcelle_herbeuse → terrain_rocheux / riviere
- Plantes & Packs (4): spores_champignon / decouverte_racines → packs_avances → recolte_legendaire
- Main & Cartes (4): poubelle → composteur, main_plus1 → starter_bonus
- Outils & Inventaire (4): ceinture_outils → pelle / engrais → arrosoir
- Savoir (3): encyclopedie → loupe → rayons_x
- Principale (2): jardinier_expert (requires all) → terrarium_parfait (END)

## Code Style

- Extreme conciseness, no unnecessary comments
- GDScript 4 with full static typing
- `StringName` (&"foo") for identifiers
- Resource classes for data, static registries for databases
- Signals for decoupling, setter pattern for reactive state
- No rotation on plant shapes (fixed orientation)
- Warm color palette: earth browns, amber borders, cream text

## Not Yet Implemented

- Victory screen when "Terrarium Parfait" is purchased
- Main menu (game launches directly)
- Localization system (FR/EN strings, everything hardcoded French)
- Sound/music
- Higher resolution pixel art (currently 16x16 generated in code)
