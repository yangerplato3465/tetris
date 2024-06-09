extends Node

const texture0 = preload("res://Sprite/ghost.png")
const texture1 = preload("res://Sprite/block.png") #I
const texture2 = preload("res://Sprite/block.png") #J
const texture3 = preload("res://Sprite/block.png") #L
const texture4 = preload("res://Sprite/block.png") #O
const texture5 = preload("res://Sprite/block.png") #T
const texture6 = preload("res://Sprite/block.png") #Z
const texture7 = preload("res://Sprite/block.png") #S

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
