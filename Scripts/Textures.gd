extends Node

const texture0 = preload("res://spr/ghost.png")
const texture1 = preload("res://spr/block.png") #I
const texture2 = preload("res://spr/block.png") #J
const texture3 = preload("res://spr/block.png") #L
const texture4 = preload("res://spr/block.png") #O
const texture5 = preload("res://spr/block.png") #T
const texture6 = preload("res://spr/block.png") #Z
const texture7 = preload("res://spr/block.png") #S

func getTextureForColorIndex(index):
	match (index):
		(0): return texture0
		(1): return texture1
		(2): return texture2
		(3): return texture3
		(4): return texture4
		(5): return texture5
		(6): return texture6
		(7): return texture7
