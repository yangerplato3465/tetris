extends Node

const pokeball0 = preload("res://spr/ghost.png")
const pokeball1 = preload("res://spr/block.png")
const pokeball2 = preload("res://spr/block.png")
const pokeball3 = preload("res://spr/block.png")
const pokeball4 = preload("res://spr/block.png")
const pokeball5 = preload("res://spr/block.png")
const pokeball6 = preload("res://spr/block.png")
const pokeball7 = preload("res://spr/block.png")

func getTextureForColorIndex(index):
	match (index):
		(0): return pokeball0
		(1): return pokeball1
		(2): return pokeball2
		(3): return pokeball3
		(4): return pokeball4
		(5): return pokeball5
		(6): return pokeball6
		(7): return pokeball7
