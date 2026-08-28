# Alchetris — Game Concept

**Status:** Concept locked · **Date:** 2026-08-15 · **Author:** Patrick
**Session:** `/brainstorm tetris roguelike --review full` — formalization pass over an existing playable build
**Review gates run:** CD-PILLARS · AD-CONCEPT-VISUAL · TD-FEASIBILITY · PR-SCOPE

---

## 1. Core Identity

| Field | Value |
|---|---|
| **Working title** | Alchetris |
| **Genre** | Roguelike Tetris battler / build-craft roguelike |
| **Core verb** | **Place** — every piece is one decision serving two competing economies |
| **Core fantasy** | An alchemist who wins by transmutation: you don't out-stack the enemy, you convert the board into whatever your build eats |
| **Unique hook** | Like a Tetris battler, **and also** a build-craft roguelike where two players can clear the same lines and deal damage through completely different systems |
| **Primary MDA aesthetic** | Expression, with Challenge as the ceiling on each build rather than the point of the game |
| **Estimated scope** | Large — **6–8 months to ship (solo, part-time)**; full vision 15–20+ months |
| **Engine** | Godot 4.6 (settled — ~3,600 lines GDScript, data-driven `.tres` content pipeline already built) |
| **Platform** | **PC first (Steam/Epic).** Console deferred to post-launch — see §9 |
| **Current state** | Playable. 2 classes, 10 abilities, 20 enemies, 10 keepsakes, 15-floor run structure, shops, events, ability draft |

### Elevator pitch

> A roguelike Tetris battler where the board is simultaneously your weapon and your mana battery, and your build decides which one it is.

---

## 2. Design Pillars

Pillars as originally drafted were reviewed at gate **CD-PILLARS** (verdict: CONCERNS) and rewritten. The
rewrites below are the locked set. Rationale for each change is in §11.

### P1 — Two payout curves, one engine

Every build clears lines. Builds differ in **when** the board pays and **what** the payout buys.
Class passives set your default curve; run rewards let you pivot off it.

> **Test:** name the build that doesn't want this item. If you can't, it's a stat stick — cut it, or make it
> pick a side. *Exemption:* survivability and economy items may be archetype-neutral, capped at ~20% of the pool.

**Why the rewrite.** The original P1 ("two roads up the mountain — separate scaling axes") was false in the
build and contradicted by the elevator pitch. There is exactly one faucet: energy comes from orb blocks, and
orb blocks pay out only *when their row is cleared*. Energy is therefore a linear function of lines cleared
plus RNG — the same axis with latency, not a second axis.

What actually differentiates the archetypes is **class passives imposing a cadence**, and that already ships:

| Class | Passive | Cadence it forces |
|---|---|---|
| **Weaver** | `overload` — orbs collected at full energy burn 5 HP each, ignoring shield | Cannot bank indefinitely. Must weave spells between clears. **Burst, forcibly spent.** |
| **Monk** | `combo_mastery` — base `comboMult` 1.1 instead of 1.0 | Rewarded for combo continuity from floor 1. **Steady drip**, pivotable to caster via run rewards. |

This is a real mechanical distinction on an identical board. Future classes are differentiated the same way:
a passive that changes *when you must spend*, not *how you must stack*.

### P2 — Power is bought, never given

Every gain names its currency: **time, consistency, or risk**.

> **Test:** if you can name the build where the drawback costs nothing, it isn't a trade-off, it's a
> conditional buff — change the axis, not the numbers.

**Known counterexample to fix or grandfather:** `max_magic` and flat damage upgrades are currently clean buffs.
**Known trap:** the "Burn" enchantment as first drafted ("once per battle, 2× damage") is a per-spell verdict,
not a trade-off — a strict nerf on a spell cast three times, a strict *buff* on one cast once anyway (heal,
panic block). Use-count is the wrong axis.

### P3 — The board is honest

Spells change the board; **only the board pays**. No spell mints damage, energy, or combo — it moves blocks,
buys pieces, or converts what's already there.

> **Test:** after casting, would a player who stops stacking for 5 pieces still be ahead? Then the cost is wrong.

**Live violation, blocking:** `clear_rows` → `Grid.clearBottomRows` → emits `clearLines` → `Main.attack()`.
A spell currently deals full line-clear damage *and* extends the combo. This must become a no-damage,
no-combo path **before** the board-manipulation spell category is designed, or every spell in the category
inherits the violation.

### P4 — Any number on screen decomposes on sight

> **Test:** the damage popup must be readable as named terms (lines × combo − armor + element). If a term
> can't be shown, it can't ship.

**Known violation:** `pendingElementalBonus` accumulates on one drop and is consumed on the *next* line clear —
hidden cross-drop state, which is exactly what P4 forbids. Retire it in its current form.

### Productive tensions

- **P1 vs P3** — spell builds want to lean on spells; the board says no.
- **P2 vs P4** — trade-offs add clauses; legibility wants fewer.

---

## 3. Anti-Pillars

| We will NOT | Because it would compromise |
|---|---|
| Ship persistent meta-progression between runs | Difficulty tuning and run independence — unlocks make every run a function of account age, not play |
| Ship multiplayer or a versus mode | P4 and the entire scope; the enemy is a damage schedule, not an opponent |
| Ship board-size, gravity, or rule variants per floor | P3 — the board's rules are the constant against which builds are measured |
| Ship a spell that wins a fight without a line clear | P1 and P3 — the caster is a *build*, not a bypass |
| Ship enemy status effects or damage-over-time | P4 (damage stops decomposing) and scope (an unbounded status machine) |
| Add a new playable class before existing classes are ship-quality | Content-count creep — the failure mode where Weaver and Monk stay half-tuned while class 3 gets built |

**Deliberately left open** (candidates, not commitments — see §12):
- A cap on currency/resource types.
- A ban on enemy board interference beyond garbage rows (column locks, hold disable, input inversion).

---

## 4. Core Loop

### 30-second loop — per piece

Read the board → find the row that serves your build (**combo continuity** vs **completing the row holding
an orb block**) → place → collect the payout (damage, energy, elemental bonus, coins). Every `attackSteps`
drops, the enemy hits back, converting optimisation into a race.

The satisfying beat is **the resolve**: piece locks, row detonates, number flies. Already implemented
(`PopupNumbers`, particles, audio) — which is why the game feels like a game today.

**Micro-diversity already exists in the code.** Orb blocks spawn at random board positions, so a caster and a
line-clear build looking at the same board want to complete *different rows* — the caster reaches for the orb
row even when it breaks their stack; the line-clear build reaches for whatever sustains the combo. Same verbs,
same board discipline, different targeting priority. It just isn't rewarded yet, because the combo side has no
scaling.

### 5-minute loop — one battle

**Spend energy or bank it** — the decision that separates the archetypes. Drip builds cast on cooldown to
smooth incoming damage; burst builds sit on a full meter and dump into a boss window (and, as Weaver, *cannot*
sit on it without bleeding). Failure has two faces: top out, or run out of damage before the enemy runs out of you.

### Session loop — one run, 15 floors

Fight → shop or event → draft → fight. The "one more run" hook is the **shop**: you enter with coins and a
half-formed build, and the roll decides which archetype you're allowed to become.

### Progression loop — days/weeks

Growth is **knowledge**, not persistent power: which enchantment pairings are traps, which enemy debuffs punish
burst, when to commit to an archetype. Correct for a roguelike, and it means **content breadth *is* the
progression system**.

---

## 5. MDA Analysis

| Layer | Content |
|---|---|
| **Mechanics** | Tetromino placement with SRS rotation and wall kicks; line clearing; combo counter; elemental block encoding (`elemental × 10 + piece`); orb blocks → energy; abilities with orb cost and piece-drop cooldowns; class passives; shop items, keepsakes, weighted events; enemy attack every N drops with per-enemy flat and multiplicative damage reduction |
| **Dynamics** | Two payout cadences on one board (bank-and-burst vs continuous drip); row-targeting tension (orb row vs combo row); build commitment under shop RNG; a race between the player's damage curve and the enemy's attack schedule; risk management of stack height as the universal failure state |
| **Aesthetics** | **Expression** (dominant) — build identity assembled from spells, enchantments, class and keepsakes. **Challenge** (secondary) — execution sets each build's ceiling. **Discovery** (tertiary) — learning the content space across runs. *Not present and not pursued:* Fellowship, Narrative, Submission |

---

## 6. Player Motivation (Self-Determination Theory)

| Need | Assessment |
|---|---|
| **Autonomy** | **Strong.** Archetype choice, spell choice, enchantment trade-offs, floor-card choice, shop commitment. The game's best-served need. |
| **Competence** | **Weakest leg — and it's fixable.** With `BASE_COMBO_MULT = 1.0`, combos multiply damage by `1.0^(n-1)` — nothing. `checkTSpin()` detects correctly and `print()`s the result. **The game currently cannot tell a good Tetris player from an adequate one.** Building the steady-drip scaling axis is not a balance chore; it is the game's competence axis. |
| **Relatedness** | **Thin and should stay thin.** A cult you never meet. Investing here contradicts the anti-pillars and buys nothing for the target player. |

---

## 7. Flow State Design

- **Challenge/skill balance** — enemy attack cadence (`attackSteps`) is the primary difficulty dial and scales
  by tier; the board provides self-imposed difficulty via stack height. Once combo scaling exists, skilled play
  shortens fights, which *reduces* incoming attacks — a virtuous flow loop where mastery buys safety.
- **Clear goals** — enemy HP bar and player HP/shield are always visible; the goal is never ambiguous.
- **Immediate feedback** — the resolve moment. Currently the **weakest link**, see §10 risk R1.
- **Loss of self-consciousness** — Tetris's near-zero onboarding cost means the target player reaches flow in
  seconds. This is the game's largest inherited advantage and must not be spent on UI friction.
- **Flow breakers to watch** — shop and draft screens interrupt flow by design (that's their job as pacing);
  mid-battle tooltip reading does not, and is a symptom that a mechanic failed P4.

---

## 8. Player Types

**Primary — the Achiever–Creator hybrid.** Quantic Foundry's *Strategy + Challenge* cluster with strong
*Design/Customize* motivation. Concretely: the Slay the Spire player who reads every relic before picking, and
the Tetris player who knows what a T-spin double is worth. **P1 is a direct promise to this person.**

**Secondary — the Achiever proper.** Wants the 15-floor climb and a win without theorycrafting. Gravitates to
the drip archetype because it's forgiving — which usefully makes the two archetypes double as a difficulty gradient.

**Secondary — lapsed puzzle-game players.** Tetris is the most legible verb in games; onboarding cost is near
zero for a very large audience, and the roguelike layer supplies the reason to continue. **This is the commercial upside.**

**Explicitly NOT for:**
- **Explorers** — no world to find; the cult is a framing device, and the no-meta-progression anti-pillar
  removes the unlock-chasing that usually substitutes for exploration.
- **Socializers** — closed by anti-pillar.
- **Tetris purists** — the competitive stacking crowd will find the board shallow and the RNG intolerable.
  Do not chase them; a purist-facing mode would violate P1 and P3 both.

**Market validation.** The lane is proven. *Slay the Spire* established the deck-and-relic loop;
*Tetris Effect: Connected* and *Puyo Puyo Tetris* established audience size. Closest neighbours —
**Balatro**, **Dungeons & Degenerate Gamblers**, **Peglin** — each took a legible, decades-old game verb and
hung a build-craft roguelike on it, and each outperformed expectations.

**Balatro is direct proof of this game's central bet:** its base game (poker hands) is untouched and universally
understood, and *all* diversity lives in the modifier layer. That validates the decision to keep board play
identical across archetypes. The lesson to steal: its jokers are pure trade-offs and identity-changers, and
there are ~150 of them. **Breadth of modifiers, not depth of base rules** — which makes enchantment and spell
count the content budget.

---

## 9. Visual Identity Anchor — "Starved Spectrum"

Selected at gate **AD-CONCEPT-VISUAL**. This section is the seed of the art bible.

> **The rule:** *Nothing in the game is allowed to be saturated except a block and the thing that block just caused.*

### Supporting principles

**Chroma is currency.** Backgrounds, panels, enemies, frames and fonts live in a desaturated blue-grey ramp.
Saturation is spent only on the six block states and on VFX directly downstream of a block.
→ *Debating a richer background vs a flatter one: choose the flatter one.*

**Consequence inherits colour.** A damage number is the red of the fire block that produced it; energy gain is
orb-teal; coins are gold. The player never learns a legend — the number **is** the block, moved. This makes P4
an art rule, not just a design rule.
→ *Debating a prettier VFX palette vs one that matches the causing block: choose the causing block.*

**Enemies are silhouette, not colour.** Value contrast and readable outline, never hue competition with the board.
→ *Debating an eye-catching enemy vs a legible board: choose the board.*

### Colour philosophy

Six block states, each locked to a distinct **value** as well as a hue, so the board survives a greyscale
screenshot: white 95% → gold 80% → poison 65% → fire 45% → orb 35% → garbage 20%. Orb moves from its current
dark teal `Color(0.0, 0.5, 0.5)` to a bright cyan; garbage drops to a desaturated violet-black.

**Colour-blind redundancy** comes from a second channel, not a better palette: a 1px inner glyph per element
(dot, flame, droplet, coin, ring, crack) plus a per-element bevel direction. Fire red / poison green is the
textbook deuteranope collision pair and cannot be solved with hue alone.

Spell VFX uses an **additive glow the block palette cannot produce**, so magic reads as "not a block" by
*render mode* rather than by hue.

### Verified state of the art today

- `Scripts/Utils/Textures.gd` preloads `block_L.png` for **all seven** `texture1`–`texture7` constants. Every
  piece type and every element is one 8px sprite under a `modulate` tint. **Colour is currently the game's only
  information channel.**
- `Sprite/Blocks/` **already contains all seven distinct per-piece sprites** (`block_I/J/L/O/S/T/Z.png`, drawn
  March 2026), unwired. The second information channel is sitting on disk — this is a ~6-line fix, not an art task.
- `PopupNumbers.CRIT_COLOR` is `Color(1.0, 0.85, 0.2)`; the gold block is `Color(1.0, 0.85, 0.0)`. **A crit
  number and a gold block are the same colour.** Must be resolved.

### Production cost

Lowest of the three directions assessed. Six 8×8 glyph stamps, a palette pass on existing sprites, one recolour
of `bg/*.png`. Runs *with* the existing dark background shader, tinted blocks and chunky pixel font rather than
obsoleting them — the deciding factor on a part-time timeline. (The alternatives, "Leaded Glass" and "The
Alchemist's Ledger", were both stronger-looking and both required re-authoring the card kit, fonts and
backgrounds first.)

**Scope bound:** apply Starved Spectrum to a **palette token file plus the battle screen only**. Menus and shop
keep their current look until after launch. "Desaturate everything" has no completion test and will otherwise
consume unbounded time.

---

## 10. Risks

### R1 — Simultaneity collapse at the moment of clear *(art + design, highest severity)*

One line clear can emit damage, energy, coins, elemental bonus, a row flash, a screen shake and spell VFX —
four to seven signals in the same ~200px, differentiated today only by colour, in a palette that already has a
gold/crit collision. **No art direction saves this.** The fix is structural: separate **spatial lanes**
(damage → enemy, energy → orb meter, coins → purse) and **60–80ms stagger** between signals. Without it the
player learns to ignore the burst and P4 dies quietly while the game still screenshots well.

Compounding: `PopupNumbers` parents Labels to an autoload `Node` at hardcoded absolute screen coordinates,
outside the scene's canvas transform. `Main._process` writes `enemy.self_modulate` every frame while
`flashEnemy` tweens it; `screenShake`, `attackAnim`, `Grid.hardDropShake` and `Utilities.shakeNode` each snap
`position` home on finish, so overlapping effects cancel. **A real effects layer is a prerequisite for the
lanes-and-stagger work.**

### R2 — The central design bet is unfalsified *(schedule, highest cost if it lands)*

Nothing in the current build tests whether two archetypes on an identical board produce genuinely different,
viable runs — because `comboMult` is 1.0 and combos do nothing. If they turn out to feel the same, the fix is a
board-level differentiator, which collides with the "no board-rule variants" anti-pillar. Landing that discovery
late costs 2–3 months of content written against a premise that didn't hold, plus a pillar renegotiation.
**Mitigation: the MVP in §11 exists specifically to falsify this bet before content is funded against it.**

### R3 — `Main.attack()` is a four-way god function *(technical, do first)*

It is simultaneously the damage math, the audio trigger, the popup spawner and the pending-bonus consumer.
The combo axis, T-spin rewards, and the entire damage-multiplication spell category all multiply through it.
**~1 day to refactor now; the most expensive file in the project after enchantments and five classes land on top.**

### R4 — Verified correctness defects in the combat core

| Defect | Location | Consequence |
|---|---|---|
| Enemy damage is a stub — overflow past shield deals `playerHealth -= 1` flat, ignoring `enemyAttackDamage` | `Main.enemyAttack` | **Every enemy's tuned attack value is inert.** Combat scaling would be balanced against a broken denominator |
| `Grid.combo` never reset | `Grid.resetGrid` | Combo carries across battles |
| `clearBottomRows` counts empty rows as cleared and increments combo unconditionally | `Grid.clearBottomRows` | A 4-row clear on an empty board is free damage *and* free combo |
| No `free()`/`queue_free()` anywhere in `Grid.gd`; `Piece extends Node2D`, created 14/bag + 1/drop | `Grid.newBag`, `Grid.afterDrop` | Nodes aren't refcounted — a full run orphans thousands |
| `checkTSpin` excludes `rotationState == 0`, never checks the last action was a rotation or which kick fired | `Grid.checkTSpin` | Wiring rewards as-is pays out on T-pieces merely dropped into wells; cannot distinguish T-spin Triple |
| `Hold.swapPiece` assigns `Constants.SHAPES[...]` without `.duplicate(true)` | `Hold.swapPiece` | Held piece aliases a shared const and loses elementals; piece-manipulation spells will hit runtime errors here |

### R5 — `abilityState` is keyed by ability id, not by equipped slot

State is per-concept, not per-copy, so **two Magic Bolts with different enchantments cannot exist.** This — not
Resource duplication — is the real enchantment blocker. (The deep-copy boundary in `AbilityData.to_dict()` is
already correct; keep it.) Also needed: a `resolve(base, modifiers) -> Dictionary` step, since `Main.useSkill`
and four display sites read raw ability fields, one of which caches cost into row metadata and never refreshes.

### R6 — Grid cell encoding has no room for flags

`elemental × 10 + piece` is already inconsistent: `GARBAGE = 8` decodes as elemental 0 / piece 8, which
`Textures.getTextureForColorIndex` has no case for and returns `null` — so any elemental applied to a garbage
cell renders as a null texture today. The scheme has no room for orthogonal per-cell flags (frozen, marked,
bomb) that enchantment-driven block states will want. **Migrate to a bitfield or a parallel flags array before
authoring more elementals.** Readers are few and mechanical.

### R7 — No tests, no CI, no committed export presets

The damage formula is about to be rewritten with no regression net.

### R8 — Content-count creep on the spell catalogue

Item scope is benchmarked against a game with ~150 jokers, which is an unbounded target.
**Bound: 35 spells at ship, and every spell must be authorable as pure data.** The moment a spell needs a new
`match` branch in `Main._applyAbilityEffect`, it goes to a backlog, not the build — batch new effect types once
per milestone.

---

## 11. Scope Tiers

Velocity baseline: 131 commits since Feb 2024, bursty — 59 in July 2024, then a 5-month gap, then 1 commit in
all of 2025 H1, then a 7-month gap. The recent sustained stretch (Mar–Aug 2026) runs **~8.7 commits/month**.
Plan at ~10/month and assume gaps happen.

### MVP — "Does the bet hold?" · 2.5–3 months

**Exit criterion is not "shipped."** It is **20 recorded runs where a Monk run and a Weaver run demonstrably
diverge in decisions and both win.**

**IN:**
1. **Extract the combat resolution pipeline** — fact-carrying Grid signals (`cleared`, `combo`, `source`,
   `tSpin`), one damage path, presentation split out. Fix `enemyAttack`'s flat-1 damage inside it. *Do this first.*
2. **Fix the P3 violation** — `clear_rows` gets a no-damage, no-combo path; handle the stranded
   `pendingElementalBonus` / `pendingGoldCoins`.
3. **Build the steady-drip scaling axis** — meaningful `comboMult` (per-class base + item scaling), T-spin
   rewards wired (after fixing `checkTSpin`'s rotation check), elemental bonus values retuned.
4. **Enchantment system as a mechanism** — per-slot ability identity, a `resolve(base, modifiers)` step, charge
   counters for once-per-battle, card and tooltip display. **Six enchantments, not a catalogue.**
5. **Eight new spells → 18 total**, deliberately split 9 steady-curve / 9 burst-curve.
6. **Feedback triage only** — an effects layer, plus spatial lanes and stagger for the four signals that
   currently collide. Not a full overhaul.
7. **Per-piece sprites + one shape glyph** (~2 days; the sprites already exist).
8. **Resolve the elemental-count question by playtest and commit** — it gates retuning, spell design, and the palette.

**CUT from MVP:** new classes, the Starved Spectrum visual pass, the full spell catalogue, VFX beyond collision
fixes, console.

### Target — the ship target · 6–8 months

MVP, plus: spells to ~35, enchantments to ~15, Starved Spectrum applied to board and combat screens only, full
VFX pass, gamepad bindings + full focus navigation (console insurance), a save system, **one new class if and
only if Weaver and Monk are ship-quality**, Steam page and build.

### Full Vision — post-launch roadmap · 15–20+ months

Balatro-scale content (~80–150 spell/enchantment combinations), visual identity across all scenes, 4+ classes,
**console port**.

### Console decision

**PC first; console is a post-launch project.** Godot ships no first-party console export — it requires a
licensed porting house (W4 Games, Pineapple Works, Lone Wolf) plus NDA, devkit, platform approval and a
*finished* PC build as input: months and real money.

The project also fails baseline cert today: **zero joypad bindings in `project.godot`**, `Menu.gd` accepts only
`InputEventKey` when rebinding, **no save system anywhere** (no `ConfigFile` / `user://` / `ResourceSaver` — even
keybinds don't persist), no suspend/resume, and the meta UI is mouse-and-drag (`AbilityDraftScene` uses
`set_drag_forwarding`, shops use `gui_input`). **That is a UI rewrite, not a port.**

**Two cheap insurance policies, taken in the Target tier:** full gamepad navigation on every menu, and no
mouse-only interaction. Days now against weeks later — and they must land *before* more classes and spells are
added to that UI, since every new card multiplies the rewrite. Externally: *"PC first, console under evaluation."*

---

## 12. Open Questions

1. **How many elemental types?** Five (fire, poison, gold, orb, none) may not be cohesive. Two or three may be
   tighter. **Resolve by playtest during MVP** — it gates retuning, spell design, and the palette, so it cannot
   stay open. Deliberately not locked as an anti-pillar until tested.
2. **Enemy board interference** — should enemies be limited to garbage rows and stat modifiers, or may they lock
   columns / disable hold? Currently unrestricted; a candidate anti-pillar (it arguably evades the
   no-rule-variants line on a technicality).
3. **A hard cap on currency and resource types** — coins, energy and the elemental types exist today. Candidate
   anti-pillar, deferred pending question 1.
4. **P2 grandfathering** — do existing clean buffs (`max_magic`, flat damage upgrades) get reworked into
   trade-offs, or explicitly exempted? Leaving it unstated makes P2 read as aspirational and it will be ignored.
5. **What replaces `pendingElementalBonus`?** P4 requires retiring deferred cross-drop state; the replacement
   (same-clear resolution, or a visible banked-bonus indicator) is undecided.

---

## 13. Gate Verdicts

| Gate | Agent | Verdict | Headline |
|---|---|---|---|
| **CD-PILLARS** | creative-director | **CONCERNS** | P1 was false as written (one faucet, not two axes) and contradicted by the elevator pitch; P4 was a quality bar in disguise; `clear_rows` violates P3 in code. All four pillars rewritten — see §2 |
| **AD-CONCEPT-VISUAL** | art-director | **Direction selected** | "Starved Spectrum" chosen over "Leaded Glass" and "The Alchemist's Ledger". Colour is the game's only information channel today; adding a second is a bug fix, not a style choice |
| **TD-FEASIBILITY** | technical-director | **CONCERNS** | Every feature is buildable on this architecture, but three foundations are cheap now and expensive later. Extract the combat pipeline first |
| **PR-SCOPE** | producer | **TIGHT** (MVP) / **UNREALISTIC** (full vision in 3–9 months) | The full vision is a 15–20 month program. Gate passes only by cutting to an MVP that falsifies the central bet before content is funded against it |

*Note: this project has no `.claude/docs/director-gates.md` and no director agent definitions. The four gates
were run by briefing general-purpose agents with each gate's intent. All code-level claims reproduced in this
document were independently verified against the repository before being recorded.*

---

## 14. Next Steps

1. **Refactor first** — extract the combat resolution pipeline in `Main.gd` and fix `enemyAttack`'s flat-1
   damage (R3, R4). Everything downstream multiplies through this function.
2. **Wire the seven per-piece sprites** in `Textures.gd` and resolve the crit/gold colour collision — hours of
   work, closes an accessibility defect.
3. **Run `/art-bible`** to expand §9 into a full visual specification before any asset production.
4. **Run `/map-systems`** to decompose this concept into individual systems with dependencies — the enchantment
   system, the combat pipeline, the effects layer and the block-encoding migration are the four that need GDDs.
5. **Run `/design-system enchantments`** — the largest new system, and the one whose identity model (R5) needs
   settling before spells are authored.
6. **Build the MVP to its exit criterion**: 20 recorded runs where Monk and Weaver diverge and both win.

---

## 15. Ideas

Parking lot for design ideas that are decided-but-unbuilt or deliberately deferred. An entry here is not a
commitment until it appears in §14.

### I2 — Typed garbage: garbage that heals the enemy or bills the player *(deferred)*

Extension of the shipped no-damage garbage rule, not a replacement. The elemental slot on a garbage cell is
unused, so `18` / `38` / `48` /
`58` are free encodings and the elemental would mean **what clearing this cell costs you**, rather than what it
pays: healing the enemy on clear, billing HP, draining magic, stealing coins. Garbage stays fully clearable
throughout — the cost is the threat.

**Blocked on R6.** `Textures.getTextureForColorIndex` special-cases `index == GARBAGE` and returns a texture,
but `18 % 10 == 8` matches no branch, so any *elemental* garbage renders as a null texture today. R6's
migration to a bitfield or parallel flags array is the prerequisite; authoring typed garbage before it would
add a fifth consumer to an encoding already marked for replacement.

**Do not build until** the shipped no-damage rule has been playtested. That rule is the cheap version of the
same idea, and if garbage still does not feel threatening once it pays nothing, the problem is arrival rate and
hole placement rather than per-block rules.
