---
title: R1 — Simultaneity collapse at the moment of clear
type: risk
status: open
severity: highest
domain: [art, design]
blocks: [effects-layer, feedback-triage]
threatens: [P4-numbers-decompose]
---

# R1 — Simultaneity collapse at the moment of clear

*Art + design. Highest severity.*

One line clear can emit damage, energy, coins, elemental bonus, a row flash, a screen shake and spell VFX —
four to seven signals in the same ~200px, differentiated today only by colour, in a palette that already has a
gold/crit collision (see [[visual-identity]]).

**No art direction saves this.** The fix is structural:

- separate **spatial lanes** — damage → enemy, energy → orb meter, coins → purse
- **60–80ms stagger** between signals

Without it the player learns to ignore the burst and [[P4-numbers-decompose]] dies quietly while the game
still screenshots well.

## Compounding technical state

- `PopupNumbers` parents Labels to an autoload `Node` at hardcoded absolute screen coordinates, outside the
  scene's canvas transform.
- `Main._process` writes `enemy.self_modulate` every frame while `flashEnemy` tweens it.
- `screenShake`, `attackAnim`, `Grid.hardDropShake` and `Utilities.shakeNode` each snap `position` home on
  finish, so overlapping effects cancel.

**A real effects layer is a prerequisite for the lanes-and-stagger work.**

## Scheduled

Item 6 of [[mvp]] — feedback triage only. Not a full overhaul; the full VFX pass is [[target]].
