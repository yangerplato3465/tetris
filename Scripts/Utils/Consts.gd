extends Node

var tier1Enemy = [
	{
		"id": 1,
		"name": "Orc",
		"time": 60,
		"health": 10,
		"reward": 30,
		"frame": 0
	},
	{
		"id": 2,
		"name": "Goblin",
		"time": 60,
		"health": 10,
		"reward": 30,
		"frame": 2
	},
	{
		"id": 3,
		"name": "Slime",
		"time": 60,
		"health": 10,
		"reward": 30,
		"frame": 14
	},
	{
		"id": 4,
		"name": "Centipede",
		"time": 60,
		"health": 10,
		"reward": 30,
		"frame": 42
	},
	{
		"id": 5,
		"name": "Bat",
		"time": 60,
		"health": 10,
		"reward": 30,
		"frame": 48
	},
]

var tier2Enemy = [
	{
		"id": 6,
		"name": "Orc Wizard",
		"time": 30,
		"health": 60,
		"reward": 30,
		"frame": 1
	},
	{
		"id": 7,
		"name": "Skeleton",
		"time": 30,
		"health": 60,
		"reward": 30,
		"frame": 28
	},
	{
		"id": 8,
		"name": "Zombie",
		"time": 30,
		"health": 60,
		"reward": 30,
		"frame": 32
	},
	{
		"id": 9,
		"name": "Banshee",
		"time": 30,
		"health": 60,
		"reward": 30,
		"frame": 35
	},
	{
		"id": 10,
		"name": "Reaper",
		"time": 30,
		"health": 60,
		"reward": 30,
		"frame": 36
	},
]

var tier3Enemy = [
	{
		"id": 11,
		"name": "Ettin",
		"time": 30,
		"health": 60,
		"reward": 30,
		"frame": 7
	},
	{
		"id": 12,
		"name": "worm",
		"time": 30,
		"health": 60,
		"reward": 30,
		"frame": 44
	},
	{
		"id": 13,
		"name": "Death",
		"time": 30,
		"health": 60,
		"reward": 30,
		"frame": 37
	},
	{
		"id": 14,
		"name": "rock golem",
		"time": 30,
		"health": 60,
		"reward": 30,
		"frame": 51
	},
	{
		"id": 15,
		"name": "lich",
		"time": 30,
		"health": 60,
		"reward": 30,
		"frame": 33
	},
]

var BossEnemy = [
	{
		"id": 16,
		"name": "wendigo",
		"time": 30,
		"health": 60,
		"reward": 30,
		"frame": 50
	},
	{
		"id": 17,
		"name": "centaur",
		"time": 30,
		"health": 60,
		"reward": 30,
		"frame": 52
	},
	{
		"id": 18,
		"name": "Shadow Lord",
		"time": 30,
		"health": 60,
		"reward": 30,
		"frame": 30
	},
]

var alchemyItems = [
	{
		"id": 0,
		"name": "Red Potion",
		"description": "Increase single damage by 10 (Current %1)",
		"price": 10,
		"frame": 144
	},
	{
		"id": 1,
		"name": "Blue Potion",
		"description": "Increase double damage by 20 (Current %1)",
		"price": 10,
		"frame": 145
	},
	{
		"id": 2,
		"name": "Green Potion",
		"description": "Increase triple damage by 30 (Current %1)",
		"price": 10,
		"frame": 146
	},
	{
		"id": 3,
		"name": "Yellow Potion",
		"description": "Increase tetris damage by 50 (Current %1)",
		"price": 10,
		"frame":326
	},
	{
		"id": 4,
		"name": "Blue Powder",
		"description": "Increase combo multiplier by 0.1 (Current %1)",
		"price": 10,
		"frame": 144
	},
	{
		"id": 5,
		"name": "Hourglass",
		"description": "Increase timer by 5 seconds (Current %1)",
		"price": 10,
		"frame": 175
	},
	{
		"id": 6,
		"name": "",
		"description": "",
		"price": 10,
		"frame": 144
	},
	{
		"id": 7,
		"name": "",
		"description": "",
		"price": 10,
		"frame": 144
	},
	{
		"id": 8,
		"name": "",
		"description": "",
		"price": 10,
		"frame": 144
	},
	{
		"id": 9,
		"name": "",
		"description": "",
		"price": 10,
		"frame": 144
	},
	{
		"id": 10,
		"name": "",
		"description": "",
		"price": 10,
		"frame": 144
	},
	{
		"id": 11,
		"name": "",
		"description": "",
		"price": 10,
		"frame": 144
	},
	{
		"id": 12,
		"name": "",
		"description": "",
		"price": 10,
		"frame": 144
	},
	{
		"id": 13,
		"name": "",
		"description": "",
		"price": 10,
		"frame": 144
	},
]

var equipmentItems = [
	{
		"id": 0,
		"name": "Old Key",
		"description": "Unlock the ability to hold pieces",
		"price": 10,
		"frame": 185
	},
	{
		"id": 1,
		"name": "Magnifying Glass",
		"description": "See one more up coming piece",
		"price": 10,
		"frame": 169
	},
	{
		"id": 1,
		"name": "Magnifying Glass",
		"description": "See one more up coming piece",
		"price": 10,
		"frame": 169
	},
	{
		"id": 1,
		"name": "Magnifying Glass",
		"description": "See one more up coming piece",
		"price": 10,
		"frame": 169
	},
	{
		"id": 1,
		"name": "Magnifying Glass",
		"description": "See one more up coming piece",
		"price": 10,
		"frame": 169
	},
	{
		"id": 2,
		"name": "Double Edge Sword",
		"description": "Every time you hard drop, deal your single damage (%1) to the enemy",
		"price": 10,
		"frame": 82
	},
	{
		"id": 3,
		"name": "Treasure Box",
		"description": "Every time you score a tetris, gain 5 coins",
		"price": 10,
		"frame": 187
	},
	{
		"id": 3,
		"name": "Ocarina of Time",
		"description": "Every time you score a triple, gain 5 second on the timer",
		"price": 10,
		"frame": 181
	},
]
