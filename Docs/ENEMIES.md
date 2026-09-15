# Enemies

Everything you fight across the 15 floors: the regular enemies of each tier and the five
bosses. This file is the catalogue; `CLAUDE.md` documents how the combat math and the data
behind it work.

---

## How They Work

Every enemy attacks on a fixed rhythm: once every **N piece drops**, shown on screen as
`attack : n / N`. An attack hits your **shield** first, and only what leaks past it
reaches your HP, divided by 10 and rounded up. With no shield, a 25-damage attack costs
3 HP.

Beyond raw numbers, an enemy can:

- **Start you on a messy board** — rows of scattered blocks already on the grid (small,
  medium or large)
- **Add garbage with its attacks** — every attack pushes one garbage row onto your board.
  Garbage pays no damage when cleared, but still counts for the combo
- **Lock your hold** — you can't hold pieces for the whole fight
- **Reduce your damage** — every source of damage you deal is multiplied down

Which tier you meet depends on the floor:

| Floors                 | Enemies          |
| ---------------------- | ---------------- |
| 1–2                    | Tier 1           |
| **3**                  | Boss: Rock Golem |
| 4–5                    | Tier 2           |
| **6**                  | Boss: Wendigo    |
| 7                      | Shop (no fight)  |
| 8, 10, 11, 13, 14      | Tier 3           |
| **9**                  | Boss: Centaur    |
| **12**                 | Boss: Death Knight |
| **15**                 | Boss: Shadow Lord |

A normal floor offers 2–3 cards and never shows the same enemy twice on one floor.

## Reading the Tables

- **Attack** — damage per hit, against shield
- **Every** — piece drops between attacks
- **HP/hit** — HP lost to one unshielded hit
- **Reward** — coins for the win
- **Board** — the starting board: Clean, Small, Medium or Large mess

## Tier 1 — Floors 1–2


| Enemy     | HP    | Attack | Every | HP/hit | Reward | Board | Special |
| --------- | ----- | ------ | ----- | ------ | ------ | ----- | ------- |
| Goblin    | 600   | 12     | 8     | 2      | 40     | Clean | —       |
| Bat       | 600   | 10     | 8     | 1      | 60     | Clean | —       |
| Centipede | 600   | 18     | 6     | 2      | 60     | Clean | —       |
| Slime     | 600   | 15     | 7     | 2      | 60     | Small | —       |
| Orc       | 1,000 | 15     | 7     | 2      | 80     | Clean | —       |


## Tier 2 — Floors 4–5


| Enemy      | HP    | Attack | Every | HP/hit | Reward | Board  | Special             |
| ---------- | ----- | ------ | ----- | ------ | ------ | ------ | ------------------- |
| Orc Wizard | 2,000 | 25     | 6     | 3      | 100    | Medium | —                   |
| Skeleton   | 2,500 | 28     | 5     | 3      | 100    | Clean  | —                   |
| Zombie     | 2,500 | 25     | 6     | 3      | 150    | Medium | Attacks add garbage |
| Banshee    | 2,500 | 30     | 5     | 3      | 150    | Medium | —                   |
| Reaper     | 2,500 | 32     | 5     | 4      | 200    | Medium | Attacks add garbage |


## Tier 3 — Floors 8, 10, 11, 13, 14


| Enemy           | HP    | Attack | Every | HP/hit | Reward | Board  | Special                           |
| --------------- | ----- | ------ | ----- | ------ | ------ | ------ | --------------------------------- |
| Ettin           | 5,000 | 38     | 6     | 4      | 150    | Large  | Attacks add garbage               |
| Death           | 5,000 | 40     | 5     | 4      | 200    | Medium | Attacks add garbage               |
| Skeleton Archer | 5,000 | 40     | 6     | 4      | 200    | Medium | —                                 |
| Slime Body      | 6,000 | 35     | 6     | 4      | 200    | Medium | Attacks add garbage · **No hold** |
| Huge Worm       | 8,000 | 35     | 5     | 4      | 200    | Medium | Attacks add garbage               |


## Bosses


| Floor | Boss         | HP     | Attack | Every | HP/hit | Reward | Board  | Special                                                  |
| ----- | ------------ | ------ | ------ | ----- | ------ | ------ | ------ | -------------------------------------------------------- |
| 3     | Rock Golem   | 2,000  | 40     | 5     | 4      | 120    | Small  | Attacks add garbage                                      |
| 6     | Wendigo      | 4,000  | 45     | 5     | 5      | 150    | Medium | —                                                        |
| 9     | Centaur      | 8,000  | 45     | 5     | 5      | 200    | Medium | Attacks add garbage                                      |
| 12    | Death Knight | 12,000 | 50     | 4     | 5      | 300    | Large  | Attacks add garbage · **No hold**                        |
| 15    | Shadow Lord  | 10,000 | 60     | 4     | 6      | —      | Large  | Attacks add garbage · **Halves all damage you deal**     |


## Notes on a Few

**Shadow Lord** lists 10,000 HP but halves every source of damage — line clears, spells
and fire blocks alike — so it takes the work of a 20,000 HP enemy, the toughest fight in the
game. Spells with the `cleanse` effect strip the halving for the rest of the battle. It pays
no reward because the run ends when it dies.

**Rock Golem** has less HP than most of the Tier 2 enemies after it, but hits for 40 on a
5-drop rhythm and adds garbage — on floor 3 that is more pressure per drop than anything
you have faced.

**Slime Body** and **Death Knight** lock your hold for the whole fight. Hold is otherwise
always available, so these are the fights where a bad piece has nowhere to go.

**Garbage attackers** get worse the longer a fight drags on: every hit leaves a row that
pays nothing when cleared. Killing them fast is a defensive play as much as an offensive one.

## Authoring

Enemies are data — one `EnemyData` `.tres` per enemy under
`Data/Enemies/{Tier1,Tier2,Tier3,Boss}/`, scanned whole at startup. The folder decides the
tier; a boss's floor is its `bossFloor` field, not its file order. Fields: `id`, `name`,
`health`, `reward`, `frame` (sprite), `description`, `attackSteps`, `attackDamage`,
`attackAddsGarbage`, `damageReduction` and `disablesHold`.

**One exception needs code.** The starting board is not a field: `Grid.setStage` picks it
with a hardcoded match on the enemy's integer `id`. A new enemy whose id isn't in that list
starts on a clean board no matter what its description says, and renumbering an enemy
silently changes its board. The `description` text is not connected to it either — keep
the two in step by hand.

Enemy data is also not checked by `DataValidator`, unlike abilities, keepsakes and events.

**Data debt spotted while writing this:**

- Several names are authored in lowercase (`huge worm`, `skeleton archer`, `slime body`,
  `rock golem`, `wendigo`, `centaur`, `death knight`) and show that way in game; this file
  capitalises them
- Shadow Lord and Death Knight share sprite `frame` 30, so the final boss looks like the
  floor-12 boss
- Shadow Lord's description says "halfed"
