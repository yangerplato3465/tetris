---
title: R7 — No tests, no CI, no committed export presets
type: risk
status: open
severity: medium
domain: [technical, process]
---

# R7 — No tests, no CI, no committed export presets

The damage formula is about to be rewritten with no regression net.

`export_presets.cfg` is in `.gitignore`, so there is no reproducible build configuration in the repo either.

## Related

- [[R3-main-attack-god-function]] — the rewrite this risk is about.
- [[target]] — the Steam build in the ship tier needs export presets to exist.
