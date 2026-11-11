# Data Schema & Persistence Architecture

This document serves as the definitive reference for static data templates and dynamic player save persistence across Project Exvius: Reborn.

---

## 1. Static Data Architecture

Static data is split into two complementary stores:
1. **Baked JSON Templates**: Fast, direct-access JSON structures loaded into memory at startup via `StaticDataLoader` / `StaticData`.
2. **Static SQLite Database (`ffbe-data.db`)**: Read-only SQLite relational database accessed via `GameDatabase` for missions, encounters, monster AI, dialogue scripts, and item databases.

### A. Static Unit Template (`units.json`)
Provides base progression, growth curves, equipment permissions, and rarity entries for playable units.

```json
{
  "100000102": {
    "name": "Rain",
    "rarity_min": 2,
    "rarity_max": 6,
    "job": "Knight",
    "equip": [1, 2, 3, 9, 15, 30, 31, 40, 41, 50, 51, 52, 60],
    "entries": {
      "100000102": {
        "rarity": 2,
        "stats": {
          "HP": [378, 1144, 900, 450],
          "MP": [15, 45, 150, 75],
          "ATK": [14, 41, 65, 32],
          "DEF": [13, 40, 65, 32],
          "MAG": [13, 39, 65, 32],
          "SPR": [12, 37, 65, 32]
        },
        "limitburst_id": 100000102,
        "attack_count": 2,
        "ability_slots": 1,
        "element_resist": [0, 0, 0, 0, 0, 0, 0, 0],
        "status_resist": [0, 0, 0, 0, 0, 0, 0, 0],
        "awakening": {
          "gil": 750,
          "materials": [
            [200000500, 5],
            [200000800, 3]
          ]
        }
      }
    }
  }
}
```

### B. Static Equipment Template (`equipment.json`)
Defines the stats, slots, handedness, and element/status affinities of equippable gear.

```json
{
  "301000200": {
    "name": "Bronze Knife",
    "rarity": 1,
    "type_id": 1,
    "type": "Short Sword",
    "slot_id": 1,
    "slot": "Weapon",
    "is_twohanded": false,
    "stats": {
      "HP": 0,
      "MP": 0,
      "ATK": 10,
      "DEF": 0,
      "MAG": 0,
      "SPR": 0,
      "element_resist": null,
      "element_inflict": null,
      "status_resist": null,
      "status_inflict": null
    },
    "price_buy": 100,
    "price_sell": 10
  }
}
```

### C. SQLite Master Database (`ffbe-data.db`)
Queried at runtime through the `GameDatabase` service:
* **World & Missions**:
  * `world`, `land`, `area`, `town`, `dungeon`: Navigation and world progression hierarchy.
  * `mission`: Mission metadata, energy cost, first-clear rewards, wave count, and background links.
  * `mission_wave`: Spawn formations and monster IDs per wave.
  * `battle_bg`: Background JPG paths and animated SpriteStudio (`ssbp`) layer definitions.
* **Combat & Entities**:
  * `monster`, `monster_parts`: Base stats, resistances, race/killer traits, and drop rates.
  * `monster_ai`: Scripted AI logic with trigger conditions and target priority.
  * `battle_scripts`: Localized combat dialogue (in-battle speech, boss cutscenes, and triggers) in English, Japanese, and Thai.
* **Abilities & Magic**:
  * `skill`, `magic`, `materia`: Opcode parameters (`processId`, `processParam`, `targetType`), MP costs, and frame timings.
  * `beast`, `beast_board`: Esper progression, stat growth patterns, and skill boards.

---

## 2. Dynamic Player Persistence (`user://game_state/`)

All player data is stored locally in the user directory using atomic JSON snapshots managed by the `Persistence` service (`user://game_state/<save_id>__<file>.json`). The default save prefix is `default__`.

### Terminology
* `template_id`: Static string or integer ID matching the datamine (e.g. `"100000102"` for Rain, `"301000200"` for Bronze Knife).
* `instance_id`: Unique UUID v4 string identifying an individual owned unit or piece of equipment.

---

### A. Player Profile (`stats.json`)
Managed by `PlayerProfile` service:

```json
{
  "name": "Rain",
  "rank": 34,
  "xp": 8309,
  "current_nrg": 284,
  "last_nrg_update_time": 1775824657,
  "gil": 154200,
  "lapis": 5400,
  "last_entered_mission_id": "1110101"
}
```
* `max_nrg` and `next_rank_xp` are computed dynamically from static rank tables based on current `rank`.
* NRG regenerates over real-time intervals (300 seconds = 1 NRG).

---

### B. Player Units (`units.json`)
Managed by `UnitService`. Maps each unique `instance_id` to its owned unit state:

```json
{
  "b019e4b9-96a5-4f2a-a664-b746b885fd26": {
    "instance_id": "b019e4b9-96a5-4f2a-a664-b746b885fd26",
    "unit_id": "100000102",
    "level": 35,
    "xp": 14200,
    "current_rarity": 4,
    "trust_value": 45.2,
    "limitburst_level": 5,
    "limitburst_xp": 240,
    "is_locked": true,
    "equipment": {
      "r_hand": "uuid-weapon-1",
      "l_hand": "uuid-shield-1",
      "head": "uuid-helm-1",
      "body": "uuid-armor-1",
      "accessory1": "uuid-acc-1",
      "accessory2": "",
      "materia1": "uuid-mat-1",
      "materia2": "",
      "materia3": "",
      "materia4": ""
    }
  }
}
```

---

### C. Player Inventory (`items.json`)
Managed by `InventoryService` using a hybrid model:

```json
{
  "stackables": {
    "item_potion_01": 25,
    "item_ether_01": 10,
    "mat_iron_ore": 99,
    "mat_lapis_crystal": 5
  },
  "equipment": [
    {
      "instance_id": "uuid-weapon-1",
      "template_id": "301000200",
      "equipped_to": "b019e4b9-96a5-4f2a-a664-b746b885fd26"
    },
    {
      "instance_id": "uuid-weapon-2",
      "template_id": "301000200",
      "equipped_to": null
    }
  ]
}
```
* **Stackables (Fungible)**: Directly mapped as `template_id -> quantity`.
* **Equipment (Non-Fungible)**: Each item possesses a unique `instance_id` and tracks its `equipped_to` unit binding.

---

### D. Combat Item Loadout (`combat_items.json`)
Managed by `CombatItemsService`:

```json
{
  "slots": [
    "item_potion_01",
    "item_hi_potion_01",
    "item_ether_01",
    "",
    "",
    "",
    "",
    "",
    "",
    ""
  ]
}
```
* Fixed-length array of 10 slots available in battle menus. Empty slots are represented by `""`.

---

### E. Party Composition (`parties.json`)
Managed by `PartyService`:

```json
{
  "selected_party_index": 0,
  "parties": [
    {
      "name": "Party 1",
      "units": [
        "b019e4b9-96a5-4f2a-a664-b746b885fd26",
        "03d04f22-4a0d-48ff-b93f-62a1f2210365",
        "10a17f72-ef1a-40e8-abad-902fd7126b85",
        "",
        ""
      ],
      "espers": [
        "1",
        "",
        "",
        "",
        ""
      ]
    }
  ]
}
```
* Contains up to 5 party decks. Slots contain unit instance UUIDs and equipped esper IDs.

---

### F. Espers (`espers.json`)
Managed by `EsperService`:

```json
{
  "1": {
    "esper_id": "1",
    "tier": 1,
    "level": 25,
    "xp": 3400,
    "sp_remaining": 120,
    "unlocked_nodes": [1, 2, 5, 8]
  }
}
```

---

### G. Mission Progress (`mission_progress.json`)
Managed by `MissionService`:

```json
{
  "cleared_missions": {
    "1110101": {
      "cleared": true,
      "objectives": [true, true, true]
    }
  }
}
```
* Tracks cleared status and challenge objectives (star missions) per mission ID.

---

### H. Story & Quest Switches (`switches.json`)
Managed by `StoryFlow` and `EventPlayer`:

```json
{
  "19100010": 1,
  "19100011": 0,
  "19100012": 1
}
```
* Bitflags and trigger conditions governing story progression, NPC dialog variants, and world map unlocks.

---

## 3. Combat Event Log Schema (`BattleEventLog`)

During combat simulation, the `BattleEngine` emits immutable event records consumed by the UI. Key events include:

### `HIT_LANDED`
```json
{
  "action": 101,
  "actor": 0,
  "target": 10,
  "amount": 1250,
  "absorbed": 250,
  "hp_lost": 1000,
  "hp": 3750,
  "max_hp": 5000,
  "chain": 3,
  "chain_pct": 130,
  "spark": false,
  "element_chain": 1
}
```
* `absorbed`: Damage absorbed by an active barrier (`BattleStatus.SHIELD`), triggering "ABSORB" floating callout.

### `LB_CRYSTAL_DROPPED`
```json
{
  "source": 10,
  "target": 0,
  "amount": 100,
  "lb": 600,
  "max_lb": 800
}
```

### `ESPER_ORB_DROPPED`
```json
{
  "source": 10,
  "actor": 0,
  "amount": 1,
  "orbs": 4,
  "max_orbs": 10
}
```

### `STATUS_ADDED`
```json
{
  "action": 102,
  "actor": 0,
  "target": 10,
  "kind": "ailment",
  "key": "SLEEP",
  "value": 0,
  "turns": 3
}
```
* Triggers color-coded floating callout (e.g. "SLEEP", "BARRIER", "ATK UP"), sprite tint & pause, and unit panel / enemy target bar icon.

### `STATUS_REMOVED`
```json
{
  "target": 10,
  "kind": "ailment",
  "key": "SLEEP",
  "value": 0,
  "reason": "damaged"
}
```
* Common `reason` values: `"damaged"` ("WAKE" callout), `"broken"` ("BARRIER BREAK" callout), `"cured"` ("CURED" callout), `"expired"`.

### `STATUS_RESISTED`
```json
{
  "action": 102,
  "actor": 0,
  "target": 10,
  "kind": "ailment",
  "key": "POISON",
  "reason": "resisted"
}
```
* Triggers "RESIST" floating callout.

---

## 4. Item Drop & Town Store Lookup (`GameDatabase.get_item_drop_locations`)

Provides relational lookup for material items across datamined tables (`monster_parts`, `mission_phase`, `battle_group`, `battle_lottery`, `mission`, `dungeon`, `store_item`, `town_store`, `town`):

```json
{
  "dungeons": [
    {
      "dungeon_name": "Earth Shrine",
      "mission_name": "Entrance",
      "land_name": "Grandshelt"
    }
  ],
  "shops": [
    {
      "shop_name": "Provisions Store",
      "town_name": "Royal Capital Grandshelt",
      "land_name": "Grandshelt"
    }
  ]
}
```
* Displayed in `ItemDropPopup.tscn` when clicking the magnifying glass (`unit_classup_item_search_on`) in Unit Awakening (`unit_awakening.gd`) and Ability Awakening (`ability_awakening.gd`).
