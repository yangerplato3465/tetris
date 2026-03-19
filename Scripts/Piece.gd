extends Node2D

var positionInGrid:Vector2
var rotationState = 0
var shape

func getColorIndex():
	for i in range(shape.size()):
		for j in range(shape[0].size()):
			if shape[i][j] != 0:
				return shape[i][j] % 10
	return 0

# Assigns a random elemental type to one random block in the piece.
# Fire (1) and poison (3) only appear if unlocked via upgrades. Ice (2) is always available.
func assignRandomElemental():
	var available = [2]  # ice always available
	if PlayerManager.fireBlocks:
		available.append(1)
	if PlayerManager.poisonBlocks:
		available.append(3)
	if PlayerManager.goldBlocks:
		available.append(4)
	var cells = []
	for x in range(shape.size()):
		for y in range(shape[0].size()):
			if shape[x][y] != 0:
				cells.append(Vector2(x, y))
	if cells.is_empty():
		return
	var chosen = cells[randi() % cells.size()]
	var elemental_type = available[randi() % available.size()]
	shape[chosen.x][chosen.y] += elemental_type * 10
	
func assignAllElemental(elemental_type: int):
	for x in range(shape.size()):
		for y in range(shape[0].size()):
			if shape[x][y] != 0:
				shape[x][y] = (shape[x][y] % 10) + elemental_type * 10

func assignOrb():
	var cells = []
	for x in range(shape.size()):
		for y in range(shape[0].size()):
			if shape[x][y] != 0:
				cells.append(Vector2(x, y))
	if cells.is_empty():
		return
	var chosen = cells[randi() % cells.size()]
	shape[chosen.x][chosen.y] = (shape[chosen.x][chosen.y] % 10) + 50

func getShapeWithoutBorders():
	var newShape = shape.duplicate(true)
	
	#Check and remove empty rows
	var rowsToRemove = []
	for i in range(shape.size()):
		var empty = true
		for j in range(shape[0].size()):
			if shape[j][i] != 0:
				empty = false
				break;
		if empty:
			rowsToRemove.append(i)
	MatrixOperations.removeRowsFromMatrix(newShape,rowsToRemove)
	
	#Check and remove empty columns
	var columnsToRemove = []
	for j in range(newShape.size()):
		var empty = true
		for i in range(newShape[0].size()):
			if newShape[j][i] != 0:
				empty = false
				break;
		if empty:
			columnsToRemove.append(j)
	
	MatrixOperations.removeColumnsFromMatrix(newShape, columnsToRemove)
	return newShape

func getTextureForPiece():
	return Textures.getTextureForColorIndex(getColorIndex())

func getShapeName():
	match (getColorIndex()):
		1: return "I"
		2: return "J"
		3: return "L"
		4: return "O"
		5: return "T"
		6: return "Z"
		7: return "S"
