---
title: P1 — Two payout curves, one engine
type: pillar
status: locked
gate: CD-PILLARS
revised: 2026-08-15
---

# P1 — Two payout curves, one engine

Every build clears lines. Builds differ in **when** the board pays and **what** the payout buys.
Class passives set your default curve; run rewards let you pivot off it.

> **Test:** name the build that doesn't want this item. If you can't, it's a stat stick — cut it, or make it
> pick a side. *Exemption:* survivability and economy items may be archetype-neutral, capped at ~20% of the pool.

## Why the rewrite

The original P1 ("two roads up the mountain — separate scaling axes") was false in the build and contradicted
by the elevator pitch. There is exactly one faucet: energy comes from orb blocks, and orb blocks pay out only
*when their row is cleared*. Energy is therefore a linear function of lines cleared plus RNG — the same axis
with latency, not a second axis.

What actually differentiates the archetypes is **class passives imposing a cadence**, and that already ships:

| Class | Passive | Cadence it forces |
|---|---|---|
| **Weaver** | `overload` — orbs collected at full energy burn 5 HP each, ignoring shield | Cannot bank indefinitely. Must weave spells between clears. **Burst, forcibly spent.** |
| **Monk** | `combo_mastery` — base `comboMult` 1.1 instead of 1.0 | Rewarded for combo continuity from floor 1. **Steady drip**, pivotable to caster via run rewards. |

This is a real mechanical distinction on an identical board. Future classes are differentiated the same way:
a passive that changes *when you must spend*, not *how you must stack*.

## Related

- Productive tension with [[P3-the-board-is-honest]] — spell builds want to lean on spells; the board says no.
- [[R2-central-bet-unfalsified]] — nothing in the build currently tests whether this pillar is true.
- Depends on the steady-drip scaling axis in [[mvp]], because `comboMult` is 1.0 today.
- Closed by [[anti-pillars]]: no spell may win a fight without a line clear.
