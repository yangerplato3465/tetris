---
title: P4 — Any number on screen decomposes on sight
type: pillar
status: locked
gate: CD-PILLARS
revised: 2026-08-15
violation: known
---

# P4 — Any number on screen decomposes on sight

> **Test:** the damage popup must be readable as named terms (lines × combo − armor + element). If a term
> can't be shown, it can't ship.

## Known violation

`pendingElementalBonus` accumulates on one drop and is consumed on the *next* line clear — hidden cross-drop
state, which is exactly what P4 forbids. **Retire it in its current form.** The replacement is undecided —
see [[Q5-replace-pending-elemental-bonus]].

## This is an art rule too

[[visual-identity]] makes P4 enforceable in the palette: consequence inherits the colour of the block that
caused it, so the player never learns a legend — the number **is** the block, moved.

## Related

- Productive tension with [[P2-power-is-bought]] — trade-offs add clauses; legibility wants fewer.
- [[R1-simultaneity-collapse]] is the highest-severity threat to this pillar: 4–7 signals in the same ~200px
  and P4 dies quietly while the game still screenshots well.
- Closed by [[anti-pillars]]: no enemy status effects or damage-over-time, because damage stops decomposing.
