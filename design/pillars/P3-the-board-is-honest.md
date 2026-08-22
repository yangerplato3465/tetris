---
title: P3 — The board is honest
type: pillar
status: locked
gate: CD-PILLARS
revised: 2026-08-15
violation: blocking
---

# P3 — The board is honest

Spells change the board; **only the board pays**. No spell mints damage, energy, or combo — it moves blocks,
buys pieces, or converts what's already there.

> **Test:** after casting, would a player who stops stacking for 5 pieces still be ahead? Then the cost is wrong.

## Live violation — blocking

`clear_rows` → `Grid.clearBottomRows` → emits `clearLines` → `Main.attack()`.

A spell currently deals full line-clear damage *and* extends the combo. This must become a no-damage,
no-combo path **before** the board-manipulation spell category is designed, or every spell in the category
inherits the violation.

`holy_beam` is the correct precedent: `Grid.holyBeam` emits nothing, so it is pure board relief.

Fixing it strands `pendingElementalBonus` / `pendingGoldCoins` — see [[Q5-replace-pending-elemental-bonus]].

## Related

- Productive tension with [[P1-two-payout-curves-one-engine]].
- Scheduled as item 2 of [[mvp]].
- [[R3-main-attack-god-function]] — the fix routes through the same function.
