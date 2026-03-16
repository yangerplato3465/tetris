extends Node

var tier1Enemy = [
	{
		"id": 1,
		"name": "Orc",
		"health": 100,
		"reward": 80,
		"frame": 0,
		"description": "",
		"attackInterval": 7,
		"attackDamage": 15,
		"attackAddsGarbage": false
	},
	{
		"id": 2,
		"name": "Goblin",
		"health": 60,
		"reward": 40,
		"frame": 2,
		"description": "",
		"attackInterval": 8,
		"attackDamage": 12,
		"attackAddsGarbage": false
	},
	{
		"id": 3,
		"name": "Slime",
		"health": 60,
		"reward": 60,
		"frame": 15,
		"description": "Start with small messy board",
		"attackInterval": 7,
		"attackDamage": 15,
		"attackAddsGarbage": false
	},
	{
		"id": 4,
		"name": "Centipede",
		"health": 60,
		"reward": 60,
		"frame": 42,
		"description": "",
		"attackInterval": 6,
		"attackDamage": 18,
		"attackAddsGarbage": false
	},
	{
		"id": 5,
		"name": "Bat",
		"health": 60,
		"reward": 60,
		"frame": 48,
		"description": "-5 on all damage",
		"attackInterval": 8,
		"attackDamage": 10,
		"attackAddsGarbage": false
	},
]

var tier2Enemy = [
	{
		"id": 6,
		"name": "Orc Wizard",
		"health": 200,
		"reward": 100,
		"frame": 1,
		"description": "Start with a messy board",
		"attackInterval": 6,
		"attackDamage": 25,
		"attackAddsGarbage": false
	},
	{
		"id": 7,
		"name": "Skeleton",
		"health": 250,
		"reward": 100,
		"frame": 28,
		"description": "",
		"attackInterval": 5,
		"attackDamage": 28,
		"attackAddsGarbage": false
	},
	{
		"id": 8,
		"name": "Zombie",
		"health": 250,
		"reward": 150,
		"frame": 32,
		"description": "Start with a messy board",
		"attackInterval": 6,
		"attackDamage": 25,
		"attackAddsGarbage": true
	},
	{
		"id": 9,
		"name": "Banshee",
		"health": 250,
		"reward": 150,
		"frame": 35,
		"description": "Start with a messy board, -15 on all damage",
		"attackInterval": 5,
		"attackDamage": 30,
		"attackAddsGarbage": false
	},
	{
		"id": 10,
		"name": "Reaper",
		"health": 250,
		"reward": 200,
		"frame": 36,
		"description": "Start with a messy board, -10 on all damage",
		"attackInterval": 5,
		"attackDamage": 32,
		"attackAddsGarbage": true
	},
]

var tier3Enemy = [
	{
		"id": 11,
		"name": "Ettin",
		"health": 500,
		"reward": 150,
		"frame": 7,
		"description": "Start with a very messy board",
		"attackInterval": 5,
		"attackDamage": 38,
		"attackAddsGarbage": true
	},
	{
		"id": 12,
		"name": "huge worm",
		"health": 800,
		"reward": 200,
		"frame": 44,
		"description": "Start with a messy board",
		"attackInterval": 4,
		"attackDamage": 35,
		"attackAddsGarbage": true
	},
	{
		"id": 13,
		"name": "Death",
		"health": 500,
		"reward": 200,
		"frame": 37,
		"description": "Start with a messy board",
		"attackInterval": 4,
		"attackDamage": 40,
		"attackAddsGarbage": true
	},
	{
		"id": 14,
		"name": "slime body",
		"health": 600,
		"reward": 200,
		"frame": 16,
		"description": "Start with a messy board, You cannot hold pieces",
		"attackInterval": 5,
		"attackDamage": 35,
		"attackAddsGarbage": true
	},
	{
		"id": 15,
		"name": "skeleton archer",
		"health": 500,
		"reward": 200,
		"frame": 29,
		"description": "Start with a messy board, -20 on all damage",
		"attackInterval": 5,
		"attackDamage": 40,
		"attackAddsGarbage": false
	},
]

var BossEnemy = [
	{
		"id": 16,
		"name": "rock golem",
		"health": 200,
		"reward": 120,
		"frame": 51,
		"description": "Start with a small messy board",
		"attackInterval": 4,
		"attackDamage": 40,
		"attackAddsGarbage": true
	},
	{
		"id": 17,
		"name": "wendigo",
		"health": 400,
		"reward": 150,
		"frame": 50,
		"description": "Start with a messy board, -15 on all damage",
		"attackInterval": 4,
		"attackDamage": 45,
		"attackAddsGarbage": false
	},
	{
		"id": 18,
		"name": "centaur",
		"health": 800,
		"reward": 200,
		"frame": 52,
		"description": "Start with a messy board, -15 on all damage",
		"attackInterval": 4,
		"attackDamage": 45,
		"attackAddsGarbage": true
	},
	{
		"id": 19,
		"name": "death knight",
		"health": 1200,
		"reward": 300,
		"frame": 30,
		"description": "Start with a very messy board, -10 on all damage, you cannot hold pieces",
		"attackInterval": 3,
		"attackDamage": 50,
		"attackAddsGarbage": true
	},
	{
		"id": 20,
		"name": "Shadow Lord",
		"health": 1000,
		"reward": 0,
		"frame": 30,
		"description": "Final boss, Start with a very messy board, all damage halfed",
		"attackInterval": 3,
		"attackDamage": 60,
		"attackAddsGarbage": true
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
		"id": 4,
		"name": "White Powder",
		"description": "Increase combo multiplier by 0.1 (Current %1)",
		"price": 30,
		"frame": 331,
		"tier": COMMON
	},
	{
		"id": 28,
		"name": "Fire Shard",
		"description": "Fire blocks appear in pieces. Clearing fire blocks deals +15 bonus damage each",
		"price": 40,
		"frame": 242,
		"tier": COMMON
	},
	{
		"id": 29,
		"name": "Poison Vial",
		"description": "Poison blocks appear in pieces. Clearing poison blocks deals +8 bonus damage each",
		"price": 30,
		"frame": 244,
		"tier": COMMON
	},
	{
		"id": 30,
		"name": "Gold Shard",
		"description": "Gold blocks appear in pieces. Clearing gold blocks gives 1 coin each",
		"price": 40,
		"frame": 246,
		"tier": COMMON
	},
]

var alchemyRareItems = [
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
]

var alchemyLegendaryItems = [
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
		"price": 30,
		"frame": 169,
		"tier": COMMON
	},
	{
		"id": 21,
		"name": "Magnifying Glass",
		"description": "See one more up coming piece",
		"price": 30,
		"frame": 169,
		"tier": COMMON
	},
	{
		"id": 22,
		"name": "Magnifying Glass",
		"description": "See one more up coming piece",
		"price": 30,
		"frame": 169,
		"tier": COMMON
	},
	{
		"id": 23,
		"name": "The lost chapter",
		"description": "Rare and Epic items will appear in the shop",
		"price": 30,
		"frame": 215,
		"tier": COMMON
	},
]

var equipmentRareItems = [
	{
		"id": 24,
		"name": "Double Edge Sword",
		"description": "Every time you hard drop, deal 20 damage to the enemy",
		"price": 150,
		"frame": 82,
		"tier": RARE
	},
	{
		"id": 25,
		"name": "Treasure Box",
		"description": "Every time you score a Tetris, gain 50 coins",
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

var equipmentLegendaryItems = []

var howToPlay = "-Deal damage by clearing lines on a tetris board
-consecutively clearing lines deals more damage
-you lose a run when the tetrimino reaches the top
-you start with 50 coins, item shop shows up when you
defeat an enemy,gather coins to spend at the shop
-hover on shop items to see what it does
-you can rebind control in the settings menu
-different enemies have certain debuff on you
-There are a total of 15 levels, good luck!"
