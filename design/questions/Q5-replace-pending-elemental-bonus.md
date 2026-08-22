---
title: Q5 — What replaces pendingElementalBonus?
type: open-question
status: open
blocking: true
gates: [mvp-item-2]
---

# Q5 — What replaces `pendingElementalBonus`?

[[P4-numbers-decompose]] requires retiring deferred cross-drop state. The replacement is undecided:

- **same-clear resolution** — the bonus resolves on the drop that generated it, or
- **a visible banked-bonus indicator** — the state stays, but stops being hidden

## Why it's blocking

It is stranded by item 2 of [[mvp]] — fixing the [[P3-the-board-is-honest]] violation in `clear_rows` cuts
the path that currently consumes it, along with `pendingGoldCoins`. The `charge` ability effect writes to it,
so the answer decides what `charge` becomes.
