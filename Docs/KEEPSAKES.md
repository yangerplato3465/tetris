# Keepsakes

Permanent trinkets bought from the shop's bottom row. A keepsake is bought once, applied
immediately and kept for the rest of the run — there is no equip step and no slot limit.
This file is the catalogue; `CLAUDE.md` documents how the system is built and how to add
one.

---

## How They Work

The shop rolls **5** of the **15** keepsakes per visit from `Keepsakes.pool`, filtering out
anything you already own, so a keepsake never appears twice in a run. Buying one runs
`PlayerManager.addKeepsake`, which applies its permanent effects on the spot; the rest fire
on their trigger (battle start, line clear, victory) for as long as you own it.

Keepsakes are the only way to unlock two of the game's systems — the **next piece**
preview and the three **elemental block** types. Until you buy the relevant keepsake,
those blocks never spawn.

**Hold is not one of them.** It is a default feature for every class from the start of a
run — the `Old Key` keepsake that used to unlock it has been removed. Individual enemies
can still take it away for a fight (`EnemyData.disablesHold`; Death Knight and Slime Body
do).

## Keepsake List


| Keepsake             | Rarity   | Price | Effect                                                                          |
| -------------------- | -------- | ----- | ------------------------------------------------------------------------------- |
| **Spark Vial**       | Common   | 30    | Start every battle with +1 magic orb                                            |
| **Tin Buckler**      | Common   | 30    | Start every battle with +10 shield                                              |
| **Coin Pouch**       | Common   | 30    | +8 coins after every victory                                                    |
| **Whetstone**        | Common   | 30    | Your first line clear each battle deals +50 damage                              |
| **Hourglass Charm**  | Common   | 35    | The enemy's first attack each battle comes 2 drops later                        |
| **Bandage Roll**     | Common   | 35    | Heal 3 HP after every victory                                                   |
| **Worn Gauntlet**    | Common   | 40    | Every Tetris (4-line clear) gives +1 magic orb                                  |
| **Magnifying Glass** | Common   | 30    | See one more upcoming piece                                                     |
| **Rime Shard**       | Uncommon | 30    | **Ice blocks** appear in pieces; clearing one delays the enemy attack by 1 drop |
| **Ember Charm**      | Uncommon | 40    | **Fire blocks** appear in pieces; clearing one deals 15 damage immediately      |
| **Gilded Idol**      | Uncommon | 40    | **Gold blocks** appear in pieces; clearing one gives 1 coin                     |
| **Alchemist's Ring** | Common   | 40    | Combo multiplier +0.1                                                           |
| **Heart Locket**     | Common   | 50    | +25 max HP                                                                      |
| **Mana Crystal**     | Common   | 50    | +2 max magic orbs                                                               |
| **Dragon's Chest**   | Common   | 60    | Every Tetris (4-line clear) pays 50 coins                                       |




## Notes on a Few

**Alchemist's Ring** is one of only two things in the game that raises the combo
multiplier — the other is the Monk's *Combo Mastery* passive. The base multiplier is
**1.0**, meaning `1.0^(combo-1) == 1` and a combo scales your damage by nothing at all.
Without the Ring or the Monk, combo length is worth no extra damage on its own.

**Rime Shard** pays in tempo rather than damage, and its timing is exact: the ice payout
resolves *before* the piece-drop that would have triggered an enemy attack, so clearing an
ice block on that drop cancels the attack instead of arriving a step late.

**Ember Charm** deals its damage the instant a fire block clears — not banked onto a later
clear. It lands before the line-clear damage for that same row, and respects enemy damage
reduction.

**Mana Crystal** raises the orb cap above the class default (5). For the Weaver this also
softens the *Overload* passive, which burns 5 HP for every orb collected past the cap.

## Shop Services

The shop's other two cards are not keepsakes — they are services defined inline in
`Scripts/UI/ShopPanell.gd`:


| Service           | Price | Effect                                 |
| ----------------- | -------- | -------------------------------------- |
| **Rest**          | 30    | Restore 30 HP                          |
| **Upgrade Spell** | —     | **Not implemented** — currently a stub |




## Authoring

Keepsakes are data — one `.tres` per keepsake under `Data/Keepsakes/`, scanned whole at
startup. Each effect names **when** it runs and **what** it does:

```
{"trigger": "victory", "type": "heal", "amount": 3}                       # Bandage Roll
{"trigger": "line_clear", "min_lines": 4, "type": "coins", "amount": 50}  # Dragon's Chest
```

| Trigger        | When                                  | Effect types                                     |
| -------------- | ------------------------------------- | ------------------------------------------------ |
| `acquire`      | once, when bought                     | `combo_mult` · `max_hp` · `heal` · `max_magic` · `next_piece` · `fire_blocks` · `ice_blocks` · `gold_blocks` |
| `battle_start` | every battle, as it begins            | any spell effect (`shield`, `magic`, `attack_grace`, …) |
| `line_clear`   | every line clear; `min_lines` filters | any spell effect (`coins`, `magic`, …)           |
| `victory`      | every enemy killed                    | any spell effect (`heal`, `coins`, …)            |

Everything except `acquire` uses the same effect types as spells (see `CLAUDE.md` for the
full table), so a new keepsake built from existing triggers and types needs no code. The
game checks every keepsake at startup and prints a red error for an unknown trigger or
type, or a missing or misspelled key.