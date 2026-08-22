---
title: MVP — "Does the bet hold?"
type: scope-tier
status: active
estimate: 2.5–3 months
gate: PR-SCOPE
verdict: TIGHT
---

# MVP — "Does the bet hold?"

**2.5–3 months.**

## Exit criterion

**Not "shipped."** It is **20 recorded runs where a Monk run and a Weaver run demonstrably diverge in
decisions and both win.**

This exists specifically to falsify [[R2-central-bet-unfalsified]] before content is funded against it.
Logs live in `design/playtests/`.

## In scope

1. **Extract the combat resolution pipeline** — fact-carrying Grid signals (`cleared`, `combo`, `source`,
   `tSpin`), one damage path, presentation split out. Fix `enemyAttack`'s flat-1 damage inside it.
   *Do this first.* → [[R3-main-attack-god-function]], [[R4-combat-core-defects]]
2. **Fix the P3 violation** — `clear_rows` gets a no-damage, no-combo path; handle the stranded
   `pendingElementalBonus` / `pendingGoldCoins`. → [[P3-the-board-is-honest]],
   [[Q5-replace-pending-elemental-bonus]]
3. **Build the steady-drip scaling axis** — meaningful `comboMult` (per-class base + item scaling), T-spin
   rewards wired (after fixing `checkTSpin`'s rotation check), elemental bonus values retuned.
   → [[P1-two-payout-curves-one-engine]], the competence axis in [[player-experience]]
4. **Enchantment system as a mechanism** — per-slot ability identity, a `resolve(base, modifiers)` step,
   charge counters for once-per-battle, card and tooltip display. **Six enchantments, not a catalogue.**
   → [[R5-ability-state-keyed-by-id]]
5. **Eight new spells → 18 total**, deliberately split 9 steady-curve / 9 burst-curve.
6. **Feedback triage only** — an effects layer, plus spatial lanes and stagger for the four signals that
   currently collide. Not a full overhaul. → [[R1-simultaneity-collapse]]
7. **Per-piece sprites + one shape glyph** (~2 days; the sprites already exist). → [[visual-identity]]
8. **Resolve the elemental-count question by playtest and commit** — it gates retuning, spell design, and
   the palette. → [[Q1-how-many-elementals]]

## Cut from MVP

New classes, the Starved Spectrum visual pass, the full spell catalogue, VFX beyond collision fixes, console.

## Next tier

[[target]]
