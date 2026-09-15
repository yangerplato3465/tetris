# Enemies

Everything you fight across the 15 floors: the regular enemies of each tier and the five
bosses. This file is the catalogue; `CLAUDE.md` documents how the combat math and the data
behind it work.

---

## How They Work

Every enemy winds up one **move** at a time and it lands after **N piece drops**, shown on
screen as `Attack : n / N`, with what the move will do written underneath (`32 dmg, +1
garbage`). Most enemies loop a short pattern you can learn; a few pick at random; the
tougher ones and every boss switch patterns as their HP drops, announcing it on screen.
The move already winding up when a phase changes still lands. An attack hits your
**shield** first, and only what leaks past it
reaches your HP, divided by 10 and rounded up. With no shield, a 25-damage attack costs
3 HP.

Beyond raw numbers, an enemy can:

- **Start you on a messy board** — rows of scattered blocks already on the grid (small,
  medium or large)
- **Add garbage** — a move pushes garbage rows onto your board. Garbage pays no damage
  when cleared, but still counts for the combo
- **Lock your hold** for the whole fight
- **Reduce your damage** for the whole fight — every source of damage you deal is
  multiplied down
- **Shield** itself — damage goes into the shield (shown above its HP) until it breaks
- **Heal**, up to its max HP
- **Weaken** you — your damage is multiplied down for a few drops
- **Lock your hold** or **blind your preview** for a few drops
- **Curse** upcoming pieces — they turn to garbage in your queue, so they pay nothing
  when cleared. You see it happen in the preview; holding a cursed piece parks it but
  doesn't lift the curse

Timed debuffs are listed under the enemy's next move with the drops left, and a Cleanse
spell lifts a weaken as well as a damage reduction.

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

- **Moves** — `Name damage / drops`: `Bite 10 / 6` hits for 10 (against shield) after 6
  piece drops. Anything else the move does follows the damage: `+1 garbage` (rows),
  `shield`, `heal`, `weaken ×0.75 for 4`, `no hold 3`, `blind 3` (preview hidden), `curse 1`
  (pieces). Timed effects count your piece drops
- **Pattern** — the order moves come in, looping. *Random* picks one each time (×2 = twice
  as likely). **→ below N% (Name)** is a phase: under that much HP the enemy announces
  Name and switches to the next pattern for the rest of the fight
- **Reward** — coins for the win
- **Board** — the starting board: Clean, Small, Medium or Large mess

## Tier 1 — Floors 1–2

Short loops, one idea each — the floors that teach reading the next move.

| Enemy     | HP    | Reward | Board | Moves | Pattern |
| --------- | ----- | ------ | ----- | ----- | ------- |
| Goblin    | 600   | 40     | Clean | Poke 6 / 5 · Stab 16 / 8 | Poke, Poke, Stab |
| Bat       | 600   | 60     | Clean | Bite 10 / 6 · Screech: blind 2 / 4 | Bite, Bite, Screech |
| Centipede | 600   | 60     | Clean | Nip 6 / 2 · Lunge 24 / 8 | Nip ×3, Lunge |
| Slime     | 600   | 60     | Small | Ooze 12 / 5 · Splat: +1 garbage / 6 | Ooze, Ooze, Splat |
| Orc       | 1,000 | 80     | Clean | Club 14 / 6 · Guard: shield 100 / 4 · Rage 22 / 6 | Club, Club, Guard **→ below 40% (Enraged):** Rage |

## Tier 2 — Floors 4–5

Each adds one twist: a debuff, a curse, a heal or a random pick.

| Enemy      | HP    | Reward | Board  | Moves | Pattern |
| ---------- | ----- | ------ | ------ | ----- | ------- |
| Orc Wizard | 2,000 | 100    | Medium | Bolt 22 / 5 · Hex: weaken ×0.75 for 4 / 4 | Bolt, Bolt, Hex |
| Skeleton   | 2,500 | 100    | Clean  | Slash 20 / 4 · Bone Crush 40 / 7 | Slash, Slash, Bone Crush |
| Zombie     | 2,500 | 150    | Medium | Claw 20 / 5 · Grab 25 +1 garbage / 6 · Retch: curse 1 / 4 | Claw, Grab, Retch |
| Banshee    | 2,500 | 150    | Medium | Shriek 35 / 5 · Wail 15, blind 3 / 4 | Shriek, Wail |
| Reaper     | 2,500 | 200    | Medium | Reap 36 +1 garbage / 5 · Harvest 20, heal 200 / 5 | *Random:* Reap ×2, Harvest |

## Tier 3 — Floors 8, 10, 11, 13, 14

| Enemy           | HP    | Reward | Board  | Moves | Pattern |
| --------------- | ----- | ------ | ------ | ----- | ------- |
| Ettin           | 5,000 | 150    | Large  | Left Head 30 / 5 · Right Head 30 +1 garbage / 5 · Both Heads 60 +1 garbage / 8 | Left Head, Right Head, Both Heads |
| Death           | 5,000 | 200    | Medium | Scythe 40 +1 garbage / 5 · Death Mark: weaken ×0.7 for 4 / 3 · Doom 70 +1 garbage / 6 | Scythe, Scythe, Death Mark **→ below 30% (Final Hour):** Doom |
| Skeleton Archer | 5,000 | 200    | Medium | Arrow 22 / 3 · Pin 15, no hold 3 / 4 · Volley 60 / 7 | *Random:* Arrow ×2, Pin, Volley |
| Slime Body      | 6,000 | 200    | Medium · **No hold** | Slam 35 +1 garbage / 5 · Absorb: shield 400 / 5 · Spit: +1 garbage, curse 1 / 4 | Slam, Absorb, Slam **→ below 50% (Splitting):** *random* Slam, Spit |
| Huge Worm       | 8,000 | 200    | Medium | Bite 35 +1 garbage / 5 · Burrow: shield 600, blind 3 / 4 · Erupt 60 +2 garbage / 6 | Bite, Burrow, Erupt |

## Bosses

| Floor | Boss         | HP     | Reward | Board  | Moves | Pattern |
| ----- | ------------ | ------ | ------ | ------ | ----- | ------- |
| 3     | Rock Golem   | 2,000  | 120    | Small  | Pound 40 +1 garbage / 5 · Harden: shield 200 / 3 · Avalanche 45 +1 garbage / 5 | Pound, Harden, Pound **→ below 50% (Crumbling):** Avalanche |
| 6     | Wendigo      | 4,000  | 150    | Medium | Rend 35 / 4 · Feast 25, heal 150 / 5 · Frenzy 70 / 6 | Rend, Rend, Feast **→ below 40% (Starving):** *random* Rend, Feast, Frenzy |
| 9     | Centaur      | 8,000  | 200    | Medium | Volley 30 / 4 · Pin Shot 20, no hold 4 / 4 · Charge 70 +1 garbage / 6 · Trample 35 +1 garbage / 4 | Volley, Volley, Pin Shot, Charge **→ below 50% (Stampede):** Charge, Trample |
| 12    | Death Knight | 12,000 | 300    | Large · **No hold** | Cleave 50 +1 garbage / 4 · Dark Ward: shield 800 / 3 · Soul Drain 45, heal 400 / 5 · Execution 80 +1 garbage / 5 | Cleave, Cleave, Dark Ward **→ below 60% (Unholy Vigor):** Cleave, Soul Drain, Cleave **→ below 25% (Last Stand):** Execution |
| 15    | Shadow Lord  | 10,000 | —      | Large · **Halves your damage** | Dark Bolt 60 +1 garbage / 4 · Veil 30, blind 3, curse 1 / 4 · Wither 50, weaken ×0.75 for 4 / 4 · Grasp: +2 garbage, no hold 3 / 4 · Oblivion 70, curse 1 / 4 · Eclipse: steals half your shield, then 30 / 5 | Dark Bolt, Veil, Dark Bolt **→ below 66% (The Veil Tears):** *random* Dark Bolt, Wither, Grasp **→ below 33% (Eclipse):** Oblivion, Oblivion, Eclipse |

## Notes on a Few

**Shadow Lord** lists 10,000 HP but halves every source of damage — line clears, spells
and fire blocks alike — so it takes the work of a 20,000 HP enemy, the toughest fight in the
game. Spells with the `cleanse` effect strip the halving for the rest of the battle. Its
middle phase stacks a weaken on top of that, and its last phase **Eclipse** takes half your
banked shield and adds it to its own before hitting — a big pre-boss shield still helps, but
it's a race to finish the fight before too much of it changes sides. It pays no reward
because the run ends when it dies.

**Rock Golem** is the first boss and the first enemy shield: Harden has to be broken
through before damage reaches it again. Below half it stops defending and drops an
Avalanche every 5 drops — more pressure per drop than anything before it.

**Hold lockers.** Slime Body and Death Knight lock your hold for the whole fight; Skeleton
Archer's Pin and Centaur's Pin Shot lock it for a few drops, telegraphed a move ahead.

**Healers** — Reaper, Wendigo and Death Knight — undo a slice of your damage, so steady
damage beats saving up. A heal never sends a boss back to an earlier phase.

**Phase spikes.** Orc, Death, Death Knight and both halves of the Centaur and Rock Golem hit
harder late than their early loop suggests. Their final phases are where a run most often
bleeds HP, and where banking shield for the second half pays off.

**Garbage attackers** get worse the longer a fight drags on: every row they add pays
nothing when cleared. Killing them fast is a defensive play as much as an offensive one.

**Tuning.** The patterns were written to keep each enemy's average damage per drop within
about 30% of its old single attack — lower where a move spends its turn on a debuff, a
shield or a curse, higher only inside late phases. None of it has been playtested yet.

## Authoring

Enemies are data — one `.gd` file per enemy under `Data/Enemies/{Tier1,Tier2,Tier3,Boss}/`,
named for its id and holding a `const ENEMY` dictionary. The folder decides the tier; a
boss's floor is its `boss_floor`, not its file order.

```gdscript
const ENEMY := {
	"id": "reaper",
	"name": "Reaper",
	"health": 2500,
	"reward": 200,
	"frame": 36,
	"description": "Start with a messy board",
	"board": "medium",
	"moves": {
		"reap": {"name": "Reap", "steps": 5, "effects": [{"type": "attack", "amount": 36}, {"type": "add_garbage", "amount": 1}]},
		"harvest": {"name": "Harvest", "steps": 5, "effects": [{"type": "attack", "amount": 20}, {"type": "heal", "amount": 200}]},
	},
	"phases": [
		{"pattern": {"type": "random", "moves": ["reap", "reap", "harvest"]}},
	],
}
```

- `board` — `clean`, `small`, `medium` or `large`
- `passives` — battle-long rules: `{"type": "damage_reduction", "amount": 0.5}`,
  `{"type": "disable_hold"}`
- `moves` — named actions: `steps` is the piece drops to wind up and `effects` run in
  order (table below). Keep `name` short, since it shares a line with the counter. The
  line under it is generated from the effects; an optional `intent` string replaces it

| effect | keys | does |
|---|---|---|
| `attack` | `amount` | hits your shield, then HP |
| `add_garbage` | `amount` | garbage rows onto your board |
| `enemy_shield` | `amount` | the enemy blocks that much damage, until broken |
| `heal` | `amount` | the enemy regains HP, up to max |
| `weaken` | `amount`, `drops` | your damage × `amount` (0.5 = halved) for `drops` drops |
| `lock_hold` | `drops` | no hold for `drops` drops |
| `hide_preview` | `drops` | blank next-piece preview for `drops` drops |
| `curse_piece` | `amount` (optional, 1) | that many upcoming pieces turn to garbage |
| `call` | `method` | runs `func method(battle)` written in the enemy's own file |

Re-applying a timed effect that's still running keeps the longer count; it doesn't add.
`call` is for the one-off boss trick nothing else covers — the function gets the battle
(`Main`), and a String it returns pops up over the enemy. Give that move an `intent`:

```gdscript
"summon": {"name": "Summon", "steps": 5, "intent": "summons a wall", "effects": [{"type": "call", "method": "summon"}]},
...
func summon(battle):
	battle.enemyShield += 400
	battle.updateEnemyShieldUI()
	return "THE WALL RISES"
```

- `phases` — each holds a `pattern` saying which moves the enemy uses:
  - `cycle` plays the moves in order and loops
  - `random` picks one each time; list a move twice to make it twice as likely
- Every phase after the first needs `hp_below`, the fraction of max HP it starts under
  (`0.5` = half), each lower than the last. An optional `name` pops up when it starts

A multi-phase enemy:

```gdscript
"moves": {
	"jab": {"name": "Jab", "steps": 4, "effects": [{"type": "attack", "amount": 15}]},
	"slam": {"name": "Slam", "steps": 6, "effects": [{"type": "attack", "amount": 40}, {"type": "add_garbage", "amount": 1}]},
	"spit": {"name": "Spit", "steps": 3, "effects": [{"type": "add_garbage", "amount": 2}]},
},
"phases": [
	{"pattern": {"type": "cycle", "moves": ["jab", "jab", "slam"]}},
	{"name": "Enraged", "hp_below": 0.5, "pattern": {"type": "random", "moves": ["slam", "slam", "spit"]}},
],
```

It opens Jab, Jab, Slam on repeat; below half HP it announces "ENRAGED" and picks Slam
two times in three, Spit otherwise. The move already on screen when a phase starts still
lands — the new pattern takes over from the next pick — and a single big hit can skip
straight past a phase. Every file is checked at startup: a typo, an unknown board or
pattern type, a phase threshold out of order, a missing or duplicate `boss_floor` is a red
error on launch, and a move no pattern uses is a warning. The `description` is still free text, so
keep it in step with the data by hand.

**Data debt spotted while writing this:**

- Several names are authored in lowercase (`huge worm`, `skeleton archer`, `slime body`,
  `rock golem`, `wendigo`, `centaur`, `death knight`) and show that way in game; this file
  capitalises them
- Shadow Lord and Death Knight share sprite `frame` 30, so the final boss looks like the
  floor-12 boss
- Shadow Lord's description says "halfed"
