---
title: Visual Identity — "Starved Spectrum"
type: gdd
status: direction-selected
gate: AD-CONCEPT-VISUAL
scope_tier: target
---

# Visual Identity — "Starved Spectrum"

Selected at gate **AD-CONCEPT-VISUAL**. This note is the seed of the art bible — run `/art-bible` to expand
it into a full visual specification before any asset production.

> **The rule:** *Nothing in the game is allowed to be saturated except a block and the thing that block just caused.*

## Supporting principles

**Chroma is currency.** Backgrounds, panels, enemies, frames and fonts live in a desaturated blue-grey ramp.
Saturation is spent only on the six block states and on VFX directly downstream of a block.
→ *Debating a richer background vs a flatter one: choose the flatter one.*

**Consequence inherits colour.** A damage number is the red of the fire block that produced it; energy gain is
orb-teal; coins are gold. The player never learns a legend — the number **is** the block, moved. This makes
[[P4-numbers-decompose]] an art rule, not just a design rule.
→ *Debating a prettier VFX palette vs one that matches the causing block: choose the causing block.*

**Enemies are silhouette, not colour.** Value contrast and readable outline, never hue competition with the
board.
→ *Debating an eye-catching enemy vs a legible board: choose the board.*

## Colour philosophy

Six block states, each locked to a distinct **value** as well as a hue, so the board survives a greyscale
screenshot:

| State | Value |
|---|---|
| white | 95% |
| gold | 80% |
| poison | 65% |
| fire | 45% |
| orb | 35% |
| garbage | 20% |

Orb moves from its current dark teal `Color(0.0, 0.5, 0.5)` to a bright cyan; garbage drops to a desaturated
violet-black.

**Colour-blind redundancy** comes from a second channel, not a better palette: a 1px inner glyph per element
(dot, flame, droplet, coin, ring, crack) plus a per-element bevel direction. Fire red / poison green is the
textbook deuteranope collision pair and cannot be solved with hue alone.

Spell VFX uses an **additive glow the block palette cannot produce**, so magic reads as "not a block" by
*render mode* rather than by hue.

The state count here assumes today's elemental roster — [[Q1-how-many-elementals]] can collapse this ramp.

## Verified state of the art today

- `Scripts/Utils/Textures.gd` preloads `block_L.png` for **all seven** `texture1`–`texture7` constants. Every
  piece type and every element is one 8px sprite under a `modulate` tint. **Colour is currently the game's
  only information channel.**
- `Sprite/Blocks/` **already contains all seven distinct per-piece sprites** (`block_I/J/L/O/S/T/Z.png`, drawn
  March 2026), unwired. The second information channel is sitting on disk — this is a ~6-line fix, not an art
  task. Scheduled as item 7 of [[mvp]].
- `PopupNumbers.CRIT_COLOR` is `Color(1.0, 0.85, 0.2)`; the gold block is `Color(1.0, 0.85, 0.0)`. **A crit
  number and a gold block are the same colour.** Must be resolved — it compounds [[R1-simultaneity-collapse]].

## Production cost

Lowest of the three directions assessed. Six 8×8 glyph stamps, a palette pass on existing sprites, one
recolour of `bg/*.png`. Runs *with* the existing dark background shader, tinted blocks and chunky pixel font
rather than obsoleting them — the deciding factor on a part-time timeline.

The alternatives, **"Leaded Glass"** and **"The Alchemist's Ledger"**, were both stronger-looking and both
required re-authoring the card kit, fonts and backgrounds first.

## Scope bound

Apply Starved Spectrum to a **palette token file plus the battle screen only** ([[target]]). Menus and shop
keep their current look until after launch ([[full-vision]]).

**"Desaturate everything" has no completion test and will otherwise consume unbounded time.**
