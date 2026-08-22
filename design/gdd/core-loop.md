---
title: Core Loop
type: gdd
status: current
---

# Core Loop

## 30-second loop — per piece

Read the board → find the row that serves your build (**combo continuity** vs **completing the row holding
an orb block**) → place → collect the payout (damage, energy, elemental bonus, coins). Every `attackSteps`
drops, the enemy hits back, converting optimisation into a race.

The satisfying beat is **the resolve**: piece locks, row detonates, number flies. Already implemented
(`PopupNumbers`, particles, audio) — which is why the game feels like a game today. It is also the moment
most at risk, see [[R1-simultaneity-collapse]].

### Micro-diversity already exists in the code

Orb blocks spawn at random board positions, so a caster and a line-clear build looking at the same board want
to complete *different rows* — the caster reaches for the orb row even when it breaks their stack; the
line-clear build reaches for whatever sustains the combo. Same verbs, same board discipline, different
targeting priority.

**It just isn't rewarded yet**, because the combo side has no scaling. That is item 3 of [[mvp]].

## 5-minute loop — one battle

**Spend energy or bank it** — the decision that separates the archetypes ([[P1-two-payout-curves-one-engine]]).
Drip builds cast on cooldown to smooth incoming damage; burst builds sit on a full meter and dump into a boss
window (and, as Weaver, *cannot* sit on it without bleeding).

Failure has two faces: **top out**, or **run out of damage before the enemy runs out of you**.

## Session loop — one run, 15 floors

Fight → shop or event → draft → fight.

The "one more run" hook is the **shop**: you enter with coins and a half-formed build, and the roll decides
which archetype you're allowed to become.

## Progression loop — days/weeks

Growth is **knowledge**, not persistent power: which enchantment pairings are traps, which enemy debuffs
punish burst, when to commit to an archetype.

Correct for a roguelike, and it means **content breadth *is* the progression system** — which is why
[[R8-content-count-creep]] needs a hard bound rather than a preference.

## Related

- [[player-experience]] — what these loops are doing psychologically.
- [[anti-pillars]] — persistent meta-progression is closed, which is what forces the knowledge model above.
