extends Node

var tier1Enemy = [
	{
		"id": 1,
		"name": "Orc",
		"health": 200,
		"reward": 60,
		"frame": 0,
		"description": "Extra high health"
	},
	{
		"id": 2,
		"name": "Goblin",
		"health": 150,
		"reward": 30,
		"frame": 2,
		"description": ""
	},
	{
		"id": 3,
		"name": "Slime",
		"health": 120,
		"reward": 20,
		"frame": 15,
		"description": "Start with small messy board"
	},
	{
		"id": 4,
		"name": "Centipede",
		"health": 120,
		"reward": 40,
		"frame": 42,
		"description": "Start with 10 less sec on the timer"
	},
	{
		"id": 5,
		"name": "Bat",
		"health": 100,
		"reward": 30,
		"frame": 48,
		"description": "-10 on all damage"
	},
]

var tier2Enemy = [
	{
		"id": 6,
		"name": "Orc Wizard",
		"health": 200,
		"reward": 100,
		"frame": 1,
		"description": "Start with a messy board"
	},
	{
		"id": 7,
		"name": "Skeleton",
		"health": 250,
		"reward": 100,
		"frame": 28,
		"description": "Start with 15 less sec on the timer"
	},
	{
		"id": 8,
		"name": "Zombie",
		"health": 300,
		"reward": 150,
		"frame": 32,
		"description": "Start with a messy board, -10 sec on the timer"
	},
	{
		"id": 9,
		"name": "Banshee",
		"health": 200,
		"reward": 150,
		"frame": 35,
		"description": "Start with a messy board, -10 on all damage"
	},
	{
		"id": 10,
		"name": "Reaper",
		"health": 200,
		"reward": 200,
		"frame": 36,
		"description": "Start with a messy board, -5 on all damage, -10 sec on the timer"
	},
]

var tier3Enemy = [
	{
		"id": 11,
		"name": "Ettin",
		"health": 500,
		"reward": 150,
		"frame": 7,
		"description": "Start with a very messy board"
	},
	{
		"id": 12,
		"name": "huge worm",
		"health": 1000,
		"reward": 200,
		"frame": 44,
		"description": "Start with a very messy board, Extra high health"
	},
	{
		"id": 13,
		"name": "Death",
		"health": 500,
		"reward": 200,
		"frame": 37,
		"description": "Start with a very messy board, 15 less sec on the timer"
	},
	{
		"id": 14,
		"name": "slime body",
		"health": 600,
		"reward": 200,
		"frame": 16,
		"description": "Start with a very messy board, You cannot hold pieces"
	},
	{
		"id": 15,
		"name": "skeleton archer",
		"health": 500,
		"reward": 200,
		"frame": 29,
		"description": "Start with a very messy board, -20 on all damage"
	},
]

var BossEnemy = [
	{
		"id": 16,
		"name": "rock golem",
		"health": 500,
		"reward": 200,
		"frame": 51,
		"description": "Start with a small messy board, 15 less sec on the timer"
	},
	{
		"id": 17,
		"name": "wendigo",
		"health": 400,
		"reward": 300,
		"frame": 50,
		"description": "Start with a messy board, -10 on all damage"
	},
	{
		"id": 18,
		"name": "centaur",
		"health": 60,
		"reward": 400,
		"frame": 52,
		"description": "Start with a messy board, -10 on all damage, 20 less sec on the timer"
	},
	{
		"id": 19,
		"name": "death knight",
		"health": 60,
		"reward": 500,
		"frame": 30,
		"description": "Start with a very messy board, -10 on all damage, you cannot hold pieces"
	},
	{
		"id": 20,
		"name": "Shadow Lord",
		"health": 60,
		"reward": 0,
		"frame": 30,
		"description": "Final boss, Start with a very messy board, all damage halfed"
	},
]

enum {
	COMMON,
	RARE,
	EPIC,
	LEGENDARY
}

var alchemyCommonItems = [
	{
		"id": 0,
		"name": "Red Potion",
		"description": "Increase single damage by 10 (Current %1)",
		"price": 20,
		"frame": 144,
		"tier": COMMON
	},
	{
		"id": 1,
		"name": "Blue Potion",
		"description": "Increase double damage by 20 (Current %1)",
		"price": 30,
		"frame": 145,
		"tier": COMMON
	},
	{
		"id": 2,
		"name": "Green Potion",
		"description": "Increase triple damage by 30 (Current %1)",
		"price": 30,
		"frame": 146,
		"tier": COMMON
	},
	{
		"id": 3,
		"name": "Yellow Potion",
		"description": "Increase tetris damage by 50 (Current %1)",
		"price": 40,
		"frame":147,
		"tier": COMMON
	},
	{
		"id": 4,
		"name": "White Powder",
		"description": "Increase combo multiplier by 0.1 (Current %1)",
		"price": 30,
		"frame": 331,
		"tier": COMMON
	},
	{
		"id": 5,
		"name": "Hourglass",
		"description": "Increase timer by 10 seconds (Current %1)",
		"price": 30,
		"frame": 175,
		"tier": COMMON
	},
]

var alchemyRareItems = [
	{
		"id": 6,
		"name": "Red Potion+",
		"description": "Increase single damage by 20 (Current %1)",
		"price": 50,
		"frame": 148,
		"tier": RARE
	},
	{
		"id": 7,
		"name": "Blue Potion+",
		"description": "Increase double damage by 40 (Current %1)",
		"price": 60,
		"frame": 149,
		"tier": RARE
	},
	{
		"id": 8,
		"name": "Green Potion+",
		"description": "Increase triple damage by 60 (Current %1)",
		"price": 60,
		"frame": 150,
		"tier": RARE
	},
	{
		"id": 9,
		"name": "Yellow Potion+",
		"description": "Increase tetris damage by 100 (Current %1)",
		"price": 70,
		"frame":151,
		"tier": RARE
	},
	{
		"id": 10,
		"name": "Magic mirror",
		"description": "Increase timer by 15 seconds (Current %1)",
		"price": 60,
		"frame":177,
		"tier": RARE
	},
	{
		"id": 11,
		"name": "Blue Powder",
		"description": "'I' pieces appear 2X more often",
		"price": 100,
		"frame": 326,
		"tier": EPIC
	},
	{
		"id": 12,
		"name": "Purple Powder",
		"description": "Increase combo multiplier by 0.2",
		"price": 60,
		"frame": 329,
		"tier": RARE
	},
	{
		"id": 13,
		"name": "Gray Powder",
		"description": "Increase all type damage by 30",
		"price": 80,
		"frame": 332,
		"tier": EPIC
	},
]

var alchemyLegendaryItems = [
		{
		"id": 14,
		"name": "Red Glob",
		"description": "Double your current single damage (Current %1)",
		"price": 150,
		"frame": 288,
		"tier": LEGENDARY
	},
	{
		"id": 15,
		"name": "Blue Glob",
		"description": "Double your current double damage (Current %1)",
		"price": 200,
		"frame": 289,
		"tier": LEGENDARY
	},
	{
		"id": 16,
		"name": "Green Glob",
		"description": "Double your current triple damage (Current %1)",
		"price": 200,
		"frame": 290,
		"tier": LEGENDARY
	},
	{
		"id": 17,
		"name": "Yellow Glob",
		"description": "Double your current tetris damage (Current %1)",
		"price": 250,
		"frame": 291,
		"tier": LEGENDARY
	},
	{
		"id": 18,
		"name": "Purple Glob",
		"description": "Increase combo multiplier by 0.5 (Current %1)",
		"price": 250,
		"frame": 291,
		"tier": LEGENDARY
	},
]

var equipmentCommonItems = [
	{
		"id": 19,
		"name": "Old Key",
		"description": "Unlock the ability to hold pieces",
		"price": 30,
		"frame": 185,
		"tier": COMMON
	},
	{
		"id": 20,
		"name": "Magnifying Glass",
		"description": "See one more up coming piece",
		"price": 20,
		"frame": 169,
		"tier": COMMON
	},
	{
		"id": 21,
		"name": "Magnifying Glass",
		"description": "See one more up coming piece",
		"price": 20,
		"frame": 169,
		"tier": COMMON
	},
	{
		"id": 22,
		"name": "Magnifying Glass",
		"description": "See one more up coming piece",
		"price": 20,
		"frame": 169,
		"tier": COMMON
	},
	{
		"id": 23,
		"name": "The lost chapter",
		"description": "Rare and Epic items will appear in the shop",
		"price": 20,
		"frame": 215,
		"tier": COMMON
	},
]

var equipmentRareItems = [
	{
		"id": 24,
		"name": "Double Edge Sword",
		"description": "Every time you hard drop, deal your single damage (%1) to the enemy",
		"price": 80,
		"frame": 82,
		"tier": RARE
	},
	{
		"id": 25,
		"name": "Treasure Box",
		"description": "Every time you score a Tetris, gain 10 coins",
		"price": 100,
		"frame": 187,
		"tier": RARE
	},
	{
		"id": 26,
		"name": "The legendary chapter",
		"description": "Legendary items will appear in the shop",
		"price": 100,
		"frame": 215,
		"tier": RARE
	},
]

var equipmentLegendaryItems = [
	{
		"id": 27,
		"name": "Ocarina of Time",
		"description": "Every time you score a double, gain 5 second on the timer",
		"price": 500,
		"frame": 181,
		"tier": LEGENDARY
	},
]

var howToPlay = "-Deal damage by clearing lines on a tetris board
-The more lines cleared the more damage dealt
-consecutively clearing lines deals more damage
-you lose a run when the timer runs out or the tetrimino
reaches the top, base timer is 40 seconds
-item shop shows up when you defeat an enemy, gather 
coins to spend at the shop
-you can rebind control in the settings menu
-different enemies have certain debuff on you"
