---
title: R2 — The central design bet is unfalsified
type: risk
status: open
severity: highest-cost
domain: [schedule]
threatens: [P1-two-payout-curves-one-engine]
---

# R2 — The central design bet is unfalsified

*Schedule. Highest cost if it lands.*

Nothing in the current build tests whether two archetypes on an identical board produce genuinely different,
viable runs — because `comboMult` is 1.0 and combos do nothing.

If they turn out to feel the same, the fix is a board-level differentiator, which collides with the
"no board-rule variants" line in [[anti-pillars]]. Landing that discovery late costs **2–3 months of content
written against a premise that didn't hold**, plus a pillar renegotiation of [[P1-two-payout-curves-one-engine]].

## Mitigation

[[mvp]] exists specifically to falsify this bet before content is funded against it. Its exit criterion —
20 recorded runs where Monk and Weaver diverge and both win — is the falsification test.
