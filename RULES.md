# Project Architecture & AI Coding Rules

Before generating any code or plans, you must strictly adhere to the Godot 4 architecture of this project. Do not deviate from these rules under any circumstances.

## 1. STRICT COMPOSITION (DUMB UI)
* Every UI element (menus, popups, fields) is its own standalone `.tscn` file.
* UI scripts must NOT contain backend, server, or game state mutation logic.
* UI scripts only handle presentation, layout, visual animations, and emit user-intent signals.
* UI redraws reactively from state provided by domain services or battle events.

## 2. UIMANAGER AUTOLOAD (NAVIGATION)
* All UI navigation is handled centrally by the `UIManager` singleton.
* The `UIManager` uses a Menu Stack (`push`, `pop`, `pop_to_root`, `set_root`).
* It dynamically loads and `instantiate()`s scenes when pushing, and uses `queue_free()` when popping. It does NOT hold references to hidden, pre-instanced scenes.
* Persistent overlays (header, bottom navigation) are managed at the root and toggled by scene key.

## 3. DOMAIN SERVICE AUTOLOADS & PERSISTENCE (STATE & LOCAL AUTHORITY)
* The game operates local-first / offline-authoritative. There is no remote backend server.
* Global game state is partitioned into domain-specific service autoloads:
  * `UnitService`: Unit roster, enhancements, awakenings, trust, and level progression.
  * `InventoryService`: Stackable materials/items and unique equipment instances.
  * `PartyService`: Party decks, unit slot assignments, and active party selection.
  * `PlayerProfile`: Player rank, rank XP, NRG calculations, and currency (Gil, Lapis).
  * `EsperService`: Esper acquisition, training, and skill grid unlock state.
  * `MissionService`: Mission lifecycle (start, complete, rewards, clear flags).
  * `FriendsService`: Friend list state and companion picks.
* UI never mutates state directly. UI calls service request methods or emits signals; services perform validation, update memory state, and trigger persistence.
* Local save snapshots are persisted to `user://game_state/` via the `Persistence` singleton using atomic scoped JSON files (`stats.json`, `items.json`, `units.json`, `parties.json`, `mission_progress.json`, etc.).

## 4. NO SPAGHETTI REFERENCES (SIGNAL UP, SERVICE DOWN)
* Never use fragile relative node paths like `get_node("../../SomeNode")`.
* Use the "Signal up, call down" hierarchy pattern for internal UI components.
* For cross-system communication, communicate strictly via Service signals and autoload interfaces.

## 5. BATTLE ENGINE ARCHITECTURE & DETERMINISM
* **Separation of Concerns**: Combat simulation is strictly decoupled from presentation:
  * **Simulation Layer**: `BattleEngine`, `BattleTimeline`, `BattleRules`, `EffectRegistry`, and effect handlers (`DamageHandler`, `StatusHandler`, `LibraHandler`, etc.).
  * **Presentation Layer**: `BattleScreen`, `EnemyField`, `PartyField`, `BattleMenus`, `UnitInfoPopup`.
* **Deterministic Execution**: The battle engine simulation must remain deterministic:
  * Always use the engine's internal seeded RNG (`self.rng`), never global `randf()` or `randi()`.
  * Multi-hit frames, actions, and reactions must execute consistently across identical seeds for replayability and testability.
* **Event-Driven UI**: The engine emits immutable event dictionaries through `BattleEventLog` (e.g. `HIT_LANDED`, `LB_CRYSTAL_DROPPED`, `STATUS_ADDED`, `STATUS_REMOVED`, `STATUS_RESISTED`, `STATUS_DAMAGE`). The UI subscribes to these events to spawn damage labels, audio, and visual animations without writing back to the engine.
* **Status & Barrier Visualization**:
  * **Floating Callout Labels**: Status applications, removals, resists, and barrier absorptions trigger animated floating labels over combatant sprites (`party_field.show_status_text`, `enemy_field.show_status_text`) using color-coded callouts (`"SLEEP"`, `"POISON"`, `"BARRIER"`, `"ATK UP"`, `"DEF DOWN"`, `"ABSORB"`, `"BARRIER BREAK"`, `"WAKE"`, `"CURED"`).
  * **Sprite Visual Modulation (`CombatSprite`)**: Severe status ailments tint combatant sprites and pause animation playback (Petrify stone gray, Sleep blue, Paralyze yellow, Stop cyan). Mild ailments tint without pausing (Poison purple, Blind dark, Charm pink).
  * **Barrier Gauge (`UnitPanel`)**: Active shields dynamically display a glowing barrier frame (`BarrierGage`) and yellow fill bar (`BattleUnitBarrierBar`) over the unit's HP bar proportional to remaining barrier HP.
  * **Status Icon Badges**: Active statuses display authentic FFBE icons (`state_icon_bad.png`, `state_icon_up.png`, `state_icon_down.png`) via `BattleStatusIconHelper` in `StatusContainer` on unit panels and the enemy target bar.

## 6. STRICT TYPE HINTING
* Use Godot 4 static typing for all GDScript files.
* Variables: `var current_hp: int = 0`
* Functions: `func equip_item(item_id: String) -> void:`
* Explicitly cast Dictionary/Variant values from JSON or database queries (`int(dict.get("id", 0))`, `str(...)`, `as Dictionary`).

## 7. STRICT NAMING CONVENTIONS
* Scripts and Directories: `snake_case` (e.g., `unit_panel.gd`, `battle_engine.gd`)
* Scenes and Nodes in Scene Tree: `PascalCase` (e.g., `UnitPanel.tscn`, `BattleScreen`)
* Signals: past_tense intent or event (e.g., `signal item_equipped`, `signal target_selected`, NOT `signal equip_item`)

## 8. GODOT 4 INSTANTIATION & RESOURCE LOADING
* Always use `.instantiate()`, NEVER the obsolete Godot 3 `.instance()`.
* Use `@onready var` for node references at the top of the script.
* Use `preload("res://path/to/scene.tscn")` at script top-level for scenes/resources instantiated frequently.
* Dynamic textures (e.g. unit sprites, icons) must be routed through texture caching rather than calling `load()` repeatedly inside frame loops.
* Audio playback must be routed through `AudioService` (SFX/BGM buses).

## 9. STATIC DATA & DATABASE ACCESS
* Static master data is partitioned into:
  1. Baked JSON templates (`units.json`, `equipment.json`, `materia.json`, `skills.json`) accessed via `StaticData` / `StaticDataLoader`.
  2. Read-only SQLite database (`ffbe-data.db`) accessed via `GameDatabase` for missions, monster stats, monster AI, battle background layers, and dialogue scripts.
* Do not perform raw SQL file writes at runtime; runtime player progression belongs in `Persistence` snapshots.

## 10. LOCALIZATION & TRANSLATION INTEGRITY
* Story dialogue, battle scripts, and cutscenes maintain dual Japanese/English and Thai translation structures.
* All engine-level tokens, pipe delimiters (`|`), conditional flags, and engine control codes (e.g. `{0}`, `[NAME]`) must be preserved exactly.
* Character tone and persona must adhere to the Character Voice Matrix established in `SEASON2_TRANSLATION_GUIDE.md`.

## 11. AUTOMATED TESTING DISCIPLINE
* Every core feature, battle handler, passive mechanic, or progression service must be backed by automated headless unit tests in `res://tests/`.
* All tests must pass cleanly (`Godot_console.exe --headless --path ExviusReborn/godot --script res://tests/run_tests.gd`) before completing any major feature or architectural refactor.
