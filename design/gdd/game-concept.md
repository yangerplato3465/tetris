---
title: Alchetris — Game Concept
type: index
status: concept-locked
date: 2026-08-15
author: Patrick
---

# Alchetris — Game Concept

**Status:** Concept locked · **Date:** 2026-08-15 · **Author:** Patrick
**Session:** `/brainstorm tetris roguelike --review full` — formalization pass over an existing playable build
**Review gates run:** CD-PILLARS · AD-CONCEPT-VISUAL · TD-FEASIBILITY · PR-SCOPE

This is the index note. Every concept below lives in its own note — follow the links, and use the backlinks
pane on any note to see what depends on it.

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
| **Platform** | **PC first (Steam/Epic).** Console deferred — [[console-decision]] |
| **Current state** | Playable. 2 classes, 10 abilities, 20 enemies, 10 keepsakes, 15-floor run structure, shops, events, ability draft |

### Elevator pitch

> A roguelike Tetris battler where the board is simultaneously your weapon and your mana battery, and your
> build decides which one it is.

---

## 2. Design Pillars

Reviewed at gate **CD-PILLARS** (verdict: CONCERNS) and rewritten. The linked set is locked; each note carries
its own rationale for the change.

- [[P1-two-payout-curves-one-engine]] — every build clears lines; builds differ in **when** the board pays
- [[P2-power-is-bought]] — every gain names its currency: time, consistency, or risk
- [[P3-the-board-is-honest]] — spells change the board; **only the board pays** ⚠️ live violation
- [[P4-numbers-decompose]] — any number on screen decomposes on sight ⚠️ known violation
- [[anti-pillars]] — what the game will never ship, and why

**Productive tensions:** P1 vs P3 (spell builds want to lean on spells; the board says no) · P2 vs P4
(trade-offs add clauses; legibility wants fewer).

---

## 3. Design

- [[core-loop]] — the 30-second, 5-minute, session and progression loops
- [[player-experience]] — MDA, self-determination analysis, flow, player types, market validation
- [[visual-identity]] — "Starved Spectrum", the art bible seed

---

## 4. Risks

| Risk | Domain | Severity |
|---|---|---|
| [[R1-simultaneity-collapse]] — four to seven signals in the same 200px | art + design | **highest** |
| [[R2-central-bet-unfalsified]] — nothing tests whether the two archetypes actually diverge | schedule | **highest cost** |
| [[R3-main-attack-god-function]] — `Main.attack()` does four jobs; **do this first** | technical | high |
| [[R4-combat-core-defects]] — six verified defects incl. an inert enemy damage stub | technical | high |
| [[R5-ability-state-keyed-by-id]] — two copies of one spell cannot differ; the real enchantment blocker | technical | high |
| [[R6-grid-cell-encoding]] — `elemental × 10 + piece` has no room for flags | technical | medium |
| [[R7-no-tests-no-ci]] — the damage formula is about to be rewritten with no net | process | medium |
| [[R8-content-count-creep]] — the spell catalogue is benchmarked against an unbounded target | scope | medium |

---

## 5. Scope

- [[mvp]] — "Does the bet hold?" · 2.5–3 months · **active**
- [[target]] — the ship target · 6–8 months
- [[full-vision]] — post-launch roadmap · 15–20+ months
- [[console-decision]] — PC first, console post-launch

---

## 6. Open Questions

| Question | Status |
|---|---|
| [[Q1-how-many-elementals]] — five may not be cohesive; two or three may be tighter | open, **blocking**, resolve by MVP playtest |
| [[Q2-enemy-board-interference]] — garbage rows only, or column locks and hold disable? | open, candidate anti-pillar |
| [[Q3-currency-cap]] — a hard cap on currency and resource types | deferred pending Q1 |
| [[Q4-p2-grandfathering]] — rework existing clean buffs, or exempt them? | open, **blocking** |
| [[Q5-replace-pending-elemental-bonus]] — what replaces the hidden cross-drop state? | open, **blocking** |

---

## 7. Gate Verdicts

| Gate | Agent | Verdict | Headline |
|---|---|---|---|
| **CD-PILLARS** | creative-director | **CONCERNS** | P1 was false as written (one faucet, not two axes) and contradicted by the elevator pitch; P4 was a quality bar in disguise; `clear_rows` violates P3 in code. All four pillars rewritten |
| **AD-CONCEPT-VISUAL** | art-director | **Direction selected** | "Starved Spectrum" chosen over "Leaded Glass" and "The Alchemist's Ledger". Colour is the game's only information channel today; adding a second is a bug fix, not a style choice |
| **TD-FEASIBILITY** | technical-director | **CONCERNS** | Every feature is buildable on this architecture, but three foundations are cheap now and expensive later. Extract the combat pipeline first |
| **PR-SCOPE** | producer | **TIGHT** ([[mvp]]) / **UNREALISTIC** ([[full-vision]] in 3–9 months) | The full vision is a 15–20 month program. Gate passes only by cutting to an MVP that falsifies the central bet before content is funded against it |

*Note: this project has no `.claude/docs/director-gates.md` and no director agent definitions. The four gates
were run by briefing general-purpose agents with each gate's intent. All code-level claims reproduced in these
notes were independently verified against the repository before being recorded.*

---

## 8. Next Steps

1. **Refactor first** — extract the combat resolution pipeline in `Main.gd` and fix `enemyAttack`'s flat-1
   damage ([[R3-main-attack-god-function]], [[R4-combat-core-defects]]). Everything downstream multiplies
   through this function.
2. **Wire the seven per-piece sprites** in `Textures.gd` and resolve the crit/gold colour collision
   ([[visual-identity]]) — hours of work, closes an accessibility defect.
3. **Run `/art-bible`** to expand [[visual-identity]] into a full visual specification before any asset
   production.
4. **Run `/map-systems`** to decompose this concept into individual systems with dependencies — the
   enchantment system, the combat pipeline, the effects layer and the block-encoding migration are the four
   that need GDDs.
5. **Run `/design-system enchantments`** — the largest new system, and the one whose identity model
   ([[R5-ability-state-keyed-by-id]]) needs settling before spells are authored.
6. **Build the MVP to its exit criterion** ([[mvp]]): 20 recorded runs where Monk and Weaver diverge and both win.
