---
title: R3 — Main.attack() is a four-way god function
type: risk
status: open
severity: high
domain: [technical]
effort: ~1 day
blocks: [combo-scaling, tspin-rewards, damage-spells, P3-the-board-is-honest]
---

# R3 — `Main.attack()` is a four-way god function

*Technical. **Do this first.***

`Main.attack()` is simultaneously:

1. the damage math
2. the audio trigger
3. the popup spawner
4. the pending-bonus consumer

The combo axis, T-spin rewards, and the entire damage-multiplication spell category all multiply through it.
So does the [[P3-the-board-is-honest]] fix.

**~1 day to refactor now; the most expensive file in the project after enchantments and five classes land on top.**

## Scheduled

Item 1 of [[mvp]] — extract the combat resolution pipeline: fact-carrying Grid signals (`cleared`, `combo`,
`source`, `tSpin`), one damage path, presentation split out. Fix `enemyAttack`'s flat-1 damage
([[R4-combat-core-defects]]) inside the same refactor.
