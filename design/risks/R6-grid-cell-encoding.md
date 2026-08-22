---
title: R6 — Grid cell encoding has no room for flags
type: risk
status: open
severity: medium
domain: [technical]
blocks: [elemental-authoring, block-states]
---

# R6 — Grid cell encoding has no room for flags

`elemental × 10 + piece` is already inconsistent: `GARBAGE = 8` decodes as elemental 0 / piece 8, which
`Textures.getTextureForColorIndex` has no case for and returns `null` — **so any elemental applied to a
garbage cell renders as a null texture today.**

The scheme has no room for orthogonal per-cell flags (frozen, marked, bomb) that enchantment-driven block
states will want.

**Migrate to a bitfield or a parallel flags array before authoring more elementals.** Readers are few and
mechanical.

## Related

- [[Q1-how-many-elementals]] — the elemental count decision gates how urgent this is.
- [[R5-ability-state-keyed-by-id]] — enchantment-driven block states are the consumer that needs the flags.
