# Alchetris

A roguelike Tetris battle game made with **Godot 4.6**.

You play an alchemist fighting a secret evil cult. Clearing lines is how you attack — a
row you place yourself pays full damage, a row you dig out of the enemy's rubble pays
less but still feeds your combo. Between fights you draft spells, buy keepsakes and
pick your next floor, over a 15-floor run.

Tetris base game by [Juan Cerrone](https://www.youtube.com/user/jpcerrone).

---

## Running

Open the project in the Godot 4.6 editor and press **F5**, or from the CLI:

```
godot --path /path/to/tetris
```

No build step, no dependencies, no test suite.

`GameplayScene.gd` has `const DEV_MODE := true`, which adds a collapsible dev overlay:
jump straight to the shop, draft, floor screen or an event, win the current battle, fill
magic, heal, add coins, or drop a garbage row. That is how you exercise a system without
playing up to it. Set it to `false` to hide the overlay.

---

## A Run

Fifteen floors. Each floor shows 2–3 cards and you take exactly one — an enemy, a `?`
event, or a `$` shop. **Taking any card spends the floor**, so a shop or event replaces
a fight rather than being handed to you on top of one.

- Floors **3, 6, 9, 12, 15** are boss floors: one mandatory boss, no choice
- Floor **7** is a mandatory shop, so there is always one guaranteed restock
- Everything else is rolled, with at most one event per floor and always at least one fight

HP is a single 100-point pool spent across the whole run. Almost nothing refills it —
Rest at a shop (30 HP), a few spells, and some events — so damage taken on floor 2 is
still with you at the boss on floor 15.

---

## Combat

**Attacking.** Line clears bill *per block*, not per row:

```
damage = payingBlocks × 10 × comboMult^(combo-1) × enemyDamageReduction + elementalBonus
```

A clean row is 10 blocks, so a clean line is worth 100 exactly as it always was. What
changed is that garbage blocks pay nothing — a row dug out of enemy garbage only pays for
the blocks you placed. Garbage still completes rows and **still counts for the combo**,
so digging out is a setup move, not a wasted turn.

**Defending.** Enemy attack damage is denominated in *shield*, not HP:

```
overflow = enemyAttackDamage - yourShield     # shield eats the hit first
hpLost   = ceil(overflow / 10)                # only the leak reaches HP
```

Shield is your moment-to-moment defense and it **persists between battles**, so banking it
before a boss is a real play. HP is the run's attrition clock. A hit that leaks always
costs at least 1 HP, so shaving an attack down to a sliver is a win but never free.

The enemy attacks every `attackSteps` piece drops — the counter is on screen and pulses
red when the next drop will trigger it.

---

## Abilities

You have **five ability slots**, cast with keys **1–5**, paid for with magic orbs. Two
slots start filled from your class; the rest you fill during the run.

- **After every victory** you are offered 3 random spells, free — drag one into a slot
- **At a shop** you can buy spells for coins; buying one opens the same screen to equip it
- Filled slots can be dragged onto each other to swap or move

Some spells have a **cooldown** (counted in piece drops, shown as `CD n` in place of the
orb cost). Four are **burn** spells — one cast per battle, then the slot reads `BURNED`
until the next fight.

| Spell | Cost | CD | Effect |
|---|---|---|---|
| Magic Bolt | 1 orb | — | Deal 50 damage |
| Cinder | free | 3 | Deal 30 damage |
| Interrupt | 1 orb | 4 | Deal 40 damage and wind the attack counter back 2 drops |
| Shield Bash | 1 orb | 4 | Deal damage equal to your shield — the shield is not spent |
| Barrier | 1 orb | — | Gain 20 shield |
| Aegis | free | 6 | Gain 10 shield |
| Riposte | 1 orb | 4 | Gain 15 shield and wind the attack counter back 3 drops |
| Bulwark | 2 orbs | 3 | Gain 8 shield per occupied row on your board |
| Barricade | 1 orb | 3 | Gain 45 shield, but push a garbage row onto your own board |
| Ore Vein | 1 orb | 5 | The next piece is an I-piece |
| Plumb Line | 2 orbs | 3 | Deal 15 damage per occupied row on your board |
| Frostbite | 1 orb | 5 | Turn the falling piece to ice, then deal 20 damage |
| **Collapse** | 3 orbs | burn | Every block falls straight down; rows completed on the way clear normally |
| **Crucible** | 3 orbs | burn | Gain 90 shield |
| **Immolate** | 2 orbs | burn | Deal 150 damage per garbage block, then purify them all |
| **Slag** | 2 orbs | burn | Gain 5 shield per garbage block, then purify them all |
| **Absolute Zero** | 3 orbs | burn | Deal 250 damage, then hand the enemy 3 drops of attack progress |

Spells are data — one `.tres` per spell under `Data/Abilities/`, assembled from a
vocabulary of effect types. Adding one usually needs no code at all.

---

## Classes

Picked once at the start of a run.

| Class | Passive |
|---|---|
| **Weaver** — Amplification & Burst | **Overload** — collecting an orb while already at max energy burns 5 HP per wasted orb, straight through shield |
| **Monk** — Discipline & Endurance | **Combo Mastery** — your combo multiplier is 1.1 instead of the flat 1.0 base |

Note that the base combo multiplier is **1.0**, meaning a combo adds nothing on its own.
Combo Mastery and the Alchemist's Ring are currently the only things that raise it.

---

## Magic Orbs

Orbs pay for spells. A run starts with none, and the cap starts at 5.

- Every 3rd piece spawns with one block converted to an **orb block**; clearing it banks the orb
- Clearing orb blocks already on the board also banks them

Orbs collected past the cap are wasted. For the Weaver they are worse than wasted — see
Overload above.

---

## Block Types

Once an elemental is unlocked by its keepsake, **every piece** gets one random block of an
unlocked type. Every 3rd piece gets an orb block instead. Fire banks onto your *next* line
clear; ice pays immediately in tempo instead of damage.

| Block | Colour | How it appears | On clear |
|---|---|---|---|
| Normal | White | Always | — |
| Fire | Red | Ember Charm keepsake | +15 bonus damage per block |
| Ice | Pale blue | Rime Shard keepsake | Delays the enemy attack by 1 drop per block |
| Gold | Yellow | Gilded Idol keepsake | +1 coin per block |
| Orb | Teal | Every 3rd piece | +1 magic orb |
| Garbage | Purple | Enemy attacks | Pays no damage, but still counts for the combo |

---

## Keepsakes

The shop's bottom row: permanent trinkets, bought once, kept for the rest of the run.
Five of the nine are offered per visit, and anything you already own never reappears.

| Keepsake | Price | Effect |
|---|---|---|
| Old Key | 30 | Unlocks holding pieces |
| Magnifying Glass | 30 | See one more upcoming piece |
| Rime Shard | 30 | Unlocks ice blocks |
| Ember Charm | 40 | Unlocks fire blocks |
| Gilded Idol | 40 | Unlocks gold blocks |
| Alchemist's Ring | 40 | +0.1 combo multiplier |
| Heart Locket | 50 | +25 max HP |
| Mana Crystal | 50 | +2 max orb capacity |
| Dragon's Chest | 60 | Every Tetris pays 50 extra coins |

The shop also sells spells and a **Rest** (30 coins for 30 HP).

---

## Controls

| Action | Key |
|---|---|
| Move | ← / → |
| Soft drop | ↓ |
| Hard drop | Space |
| Rotate right / left | ↑ / Z |
| Hold piece | Shift |
| Cast ability 1–5 | 1 – 5 |

All of these are rebindable from the Settings menu.

---

## Project Layout

```
Scripts/Core/       Grid.gd (Tetris engine), Main.gd (battle), Piece.gd
Scripts/Scenes/     run flow — FlowController, PrepareScene, EventScene
Scripts/Managers/   PlayerManager (all run state), PopupNumbers, AudioManager
Scripts/Utils/      Constants, Consts, Keepsakes, Events, Utilities
Scripts/Data/       typed Resource definitions (EnemyData, AbilityData, ...)
Data/               the actual content, as .tres files
Scene/              scenes and UI components
```

All content — enemies, spells, characters, keepsakes — is authored as `.tres` resources
and scanned from its directory at startup, so adding or tuning content needs no code
change. **`CLAUDE.md` documents the architecture in detail**, including the ability effect
vocabulary, the block value encoding, and how to add a new spell.

---

## Status

The engine and every system framework are finished. What remains is mostly content and
balance.

**Working:** the full Tetris engine (SRS rotation with kick tables, hold, next queue,
ghost piece, 7-bag), the battle loop, the 15-floor run structure, the ability system
(14 spells, cooldowns, burn, drafting and swapping), keepsakes, events, the shop, class
passives, key rebinding and audio.

**Known gaps:**

- **Classes barely differ.** Weaver and Monk share the same 14-spell pool, the same
  starting kit and the same orb cap. Only the passive separates them.
- **Enemies differ by numbers only.** 17 of the 20 carry no debuff at all, though the
  data supports them — only Shadow Lord (halves your damage) and two hold-lockers use it.
- **Balance is unverified.** Enemy HP climbs from 600 to 12,000 across the run while the
  player's damage scaling is thin, especially with the combo multiplier flat at 1.0 by
  default. A full run needs playtesting before the numbers can be trusted.
- **Only two events exist**, one of which is an authoring template — the event schema
  supports branching pages, weighted outcomes and costs, and almost none of it is used.
- **Tier pacing is lopsided.** Tier 2 enemies appear on only two floors; five Tier 3
  enemies cover the five remaining non-boss floors, so late-run repeats are guaranteed.
- **T-spins are detected but unrewarded** — the result is only printed to the console.
- **"Upgrade Spell" in the shop is a stub** that prints to the console and does nothing.
- **No save/load.** A run cannot be resumed and there is no meta-progression.
