# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## GodotPrompter

This project targets **Godot 4.6**. Prefer APIs and advice valid for that version.

Before implementing any Godot system, check for a matching `godot-prompter:*` skill and invoke it first. The skills cover movement and input, architecture (state machines, event buses, resource patterns), gameplay systems (inventory, dialogue, abilities, save/load), UI and HUD, animation and audio, physics, shaders and VFX, testing, debugging, and optimization. `godot-prompter:using-godot-prompter` lists them all.

This applies to subagents writing Godot code too. Knowing the engine class is not the same as knowing the pattern — invoke the skill even for a small change, since small changes still pick node types and set architecture.

## Running the Game

Open the project in the Godot 4.6 editor and press **F5**, or run from the CLI:

```
godot --path /path/to/tetris
```

There is no build step, test suite, or linter — this is a pure Godot project.

**Dev panel.** `GameplayScene.gd` has `const DEV_MODE := true`, which builds a collapsible overlay (`_buildDevPanel`) on a `CanvasLayer` above every panel: jump to the ability draft, shop, floor screen or an event; win the battle; fill magic; full heal; +100 coins; add a garbage row. This is how you exercise a system without playing to it — it is the closest thing the project has to a test harness. Add buttons there rather than hacking temporary code into the systems themselves. Set `DEV_MODE` false to hide it.

## Architecture Overview

**Alchetris** is a roguelike Tetris battle game. The player clears lines to deal damage to enemies, casts abilities fueled by magic orbs, and spends coins on spells and keepsakes between fights.

### Scene Flow

```
Splash.tscn → Menu.tscn → GameplayScene.tscn
```

`GameplayScene.tscn` is the top-level scene for a run. It hosts sibling panels that are slid in and out:

| Panel | Script | Role |
|---|---|---|
| `CharacterSelectScene` | (built inline in `GameplayScene.gd`) | pick a class from the `.tres` files in `Data/Characters/` |
| `PrepareScene` | `Scripts/Scenes/PrepareScene.gd` | the floor choice screen: pick one of 2–3 cards (enemy, event or shop) |
| `Main` | `Scripts/Core/Main.gd` | active battle |
| `AbilityDraftScene` | `Scripts/UI/AbilityDraftScene.gd` | post-victory draft / equip screen |
| `ShopPanel` | `Scripts/UI/ShopPanell.gd` | spells, services and keepsakes |
| `EventScene` | `Scripts/Scenes/EventScene.gd` | `?` events |
| `GameoverPanel` | `Scripts/UI/GameoverPanel.gd` | end-of-run stats, slid in as an overlay |

**`Scripts/Scenes/FlowController.gd`** owns which panel is on screen and the transitions between them. `GameplayScene._connectFlow()` wires every "this panel is done" signal in one place, so the whole run reads top to bottom there. Three entry points:

- `goto(to, prep, onArrive)` — the normal animated transition. `prep` runs while the panel is still offscreen (`_prepBattle` sets the enemy up), `onArrive` runs once it has landed (`_startBattle`, `PrepareScene.unlockCards`). Panels that gate input arm it in `onArrive` — a card taken mid-slide would lock itself and then have its own transition refused by the busy guard, stranding the run.
- `jump(to, prep)` — instant switch, used only by the dev panel; still keeps `current` accurate.
- `overlay(panel)` — slides a panel in on top without removing `current` (game over).

A transition requested while another is running is held in a single `_pending` slot (last request wins) and dispatched when the running one lands, so a burst of clicks can neither be dropped nor queue up a chain of panels.

### Autoloaded Singletons

Defined in `project.godot` and available everywhere without `$`:

| Singleton | Script | Purpose |
|---|---|---|
| `Utilities` | `Scripts/Utils/Utilities.gd` | shared helpers: juice tweens, board generators, `chooseRandom` |
| `Constants` | `Scripts/Utils/Constants.gd` | tetromino shapes, SRS kick tables, the `Elemental` enum |
| `MatrixOperations` | `Scripts/Utils/MatrixOperations.gd` | 2D matrix helpers used for piece rotation |
| `Textures` | `Scripts/Utils/Textures.gd` | block texture and elemental color lookups |
| `Consts` | `Scripts/Utils/Consts.gd` | loads `Data/Enemies`, `Data/Abilities`, `Data/Characters` |
| `Keepsakes` | `Scripts/Utils/Keepsakes.gd` | loads `Data/Keepsakes`; `keepsakes` (id → data) and `pool` |
| `PlayerManager` | `Scripts/Managers/PlayerManager.gd` | all persistent run state |
| `PopupNumbers` | `Scripts/Managers/PopupNumbers.gd` | floating damage/text popups |
| `Events` | `Scripts/Utils/Events.gd` | loads `Data/Events/*.gd`; `events` (id → event) and `pool` |
| `AudioManager` | `Scene/AudioManager.tscn` | central audio node with named players |

`Consts` and `Keepsakes` load their `.tres` files in `_init()`, not `_ready()` — `PlayerManager._ready` reads `Consts.abilities` and `_init` runs before any autoload's `_ready`, so the data is populated regardless of autoload order. Preserve that if you add a data singleton.

`Scripts/Utils/Global.gd` exists but is **not** autoloaded and is unused.

### Core Scripts

**`Scripts/Core/Grid.gd`** — The Tetris engine (~850 lines). Owns the 10×23 grid array (3-row vanish zone), piece movement, SRS rotation with kick tables, line clearing, and every board-mutation method skills call (`clearBottomRows`, `addGarbageRows`, `purifyGarbage`, `shuffleBottomRows`, `holyBeam`, `compactBoard`, `enchantCurrentPiece`, `queuePiece`) plus the board queries they scale off (`occupiedRowCount`, `garbageBlockCount`, `payingBlockCount`). Emits: `clearLines(cleared, combo, paying)`, `pieceDropped`, `magicMeterChanged`, `energyOverflow(count)`, `grid_gameover`.

**`Scripts/Core/Main.gd`** — The battle controller (attached to `Main.tscn` inside `GameplayScene`). All combat math: line-clear damage, enemy moves (picked by `EnemyBrain`, landing every `enemyAttackSteps` drops), ability casting (`useSkill` → `_applyAbilityEffect`), the skill panel, win/loss. Connects to Grid's signals.

**`Scripts/Core/Piece.gd`** — A single tetromino: shape matrix, rotation state, and elemental assignment (`assignRandomElemental`, `assignOrb`, `assignAllElemental`).

**`Scripts/Managers/PlayerManager.gd`** — Mutable singleton holding the entire run state. `reset()` (called from `GameplayScene._ready`) restores defaults; `_setDefaults()` is the single list of what a run starts with. Keepsakes are gained through `addKeepsake(keepsake, pay)`, which applies `acquire` effects via `RunEffects.apply`; `keepsakeEffects(trigger)` is what `Main` fires everything else from.

### Content is Data, Not Code

Every content directory under `Data/` is scanned whole at startup and loaded into a typed `Resource`. Nothing depends on load order or filename, so a file can be added, renamed or dropped without touching code:

| Directory | Class | Loaded into |
|---|---|---|
| `Data/Enemies/{Tier1,Tier2,Tier3,Boss}/` | `.gd` files with `const ENEMY`, built into `EnemyData` | `Consts.tier1Enemy` … `Consts.BossEnemy` |
| `Data/Abilities/` | `AbilityData` | `Consts.abilities` (keyed by `id`) |
| `Data/Characters/` | `CharacterData` | `Consts.characters` |
| `Data/Keepsakes/` | `KeepsakeData` | `Keepsakes.keepsakes` / `Keepsakes.pool` |
| `Data/Events/` | `.gd` files with `const EVENT` (schema in `EventData`) | `Events.events` / `Events.pool` |

The `id` field is identity; each file is named for its `id` and nothing else. Boss scheduling lives in each boss's `boss_floor`, not in file order.

**Validation.** `Scripts/Data/DataValidator.gd` checks abilities, keepsakes, characters and events at boot, called from `Consts._init`, `Keepsakes._init` and `Events._init`. It reports every problem with `push_error` (the game still runs): an unknown effect `type` or keepsake `trigger`, a missing required key or an unexpected one (catches `"ammount"`), a non-numeric `amount`/`min_lines`/`element`/`shape`, an `id` that doesn't match its filename or is reused, an unknown rarity or passive, and an `abilityPool`/`startingAbilities` id with no ability. The allowed lists are `AbilityData.EFFECT_KEYS`, `RunEffects.EFFECT_KEYS`, `KeepsakeData.TRIGGERS`, `CharacterData.PASSIVES` and the `EventData` key lists, where each type maps to the keys it reads (`"amount?"` = optional). **Adding an effect type, trigger or passive means adding it to that list too**, or every file using it fails validation. Beyond key shape it checks what an effect points at: a `shape` inside `Constants.SHAPES`, a `gain_keepsake` id that exists, a `gain_random_keepsake` rarity, and a `call` method the event file defines. Event and option `requires` are checked for known condition names, one key per entry, the right value type, and keepsake and class ids that exist; `locked_text` without `requires` is an error, and a `flag`/`not_flag` naming a flag no `set_flag` anywhere writes is a warning (usually a typo). Enemies are checked by `validateEnemies` (called from `Consts._init`): keys and types, id matching the filename and unique across tiers, a known `board`, passives and move effects against `EnemyData.PASSIVE_KEYS` / `EFFECT_KEYS`, `steps` of at least 1, a known pattern `type`, pattern move ids that exist, `drops` a whole number of at least 1, a `weaken` multiplier above 0, a `call` method the enemy's file defines with one argument, phase thresholds (the opening phase has no `hp_below`, every later one has one, each strictly below the one before and above 0), and `boss_floor` present on every `Boss/` enemy, absent everywhere else and not shared. A move no pattern uses is a warning.

**Enemies are `.gd` files, like events.** Each file in `Data/Enemies/<Tier>/` holds a `const ENEMY` dictionary (schema in `Scripts/Data/EnemyData.gd`); the folder is the tier. `Consts._loadEnemyDir` reads it via `DataFiles.loadConstant` and builds an `EnemyData` with `EnemyData.fromDict`, which is still what `Main`, `PrepareScene` and `GameoverPanel` read. An enemy has a `board` (`clean`/`small`/`medium`/`large`, matched in `Grid.setStage`), `passives` (`damage_reduction`, `disable_hold`, derived into `EnemyData.damageReduction` / `disablesHold`), named `moves` (`steps` to wind up, `effects` run in order — see the table below — and an optional `intent` string overriding the generated intent line) and `phases`, each holding a `pattern` (`cycle` loops its move list, `random` picks uniformly — list a move twice to weight it) and, after the first, an `hp_below` fraction plus an optional `name`. `DataFiles.scriptPaths` is the folder scan both enemies and events use.

**Enemy turns.** `Scripts/Data/EnemyBrain.gd` decides, `Main` performs. `Main.setStage` creates one `EnemyBrain` per battle and takes its first `pickMove()` into `currentMove`; `enemyAttackSteps` is that move's `steps` and is what the attack counter, `delay_attack`/`advance_attack`/`attack_grace` and the red pulse all keep reading. When the counter fills, `enemyAttack` runs the move's effects through `_applyEnemyEffect` (stopping if one tops the player out), resets the counter and grace, and picks the next move. The phase is the last one whose `hp_below` the enemy's HP fraction is under: `updateEnemyHealth` calls `_checkPhase` after every hit, so the phase name pops up the moment the threshold is crossed — but **the move already wound up is committed**, since the player has seen it telegraphed; the new pattern starts on the next pick. A big hit can skip phases, entering a phase starts its cycle at the top, and phases **only move forward** — an enemy that heals back over a threshold stays in the later phase. The HUD shows the move as `"<name> : n / steps"` in `StepsLabel` and what it will do (`EnemyData.describeMove`, e.g. `40 dmg, +1 garbage`) in `IntentLabel`, which `Main._buildIntentLabel` copies from `StepsLabel` at `_ready`. A new enemy effect type needs a branch in `Main._applyEnemyEffect`, an entry in `EnemyData.EFFECT_KEYS`, and a line in `describeMove` if the player should see it coming. `EnemyBrain.rng` can be seeded for a repeatable fight.

Enemy effects (`EnemyData.EFFECT_KEYS`, applied by `Main._applyEnemyEffect`):

| type | effect |
|---|---|
| `attack` | hit shield, then HP (see Combat & Damage Formula) |
| `add_garbage` | `amount` garbage rows onto the player's board |
| `enemy_shield` | `Main.enemyShield += amount`; `updateEnemyHealth` soaks every damage source with it before HP, and it lasts until broken (shown above the enemy's HP by `EnemyShieldLabel`) |
| `heal` | enemy regains `amount` HP, capped at max; never moves the phase back |
| `weaken` | the player's damage × `amount` for `drops` drops, through `Main._outgoingMult()` alongside the `damage_reduction` passive; a new one replaces the multiplier rather than compounding; `cleanse` lifts it |
| `lock_hold` | no hold for `drops` drops; `_refreshHoldLock` keeps a `disable_hold` passive's lock when it expires |
| `hide_preview` | `NextPieces.setConcealed(true)` for `drops` drops — the queue draws empty |
| `curse_piece` | the next `amount` (default 1) uncursed queued pieces become all garbage (`Grid.cursePieces` → `Piece.curse`); the falling piece is never touched, so it always shows in the preview first |
| `call` | run `func <method>(battle)` from the enemy's own file, passed `Main`; a returned String pops up over the enemy |

Timed effects (`drops`) count down in `Main._tickEnemyDebuffs`, called from `onPieceDropped` *before* the attack check, so a debuff a move applies lasts its full count from the next piece; re-applying one keeps the longer count. The `StatusLabel` under the intent line lists what's running (`weak x0.5 (2)  no hold (1)`). `setStage` clears all of it, plus the enemy shield. For `call`, `Consts` keeps each enemy file's GDScript on `EnemyData.fileScript` and `setStage` instances it fresh each battle (`Main._enemyScript`), so a boss function can keep per-fight state; the validator checks the method exists and takes one argument.

A cursed `Piece` keeps `baseColorIndex`, since its cells are all `Constants.GARBAGE`; `assignOrb`/`assignAllElemental`/`assignRandomElemental` skip it, and holding it keeps the curse. `Hold.swapPiece` now rebuilds a held piece from a **copy** of its `Constants.SHAPES` entry — it used to assign the shared array itself, so writing to a piece that had been held (an enchant, a curse) wrote into the shape table.

### Block Value Encoding

Grid cells store integers that encode both piece identity and elemental type:

```
value = elemental_type * Constants.ELEMENTAL_MUL + piece_color_index
```

- `piece_color_index` 1–7 → I, J, L, O, T, Z, S pieces
- `Constants.Elemental`: `NONE = 0`, `FIRE = 1`, `ICE = 2`, `GOLD = 4`, `ORB = 5` (3 is a gap — poison was removed; values are never renumbered, since they are baked into every grid cell)
- `Constants.GARBAGE` (`8`) → garbage block from an enemy attack
- `0` → empty cell

Example: `23` = ice (2×10) + L piece (3). `grid[x][y] % 10` gives the piece type; `grid[x][y] / 10` gives the elemental type. The raw `/10` and `%10` arithmetic is still used in several files — prefer `Constants.Elemental` / `Constants.ELEMENTAL_MUL` in new code.

### Combat & Damage Formula

Line-clear damage in `Main.attack()`:
```
damage = payingBlocks * DAMAGE_PER_BLOCK * comboMult^(combo-1) * damageReduction
```

- `payingBlocks` is billed **per block, not per row**: every cleared cell except garbage, counted by `Grid.payingBlockCount` and carried on the `clearLines(cleared, combo, paying)` signal. A clean row is 10 blocks × `DAMAGE_PER_BLOCK` (10) = the same 100 a line has always been worth, so a clean board is unchanged — what differs is that a row dug out of the enemy's rubble pays only for the blocks the player placed. Garbage still completes and clears rows normally and **still counts for the combo**, so digging out is a setup move rather than a wasted multiplier. This is the only mechanical difference between a garbage block and a plain one; everything else in `Grid.gd` tests `!= 0` and cannot tell them apart
- `comboMult` starts flat at `PlayerManager.BASE_COMBO_MULT` (1.0) — a combo adds nothing by itself. The Monk's `combo_mastery` passive sets it to `COMBO_MASTERY_MULT` (1.1) at character select, and `combo_mult` keepsakes raise it from there
- `damageReduction` set per-enemy by a `damage_reduction` passive (e.g. Shadow Lord = 0.5) and is the only damage debuff an enemy carries — it scales, so it never punishes small hits disproportionately. The `disable_hold` passive (`EnemyData.disablesHold`) is the other debuff
- There is **no** elemental bonus term any more. Fire blocks deal their damage immediately on clear via `fireCleared` rather than being banked into the next clear — see Elemental Blocks below

Incoming damage — an enemy move's `attack` effect, in `Main._applyEnemyEffect` — runs on a different scale from outgoing damage:

```
overflow = amount - shieldNum                      # shield eats the hit first
hpLost   = ceil(overflow / ATTACK_DAMAGE_PER_HP)   # only the leak reaches HP
```

An `attack` `amount` (10–60 today) is denominated in *shield*, not HP. HP is a single
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

15 floors (`PrepareScene.FLOOR_COUNT`) across the enemy tiers. Each floor is one choice on `PrepareScene`, generated by `_rollOptions()`:
- Boss floors (`BOSS_FLOORS` = 3, 6, 9, 12, 15): a single mandatory boss, found by matching `EnemyData.bossFloor` (`PrepareScene._bossForFloor`). To move a boss to a different floor, edit its `boss_floor` (the validator refuses two bosses on one floor)
- `SHOP_FLOORS` (= 7): a single mandatory shop
- Every other floor: 2–3 cards, each an enemy, a `?` event or a `$` shop

Taking *any* card spends the floor, so a shop or event replaces a fight rather than being extra. Tuning knobs live at the top of `PrepareScene.gd` (`EVENT_CHANCE`, `SHOP_CHANCE`, `MAX_EVENTS`, `FIRST_EVENT_FLOOR`, `FIRST_SHOP_FLOOR`, `MIN_OPTIONS`/`MAX_OPTIONS`). Two invariants are enforced after the roll: at most `MAX_EVENTS` events per floor, and always at least one fight. An event card is only rolled at all when `Events.hasEligibleEvent()` — some event's `requires` hold — so a `?` card never leads to an event that can't be shown.

`PlayerManager.currentLevel` persists across battles; `reset()` puts it back to 1. `Main.victory()` steps it after a win, `GameplayScene.advanceFloor()` after an event or shop.

### Abilities

Abilities are data. One `.tres` per ability under `Data/Abilities/`, loaded into `Consts.abilities` at startup. `PlayerManager` keeps a **mutable dictionary copy** of each (`abilityState`, built by `AbilityData.to_dict()`) so a run can retext or upgrade an ability without touching the shared resource — which is why every consumer (`Main.useSkill`, `AbilityDraftScene`, `ShopPanell`) reads a `Dictionary`, not an `AbilityData`.

`PlayerManager.ABILITY_SLOTS` is **5**. `equippedAbilities` is a fixed-size array of ability ids in slot order (`""` = empty), mapped to the `skill_1`–`skill_5` input actions. `selectCharacter` fills the first slots from the class's `startingAbilities`; the rest are drafted into. `Main._buildSkillRows` duplicates the two authored skill rows in `Main.tscn` up to `ABILITY_SLOTS`, so the slot count is changed in one constant.

Two screens grant abilities, both rolling from the class's `CharacterData.abilityPool` — an ability missing from that pool can never be obtained:
- **`AbilityDraftScene.generateDraft`** — after every victory, 3 free options, drag one into a slot. Filled slots are also drag sources (`PlayerManager.swapAbilitySlots`), so dragging onto an empty slot moves and onto a filled one swaps
- **`ShopPanell.generateItems`** — 3 spells for coins. Buying one emits `spellPurchased`, which routes through `AbilityDraftScene.generateEquip` for the slot choice and back to the shop with its stock intact

What an ability *does* is the `effects` array: `{"type": ..., "amount": ...}` dictionaries applied in order by `Main._applyAbilityEffect`. Current vocabulary:

| type | effect |
|---|---|
| `damage_enemy` | damage the enemy, after its damage reduction |
| `damage_per_row` | `amount` damage per occupied row on the board |
| `damage_per_combo` | `amount` damage per step of the combo held right now |
| `damage_per_garbage` | `amount` damage per garbage block on the board (0 on a clean board — not floored at 1) |
| `damage_per_shield` | `amount` damage per point of current shield; the shield is **not** consumed |
| `damage_per_line_cleared` | `amount` damage per line cleared so far *this battle* (`Grid.linesThisBattle`, reset in `resetGrid`); not floored, so an opening cast does nothing |
| `shield` | gain shield |
| `shield_per_row` | `amount` shield per occupied row on the board (floored at 1 row, like `damage_per_row`) |
| `shield_per_garbage` | `amount` shield per garbage block on the board (0 on a clean board — not floored, like `damage_per_garbage`) |
| `shield_per_combo` | `amount` shield per step of the combo held right now (floored at 1, like `damage_per_combo`) |
| `heal` | restore HP, capped at `maxPlayerHealth` |
| `magic` | refund orbs, capped at `maxMagicMeter` |
| `spell_power` | every damaging ability effect deals `amount` **extra flat damage** for the rest of the battle (`Main._spellDamageBonus`, added before the enemy's reduction, reset in `_resetSlotState`) |
| `echo_next_cast` | the **next** ability cast runs its whole effect list twice for one orb cost; never doubles the cast that grants it |
| `self_damage` | lose `amount` HP, bypassing shield like `overload`; **can kill**, and the `battleActive` guard then stops the remaining effects |
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
| `advance_attack` | wind the enemy attack counter *forward* `amount` drops; if that reaches `enemyAttackSteps` the wound-up move lands immediately, mid-cast |
| `attack_grace` | the next `amount` drops don't advance the attack counter (`Main._attackGrace`); unlike `delay_attack` it works on a counter at 0, and `enemyAttack` zeroes it |
| `next_clear_damage` | the next line clear deals `amount` extra damage, before combo and reduction (`Main._nextClearBonus`) |
| `coins` | gain `amount` coins |

Most effects carry an int `amount`. `enchant_piece` carries `element` (a
`Constants.Elemental` value) and `queue_piece` carries `shape` (an index into
`Constants.SHAPES`), so `AbilityData.headlineAmount` doesn't print an id as a
card's headline number.

An ability may also set `cooldown` (default 0): the number of pieces that must drop before it can be recast. `Main` tracks remaining cooldown per equipped slot in `_slotCooldown`, decrements it one per `onPieceDropped`, blocks casting while >0, and resets it each battle in `stageReady`. The skill panel shows the countdown (`CD N`) in place of the orb cost while a slot is on cooldown; card tooltips append it via `AbilityData.cooldownLabel`. Skill presses are recorded in `_input` and resolved at end-of-frame by `_resolvePendingCasts` (via `call_deferred`), so a piece dropped on the same frame ticks the cooldown *before* the cast is decided — an unlocking drop always lets that frame's cast through.

An ability may also set `burn` (default `false`) — Slay the Spire's *exhaust*.
Casting a burn ability kills its slot for the rest of the battle: `Main` records
it in `_slotBurned`, `useSkill` checks it *before* the cooldown check, and the
skill panel shows `BURNED` in place of the orb cost. `_resetSlotState` (called
from `_ready` and `stageReady`) is the only thing that clears it, so a burn is
per-battle, not per-run. Burn outranks `cooldown` — a burned slot never comes
back this fight — so a burn ability should leave `cooldown` at 0 rather than
carry both. `Collapse`, `Crucible`, `Immolate`, `Slag`, `Absolute Zero`, `Attrition` and `Echo Chamber` are the burn abilities; card tooltips
append the note via `AbilityData.burnLabel`.

To add one: copy an existing `.tres`, set `id`/`name`/`rarity`/`cost`/`costLabel`/`cooldown`/`price`/`description`, write its `effects`, then **add the id to `abilityPool`** in `Data/Characters/*.tres`. No code change is needed unless you want a new effect type, which means one new `match` branch in `Main._applyAbilityEffect` plus its entry in `AbilityData.EFFECT_KEYS`.

Four gotchas. `clear_rows` calls `Grid.clearBottomRows`, which emits `clearLines` — wired to `Main.attack()` — so it *also* deals normal line-clear damage and extends the combo; price accordingly. Since that damage is per-block, wiping rows made mostly of garbage pays close to nothing while still extending the combo — `clear_rows` is board relief first and damage second. `compact_board` is the same: it routes completed rows through `checkAndClearFullLines`, so its damage is whatever the collapse happens to clear, which is why it carries no `amount` of its own. `holy_beam` deliberately does *not*: `Grid.holyBeam` emits nothing, so it is pure board relief. And `type` (`attack`/`block`) is descriptive metadata for card visuals only — casting dispatches on `effects`, not on it.

Effects run in order and `useSkill` stops the loop the moment `battleActive` goes false, so an ability that kills the enemy (or tops the player out via `add_garbage`) never runs its remaining effects — that guard is what keeps `victory()` from firing twice.

### Keepsakes

Keepsakes are the shop's bottom row: permanent trinkets bought once, applied immediately, kept for the rest of the run. One `KeepsakeData` `.tres` per keepsake under `Data/Keepsakes/`. Each carries a `rarity` (`common`/`uncommon`/`rare`, same tiers as abilities) that is descriptive only for now — the three elemental unlocks (Rime Shard, Ember Charm, Gilded Idol) are `uncommon`, the rest `common`. `ShopPanell` rolls `KEEPSAKE_COUNT` (5) ids from `Keepsakes.pool`, filtering out anything already in `PlayerManager.ownedKeepsakes`, so an owned keepsake never reappears.

**A keepsake is a list of effects, each on a trigger:** `{"trigger": ..., "type": ..., "amount": ...}`. `KeepsakeData.TRIGGERS` is the list:

| trigger | fires | vocabulary |
|---|---|---|
| `acquire` | once, when gained — bought, or granted by an event (`PlayerManager.addKeepsake` → `RunEffects.apply`) | the out-of-battle vocabulary, `RunEffects.EFFECT_KEYS` (minus the event-only `call`) |
| `battle_start` | `Main.stageReady`, after `battleActive` goes true | the ability vocabulary |
| `line_clear` | `Main.attack`, before the clear's damage lands; optional `min_lines` (4 = Tetris) | the ability vocabulary |
| `victory` | `Main.victory` | the ability vocabulary |

Every trigger except `acquire` runs through `Main._fireKeepsakes(trigger, ctx)`, which asks `PlayerManager.keepsakeEffects(trigger)` for the owned keepsakes' matching descriptors and hands each to `Main._applyAbilityEffect` — the same function spells cast with. So Bandage Roll is `{"trigger": "victory", "type": "heal", "amount": 3}` and needs no code, and any ability effect type is automatically a keepsake effect. `acquire` is the exception because it changes run state outside a battle, which is what events do too — both run through `RunEffects` (see Run Effects below). `KeepsakeData.inShop = false` makes an event-only keepsake: it stays in `Keepsakes.keepsakes` but out of `Keepsakes.pool`, so neither the shop nor `gain_random_keepsake` can roll it, and only an event's `gain_keepsake` with its id can grant it. A new keepsake needs code only for a new trigger (fire it from `Main`, add it to `TRIGGERS`) or a new effect type. `_fireKeepsakes` stops if an effect ends the battle mid-loop, and `attack` returns after firing `line_clear` if the battle ended, so a keepsake can't double-fire `victory()`. Three ability effect types exist mainly for keepsakes: `coins`, `attack_grace` (drops that don't advance the attack counter; works on a counter already at 0, zeroed by `enemyAttack`) and `next_clear_damage` (added to the next clear before combo and reduction). `next_piece` emits `PlayerManager.unlockNextPiece`, which `Main` listens to in order to clear the lock icons.

**Hold is not a keepsake.** It is a default feature for every class: `PlayerManager._setDefaults` sets `canHoldPiece = true`, and the `Old Key` keepsake that used to unlock it has been removed along with its `unlock_hold` effect type. `canHoldPiece` is deliberately kept as the switch a future debuff can turn off — `Grid` gates the hold input on it, and `Main.setStage` re-shows the lock icon when it is false. The existing per-battle enemy debuff is separate and lives in `holdPieceDebuff`, set from `EnemyData.disablesHold` (Death Knight and Slime Body use it). The `PlayerManager.unlockHold` signal is likewise kept but is currently emitted by nothing — `Main.setStage` calls its handler directly.

The shop's other two cards are services defined inline as constants at the top of `ShopPanell.gd`: `HEAL_OPTION` (Rest, 30 coins for 30 HP) and `UPGRADE_OPTION` (not implemented).

### Events

**One GDScript file per event** under `Data/Events/`, named for its id, holding a single `const EVENT` dictionary: `id`, `title`, `start` (first page id) and `pages` (page id → page). Every page of an event lives inside that one file, and page ids are local to it, so an option's `"next": "guardian"` means *this event's* `guardian` page. `Scripts/Data/EventData.gd` documents the full schema in its header comment (a page's optional `title` override, the weighted-`outcomes` form, the `cost` array that grays a button out while unaffordable) and holds the key lists the validator checks.

Events are `.gd` rather than `.tres` on purpose: an event is a tree of prose (event → pages → options → outcomes → effects), and nested sub-resources are painful to write and review in the Inspector. They are still data — `Events._init` scans the folder (handling `.gdc`/`.remap` in exports), reads each file's `EVENT` via `get_script_constant_map()`, and runs `DataValidator.validateEvents`, which checks required/unexpected keys, text fields, costs and effects against `EventData.COST_KEYS`/`RunEffects.EFFECT_KEYS`, positive integer `weight`s, a `start` and every `next` that point at a real page, and options that mix `outcomes` with flat `result`/`effects`/`next`. A page nothing links to is only a warning.

`Events.pool` is every loaded id — follow-up pages can't leak into it because they aren't top-level — so adding a file is all it takes for an event to be rolled. `?` floors call `EventScene.showEvent(Events.rollEvent())`, which picks only from events whose `requires` hold right now; `showEvent()` with no argument does the same (the dev panel's button), falling back to any event with a warning if none qualify. Custom logic lives in the event file itself: define a function there and use `{"type": "call", "method": "name"}`; a returned String is appended to the result text (`strange_shrine.gd`'s `crumble` is the example). Reach for it only for the one-off effect no descriptor covers.

**Conditions and flags.** `requires` is a list of one-key conditions that must all hold, evaluated by `Scripts/Managers/RunConditions.gd` (`RunConditions.met`): `min_floor`, `max_floor`, `min_coins`, `has_keepsake`, `lacks_keepsake`, `class`, `flag`, `not_flag` (`RunConditions.KEYS` maps each to its value type). On an **event** it gates rolling — `Events.rollEvent()` / `hasEligibleEvent()` filter the pool by it. On an **option** it hides the option, unless the option also has `locked_text`, in which case that text is shown on a disabled button. If nothing on a page is usable — hidden, locked or unaffordable — `EventScene` adds a Leave button so the player can't be stranded. Floors compare against `PlayerManager.currentLevel`, which during an event is the floor being spent. Flags are how events remember each other: `set_flag` / `clear_flag` write `PlayerManager.runFlags` (presence only, cleared by `reset()`), and `flag` / `not_flag` read it — `abandoned_cart` sets `robbed_merchant`, and `strange_shrine` shows a hidden Confess option only when it's set.

**Dialogue.** A page may carry `"lines": [{"speaker": "Guardian", "text": "..."}, ...]` (speaker optional), and `body` becomes optional once it does — the validator requires at least one of the two and rejects an empty `lines`. `EventScene` plays the body and then each line as a *beat*: one at a time in the body label, the speaker in a gold label above it, typed out via a `visible_ratio` tween (`TYPE_SECONDS_PER_CHAR`). The Next button finishes the typing first and advances second; after the last beat is fully shown, Next gives way to the options, and that beat's text stays on screen with them. A page with only a body is a single beat and shows instantly with its options, exactly as before `lines` existed. Next and Continue share a spot and are never visible together. Advancing is button-only on purpose: every panel stays in the tree offscreen, so a keyboard shortcut here would also fire mid-battle.

Costs are their own small vocabulary (`EventData.COST_KEYS`: `coins`, `magic`, `hp`), handled by `EventScene._canAfford` / `_payCost`; an HP cost can hurt but never kill.

### Run Effects

`Scripts/Managers/RunEffects.gd` is the **out-of-battle effect vocabulary**, shared by event options and keepsake `acquire` effects — `RunEffects.apply(desc, ctx)` is the only place either is interpreted. It is deliberately separate from the in-battle vocabulary (`Main._applyAbilityEffect`), which needs a live board and enemy.

| type | effect |
|---|---|
| `coins`, `heal`, `shield`, `magic` | as in battle; coins and shield never go below 0, magic is capped at `maxMagicMeter` |
| `lose_hp` | lose `amount` HP, **never below 1** — there is no game-over path outside a battle |
| `max_hp` | move max *and* current HP by `amount`; a negative amount is a curse, floored at 1 |
| `max_magic`, `combo_mult` | raise the stat |
| `next_piece` | reveal `amount` (default 1) more preview slots, capped at `MAX_NEXT_PIECES` (5) |
| `fire_blocks`, `ice_blocks`, `gold_blocks` | unlock the elemental block |
| `gain_keepsake` | grant keepsake `id` free (`addKeepsake(k, false)`), applying its `acquire` effects; skipped if already owned |
| `gain_random_keepsake` | grant a random unowned keepsake from `Keepsakes.pool`, optionally of `rarity` |
| `add_piece` | append `amount` (default 1) copies of `shape` to `PlayerManager.spawnBag` |
| `remove_piece` | remove every copy of `shape`, unless that would leave fewer than `MIN_SPAWN_BAG` (3) pieces |
| `set_flag` / `clear_flag` | set or remove run flag `flag` (`PlayerManager.runFlags`, cleared by `reset()`) |
| `call` | **events only** — run `method` on the event file's instance |

Damage is named by who takes it: `damage_enemy` in battle, `self_damage` for the player in battle, `lose_hp` out of battle.

`PlayerManager.spawnBag` lists the `Constants.SHAPES` index of every piece in a bag (`I, J, L, O, T, Z, S` = 0–6; the default is two of each). `Grid.newBag` reads it, so a piece change shows up from the next bag drawn, which in practice is the next battle. `MIN_SPAWN_BAG` exists because `NextPieces.drawPieces` indexes into the rest of the current bag plus the whole next bag — at least 2n − 1 pieces right after a draw — and must fill up to 5 preview slots; a bag under 3 would index past the end.

`apply` returns a short note for what an author can't know in advance — which random keepsake was granted, a refused `remove_piece`, a custom function's return value — and `EventScene` appends the notes to the result text. `ctx` carries `"event"`, the instance `call` runs on; `EventScene.showEvent` creates a fresh one per showing (`Events.scripts[id].new()`), so a custom function can keep state across the event's pages without leaking it into the next showing.

### Elemental Blocks

Once unlocked by its keepsake, every piece built in `Grid.newBag()` gets one random block
retyped by `Piece.assignRandomElemental()` (orb is separate — `spawnFromBag` stamps it on
every 3rd piece, overwriting whatever was there). `Grid.printClearedBlockTypes` is the one
place that pays them out:

| Element | Value | Payout | Keepsake |
|---|---|---|---|
| Fire | 1 | emits `fireCleared(n)` — deals `n * FIRE_BLOCK_DAMAGE` (15) damage **immediately** | Ember Charm |
| Ice | 2 | emits `iceCleared(n)` — winds the enemy attack counter back `n` drops | Rime Shard |
| Gold | 4 | `pendingGoldCoins += n` | Gilded Idol |
| Orb | 5 | `magicMeter += n`, overflow emits `energyOverflow` | (automatic) |

**Ice pays in tempo, not damage, and its ordering is load-bearing.** `Main.onIceCleared`
subtracts from `dropsSinceAttack`, the same counter `onPieceDropped` increments. The delay
resolves first *by construction*: `Grid.afterDrop()` calls `checkAndClearFullLines()` —
which calls `printClearedBlockTypes` and emits `iceCleared` — **before** it emits
`pieceDropped`. So clearing one ice block on the drop that would have triggered an attack
cancels that attack instead of arriving a step late. Do not reorder those two calls in
`afterDrop()`, and do not move the ice payout to a `pieceDropped` handler.

**Fire pays immediately too, and there is no banking anywhere in the game.** `Main.onFireCleared`
deals its damage the moment the block clears — in the same frame, and *before* the
line-clear damage for that row, since `fireCleared` is emitted inside
`checkAndClearFullLines` and `clearLines` is emitted after it. That ordering means fire can
kill the enemy before the clear that produced it is billed, which is why `Main.attack()`
opens with a `battleActive` guard: without it `updateEnemyHealth` would call `victory()` a
second time and advance the floor twice. Fire routes through `Main._dealFlatDamage`, so it
respects the enemy's `damageReduction` like every other damage source but does **not** pick
up `_spellDamageBonus` — a fire block is not a spell.

The old `charge` effect and `PlayerManager.pendingElementalBonus` that fire used to fill
have both been deleted. Delayed damage is a rejected mechanic: do not reintroduce a
bank-now-pay-later effect.

Fire and ice both count wherever `printClearedBlockTypes` runs, so `clear_rows` and `compact_board`
also collect them. `holy_beam` does **not** — `Grid.holyBeam` emits nothing, consistent with
it paying no damage and no combo either.

### Magic Orbs

`PlayerManager.magicMeter` fuels skills, starting a run at 0. It increases when:
1. Orb blocks are cleared from the grid (`orb` elemental type)
2. Every 3rd piece spawned automatically has one block converted to an orb (`Grid.spawnFromBag` checks `pieceCount % 3`)

Energy is capped at `maxMagicMeter`, set from the chosen class's `CharacterData.maxEnergy` (default 5) in `PlayerManager.selectCharacter`, and raised mid-run by `max_magic` keepsakes. Orbs collected past the cap are wasted: `Grid.printClearedBlockTypes` emits `energyOverflow(count)`, and `Main.onEnergyOverflow` **burns HP only for classes with the `overload` passive** — `count * ENERGY_OVERFLOW_DAMAGE` (5) straight to HP, bypassing shield. Everyone else wastes the orbs silently. Only board orbs overflow — the `magic` ability effect just caps silently.

### Class Passives

`CharacterData.passive` is a trait id (plus `passiveName`/`passiveDescription` for the character-select blurb built in `PlayerManager.getCharacterDescription`); `""` means the class has none. The systems that implement a passive gate on `PlayerManager.hasPassive("<id>")` rather than on `characterClass`, so a trait can be moved between classes by editing the `.tres` files alone.

| id | class | effect |
|---|---|---|
| `overload` | Weaver | overflowed energy orbs burn HP (`Main.onEnergyOverflow`) |
| `combo_mastery` | Monk | `comboMult` 1.1 instead of the flat 1.0 base (`PlayerManager.selectCharacter`) |

Passives that change a base stat are applied in `selectCharacter`, once, before any keepsake can add to that stat.

`selectCharacter` is also where a class's starting abilities get equipped, so it must be called on character pick (`GameplayScene.onCharacterPressed`); setting `characterClass` alone leaves the previous class's kit.

### Input Actions (defined in project.godot)

`left`, `right`, `soft_drop`, `hard_drop` (Space), `rotate_right` (Up), `rotate_left` (Z), `hold_piece` (Shift), `skill_1`–`skill_5` (keys 1–5). `Menu.gd` lets the player rebind these at runtime via `InputMap`, so never assume a keycode — read the action.

## README

`README.md` carries the credit for the Tetris base (Juan Cerrone), the block-type table (which elemental is unlocked by what, and what it pays on clear), and a live TODO list of balance/content/code debt. The player-facing catalogues live under **`Docs/`**: **`Docs/ABILITIES.md`** (slots/drafting and the full spell table), **`Docs/KEEPSAKES.md`** (keepsakes and the shop services) and **`Docs/ENEMIES.md`** (per-tier and boss stat tables, starting boards, which floors each tier covers), alongside `Docs/DESIGN-IDEAS.md`. All three are hand-maintained, so treat `Data/Abilities/`, `Data/Keepsakes/` and `Data/Enemies/` as the source of truth and update the matching file in `Docs/` when you add or retune content. `README.md` and `CLAUDE.md` stay at the repo root.
