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

# Assigns a random elemental type (1=fire, 2=ice, 3=poison) to one random block in the piece
func assignRandomElemental():
	var cells = []
	for x in range(shape.size()):
		for y in range(shape[0].size()):
			if shape[x][y] != 0:
				cells.append(Vector2(x, y))
	if cells.is_empty():
		return
	var chosen = cells[randi() % cells.size()]
	var elemental_type = 1 + randi() % 3
	shape[chosen.x][chosen.y] += elemental_type * 10
	
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
