# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## GodotPrompter

This project targets **Godot 4.6**. Prefer APIs and advice valid for that version.

Before implementing any Godot system, check for a matching `godot-prompter:*` skill and invoke it first. The skills cover movement and input, architecture (state machines, event buses, resource patterns), gameplay systems (inventory, dialogue, abilities, save/load), UI and HUD, animation and audio, physics, shaders and VFX, testing, debugging, and optimization. `godot-prompter:using-godot-prompter` lists them all.

This applies to subagents writing Godot code too. Knowing the engine class is not the same as knowing the pattern — invoke the skill even for a small change, since small changes still pick node types and set architecture.

## Design Docs (Obsidian vault)

`design/` is an Obsidian vault. The repo root is the vault folder, so `CLAUDE.md` and `README.md` are visible in it too.

When writing or editing anything under `design/`:

- **One concept per note.** A risk, a pillar, a scope tier, an open question each get their own file. Do not append a new section to an existing note when it is really a new concept.
- **Link with `[[wikilinks]]`, never "see §N".** Section numbers break the moment a note is split. Obsidian resolves a link by filename alone, so `[[R3-main-attack-god-function]]` works from any folder. A link to a note that doesn't exist yet is fine — it marks work to do.
- **YAML frontmatter on every note.** Risks carry `status` / `severity` / `blocks`; pillars carry `status`; questions carry `status` / `resolve_by`. Keep the keys stable — they are what Dataview queries read.
- **Every code-level claim names the symbol** (`Main.attack()`, `Grid.clearBottomRows`) and must be verified against the repo before being written down, not recalled.
- `design/gdd/game-concept.md` is the index note. Anything new under `design/` gets linked from it or from a note it already links to, or it will be orphaned.
- Playtest logs go in `design/playtests/YYYY-MM-DD-<class>.md` with `class` / `floor_reached` / `result` frontmatter.

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
- `CharacterSelectScene` — pick a class (defined by the `.tres` files in `Data/Characters/`; currently Weaver and Monk)
- `PrepareScene` — the floor choice screen: pick one of 2–3 cards (enemy, event or shop)
- `MainScene` (the `Main.tscn` node) — active battle
- `ShopPanel` — item shop after each victory

`GameplayScene.gd` drives all transitions between these panels using `Utilities.slideIn/slideOut`.

### Autoloaded Singletons

Defined in `project.godot` and available everywhere without `$`:

| Singleton | Script | Purpose |
|---|---|---|
| `PlayerManager` | `Scripts/Managers/PlayerManager.gd` | All persistent run state (HP, shield, magic, coins, upgrades, character class) |
| `Consts` | `Scripts/Utils/Consts.gd` | Static game data: enemy definitions by tier, shop item arrays |
| `Constants` | `Scripts/Utils/Constants.gd` | Tetromino shapes and SRS wall-kick tables |
| `MatrixOperations` | `Scripts/Utils/MatrixOperations.gd` | 2D matrix helpers used for piece rotation |
| `Textures` | `Scripts/Utils/Textures.gd` | Block texture and elemental color lookups |
| `Utilities` | `Scripts/Utils/Utilities.gd` | Shared helpers: animations, board generators, UI utilities |
| `PopupNumbers` | `Scripts/Managers/PopupNumbers.gd` | Floating damage/text popups |
| `AudioManager` | `Scene/AudioManager.tscn` | Central audio node with named players |

### Core Scripts

**`Scripts/Core/Grid.gd`** — The Tetris engine. Owns the 10×23 grid array, piece movement, SRS rotation with kick tables, line clearing, and all board-mutation methods called by skills (`clearBottomRows`, `addGarbageRows`, `purifyGarbage`, `shuffleBottomRows`, `holyBeam`). Emits signals: `clearLines(cleared, combo)`, `pieceDropped`, `magicMeterChanged`, `energyOverflow(count)`, `grid_gameover`.

**`Scripts/Core/Main.gd`** — The battle controller (attached to `Main.tscn` inside `GameplayScene`). Handles all combat math: damage from line clears (with combo multiplier, elemental bonuses, damage reduction), enemy attacks triggered every `attackSteps` piece drops, ability casting (`useSkill` → `_applyAbilityEffect`), win/loss detection. Connects to Grid signals to respond to player actions.

**`Scripts/Core/Piece.gd`** — A single tetromino. Stores its shape matrix and rotation state. Contains elemental block assignment logic (`assignRandomElemental`, `assignOrb`, `assignAllElemental`).

**`Scripts/Managers/PlayerManager.gd`** — Mutable singleton holding the entire run state. Call `PlayerManager.reset()` at the start of a new run. `applyUpgrades(id, price)` uses a dictionary of lambdas keyed by item ID to apply upgrade effects.

### Block Value Encoding

Grid cells store integers that encode both piece identity and elemental type:

```
value = elemental_type * 10 + piece_color_index
```

- `piece_color_index` 1–7 → I, J, L, O, T, Z, S pieces
- Elemental multipliers: 0=none, 1=fire, 3=poison, 4=gold, 5=orb
- `8` → garbage block (enemy attack)
- `0` → empty cell

Example: `33` = poison (3×10) + L piece (3). `grid[x][y] % 10` gives the piece type; `grid[x][y] / 10` gives the elemental type.

### Combat & Damage Formula

Line-clear damage in `Main.gd`:
```
damage = payingBlocks * DAMAGE_PER_BLOCK * comboMult^(combo-1) * damageReduction + elementalBonus
```

- `payingBlocks` is billed **per block, not per row**: every cleared cell except garbage, counted by `Grid.payingBlockCount` and carried on the `clearLines(cleared, combo, paying)` signal. A clean row is 10 blocks × `DAMAGE_PER_BLOCK` (10) = the same 100 a line has always been worth, so a clean board is unchanged — what differs is that a row dug out of the enemy's rubble pays only for the blocks the player placed. Garbage still completes and clears rows normally and **still counts for the combo**, so digging out is a setup move rather than a wasted multiplier. This is the only mechanical difference between a garbage block and a plain one; everything else in `Grid.gd` tests `!= 0` and cannot tell them apart
- `comboMult` starts flat at 1.0 — a combo adds nothing by itself. The Monk's `combo_mastery` passive sets it to 1.1 at character select, and alchemy items raise it from there
- `damageReduction` set per-enemy (e.g. Shadow Lord = 0.5) and is the only damage debuff an enemy carries — it scales, so it never punishes small hits disproportionately
- `elementalBonus` accumulates from fire/poison blocks cleared this drop, consumed on the next line clear

Incoming damage in `Main.enemyAttack()` runs on a different scale from outgoing damage:

```
overflow = enemyAttackDamage - shieldNum      # shield eats the hit first
hpLost   = ceil(overflow / ATTACK_DAMAGE_PER_HP)   # only the leak reaches HP
```

`enemyAttackDamage` (10–60) is denominated in *shield*, not HP. HP is a single
100-point pool spent across the whole 15-floor run — nothing refills it but Rest
(30 HP at a shop), `heal` effects and events — while a late fight can eat a
dozen-plus attacks, so raw attack damage would end a run on floor 3. Dividing by
`ATTACK_DAMAGE_PER_HP` (10) is what reconciles the two scales, and the ceiling
keeps a leaked hit from ever being free. `ENERGY_OVERFLOW_DAMAGE` (5 HP per
wasted orb, Weaver only) is already in HP units and bypasses shield entirely,
which makes an overload burn about as costly as a boss hit.

Shield is therefore the moment-to-moment defense and HP is the run's attrition
clock. Shield persists between battles (only `PlayerManager.reset()` clears it),
so banking it before a boss is a real play.

### Roguelike Progression

15 floors across 5 tiers. Each floor is one choice on `PrepareScene`, generated by `PrepareScene.gd:_rollOptions()`:
- Boss floors (`BOSS_FLOORS` = 3, 6, 9, 12, 15): a single mandatory boss, found by matching `EnemyData.bossFloor` (`PrepareScene._bossForFloor`). To move a boss to a different floor, edit that field — filenames and file order carry no meaning
- Floor 7: a single mandatory shop
- Every other floor: 2–3 cards, each an enemy, a `?` event or a `$` shop

Taking *any* card spends the floor, so a shop or event replaces a fight rather than being extra. Tuning knobs live at the top of `PrepareScene.gd` (`EVENT_CHANCE`, `SHOP_CHANCE`, `MAX_EVENTS`, `FIRST_EVENT_FLOOR`, `FIRST_SHOP_FLOOR`). Two invariants are enforced after the roll: at most `MAX_EVENTS` events per floor, and always at least one fight.

`PlayerManager.currentLevel` persists across battles; `PlayerManager.reset()` resets it to 1. `Main.victory()` steps it after a win, `GameplayScene.advanceFloor()` after an event or shop.

### Adding an Ability

Abilities are data. One `.tres` per ability under `Data/Abilities/`, loaded into `Consts.abilities` at startup. Every data directory is scanned whole and nothing depends on load order, so each file is named for its `id` and nothing else — `id` is identity and must be unique.

What an ability *does* is the `effects` array: `{"type": ..., "amount": ...}` dictionaries applied in order by `Main._applyAbilityEffect`. Current vocabulary:

| type | effect |
|---|---|
| `damage_enemy` | damage the enemy, after its damage reduction |
| `damage_per_row` | `amount` damage per occupied row on the board |
| `damage_per_combo` | `amount` damage per step of the combo held right now |
| `damage_per_garbage` | `amount` damage per garbage block on the board (0 on a clean board — not floored at 1) |
| `damage_per_shield` | `amount` damage per point of current shield; the shield is **not** consumed |
| `shield` | gain shield |
| `shield_per_row` | `amount` shield per occupied row on the board (floored at 1 row, like `damage_per_row`) |
| `shield_per_garbage` | `amount` shield per garbage block on the board (0 on a clean board — not floored, like `damage_per_garbage`) |
| `heal` | restore HP, capped at `maxPlayerHealth` |
| `magic` | refund orbs, capped at `maxMagicMeter` |
| `charge` | bank flat damage onto the next line clear (`pendingElementalBonus`) |
| `clear_rows` | wipe `amount` rows off the bottom of the board |
| `holy_beam` | clear the fullest row — no damage, no combo |
| `purify_garbage` | turn every garbage block back into a normal block |
| `shuffle_rows` | scramble the bottom `amount` rows |
| `compact_board` | every block falls straight down, closing all gaps; rows completed on the way clear normally |
| `add_garbage` | push `amount` garbage rows onto the player's *own* board |
| `enchant_piece` | retype the falling piece to the elemental in `element` |
| `queue_piece` | put the tetromino in `shape` (index into `Constants.SHAPES`) at the front of the queue |
| `cleanse` | strip the enemy's damage reduction for the rest of the battle |
| `delay_attack` | wind the enemy attack counter back `amount` drops |

Most effects carry an int `amount`. `enchant_piece` carries `element` (a
`Constants.Elemental` value) and `queue_piece` carries `shape` (an index into
`Constants.SHAPES`), so `AbilityData.headlineAmount` doesn't print an id as a
card's headline number.

An ability may also set `cooldown` (default 0): the number of pieces that must drop before it can be recast. `Main` tracks remaining cooldown per equipped slot in `_slotCooldown`, decrements it one per `onPieceDropped`, blocks casting while >0, and resets it each battle in `stageReady`. The skill panel shows the countdown (`CD N`) in place of the orb cost while a slot is on cooldown; card tooltips append it via `AbilityData.cooldownLabel`. Skill presses are recorded in `_input` and resolved at end-of-frame by `_resolvePendingCasts` (via `call_deferred`), so a piece dropped on the same frame ticks the cooldown *before* the cast is decided — an unlocking drop always lets that frame's cast through.

An ability may also set `burn` (default `false`) — Slay the Spire's *exhaust*.
Casting a burn ability kills its slot for the rest of the battle: `Main` records
it in `_slotBurned`, `useSkill` checks it *before* the cooldown check, and the
skill panel shows `BURNED` in place of the orb cost. `_resetSlotState` (called
from `stageReady`) is the only thing that clears it, so a burn is per-battle, not
per-run. Burn outranks `cooldown` — a burned slot never comes back this fight —
so a burn ability should leave `cooldown` at 0 rather than carry both.
`Collapse` and `Immolate` are the two burn abilities; card tooltips append the
note via `AbilityData.burnLabel`.

To add one: copy an existing `.tres`, set `id`/`name`/`rarity`/`cost`/`costLabel`/`cooldown`/`price`/`description`, write its `effects`, then **add the id to `abilityPool`** in `Data/Characters/*.tres` — both the draft (`AbilityDraftScene._buildOptions`) and the shop (`ShopPanell.generateItems`) roll from that pool, so an ability missing from it can never be obtained. No code change is needed unless you want a new effect type, which means one new `match` branch in `Main._applyAbilityEffect`.

Four gotchas. `clear_rows` calls `Grid.clearBottomRows`, which emits `clearLines` — wired to `Main.attack()` — so it *also* deals normal line-clear damage and extends the combo; price accordingly. Since that damage is per-block, wiping rows made mostly of garbage pays close to nothing while still extending the combo — `clear_rows` is board relief first and damage second. `compact_board` is the same: it routes completed rows through `checkAndClearFullLines`, so its damage is whatever the collapse happens to clear, which is why it carries no `amount` of its own. `holy_beam` deliberately does *not*: `Grid.holyBeam` emits nothing, so it is pure board relief. And `type` (`attack`/`block`) is descriptive metadata for card visuals only — casting dispatches on `effects`, not on it.

Effects run in order and `useSkill` stops the loop the moment `battleActive` goes false, so an ability that kills the enemy (or tops the player out via `add_garbage`) never runs its remaining effects — that guard is what keeps `victory()` from firing twice.

### Magic Orbs

`PlayerManager.magicMeter` fuels skills, starting a run at 0. It increases when:
1. Orb blocks are cleared from the grid (`orb` elemental type)
2. Every 3rd piece spawned automatically has one block converted to an orb (`Grid.spawnFromBag` checks `pieceCount % 3`)

Energy is capped at `maxMagicMeter`, set from the chosen class's `CharacterData.maxEnergy` (default 5) in `PlayerManager.selectCharacter`, and raised mid-run by `max_magic` upgrades. Orbs collected past the cap are wasted: `Grid.printClearedBlockTypes` emits `energyOverflow(count)`, and `Main.onEnergyOverflow` **burns HP only for classes with the `overload` passive** — `count * ENERGY_OVERFLOW_DAMAGE` (5) straight to HP, bypassing shield. Everyone else wastes the orbs silently. Only board orbs overflow — the `magic` ability effect just caps silently.

### Class Passives

`CharacterData.passive` is a trait id (plus `passiveName`/`passiveDescription` for the character-select blurb built in `PlayerManager.getCharacterDescription`); `""` means the class has none. The systems that implement a passive gate on `PlayerManager.hasPassive("<id>")` rather than on `characterClass`, so a trait can be moved between classes by editing the `.tres` files alone.

| id | class | effect |
|---|---|---|
| `overload` | Weaver | overflowed energy orbs burn HP (`Main.onEnergyOverflow`) |
| `combo_mastery` | Monk | `comboMult` 1.1 instead of the flat 1.0 base (`PlayerManager.selectCharacter`) |

Passives that change a base stat are applied in `selectCharacter`, once, before any keepsake can add to that stat.

`selectCharacter` is also where a class's starting abilities get equipped, so it must be called on character pick (`GameplayScene.onCharacterPressed`); setting `characterClass` alone leaves the previous class's kit.

### Input Actions (defined in project.godot)

`left`, `right`, `soft_drop`, `hard_drop` (Space), `rotate_right` (Up), `rotate_left` (Z), `hold_piece` (Shift), `skill_1`–`skill_4` (keys 1–4).
