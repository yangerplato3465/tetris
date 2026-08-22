---
title: R8 — Content-count creep on the spell catalogue
type: risk
status: open
severity: medium
domain: [scope]
---

# R8 — Content-count creep on the spell catalogue

Item scope is benchmarked against a game with ~150 jokers (Balatro — see [[player-experience]]), which is an
**unbounded target**.

## Bound

**35 spells at ship, and every spell must be authorable as pure data.**

The moment a spell needs a new `match` branch in `Main._applyAbilityEffect`, it goes to a backlog, not the
build — batch new effect types once per milestone.

## Related

- [[target]] sets the ~35 spell / ~15 enchantment ship numbers this bound enforces.
- [[anti-pillars]] carries the parallel bound on classes.
