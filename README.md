# Project Exvius: Reborn

## Legal Disclaimer
This is a personal, non-commercial, educational reverse-engineering project.

The goal is to study architecture and systems design inspired by the discontinued mobile game Final Fantasy Brave Exvius. It is not intended for monetization or public distribution. Datamined static assets remain the property of their original copyright holders.

## Overview
Project Exvius explores how to rebuild the complete core systems of a large-scale gacha RPG using a local-first, offline architecture in Godot 4.

### Current Implemented Systems:
- **Turn-Based Combat Engine**:
  - Deterministic, frame-exact timeline with tick simulation (`BattleEngine`, `BattleTimeline`).
  - Full combo and chaining mechanics (normal chains, spark chains, elemental chains with damage multipliers).
  - Dual wield system (separate right-hand / left-hand weapon swings, damage variance, weapon inflicts).
  - Advanced combat mechanics: Physical & Magic Covers (single & AoE), Provoke / Aggro targeting, Jump / Away status, Reaction Counters, Status Ailments, Stat Buffs & Breaks.
  - Limit Burst (LB) system with tunable crystal drop rates, smart party distribution prioritizing units needing LB, Overkill drops, and animated flying crystal visual effects.
  - Evocation & Esper summoning system with shared party gauge.
  - Opcode-driven ability system (e.g., damage formulas, heals, revives, dispels, cleanses, reraise, auto-casts, and Opcode 47 Libra/Scan).
  - Comprehensive enemy AI brain executing multi-condition scripts from datamined tables.
- **Battle Presentation & Audio**:
  - Multi-layer SpriteStudio (`ssbp`) animated battle backgrounds and front visual layers.
  - Combatant sprite animation playback (idle, attack, cast, chant, victory, hurt, dead).
  - Rich battle UI: EnemyRegion with target selection, PartyRegion with gesture controls (tap to attack, swipe for skill menu), BattleMenus with multi-cast drafting, floating damage labels, spark callouts, and UnitInfoPopup (Libra inspector).
  - Battle MENU panel (`BattleMenuScreen`, opened by the square MENU button): Give Up on the engine's own loss path, Repeat Info listing the units Reload would act with, and the party's live HP/MP. It covers the field while open, so gestures cannot reach the units behind it.
  - Visual status and barrier feedback: floating status callouts ("SLEEP", "POISON", "BARRIER", "ABSORB", "BARRIER BREAK", "ATK UP"), sprite ailment tinting and animation freezing (stone petrify, blue sleep, yellow paralyze), animated health bar barrier gauges, and battle status badges on unit panels and the enemy target bar.
  - Dedicated `AudioService` handling BGM tracks and synchronized SFX.
- **Story, Dialogue & Cutscenes**:
  - Binary cutscene script parser and playback engine (`EventPlayer`, `StoryFlow`).
  - Dynamic dialogue system with dual language support and complete Thai localization for Season 1 dialogue, Season 1 battle scripts, and Season 2 battle scripts.
  - Thai localization of town and dungeon NPC text (`map_text`): line ids, engine tokens and Thai coverage are guarded by `tests/services/test_map_text_integrity.gd`.
  - Story unit joins (`StoryUnitService`): the units the main story hands over are granted once the mission, town scene or event that unlocks them is reached.
- **Exploration & Towns**:
  - Dynamic 2D tilemap generation directly from binary map and collision data.
  - Visual layer staging, NPC placement, and interactive story triggers.
- **Summoning (Gacha) & Progression**:
  - Multi-banner gacha system (Lapis, Summon Tickets, Gil, Cactuar).
  - Authentic crystal drop and tap-to-crack reveal sequences (Blue -> Yellow -> Rainbow) with instant skip options.
  - Unit roster management: enhancements, awakenings, ability sublimations, material drop location / shop lookup modal, trust mastery, and stat calculation.
  - Esper board training, SP-based node unlocks, real-time stat delta previews, and dark fantasy detail inspection modals.
- **Hybrid Inventory & Equipment**:
  - Hybrid persistence model supporting both stackable materials/items and unique non-fungible equipment instances.
  - Legality checks for equipment slots, dual-wielding requirements, and unit equipment allowances.
- **Automated Testing Suite**:
  - Comprehensive test suite covering 749 automated headless unit tests with 100% pass rate (`res://tests/run_tests.gd`).

## Tech Stack
- **Engine**: Godot 4.6 (GDScript with static typing).
- **Data Layer**:
  - Static SQLite database (`ffbe-data.db`) for missions, monsters, abilities, magic, items, towns, and localized battle scripts.
  - Baked static JSON datasets (`units.json`, `equipment.json`, `materia.json`, `skills.json`) with automated cache validation (`StaticDataLoader`).
- **Persistence**: Local snapshot-based save system (`user://game_state/` managed by `Persistence` autoload). Fully offline and self-contained.
- **Animation & Visuals**: Datamined SpriteStudio binary formats (`ssbp`) decoded directly by in-engine parsers.

## Architecture Principles
This repository follows strict composition, dumb UI, and service-driven orchestration:

1. **Dumb UI**: UI scenes and scripts are strictly presentation-only. They never mutate game state directly; they emit user-intent signals and redraw reactively.
2. **Domain Service Autoloads**: Game state is partitioned cleanly into specialized singletons (`UnitService`, `InventoryService`, `PartyService`, `PlayerProfile`, `EsperService`, `MissionService`).
3. **Decoupled Combat Engine**: The combat engine is completely headless, deterministic, and isolated from UI nodes. It outputs immutable events via `BattleEventLog` which the UI listens to.
4. **Local Authority**: All game rules, equipment validations, damage calculations, and rewards are calculated and enforced locally without external server dependencies.
5. **Signal-First Wiring**: Clean parent-child composition ("Signal up, call down") and autoload facades eliminate fragile node path hierarchies.

## Repository Layout
- `ExviusReborn/godot/`: Main Godot client project.
  - `core/`: Core services, persistence, database, stat calculators, audio, and UI manager.
  - `features/`: Modular gameplay and outgame features:
    - `battle/`: Turn-based battle engine, timeline, effect handlers, AI, and battle UI scenes.
    - `outgame/`: Home, gacha, units, inventory, espers, parties, and shop.
    - `town/`: Exploration maps, tilemaps, and NPC interactions.
    - `event/`: Story cutscenes and dialogue playback.
  - `assets/`: Textures, sprites, audio SFX/BGM, and static database (`ffbe-data.db`).
  - `tests/`: Extensive automated unit test suite.
- `bin_parser/`: Python tools for reverse-engineering and parsing raw binary datamines.
- `scripts/`: Conversion, localization, and data generation utilities.

## Quick Start

### Launching the Game
1. Open the `ExviusReborn/godot` project in Godot 4.6 (`project.godot`).
2. Run the project with **F5** (or click the Play button).

No backend, database server, or Docker setup is required. The game initializes static data on first boot and saves progress locally in `user://`.

### Running Automated Tests
Run the headless test suite from the command line using Godot Console:

```powershell
# Run full test suite (749 tests as of 2026-11-11; the count grows with new tests)
& "Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64_console.exe" --headless --path "ExviusReborn\godot" --script "res://tests/run_tests.gd"

# Run specific feature tests (e.g. Battle engine)
& "Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64_console.exe" --headless --path "ExviusReborn\godot" --script "res://tests/run_tests.gd" -- --filter=test_battle
```

## What This Fork Adds
This fork keeps the upstream systems and carries the work below on top of them:

- Thai localization: Season 1/2 dialogue and battle scripts, plus town and dungeon `map_text`.
- Battle MENU panel: Give Up, Repeat Info and the party's live status over the field.
- Story unit joins: units handed over as the story reaches its join points.
- Esper summon presentation fallback when an Effekseer resource is missing, and the item drop popup.

Two folders are deliberately not in version control: `godot/assets/` (the datamined asset dump) and `translations/` (the translation working set, CSV/JSON). A clone therefore runs only after both are supplied locally.

## Additional Documentation
- Architectural Rules & AI Pair-Programming Guidelines: `RULES.md`
- Data Schema & Persistence Model: `DATA_SCHEMA.md`
- Godot Client Service Overview: `godot/README.md`
- Season 2 Translation Guide: `translations/story/SEASON2_TRANSLATION_GUIDE.md`

## Acknowledgements & Credits
- **aEnigmatic/ffbe**: Invaluable datamine repositories and schemas.
- **DaddyRaegen/ffbe_asset_dump**: Asset preservation.
- **dsxragnarok/ffbetool**: Sprite and animation research.
- **Exvius Wiki Community (u/Cysidus and contributors)**: Mechanics, damage formulas, and skill timings.
- **u/NightWaIker**: FFBE Memorial Edition research.
