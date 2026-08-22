---
title: R5 — abilityState is keyed by ability id, not by equipped slot
type: risk
status: open
severity: high
domain: [technical, design]
blocks: [enchantments]
---

# R5 — `abilityState` is keyed by ability id, not by equipped slot

State is per-concept, not per-copy, so **two Magic Bolts with different enchantments cannot exist.**

This — not Resource duplication — is the real enchantment blocker. The deep-copy boundary in
`AbilityData.to_dict()` is already correct; **keep it**.

## Also needed

A `resolve(base, modifiers) -> Dictionary` step, since `Main.useSkill` and four display sites read raw ability
fields — one of which caches cost into row metadata and never refreshes.

## Scheduled

Item 4 of [[mvp]] — enchantment system as a mechanism: per-slot ability identity, the `resolve` step, charge
counters for once-per-battle, card and tooltip display. **Six enchantments, not a catalogue.**

The identity model here needs settling before spells are authored — see the next steps in
[[game-concept]].
