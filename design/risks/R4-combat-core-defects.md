---
title: R4 — Verified correctness defects in the combat core
type: risk
status: open
severity: high
domain: [technical]
blocks: [combat-tuning]
---

# R4 — Verified correctness defects in the combat core

All six reproduced against the repository.

| Defect | Location | Consequence |
|---|---|---|
| Enemy damage is a stub — overflow past shield deals `playerHealth -= 1` flat, ignoring `enemyAttackDamage` | `Main.enemyAttack` | **Every enemy's tuned attack value is inert.** Combat scaling would be balanced against a broken denominator |
| `Grid.combo` never reset | `Grid.resetGrid` | Combo carries across battles |
| `clearBottomRows` counts empty rows as cleared and increments combo unconditionally | `Grid.clearBottomRows` | A 4-row clear on an empty board is free damage *and* free combo |
| No `free()`/`queue_free()` anywhere in `Grid.gd`; `Piece extends Node2D`, created 14/bag + 1/drop | `Grid.newBag`, `Grid.afterDrop` | Nodes aren't refcounted — a full run orphans thousands |
| `checkTSpin` excludes `rotationState == 0`, never checks the last action was a rotation or which kick fired | `Grid.checkTSpin` | Wiring rewards as-is pays out on T-pieces merely dropped into wells; cannot distinguish T-spin Triple |
| `Hold.swapPiece` assigns `Constants.SHAPES[...]` without `.duplicate(true)` | `Hold.swapPiece` | Held piece aliases a shared const and loses elementals; piece-manipulation spells will hit runtime errors here |

## Scheduled

The `enemyAttack` stub is fixed inside the [[R3-main-attack-god-function]] refactor — item 1 of [[mvp]].
`checkTSpin` must be fixed before T-spin rewards are wired (item 3).
