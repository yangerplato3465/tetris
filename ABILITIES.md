# Abilities

The player's active toolkit: spells bought, drafted, equipped into five slots and cast
for magic orbs. This file is the catalogue; `CLAUDE.md` documents how the system is
built and the effect vocabulary a new spell is assembled from.

---

## Slots

You have **five ability slots**, cast with keys **1–5**, paid for with magic orbs. Two
slots start filled from your class; the rest you fill during the run.

- **After every victory** you are offered 3 random spells, free — drag one into a slot
- **At a shop** you can buy spells for coins; buying one opens the same screen to equip it
- Filled slots can be dragged onto each other to swap or move

Some spells have a **cooldown** (counted in piece drops, shown as `CD n` in place of the
orb cost). Four are **burn** spells — one cast per battle, then the slot reads `BURNED`
until the next fight.

## Spell List

| Spell | Rarity | Cost | CD | Effect |
|---|---|---|---|---|
| Magic Bolt | Common | 1 orb | — | Deal 50 damage |
| Cinder | Common | free | 3 | Deal 30 damage |
| Interrupt | Uncommon | 1 orb | 4 | Deal 40 damage and wind the attack counter back 2 drops |
| Shield Bash | Uncommon | 1 orb | 4 | Deal damage equal to your shield — the shield is not spent |
| Barrier | Common | 1 orb | — | Gain 20 shield |
| Aegis | Common | free | 6 | Gain 10 shield |
| Riposte | Uncommon | 1 orb | 4 | Gain 15 shield and wind the attack counter back 3 drops |
| Bulwark | Rare | 2 orbs | 3 | Gain 8 shield per occupied row on your board |
| Barricade | Uncommon | 1 orb | 3 | Gain 45 shield, but push a garbage row onto your own board |
| Ore Vein | Uncommon | 1 orb | 5 | The next piece is an I-piece |
| Plumb Line | Uncommon | 2 orbs | 3 | Deal 15 damage per occupied row on your board |
| Frostbite | Uncommon | 1 orb | 5 | Turn the falling piece to ice, then deal 20 damage |
| **Collapse** | Rare | 3 orbs | burn | Every block falls straight down; rows completed on the way clear normally |
| **Crucible** | Rare | 3 orbs | burn | Gain 90 shield |
| **Immolate** | Rare | 2 orbs | burn | Deal 150 damage per garbage block, then purify them all |
| **Slag** | Rare | 2 orbs | burn | Gain 5 shield per garbage block, then purify them all |
| **Absolute Zero** | Rare | 3 orbs | burn | Deal 250 damage, then hand the enemy 3 drops of attack progress |

## Authoring

Spells are data — one `.tres` per spell under `Data/Abilities/`, assembled from a
vocabulary of effect types. Adding one usually needs no code at all.
