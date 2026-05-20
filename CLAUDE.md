# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Running the Game

Open the project in the Godot 4.6 editor and press **F5**, or run from the CLI:

```
godot --path /path/to/tetris
```

There is no build step, test suite, or linter — this is a pure Godot project.

## Architecture Overview

**Alchetris** is a roguelike Tetris battle game. The player clears lines to deal damage to enemies, uses character skills fueled by a Magic Meter, and buys upgrades between rounds.

### Scene Flow

```
Splash.tscn → Menu.tscn → GameplayScene.tscn
```

`GameplayScene.tscn` is the top-level scene for a run. It hosts four sub-scenes that are swapped in/out:
- `CharacterSelectScene` — pick a class (Wizard, Knight, Rogue, Cleric)
- `PrepareScene` — pick an enemy from 3 random options
- `MainScene` (the `Main.tscn` node) — active battle
- `ShopPanel` — item shop after each victory

`GameplayScene.gd` drives all transitions between these panels using `Utilities.slideIn/slideOut`.

### Autoloaded Singletons

Defined in `project.godot` and available everywhere without `$`:

| Singleton | Script | Purpose |
|---|---|---|
| `PlayerManager` | `Scripts/Managers/PlayerManager.gd` | All persistent run state (HP, shield, magic, coins, upgrades, character class) |
| `Consts` | `Scripts/Utils/Consts.gd` | Static game data: enemy definitions by tier, shop item arrays |
| `Constants` | `Scripts/Constants.gd` | Tetromino shapes and SRS wall-kick tables |
| `MatrixOperations` | `Scripts/Utils/MatrixOperations.gd` | 2D matrix helpers used for piece rotation |
| `Textures` | `Scripts/Textures.gd` | Block texture and elemental color lookups |
| `Utilities` | `Scripts/Utils/Utilities.gd` | Shared helpers: animations, board generators, UI utilities |
| `PopupNumbers` | `Scripts/Managers/PopupNumbers.gd` | Floating damage/text popups |
| `AudioManager` | `Scene/AudioManager.tscn` | Central audio node with named players |

### Core Scripts

**`Scripts/Grid.gd`** — The Tetris engine. Owns the 10×23 grid array, piece movement, SRS rotation with kick tables, line clearing, and all board-mutation methods called by skills (`clearBottomRows`, `addGarbageRows`, `purifyGarbage`, `shuffleBottomRows`, `holyBeam`). Emits signals: `clearLines(cleared, combo)`, `hardDrop`, `shieldChanged`, `magicMeterChanged`, `grid_gameover`.

**`Scripts/Main.gd`** — The battle controller (attached to `Main.tscn` inside `GameplayScene`). Handles all combat math: damage from line clears (with combo multiplier, elemental bonuses, damage reduction), enemy attack timer, all 16 character skills, win/loss detection. Connects to Grid signals to respond to player actions.

**`Scripts/Piece.gd`** — A single tetromino. Stores its shape matrix and rotation state. Contains elemental block assignment logic (`assignRandomElemental`, `assignOrb`, `assignAllElemental`).

**`Scripts/Managers/PlayerManager.gd`** — Mutable singleton holding the entire run state. Call `PlayerManager.reset()` at the start of a new run. `applyUpgrades(id, price)` uses a dictionary of lambdas keyed by item ID to apply upgrade effects.

### Block Value Encoding

Grid cells store integers that encode both piece identity and elemental type:

```
value = elemental_type * 10 + piece_color_index
```

- `piece_color_index` 1–7 → I, J, L, O, T, Z, S pieces
- Elemental multipliers: 0=none, 1=fire, 2=ice, 3=poison, 4=gold, 5=orb
- `8` → garbage block (enemy attack)
- `0` → empty cell

Example: `23` = ice (2×10) + L piece (3). `grid[x][y] % 10` gives the piece type; `grid[x][y] / 10` gives the elemental type.

### Combat & Damage Formula

Line-clear damage in `Main.gd`:
```
damage = (clearedLines * 100 * comboMult^(combo-1) - damageReductionFlat) * damageReduction + elementalBonus
```

- `comboMult` starts at 1.1, increased by alchemy items
- `damageReductionFlat` set per-enemy (e.g. Banshee = 15)
- `damageReduction` set per-enemy (e.g. Shadow Lord = 0.5)
- `elementalBonus` accumulates from fire/poison blocks cleared this drop, consumed on the next line clear

### Roguelike Progression

15 levels across 5 tiers. Boss enemies appear at levels 3, 6, 9, 12, 15. Level structure in `GameplayScene.gd:generateRandomEnemies()`:
- Levels 1–2: 3 random tier1 enemies
- Level 3: Boss 0 (rock golem)
- Levels 4–5: 3 random tier2 enemies
- etc.

`PlayerManager.currentLevel` persists across battles; `PlayerManager.reset()` resets it to 1.

### Magic Orbs

`PlayerManager.magicMeter` fuels skills. It increases when:
1. Orb blocks are cleared from the grid (`orb` elemental type)
2. Every 3rd piece spawned automatically has one block converted to an orb (`Grid.spawnFromBag` checks `pieceCount % 3`)

### Input Actions (defined in project.godot)

`left`, `right`, `soft_drop`, `hard_drop` (Space), `rotate_right` (Up), `rotate_left` (Z), `hold_piece` (Shift), `skill_1`–`skill_4` (keys 1–4).
