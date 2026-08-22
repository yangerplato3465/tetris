---
title: Player Experience — MDA, motivation, flow, audience
type: gdd
status: current
---

# Player Experience

## MDA Analysis

| Layer | Content |
|---|---|
| **Mechanics** | Tetromino placement with SRS rotation and wall kicks; line clearing; combo counter; elemental block encoding (`elemental × 10 + piece`); orb blocks → energy; abilities with orb cost and piece-drop cooldowns; class passives; shop items, keepsakes, weighted events; enemy attack every N drops with per-enemy flat and multiplicative damage reduction |
| **Dynamics** | Two payout cadences on one board (bank-and-burst vs continuous drip); row-targeting tension (orb row vs combo row); build commitment under shop RNG; a race between the player's damage curve and the enemy's attack schedule; risk management of stack height as the universal failure state |
| **Aesthetics** | **Expression** (dominant) — build identity assembled from spells, enchantments, class and keepsakes. **Challenge** (secondary) — execution sets each build's ceiling. **Discovery** (tertiary) — learning the content space across runs. *Not present and not pursued:* Fellowship, Narrative, Submission |

## Player Motivation (Self-Determination Theory)

| Need | Assessment |
|---|---|
| **Autonomy** | **Strong.** Archetype choice, spell choice, enchantment trade-offs, floor-card choice, shop commitment. The game's best-served need. |
| **Competence** | **Weakest leg — and it's fixable.** With `BASE_COMBO_MULT = 1.0`, combos multiply damage by `1.0^(n-1)` — nothing. `checkTSpin()` detects correctly and `print()`s the result. **The game currently cannot tell a good Tetris player from an adequate one.** Building the steady-drip scaling axis is not a balance chore; it is the game's competence axis. |
| **Relatedness** | **Thin and should stay thin.** A cult you never meet. Investing here contradicts [[anti-pillars]] and buys nothing for the target player. |

The competence gap is item 3 of [[mvp]] and the reason [[R2-central-bet-unfalsified]] is unfalsified.

## Flow State Design

- **Challenge/skill balance** — enemy attack cadence (`attackSteps`) is the primary difficulty dial and scales
  by tier; the board provides self-imposed difficulty via stack height. Once combo scaling exists, skilled
  play shortens fights, which *reduces* incoming attacks — a virtuous flow loop where mastery buys safety.
- **Clear goals** — enemy HP bar and player HP/shield are always visible; the goal is never ambiguous.
- **Immediate feedback** — the resolve moment. Currently the **weakest link**, see [[R1-simultaneity-collapse]].
- **Loss of self-consciousness** — Tetris's near-zero onboarding cost means the target player reaches flow in
  seconds. This is the game's largest inherited advantage and must not be spent on UI friction.
- **Flow breakers to watch** — shop and draft screens interrupt flow by design (that's their job as pacing);
  mid-battle tooltip reading does not, and is a symptom that a mechanic failed [[P4-numbers-decompose]].

## Player Types

**Primary — the Achiever–Creator hybrid.** Quantic Foundry's *Strategy + Challenge* cluster with strong
*Design/Customize* motivation. Concretely: the Slay the Spire player who reads every relic before picking, and
the Tetris player who knows what a T-spin double is worth. **[[P1-two-payout-curves-one-engine]] is a direct
promise to this person.**

**Secondary — the Achiever proper.** Wants the 15-floor climb and a win without theorycrafting. Gravitates to
the drip archetype because it's forgiving — which usefully makes the two archetypes double as a difficulty
gradient.

**Secondary — lapsed puzzle-game players.** Tetris is the most legible verb in games; onboarding cost is near
zero for a very large audience, and the roguelike layer supplies the reason to continue. **This is the
commercial upside.**

### Explicitly NOT for

- **Explorers** — no world to find; the cult is a framing device, and the no-meta-progression anti-pillar
  removes the unlock-chasing that usually substitutes for exploration.
- **Socializers** — closed by [[anti-pillars]].
- **Tetris purists** — the competitive stacking crowd will find the board shallow and the RNG intolerable.
  Do not chase them; a purist-facing mode would violate [[P1-two-payout-curves-one-engine]] and
  [[P3-the-board-is-honest]] both.

## Market validation

The lane is proven. *Slay the Spire* established the deck-and-relic loop; *Tetris Effect: Connected* and
*Puyo Puyo Tetris* established audience size. Closest neighbours — **Balatro**, **Dungeons & Degenerate
Gamblers**, **Peglin** — each took a legible, decades-old game verb and hung a build-craft roguelike on it,
and each outperformed expectations.

**Balatro is direct proof of this game's central bet:** its base game (poker hands) is untouched and
universally understood, and *all* diversity lives in the modifier layer. That validates the decision to keep
board play identical across archetypes.

The lesson to steal: its jokers are pure trade-offs and identity-changers, and there are ~150 of them.
**Breadth of modifiers, not depth of base rules** — which makes enchantment and spell count the content
budget, and is exactly why [[R8-content-count-creep]] needs a number.
