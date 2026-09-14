# Alchetris — Design Ideas

**Date:** 2026-09-11
**Source:** design pass by the CCGS `game-designer` agent, run against the current `master`.

**How to read this.** Claims marked **[verified]** were checked against the source
before this file was written — they are facts about the code as it stands today.
Everything else is a *proposal*: the designer's recommendation, including all
suggested numbers. Numbers are tagged by tuning-knob category where it matters:
*feel* (tuned by playtest intuition), *curve* (tuned by math), *gate* (tuned by
session-length targets).

> **⚠️ Outdated premise (2026-09-12).** This document was written while fire blocks
> *banked* damage into `PlayerManager.pendingElementalBonus`, paid out on the next line
> clear. **That mechanic has been removed.** Fire blocks now deal their damage immediately
> on clear, the `charge` ability effect is gone, and `pendingElementalBonus` no longer
> exists. Delayed damage is a rejected design direction, so every proposal below that
> builds on banking — the *resonance* Weaver passive, **Kindle**, **Transmute**, and the
> garbage-banks-charge rule — no longer applies as written. The rest of the analysis still
> stands. Kept as-is for the reasoning, not as a to-do list.
>
> This also retires the **[verified]** finding that `pendingElementalBonus` leaked between
> battles: the variable it described is deleted.

---

## 0. The damage budget — the arithmetic everything else is sized to

**Per-block billing made all play styles mathematically identical.** A tetromino is
4 blocks, and on a hole-free board every block you place eventually clears. So
`payingBlocks × DAMAGE_PER_BLOCK` = **40 damage per piece dropped, no matter how you
clear**. Four singles and one Tetris pay exactly the same. Combo play and
stack-and-Tetris play pay exactly the same.

(This is a throughput idealization — blocks buried in holes never clear and the board
ends non-empty — but the *relative* point is exact: the shape of your clear currently
changes nothing.)

That means the combo multiplier is carrying the entire "how you play matters" load,
and it is set to a flat 1.0. The problem is not that combos are weak. It is that
**skill expression is currently worth zero**.

### Growth needed vs. growth authored

Target fight lengths (*gate* knobs): ~25–30 drops for a normal floor, ~50–65 for a
boss. Against that:

| Floor | Enemy HP (authored) | Effective HP | Drops at 40 dmg/drop | Needed dmg/drop |
|---|---|---|---|---|
| 1 (Bat/Goblin) | 600 | 600 | 15 | 30 |
| 3 (Rock Golem) | 2,000 | 2,000 | 50 | 57 |
| 6 (Wendigo) | 4,000 | 4,000 | 100 | 89 |
| 9 (Centaur) | 8,000 | 8,000 | 200 | 160 |
| 12 (Death Knight) | 12,000 | 12,000 | **300** | 218 |
| 15 (Shadow Lord) | 10,000 @ DR 0.5 | **20,000** | **500** | 285 |

The player needs roughly **×7 damage growth** across the run. What is actually
authored is **×1.5** — `comboMult` reaches 1.2 at absolute best (Monk + Alchemist's
Ring), elementals add ~11/piece banked.

**Shadow Lord is not winnable as tuned.** 500 drops at `attackSteps = 4` is 125
attacks × 60 shield-damage = 7,500 shield needed. Orb income is hard-fixed at
`pieceCount % 3` = 0.33 orbs/drop → ~166 orbs → ~3,333 shield via Barrier. The
~4,000 deficit becomes ~417 HP against a 100-HP pool. Death Knight at 12,000 HP over
300 drops is the same story.

**Spells get weaker as the run goes on. [verified]** `assignRandomElemental` never
rolls ORB, so the only orb source is the fixed every-3rd-piece rule; `max_magic`
raises the *cap*, not the *rate*. Magic Bolt at 50 dmg/orb = 16.7 dmg/drop — roughly
30% of throughput on floor 1, ~11% on floor 15. The spell system goes quiet exactly
when the player has the most spells.

### The budget being designed to

Player damage goes **40 → ~150 per drop (×3.75)** across 15 floors, and **late enemy
HP comes down by roughly half**. Split of the ×3.75: shape-of-clear bonus ×1.8,
combo/bank class axis ×1.3–1.5, spell upgrades ×2.2 on the ~25% of throughput that is
spells, elementals filling the rest.

Revised HP targets (*curve* knobs): F3 2,000 (keep) · F6 4,000 (keep) · F9 **6,000** ·
F12 **7,500** · F15 **9,500 with no flat DR** · Tier-3 normals **3,500–4,500** (down
from 5,000–8,000).

---

## Verified code findings

These were checked against the source and are true of `master` today.

- **[verified] Enemies are not fully data-driven.** `Grid.setStage()` picks the
  starting board with `match enemyInfo.id:` against hardcoded integers (`3, 16` →
  small messy board; `6, 8, 9, 10, 17, 18, 12, 13, 15` → medium; `11, 20` → large).
  A new enemy `.tres` whose id is not listed silently gets a clean board, and
  renumbering an enemy silently changes its opening board. **Fix first** — it blocks
  ideas 4 and 8. Replace with `@export var startingGarbageRows: int = 0` on
  `EnemyData` and `Utilities._generateMessyBoard(enemyInfo.startingGarbageRows)`.
- **[verified] `Grid.clearBottomRows` does `combo += 1` unconditionally.** Any cheap
  `clear_rows` spell is therefore a free combo ladder. Nothing authored exploits this
  today.
- **[verified] `pendingElementalBonus` is never reset between battles.** It is zeroed
  only at run start (`_setDefaults`) and on a line clear (`Main.attack`). Kill an
  enemy with a spell and the bank carries into the next fight. Zero it in
  `Main.stageReady()` unless that is wanted as a feature.
- **[verified] `PlayerManager.updateAbility` is called from nowhere.** The shop's
  "coming soon" upgrade card, and the deep copy in `AbilityData.to_dict()` that exists
  specifically to let a run upgrade a spell without touching the shared `.tres` — the
  whole mechanism is built and dead.
- **[verified] 10 of 21 effect types are used by zero spells:** `damage_per_row`,
  `damage_per_combo`, `heal`, `magic`, `charge`, `clear_rows`, `holy_beam`,
  `shuffle_rows`, `enchant_piece`, `cleanse`. `damage_per_combo` is the Monk's
  signature effect and no spell uses it.

---

## 1. Two classes = two growth curves, not two footnotes

**What it is.** Differentiate classes by *which multiplier in the damage formula they
ride*, not by passive flavour. Monk rides `comboMult` (exponential, earned per-drop,
dies on a single miss). Weaver rides `pendingElementalBonus` (additive, banked across
drops, dumped in one hit).

- **Monk** — `passive = "combo_mastery"`, `COMBO_MASTERY_MULT` **1.0 → 1.20**;
  `maxEnergy` 5 → **4**.
- **Weaver** — `passive = "resonance"` (new): the banked bonus pays out **× lines
  cleared**. `maxEnergy` 5 → **7**. Retire `overload` from the class.

```gdscript
var elementalBonus = PlayerManager.pendingElementalBonus
if PlayerManager.hasPassive("resonance"):
    elementalBonus *= clearedLines
```

**Why it works.** Asymmetric balance with two numbers, and parity falls out at
end-of-run: Monk holding a 5-combo is `40 × 1.20^4 = 83` dmg/drop; Weaver on Tetris
cadence with fire+poison (~11.5 banked/piece × 10 pieces = 115, paid ×4) is
`40 × 1.8 + 46 = 118`; Monk with the same line bonus reaches ~120.

More importantly the two are **mutually exclusive play patterns in real Tetris** —
holding a combo means clearing on every drop, and setting up a Tetris means ~10 drops
of *not* clearing, which zeroes `combo` in `checkAndClearFullLines`. A genuine
intransitive fork, already enforced by existing code. Character select stops being a
false choice (SDT/autonomy), and each class finally has a feel: Monk = sustained
pressure and anxiety about dropping the chain; Weaver = patient accumulation and one
enormous payoff.

**Cost.** Character `.tres` edits + one `hasPassive` branch in `Main.attack` (~3 lines).

**Risk.** `overload` is pure downside with no upside — it punishes without teaching,
which is why the Weaver reads as strictly worse. Re-home it as a high-variance
keepsake: *Overcharged Core — +3 max orbs, orbs at cap burn 5 HP* (needs a
`PlayerManager` bool rather than `hasPassive`, ~2 lines). Also zero
`pendingElementalBonus` in `stageReady()` (see verified findings).

---

## 2. Split the ability pools and starting kits

**What it is.** Both classes currently list all 14 spell ids and both start
`["magic_bolt", "barrier"]`. Split into ~4 neutral + ~5 exclusive each, and give each
class a kit that teaches its axis immediately.

| | Monk | Weaver | Neutral (both) |
|---|---|---|---|
| Starts with | `magic_bolt`, `riposte` | `cinder`, `barricade` | — |
| Pool | `aegis`, `bulwark`, `riposte`, `shield_bash`, `crucible`, `interrupt` | `immolate`, `collapse`, `slag`, `barricade`, `ore_vein`, `cinder` | `magic_bolt`, `barrier`, `interrupt`, `ore_vein` |

Then author six spells against the dead effect types:

| Spell | Class | Cost | Effects |
|---|---|---|---|
| **Cadence** | Monk, rare | 2 orbs, CD 4 | `damage_per_combo: 45` — 225 at combo 5, 45 at combo 1. The class's identity card. |
| **Kindle** | Weaver, common | 1 orb, CD 2 | `charge: 40` — bank-builder; with `resonance` a Tetris pays it 4×. |
| **Transmute** | Weaver, uncommon | 1 orb, CD 5 | `enchant_piece: FIRE` — one tetromino = 4 fire blocks = +60 banked, ×4 on a Tetris. |
| **Mend** | Neutral, uncommon | 2 orbs, burn | `heal: 15` — the only in-battle HP source. HP is the attrition clock, so quietly one of the strongest cards in the game. |
| **Dispel** | Neutral, common | 1 orb, CD 8 | `cleanse` + `damage_enemy: 20` — worthless today (one enemy has DR); idea 4 gives it a job. |
| **Sanctuary** | Monk, uncommon | 1 orb, CD 6 | `holy_beam` + `shield: 15` — board relief that does not break the combo, because `Grid.holyBeam` emits nothing. |

**Cost.** Pure data. Zero code.

**Risk.** Leave `clear_rows` unauthored, or fence it hard. `clearBottomRows`
increments `combo` unconditionally **[verified]**, so a cheap `clear_rows` spell is a
free combo ladder — and at `comboMult 1.20` exponential that is the most degenerate
thing you could ship. Either keep every `clear_rows` spell at CD ≥ 8, or (cleaner, one
line) stop `clearBottomRows` from touching `combo`.

---

## 3. Make "Upgrade Spell" real

**What it is.** 100 coins, pick an equipped spell, every numeric `amount` in its
`effects` rises by **+60% of base**, name gains a `+`. Allow **two upgrades per spell**
(`magic_bolt` 50 → 80 → 110).

**Why it works.** This is the answer to spell decay. Orb income is structurally fixed
at 0.33/drop and should stay that way — it is what keeps spells from replacing the
board. So the only honest way for spells to keep pace with late enemies is for each orb
to buy more, and ×2.2 over two tiers is exactly the budget. It also gives coins a
*vertical* sink: right now coins buy only horizontal breadth (more spells, more
keepsakes), so a player happy with their build has nothing to spend on — a dead
autonomy branch. Per Flow, an upgrade is a milestone: tension releases at the shop,
then re-engages at a higher baseline. That is the sawtooth.

**Cost.** One shop screen wired to machinery that already exists (`updateAbility`,
`to_dict()`'s deep copy) plus one function that walks `effects` and scales `amount`.
Roughly half a day. You would be deleting a "coming soon" string, not adding a system.

**Risk.** Percentage scaling on `damage_per_shield` (Shield Bash) and
`damage_per_garbage` (Immolate) is multiplicative on an already-unbounded base.
Hard-exclude those two types from upgrades, or upgrade them by a flat +1 / +50.

---

## 4. Give enemies verbs, not bigger numbers

**What it is.** Five new `EnemyData` fields, each one branch in `Main.enemyAttack()`
or `setStage`:

| Field | Effect | Targets |
|---|---|---|
| `attackGarbageRows: int` | replaces the `attackAddsGarbage` bool — bury 2–3 rows per attack | the board |
| `breaksCombo: bool` | the attack also sets `$Grid.combo = 0` | **Monk axis** |
| `drainsOrbs: int` | attack steals N orbs from `magicMeter` | spell economy |
| `shieldDecay: float` | unspent shield multiplied by this *before* the hit resolves | shield-bankers |
| `enrageEvery: int` | `attackSteps -= 1` every N attacks, floored at 3 | a soft timer |

Plus `retaliateOnBigClear: int` — a clear of 3+ lines pushes N garbage rows back at
you, wired off `Grid.clearLines`, which already carries `cleared`. That one punishes
the Weaver axis symmetrically.

**Why it works.** This is where the garbage-pays-nothing bet earns its keep. Garbage is
currently a tempo tax with exactly one shape; these give it texture. `breaksCombo` and
`retaliateOnBigClear` are direct counters to the two class axes from idea 1 — and
because `PrepareScene` shows the enemy card **before** you commit the floor, that is
legible rock-paper-scissors the player can route around. The floor-choice screen stops
being "which HP bar" and becomes "which of my strengths is safe here." `shieldDecay` is
the frustra piece: banking shield looks strictly good until floor 11 teaches you there
is a counter.

Suggested assignments (all `.tres`): Banshee `breaksCombo` · Orc Wizard
`drainsOrbs: 1` · Reaper `attackGarbageRows: 2` · Huge Worm `attackGarbageRows: 3`,
`startingGarbageRows: 6` · Death Knight `enrageEvery: 3` + `breaksCombo` · Shadow Lord
`shieldDecay: 0.5` + `retaliateOnBigClear: 1`, **and drop its flat
`damageReduction: 0.5`** — a flat halving is invisible, unfun, and doubles a fight
already 500 drops long. Move DR to two mid-tier enemies at 0.75 instead, where
`cleanse` can answer it and the fight is short enough to feel it.

**Cost.** Five `EnemyData` fields + ~8 lines across `Main.enemyAttack` / `setStage`.
Then pure data forever. **Depends on the `startingGarbageRows` fix in §0.**

**Risk.** `drainsOrbs` can soft-lock a player at 0 orbs with a dead skill panel — a
competence failure, since you cannot tell why you are losing. Never drain below 1, and
never put it on a boss. `breaksCombo` is brutal against a Monk at `comboMult 1.20` —
that is the point, but keep it off enemies with `attackSteps ≤ 4`.

---

## 5. Give bosses a heartbeat

**What it is.** `heavyEvery: int` + `heavyMultiplier: float` on `EnemyData`. Every Nth
attack hits for `attackDamage × multiplier`, and the on-screen counter telegraphs it
(`attack: 3/5 ⚠ HEAVY`). Rock Golem `heavyEvery: 3, ×2.5`. Shadow Lord
`heavyEvery: 4, ×3.0`.

**Why it works.** The attack counter is currently a metronome — identical tension
forever, a flat Flow curve by construction. A 3-beat cadence makes it a sawtooth
*inside a single fight*, and existing systems suddenly have a deadline to play against:

- **`delay_attack` becomes a real decision.** Riposte and Interrupt currently buy 2–3
  drops of nothing in particular. Against a telegraphed heavy they buy *"push the big
  swing past my Tetris."* Same data, ten times the meaning.
- **Persistent shield gets a purpose beyond stockpiling.** You bank shield *to eat beat
  3*. Crucible (90 shield, burn) goes from "a big number" to "the answer to one
  specific moment."
- **`shield_per_row` / `shield_per_garbage` get their window.** They whiff on a clean
  board by design; a telegraphed heavy is exactly when your board is dirtiest.

**Cost.** Two `EnemyData` fields, one branch in `enemyAttack`, one string in
`updateAttackStepsUI`. The pulse animation in `Main._process` already exists — extend
its threshold.

**Risk.** A heavy landing unblocked on an empty shield can delete 15+ HP from a
100-point run pool, which reads as unfair rather than as a mistake. Keep
`heavyMultiplier ≤ 3.0` and telegraph **at least 3 drops out**, not 1.

---

## 6. Reward the *shape* of the clear

**What it is.** Three changes to one line of `Main.attack()`:

```gdscript
damage = payingBlocks × DAMAGE_PER_BLOCK
       × LINE_BONUS[clearedLines]          # [1.0, 1.15, 1.35, 1.8]
       × SPIN_BONUS[tSpinType]             # none 1.0, Mini 1.2, Full 1.6
       × pow(comboMult, combo - 1)
       × damageReduction
       + elementalBonus
```

Plus: **every garbage block cleared banks +5 into `pendingElementalBonus`**, added in
`Grid.printClearedBlockTypes` where the row is already being walked.

**Why it works.** The first two restore the skill economy that per-block billing
flattened. Today a Tetris is worth *exactly four singles* — in a game whose combat
frame is Tetris Battle, where the entire economy is "a Tetris sends 4, a single sends
0." `LINE_BONUS[4] = 1.8` (*feel* knob — start there, playtest) makes stacking a real
commitment again, and it is the Weaver's half of the parity math in idea 1.

T-spins: `Grid.checkTSpin()` already computes `"Full"` / `"Mini"` and already hands
`tSpinType` to `checkAndClearFullLines`, where it only `print()`s. Three lines to pass
it through `clearLines` and multiply. The deeper reason: **a T-spin is how you clear a
line on a board you cannot stack on** — i.e. a board full of the enemy's garbage.
Paying T-spins is paying the dig-out.

The garbage-banks-charge rule is the systemic version of the same patch. The central
bet is right — garbage *should not* pay damage, or the enemy would be handing you
ammunition. But right now the dig pays in nothing, and the player must be able to feel
the difference between a good dig and a bad one. Banking +5/block means a 20-block dig
loads 100 damage onto your next real clear: garbage stops being a tax and becomes
**ammunition you have to survive long enough to fire**. That makes the "setup move, not
a wasted turn" framing mechanically true for the first time, and it turns
`damage_per_garbage` / `shield_per_garbage` plus idea 4's garbage-heavy enemies into a
coherent archetype rather than a niche.

**Cost.** Two const arrays + one multiply, plus widening the `clearLines` signal to
carry `tSpinType`. Garbage-banks-charge is 2 lines in an existing loop.

**Risk.** Line bonus and combo multiply, so a Monk landing a Tetris at combo 4 gets
`1.8 × 1.20^3 = 3.1×`. That is a legitimate skill ceiling and near-impossible to set
up, but it is what `breaksCombo` enemies exist to police. Garbage-banks-charge plus
`retaliateOnBigClear` is a mild reinforcing loop — self-limiting because the garbage
also chokes your board, but watch it. Set the garbage bank at 5, not 10.

---

## 7. Events that trade in things the shop cannot sell

**What it is.** The event schema is good — costs, weighted `outcomes`, `next` pages, a
`Callable` escape hatch — and it is spending it on coins and HP, which the shop already
sells. Add four effect types to `EventScene._applyEffect`, each a one-line call into an
existing function:

- `grant_ability` → `PlayerManager.setEquippedAbility` (first empty slot)
- `grant_keepsake` → `PlayerManager.addKeepsake` (price waived)
- `upgrade_ability` → the idea-3 upgrade function
- `curse_*` → set an `EnemyData`-style debuff for the *next fight only*

Then author 6–8 real events:

- **The Quarry** *(before a boss)* — "Take 15 damage now, or 40 shield now." A live
  test of whether the player has internalised the two-scale split. 40 shield is ~4
  attacks absorbed; 15 HP is 15% of the run. The shop literally cannot offer this,
  because shield persists and is not for sale.
- **The Whetstone** — 75 coins to upgrade one equipped spell. A shop service whose real
  price is a floor.
- **The Glutton** — sacrifice one equipped ability → gain a keepsake. The only
  ability-removal in the game; Spire's card-removal is its most-loved service for a
  reason.
- **The Buried Vault** — weighted: 60% +90 coins, 40% next fight starts with 4 garbage
  rows. Uses `outcomes` + a curse, and the punishment is *board state*.
- **Rival Alchemist** — a 2-page branching event ending in an elite fight for a rare
  spell. Exercises `next` and gives the map a player-elected difficulty spike.
- **The Overflowing Font** — `+3 max_magic`, but the next fight's orbs all arrive at
  once. Makes the orb cap a decision.

**Why it works.** `EVENT_CHANCE = 0.18` over ~9 rollable floors means a run sees 1–2
events drawn from a pool of 2, one of which is labelled an authoring template in the
source. So a typical run sees the demo cart. Once the pool exists, raise
`EVENT_CHANCE` to **0.25** (*gate* knob — it trades fights for texture, and taking a
card spends the floor).

**Cost.** Pure data for the events; ~4 `match` branches in `EventScene._applyEffect`.
The `curse_next_fight` type wants a `PlayerManager` field that `Main.setStage` reads
(~5 lines).

**Risk.** `grant_ability` into a full slot array needs a fallback — offer the equip
screen, since `AbilityDraftScene.generateEquip` already handles exactly this case for
shop purchases. Events granting permanent power raise the run's variance ceiling; gate
the strongest outcomes behind a real cost so a lucky `?` cannot outpace a shop.

---

## 8. Fix the floor bands, and add elites instead of new art

**What it is.** Three changes:

1. **Reband.** `PrepareScene._tierPool` sends floors 8, 10, 11, 13, 14 all to the same
   5-enemy Tier-3 pool — with 2–3 cards per floor that is ~12 draws from 5 enemies, so
   late-run repeats are guaranteed. Reband as `1,2 → T1` · `4,5 → T1+T2` ·
   `8 → T2+T3` · `10,11 → T3` · `13,14 → T3+Elite`.
2. **No repeats.** Add `PlayerManager.defeatedEnemies: Array`, filter it out of
   `_tierPool`, fall back to the full pool when exhausted. ~4 lines, and it fixes the
   *felt* problem immediately even before new content lands.
3. **Five elite `.tres` files** in a new `Data/Enemies/Elite/`: existing frames, ×1.6
   HP, ×1.3 attack damage, **two** verbs from idea 4 each, ×2.5 reward, and a
   guaranteed rare in the post-fight draft. One line in `Consts._init`, one band in
   `_tierPool`.

**Why it works.** Elites are the cheapest roster expansion available — no art, no new
systems — and they solve the other pacing problem: floors 10–14 currently cannot offer
a hard choice, because every card is the same difficulty. An elite beside a normal card
is a genuine risk/reward fork, and it is the natural home for `enrageEvery` and
`shieldDecay`. `bossFloor` already lives on `EnemyData` rather than in file order, so
this slots into a scheduling model that is already data-driven.

**Cost.** Pure data (5 `.tres`) + ~10 lines across `PrepareScene` and `PlayerManager`.
**Depends on the `startingGarbageRows` fix in §0.**

**Risk.** Elites need `reward` high enough to justify the HP, or nobody takes the card
and you have authored dead content. Start at ×2.5 coins **plus** the rare-draft
guarantee. If players still avoid them, the fix is reward, not difficulty.

---

## 9. Degenerate strategies to watch

- **The shield ouroboros — live in the build today, and the worst thing in the game.**
  Shield persists across battles, `enemyAttack` subtracts rather than consumes, and
  `damage_per_shield` explicitly does **not** spend shield. So: Crucible (90 shield,
  burn) + Aegis (free, CD 6) across several easy floors → enter a boss with 300+ banked
  shield → Shield Bash for 300 every 4 drops, forever, for 1 orb. Upgrading Shield Bash
  (idea 3) makes it worse. **Fix:** cap `shieldNum` at **150** (*gate* knob — banking
  before a boss stays a real play, unbounded stockpiling dies), exclude
  `damage_per_shield` from percentage upgrades, give two late enemies `shieldDecay`.
- **The combo ladder.** `clearBottomRows` increments `combo` unconditionally
  **[verified]**. At `comboMult 1.20` exponential this is explosive. No authored spell
  does it today — keep it that way, or stop `clearBottomRows` touching `combo`.
- **The garbage loop.** `add_garbage` (Barricade, 1 orb, CD 3) feeds
  `damage_per_garbage` (Immolate, 150/block). One garbage row is 9 blocks = 1,350
  damage. Bounded today *only* because Immolate is `burn`. **Rule: any
  `damage_per_garbage` spell is burn, or CD ≥ 8. Never both cheap and repeatable.**
- **Combo × line bonus × Monk** = `1.8 × 1.20^n`. Legitimate mastery, but it needs a
  counter in the content — put `breaksCombo` on at least three enemies before shipping
  the 1.20.
- **Bank carry-over.** `pendingElementalBonus` survives battle transitions
  **[verified]**. Zero it in `stageReady()`.

---

## 10. Suggested order

1. **Line bonus + T-spin bonus** (§6). Two const arrays. Restores the entire skill
   economy; an afternoon.
2. **Split the pools, author the 6 spells** (§2). Pure data, zero risk, biggest felt
   change per hour.
3. **Class axes** — `resonance`, `combo_mastery` 1.20, energy caps 4/7 (§1). ~3 lines;
   character select becomes a real choice.
4. **Retune the HP curve down** (§0) and **cap shield at 150** (§9). Pure data; makes
   the back half of the run finishable.
5. **`startingGarbageRows` on `EnemyData`** (§0), then the five enemy verbs (§4).
   Unblocks everything data-driven.
6. **Heavy-attack cadence** (§5), then **spell upgrades** (§3), then **events** (§7)
   and **elites** (§8).

Steps 1–4 are roughly one day and address the class-identity and combo problems
outright. Steps 5–6 are where enemy variety and event content get solved, and they are
mostly content once the fields exist.
