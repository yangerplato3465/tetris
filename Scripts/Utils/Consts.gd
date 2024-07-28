extends Node

var tier1Enemy = [
	{
		"id": 1,
		"name": "Orc",
		"health": 10,
		"reward": 30,
		"frame": 0
	},
	{
		"id": 2,
		"name": "Goblin",
		"health": 10,
		"reward": 30,
		"frame": 2
	},
	{
		"id": 3,
		"name": "Slime",
		"health": 10,
		"reward": 30,
		"frame": 15
	},
	{
		"id": 4,
		"name": "Centipede",
		"health": 10,
		"reward": 30,
		"frame": 42
	},
	{
		"id": 5,
		"name": "Bat",
		"health": 10,
		"reward": 30,
		"frame": 48
	},
]

var tier2Enemy = [
	{
		"id": 6,
		"name": "Orc Wizard",
		"health": 60,
		"reward": 30,
		"frame": 1
	},
	{
		"id": 7,
		"name": "Skeleton",
		"health": 60,
		"reward": 30,
		"frame": 28
	},
	{
		"id": 8,
		"name": "Zombie",
		"health": 60,
		"reward": 30,
		"frame": 32
	},
	{
		"id": 9,
		"name": "Banshee",
		"health": 60,
		"reward": 30,
		"frame": 35
	},
	{
		"id": 10,
		"name": "Reaper",
		"health": 60,
		"reward": 30,
		"frame": 36
	},
]

var tier3Enemy = [
	{
		"id": 11,
		"name": "Ettin",
		"health": 60,
		"reward": 30,
		"frame": 7
	},
	{
		"id": 12,
		"name": "huge worm",
		"health": 60,
		"reward": 30,
		"frame": 44
	},
	{
		"id": 13,
		"name": "Death",
		"health": 60,
		"reward": 30,
		"frame": 37
	},
	{
		"id": 14,
		"name": "slime body",
		"health": 60,
		"reward": 30,
		"frame": 16
	},
	{
		"id": 15,
		"name": "skeleton archer",
		"health": 60,
		"reward": 30,
		"frame": 29
	},
]

var BossEnemy = [
	{
		"id": 16,
		"name": "rock golem",
		"health": 60,
		"reward": 30,
		"frame": 51
	},
	{
		"id": 16,
		"name": "wendigo",
		"health": 60,
		"reward": 30,
		"frame": 50
	},
	{
		"id": 17,
		"name": "centaur",
		"health": 60,
		"reward": 30,
		"frame": 52
	},
	{
		"id": 15,
		"name": "death knight",
		"health": 60,
		"reward": 30,
		"frame": 30
	},
	{
		"id": 18,
		"name": "Shadow Lord",
		"health": 60,
		"reward": 30,
		"frame": 30
	},
]

enum {
	COMMON,
	RARE,
	EPIC,
	LEGENDARY
}

var alchemyItems = [
	{
		"id": 0,
		"name": "Red Potion",
		"description": "Increase single damage by 10 (Current %1)",
		"price": 10,
		"frame": 144,
		"tier": COMMON
	},
	{
		"id": 1,
		"name": "Blue Potion",
		"description": "Increase double damage by 20 (Current %1)",
		"price": 10,
		"frame": 145,
		"tier": COMMON
	},
	{
		"id": 2,
		"name": "Green Potion",
		"description": "Increase triple damage by 30 (Current %1)",
		"price": 10,
		"frame": 146,
		"tier": COMMON
	},
	{
		"id": 3,
		"name": "Yellow Potion",
		"description": "Increase tetris damage by 50 (Current %1)",
		"price": 10,
		"frame":147,
		"tier": COMMON
	},
	{
		"id": 4,
		"name": "White Powder",
		"description": "Increase combo multiplier by 0.1 (Current %1)",
		"price": 10,
		"frame": 331,
		"tier": COMMON
	},
	{
		"id": 5,
		"name": "Hourglass",
		"description": "Increase timer by 5 seconds (Current %1)",
		"price": 10,
		"frame": 175,
		"tier": COMMON
	},
	{
		"id": 6,
		"name": "Red Potion+",
		"description": "Increase single damage by 20 (Current %1)",
		"price": 10,
		"frame": 148,
		"tier": RARE
	},
	{
		"id": 7,
		"name": "Blue Potion+",
		"description": "Increase double damage by 40 (Current %1)",
		"price": 10,
		"frame": 149,
		"tier": RARE
	},
	{
		"id": 8,
		"name": "Green Potion+",
		"description": "Increase triple damage by 60 (Current %1)",
		"price": 10,
		"frame": 150,
		"tier": RARE
	},
	{
		"id": 9,
		"name": "Yellow Potion+",
		"description": "Increase tetris damage by 100 (Current %1)",
		"price": 10,
		"frame":151,
		"tier": RARE
	},
	{
		"id": 10,
		"name": "Blue Powder",
		"description": "'I' pieces appear 2X more often",
		"price": 10,
		"frame": 326,
		"tier": RARE
	},
	{
		"id": 11,
		"name": "Purple Powder",
		"description": "Increase crit chance by 10%",
		"price": 10,
		"frame": 329,
		"tier": RARE
	},
	{
		"id": 12,
		"name": "Gray Powder",
		"description": "Increase all type damage by 30",
		"price": 10,
		"frame": 332,
		"tier": EPIC
	},
	{
		"id": 13,
		"name": "Red Glob",
		"description": "Double your current single damage (Current %1)",
		"price": 10,
		"frame": 288,
		"tier": LEGENDARY
	},
	{
		"id": 14,
		"name": "Blue Glob",
		"description": "Double your current double damage (Current %1)",
		"price": 10,
		"frame": 288,
		"tier": LEGENDARY
	},
	{
		"id": 15,
		"name": "Green Glob",
		"description": "Double your current triple damage (Current %1)",
		"price": 10,
		"frame": 288,
		"tier": LEGENDARY
	},
	{
		"id": 16,
		"name": "Yellow Glob",
		"description": "Double your current tetris damage (Current %1)",
		"price": 10,
		"frame": 288,
		"tier": LEGENDARY
	},
]

var equipmentNormalItems = [
	{
		"id": 17,
		"name": "Old Key",
		"description": "Unlock the ability to hold pieces",
		"price": 10,
		"frame": 185,
		"tier": COMMON
	},
	{
		"id": 18,
		"name": "Magnifying Glass",
		"description": "See one more up coming piece",
		"price": 10,
		"frame": 169,
		"tier": COMMON
	},
	{
		"id": 19,
		"name": "Magnifying Glass",
		"description": "See one more up coming piece",
		"price": 10,
		"frame": 169,
		"tier": COMMON
	},
	{
		"id": 20,
		"name": "Magnifying Glass",
		"description": "See one more up coming piece",
		"price": 10,
		"frame": 169,
		"tier": COMMON
	},
	{
		"id": 21,
		"name": "Magnifying Glass",
		"description": "See one more up coming piece",
		"price": 10,
		"frame": 169,
		"tier": COMMON
	},
	{
		"id": 22,
		"name": "Double Edge Sword",
		"description": "Every time you hard drop, deal your single damage (%1) to the enemy",
		"price": 10,
		"frame": 82,
		"tier": EPIC
	},
	{
		"id": 23,
		"name": "Treasure Box",
		"description": "Every time you score a Tetris, gain 10 coins",
		"price": 10,
		"frame": 187,
		"tier": RARE
	},
	{
		"id": 24,
		"name": "Ocarina of Time",
		"description": "Every time you score a double, gain 5 second on the timer",
		"price": 10,
		"frame": 181,
		"tier": RARE
	},
]
