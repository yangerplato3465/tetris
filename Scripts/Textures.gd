extends Node

const texture0 = preload("res://Sprite/grid_small.png")
const texture1 = preload("res://Sprite/block_L.png") #I
const texture2 = preload("res://Sprite/block_L.png") #J
const texture3 = preload("res://Sprite/block_L.png") #L
const texture4 = preload("res://Sprite/block_L.png") #O
const texture5 = preload("res://Sprite/block_L.png") #T
const texture6 = preload("res://Sprite/block_L.png") #Z
const texture7 = preload("res://Sprite/block_L.png") #S

func getTextureForColorIndex(index):
	if index == 8:
		return texture1
	match (index % 10):
		# (0): return texture0
		(1): return texture1
		(2): return texture2
		(3): return texture3
		(4): return texture4
		(5): return texture5
		(6): return texture6
		(7): return texture7

# Returns the tint color for an elemental block value
# Grid cell value encoding:
#   0     = empty
#   1–7   = normal block (piece type 1–7)
#   11–17 = fire block   (red tint,   elemental = value / 10 == 1)
#   21–27 = ice block    (blue tint,  elemental = value / 10 == 2)
#   31–37 = poison block (green tint, elemental = value / 10 == 3)
# piece type  = value % 10
# elemental   = value / 10
func getElementalColor(index):
	if index == 8:
		return Color(0.7, 0.2, 1.0)  # Garbage - purple
	match (index / 10):
		1: return Color(1.0, 0.25, 0.25)  # Fire - red
		2: return Color(0.25, 0.55, 1.0)  # Ice - blue
		3: return Color(0.25, 1.0, 0.25)  # Poison - green
		4: return Color(1.0, 0.85, 0.0)   # Gold - yellow
		_: return Color.WHITE
