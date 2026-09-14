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
| `Events` | `Scripts/Utils/Events.gd` | `?` event definitions and the `pool` of valid starting pages |
| `AudioManager` | `Scene/AudioManager.tscn` | central audio node with named players |

`Consts` and `Keepsakes` load their `.tres` files in `_init()`, not `_ready()` — `PlayerManager._ready` reads `Consts.abilities` and `_init` runs before any autoload's `_ready`, so the data is populated regardless of autoload order. Preserve that if you add a data singleton.

`Scripts/Utils/Global.gd` exists but is **not** autoloaded and is unused.

### Core Scripts

**`Scripts/Core/Grid.gd`** — The Tetris engine (~850 lines). Owns the 10×23 grid array (3-row vanish zone), piece movement, SRS rotation with kick tables, line clearing, and every board-mutation method skills call (`clearBottomRows`, `addGarbageRows`, `purifyGarbage`, `shuffleBottomRows`, `holyBeam`, `compactBoard`, `enchantCurrentPiece`, `queuePiece`) plus the board queries they scale off (`occupiedRowCount`, `garbageBlockCount`, `payingBlockCount`). Emits: `clearLines(cleared, combo, paying)`, `pieceDropped`, `magicMeterChanged`, `energyOverflow(count)`, `grid_gameover`.

**`Scripts/Core/Main.gd`** — The battle controller (attached to `Main.tscn` inside `GameplayScene`). All combat math: line-clear damage, enemy attacks every `attackSteps` drops, ability casting (`useSkill` → `_applyAbilityEffect`), the skill panel, win/loss. Connects to Grid's signals.

**`Scripts/Core/Piece.gd`** — A single tetromino: shape matrix, rotation state, and elemental assignment (`assignRandomElemental`, `assignOrb`, `assignAllElemental`).

**`Scripts/Managers/PlayerManager.gd`** — Mutable singleton holding the entire run state. `reset()` (called from `GameplayScene._ready`) restores defaults; `_setDefaults()` is the single list of what a run starts with. Keepsake purchases go through `addKeepsake` → `applyAcquireEffect`; `keepsakeEffects(trigger)` is what `Main` fires everything else from.

### Content is Data, Not Code

Every content directory under `Data/` is scanned whole at startup and loaded into a typed `Resource`. Nothing depends on load order or filename, so a file can be added, renamed or dropped without touching code:

| Directory | Class | Loaded into |
|---|---|---|
| `Data/Enemies/{Tier1,Tier2,Tier3,Boss}/` | `EnemyData` | `Consts.tier1Enemy` … `Consts.BossEnemy` |
| `Data/Abilities/` | `AbilityData` | `Consts.abilities` (keyed by `id`) |
| `Data/Characters/` | `CharacterData` | `Consts.characters` |
| `Data/Keepsakes/` | `KeepsakeData` | `Keepsakes.keepsakes` / `Keepsakes.pool` |

The `id` field is identity; each file is named for its `id` and nothing else. Boss scheduling lives in `EnemyData.bossFloor`, not in file order.

**Validation.** `Scripts/Data/DataValidator.gd` checks abilities, keepsakes and characters at boot, called from `Consts._init` and `Keepsakes._init`. It reports every problem with `push_error` (the game still runs): an unknown effect `type` or keepsake `trigger`, a missing required key or an unexpected one (catches `"ammount"`), a non-numeric `amount`/`min_lines`/`element`/`shape`, an `id` that doesn't match its filename or is reused, an unknown rarity or passive, and an `abilityPool`/`startingAbilities` id with no ability. The allowed lists are `AbilityData.EFFECT_KEYS`, `KeepsakeData.TRIGGERS`/`ACQUIRE_EFFECTS` and `CharacterData.PASSIVES`, where each type maps to the keys it reads (`"amount?"` = optional). **Adding an effect type, trigger or passive means adding it to that list too**, or every file using it fails validation. Enemies and events are not validated.

**One exception — enemies are not fully data-driven.** `Grid.setStage()` picks the
battle's starting board with `match enemyInfo.id:` against a hardcoded list of integer
ids (`3, 16` → small messy board, `6, 8, 9, ...` → medium, `11, 20` → large). A new
enemy `.tres` whose `id` is not in that list silently falls through to `_` and gets a
clean board, and renumbering an existing enemy silently changes its opening board. This
is the only place enemy behaviour is keyed by id rather than by an exported field;
replacing it with a `startingGarbageRows: int` export on `EnemyData` would close the gap.

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
- `damageReduction` set per-enemy (e.g. Shadow Lord = 0.5) and is the only damage debuff an enemy carries — it scales, so it never punishes small hits disproportionately. `EnemyData.disablesHold` is the other debuff
- There is **no** elemental bonus term any more. Fire blocks deal their damage immediately on clear via `fireCleared` rather than being banked into the next clear — see Elemental Blocks below

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

15 floors (`PrepareScene.FLOOR_COUNT`) across the enemy tiers. Each floor is one choice on `PrepareScene`, generated by `_rollOptions()`:
- Boss floors (`BOSS_FLOORS` = 3, 6, 9, 12, 15): a single mandatory boss, found by matching `EnemyData.bossFloor` (`PrepareScene._bossForFloor`). To move a boss to a different floor, edit that field
- `SHOP_FLOORS` (= 7): a single mandatory shop
- Every other floor: 2–3 cards, each an enemy, a `?` event or a `$` shop

Taking *any* card spends the floor, so a shop or event replaces a fight rather than being extra. Tuning knobs live at the top of `PrepareScene.gd` (`EVENT_CHANCE`, `SHOP_CHANCE`, `MAX_EVENTS`, `FIRST_EVENT_FLOOR`, `FIRST_SHOP_FLOOR`, `MIN_OPTIONS`/`MAX_OPTIONS`). Two invariants are enforced after the roll: at most `MAX_EVENTS` events per floor, and always at least one fight.

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
| `advance_attack` | wind the enemy attack counter *forward* `amount` drops; if that reaches `attackSteps` the enemy attacks immediately, mid-cast |
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
| `acquire` | once, on purchase (`PlayerManager.addKeepsake` → `applyAcquireEffect`) | `KeepsakeData.ACQUIRE_EFFECTS`: `combo_mult`, `max_hp`, `heal`, `max_magic`, `next_piece`, `fire_blocks`, `ice_blocks`, `gold_blocks` |
| `battle_start` | `Main.stageReady`, after `battleActive` goes true | the ability vocabulary |
| `line_clear` | `Main.attack`, before the clear's damage lands; optional `min_lines` (4 = Tetris) | the ability vocabulary |
| `victory` | `Main.victory` | the ability vocabulary |

Every trigger except `acquire` runs through `Main._fireKeepsakes(trigger, ctx)`, which asks `PlayerManager.keepsakeEffects(trigger)` for the owned keepsakes' matching descriptors and hands each to `Main._applyAbilityEffect` — the same function spells cast with. So Bandage Roll is `{"trigger": "victory", "type": "heal", "amount": 3}` and needs no code, and any ability effect type is automatically a keepsake effect. `acquire` stays separate because it changes run state outside a battle. A new keepsake needs code only for a new trigger (fire it from `Main`, add it to `TRIGGERS`) or a new effect type. `_fireKeepsakes` stops if an effect ends the battle mid-loop, and `attack` returns after firing `line_clear` if the battle ended, so a keepsake can't double-fire `victory()`. Three ability effect types exist mainly for keepsakes: `coins`, `attack_grace` (drops that don't advance the attack counter; works on a counter already at 0, zeroed by `enemyAttack`) and `next_clear_damage` (added to the next clear before combo and reduction). `next_piece` emits `PlayerManager.unlockNextPiece`, which `Main` listens to in order to clear the lock icons.

**Hold is not a keepsake.** It is a default feature for every class: `PlayerManager._setDefaults` sets `canHoldPiece = true`, and the `Old Key` keepsake that used to unlock it has been removed along with its `unlock_hold` effect type. `canHoldPiece` is deliberately kept as the switch a future debuff can turn off — `Grid` gates the hold input on it, and `Main.setStage` re-shows the lock icon when it is false. The existing per-battle enemy debuff is separate and lives in `holdPieceDebuff`, set from `EnemyData.disablesHold` (Death Knight and Slime Body use it). The `PlayerManager.unlockHold` signal is likewise kept but is currently emitted by nothing — `Main.setStage` calls its handler directly.

The shop's other two cards are services defined inline as constants at the top of `ShopPanell.gd`: `HEAL_OPTION` (Rest, 30 coins for 30 HP) and `UPGRADE_OPTION` (not implemented).

### Events

`?` floors run `EventScene.showEvent(id)` with an id picked from `Events.pool`. Every event is one **page** in the `Events.events` dictionary; multi-page events are just more entries reached by an option's `"next"`, and those follow-up pages must **not** be listed in `pool` (it holds valid starting points only). `Events.gd` documents the full schema in its header comment, including the weighted-`outcomes` form and the `cost` array that grays a button out while unaffordable.

Event effect descriptors are interpreted by `EventScene._applyEffect` and are a *different* vocabulary from abilities: `coins`, `heal`, `damage`, `max_hp`, `shield`, `magic`, `max_magic`. The names deliberately match the ability ones where the meaning is the same; `damage` is the exception — in an event it hurts the *player*, which is why the ability version is called `damage_enemy`. `_canAfford` handles `coins`, `magic` and `hp` costs (an HP cost can hurt but never kill).

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

`README.md` carries the credit for the Tetris base (Juan Cerrone), the block-type table (which elemental is unlocked by what, and what it pays on clear), and a live TODO list of balance/content/code debt. The player-facing catalogues live under **`Docs/`**: **`Docs/ABILITIES.md`** (slots/drafting and the full spell table) and **`Docs/KEEPSAKES.md`** (keepsakes and the shop services), alongside `Docs/DESIGN-IDEAS.md`. Both are hand-maintained, so treat `Data/Abilities/` and `Data/Keepsakes/` as the source of truth and update the matching file in `Docs/` when you add or retune content. `README.md` and `CLAUDE.md` stay at the repo root.
