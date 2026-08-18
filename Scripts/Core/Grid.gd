extends Node2D

signal clearLines(cleared, combo)
signal pieceDropped
signal magicMeterChanged
signal energyOverflow(count) # orbs collected past the energy cap
signal grid_gameover

var grid = []
const gridWidth = 10
const gridHeight = 23
const vanishZone = 3
const spriteSize = 32
var gridOffsetX
var gridOffsetY

const dasDelay = 8
const infinityValue = 15

const Piece = preload("res://Scripts/Core/Piece.gd")
var currentPiece: Piece
var lastPiece: Piece

const darkMaterial = preload("res://extras/DarkMaterial.tres")

const DropParticle = preload("res://Scene/DropParticle.tscn")
const ClearParticle = preload("res://Scene/ClearParticle.tscn")
@onready var gridBg = $UI/GridBackground
@onready var border = $UI/Border
const GRIDBG_POS = Vector2(230, 101)
const BORDER_POS = Vector2(218, 88)

var timer = 0
var deltaSum = 0
var clearedLines = 0
var dasCounter = 0
var lines = 0
var level = 1
var score = 0
var actions = 0
var prevActions = 0
var speed = 1
var hasSwapped = false
var hasCleared = false
var combo = 0
var startingBoard = []

var currentBag
var nextBag
var pieceCount = 0

var _grid_sprites: Array = []
var _ghost_sprites: Array = []

const BORDER_OFFSET = 10
enum Direction {CLOCKWISE, ANTICLOCKWISE}

# Called when the node enters the scene tree for the first time.
func _ready():
	gridOffsetX = $UI/Border.position.x + BORDER_OFFSET
	gridOffsetY = $UI/Border.position.y - (vanishZone-1)*spriteSize
	_initSprites()
	grid = MatrixOperations.create2DMatrix(gridWidth, gridHeight, 0, Utilities.generateMediumMessyBoard())

	currentBag = newBag()
	nextBag = newBag()
	spawnFromBag()
	$UI/NextPieces.drawPieces(currentBag, nextBag)

func _initSprites():
	_grid_sprites = []
	for x in range(gridWidth):
		var col = []
		for y in range(gridHeight):
			var sprite = Sprite2D.new()
			sprite.scale = Vector2(2, 2)
			sprite.centered = false
			sprite.visible = false
			if y == vanishZone - 1:
				sprite.region_enabled = true
				sprite.region_rect = Rect2(0, 6, 16, 10)
				sprite.position = Vector2(x * spriteSize + gridOffsetX, y * spriteSize + gridOffsetY + 16)
			else:
				sprite.position = Vector2(x * spriteSize + gridOffsetX, y * spriteSize + gridOffsetY)
			add_child(sprite)
			col.append(sprite)
		_grid_sprites.append(col)
	for _i in range(4):
		var ghost = Sprite2D.new()
		ghost.scale = Vector2(2, 2)
		ghost.centered = false
		ghost.visible = false
		add_child(ghost)
		_ghost_sprites.append(ghost)

func setStage(enemyInfo): # Set stage base on enemy abilities and stats
	match enemyInfo.id:
		3, 16:
			startingBoard = Utilities.generateSmallMessyBoard()
		6, 8, 9, 10, 17, 18, 12, 13, 15:
			startingBoard = Utilities.generateMediumMessyBoard()
		11, 20:
			startingBoard = Utilities.generateLargeMessyBoard()
		14:
			startingBoard = Utilities.generateMediumMessyBoard()
		19:
			startingBoard = Utilities.generateLargeMessyBoard()
		_:
			startingBoard = PlayerManager.startGrid


func stopGrid():
	set_physics_process(false)

func resetGrid():
	set_physics_process(true)
	grid = MatrixOperations.create2DMatrix(gridWidth, gridHeight, 0, startingBoard)
	currentBag = newBag()
	nextBag = newBag()
	pieceCount = 0
	spawnFromBag()
	$UI/Hold.reset()

func stageReady():
	drawGrid()
	drawDroppingPoint()

func newBag():
	var bagIndexes = PlayerManager.spawnBag
	var newBagIndexes = bagIndexes.duplicate()
	newBagIndexes.shuffle()
	var bag = []
	while (!newBagIndexes.is_empty()):
		var piece = Piece.new()
		piece.shape = Constants.SHAPES[newBagIndexes.pop_back()].duplicate(true)
		piece.assignRandomElemental()
		bag.append(piece)
	return bag

func drawGrid():
	for x in range(gridWidth):
		for y in range(vanishZone - 1, gridHeight):
			var value = grid[x][y]
			var sprite = _grid_sprites[x][y]
			if value == 0:
				sprite.visible = false
			else:
				sprite.texture = Textures.getTextureForColorIndex(value)
				sprite.self_modulate = Textures.getElementalColor(value)
				sprite.visible = true

func addPiece():
	for x in currentPiece.shape.size():
		for y in currentPiece.shape[0].size():
			if currentPiece.shape[x][y] != 0:
				grid[currentPiece.positionInGrid.x+x][currentPiece.positionInGrid.y+y] = currentPiece.shape[x][y]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var sthHappened = false
	#if Input.is_action_just_pressed("ui_exit"):
		#get_tree().quit()
	if Input.is_action_just_pressed("right"):
		if canPieceMoveRight():
			AudioManager.move.play()
			movePieceInGrid(1,0)
			sthHappened = true
			actions += 1
		deltaSum = 0
		dasCounter = 0
	if Input.is_action_just_pressed("left"):
		if canPieceMoveLeft():
			AudioManager.move.play()
			movePieceInGrid(-1,0)
			sthHappened = true
			actions += 1
		deltaSum = 0
		dasCounter = 0

	deltaSum += delta
	if (deltaSum > 2*delta) && (dasCounter>dasDelay):
		if Input.is_action_pressed("right"):
			if canPieceMoveRight():
				AudioManager.move.play()
				movePieceInGrid(1,0)
				sthHappened = true
				actions += 1
		if Input.is_action_pressed("left"):
			if canPieceMoveLeft():
				AudioManager.move.play()
				movePieceInGrid(-1,0)
				sthHappened = true
				actions += 1
		deltaSum = 0
	dasCounter+=1
	if Input.is_action_pressed("soft_drop"):
		if canPieceMoveDown():
			movePieceInGrid(0,1)
			score += 1
			$UI/Score/ScoreNumber.text = str(score)
			sthHappened = true
		actions = 0
	if Input.is_action_just_pressed("hard_drop"):
		hardDropPiece()
		afterDrop()
		sthHappened = true
		timer=0
		actions = 0
	if Input.is_action_just_pressed("rotate_right"):
		AudioManager.rotatePiece.play()
		var kickValues = getPosibleRotation(Direction.CLOCKWISE)
		if kickValues != null:
			rotatePiece(Direction.CLOCKWISE, kickValues)
			sthHappened = true
			actions += 1
	if Input.is_action_just_pressed("rotate_left"):
		AudioManager.rotatePiece.play()
		var kickValues = getPosibleRotation(Direction.ANTICLOCKWISE)
		if kickValues != null:
			rotatePiece(Direction.ANTICLOCKWISE, kickValues)
			sthHappened = true
			actions += 1
	if Input.is_action_just_pressed("hold_piece"):
		if (!hasSwapped && PlayerManager.canHoldPiece && !PlayerManager.holdPieceDebuff):
			AudioManager.drop.play()
			deletePieceFromGrid()

			# Particle
			# var particle = HoldParticle.instantiate()
			# particle.setDestination($UI/Hold.position + $UI/Hold.size/2)
			# particle.texture = currentPiece.getTextureForPiece()
			# add_child(particle)
			# particle.emit(Vector2(spriteSize*(currentPiece.positionInGrid.x + currentPiece.getShapeWithoutBorders().size()/2.0) + gridOffsetX ,spriteSize*(currentPiece.positionInGrid.y++ currentPiece.getShapeWithoutBorders()[0].size()/2.0) + gridOffsetY ))

			var heldPiece = $UI/Hold.swapPiece(currentPiece)
			if heldPiece:
				currentPiece = heldPiece
				spawnPiece()
			else:
				spawnFromBag()

			sthHappened = true
			hasSwapped = true
			actions = 0
	timer += delta
	if timer >= speed:
		if canPieceMoveDown():
			movePieceInGrid(0,1)
			actions=0
			sthHappened = true
		else:
			if $LockTimer.time_left == 0:
				$LockTimer.start()
		timer=0

	if (sthHappened):
		drawGrid()
		drawDroppingPoint()

func _on_LockTimer_timeout():
	if (actions > infinityValue) || (prevActions == actions):
		if !canPieceMoveDown():
			afterDrop()
			drawGrid()
			drawDroppingPoint()
	else:
		$LockTimer.start()
		prevActions = actions

func afterDrop():
	AudioManager.drop.play()
	hardDropShake()
	lastPiece = currentPiece;
	currentPiece = Piece.new()
	# Check for T-spin before clearing lines
	var tSpinType = checkTSpin()
	checkAndClearFullLines(tSpinType)
	if (checkGameOver()):
		grid_gameover.emit()
		gameover()
	spawnFromBag()
	hasSwapped = false
	pieceDropped.emit()

func checkTSpin():
	if lastPiece.getShapeName() != "T" or lastPiece.rotationState == 0:
		return null

	var cornersFilled = 0
	var frontCornersFilled = 0
	var x = lastPiece.positionInGrid.x
	var y = lastPiece.positionInGrid.y

	# Check all four corners
	if x > 0 and y > 0 and grid[x-1][y-1] != 0: cornersFilled += 1
	if x > 0 and y+2 < gridHeight and grid[x-1][y+2] != 0: cornersFilled += 1
	if x+2 < gridWidth and y > 0 and grid[x+2][y-1] != 0: cornersFilled += 1
	if x+2 < gridWidth and y+2 < gridHeight and grid[x+2][y+2] != 0: cornersFilled += 1

	# Check front corners based on rotation state
	match lastPiece.rotationState:
		1: # Right
			if x > 0 and y > 0 and grid[x-1][y-1] != 0: frontCornersFilled += 1
			if x > 0 and y+2 < gridHeight and grid[x-1][y+2] != 0: frontCornersFilled += 1
		2: # Down
			if x > 0 and y+2 < gridHeight and grid[x-1][y+2] != 0: frontCornersFilled += 1
			if x+2 < gridWidth and y+2 < gridHeight and grid[x+2][y+2] != 0: frontCornersFilled += 1
		3: # Left
			if x+2 < gridWidth and y > 0 and grid[x+2][y-1] != 0: frontCornersFilled += 1
			if x+2 < gridWidth and y+2 < gridHeight and grid[x+2][y+2] != 0: frontCornersFilled += 1

	if cornersFilled >= 3:
		return "Full" if frontCornersFilled == 2 else "Mini"
	return null

func gameover():
	set_physics_process(false)

func drawDroppingPoint():
	for ghost in _ghost_sprites:
		ghost.visible = false

	deletePieceFromGrid()
	var droppingY = currentPiece.positionInGrid.y
	var foundDroppingLine = false

	while (!foundDroppingLine):
		for i in range(0,currentPiece.shape.size()):
			for j in range(currentPiece.shape[0].size()-1,-1,-1):
				if currentPiece.shape[i][j] != 0:
					if droppingY + j +1>=gridHeight:
						foundDroppingLine = true
						droppingY-=1
						break
					if (grid[currentPiece.positionInGrid.x + i][droppingY + j + 1] != 0):
						foundDroppingLine = true
						droppingY-=1
						break
		droppingY+=1
	addPiece()

	if droppingY >= vanishZone:
		var ghostIdx = 0
		for x in currentPiece.shape.size():
			for y in currentPiece.shape[0].size():
				if currentPiece.shape[x][y] != 0 and grid[currentPiece.positionInGrid.x + x][droppingY + y] == 0:
					var ghost = _ghost_sprites[ghostIdx]
					ghost.position = Vector2(currentPiece.positionInGrid.x*spriteSize + x*spriteSize + gridOffsetX, droppingY*spriteSize+y*spriteSize + gridOffsetY)
					ghost.texture = Textures.getTextureForColorIndex(currentPiece.shape[x][y])
					var c = Textures.getElementalColor(currentPiece.shape[x][y])
					ghost.self_modulate = Color(c.r, c.g, c.b, 0.4)
					ghost.visible = true
					ghostIdx += 1

func hardDropPiece():
	while (canPieceMoveDown()):
		score += 2
		$UI/Score/ScoreNumber.text = str(score)
		movePieceInGrid(0,1)
	var particle = DropParticle.instantiate()
	particle.position.x = gridOffsetX + ((currentPiece.positionInGrid.x + currentPiece.shape.size()/float(2)))* spriteSize
	var pixelPosy = (currentPiece.positionInGrid.y+1)* spriteSize
	particle.position.y = (pixelPosy)/2 + gridOffsetY
	particle.setBoxRanges(Vector2(currentPiece.shape.size()/float(2)* spriteSize, pixelPosy/2 -spriteSize))
	particle.amount = pixelPosy/20
	match currentPiece.getColorIndex():
		1: particle.setColor(Color.RED)
		2: particle.setColor(Color.BLUE)
		3: particle.setColor(Color.YELLOW)
		4: particle.setColor(Color.CYAN)
		5: particle.setColor(Color.GREEN)
		6: particle.setColor(Color.FUCHSIA)
		7: particle.setColor(Color.ORANGE)
	add_child(particle)
	particle.emit()

func checkGameOver():
	for i in range (gridWidth):
		if grid[i][vanishZone-1] != 0:
			return true
	return false

func printClearedBlockTypes(y):
	var fire = 0
	var poison = 0
	var gold = 0
	var orb = 0
	for x in range(gridWidth):
		match (grid[x][y] / Constants.ELEMENTAL_MUL):
			Constants.Elemental.FIRE: fire += 1
			Constants.Elemental.POISON: poison += 1
			Constants.Elemental.GOLD: gold += 1
			Constants.Elemental.ORB: orb += 1
	if fire > 0:
		PlayerManager.pendingElementalBonus += fire * 15
	if poison > 0:
		PlayerManager.pendingElementalBonus += poison * 8
	if gold > 0:
		PlayerManager.pendingGoldCoins += gold
	if orb > 0:
		var before = PlayerManager.magicMeter
		PlayerManager.magicMeter = mini(before + orb, PlayerManager.maxMagicMeter)
		magicMeterChanged.emit()
		# Orbs collected past the cap are wasted and burn the player instead of
		# being stored. Main turns the count into HP damage (see energyOverflow).
		var overflow = before + orb - PlayerManager.maxMagicMeter
		if overflow > 0:
			energyOverflow.emit(overflow)

func checkAndClearFullLines(tSpinType = null):
	var cleared = 0
	for y in range(gridHeight):
		var fullLine = true
		for x in range(gridWidth):
			if grid[x][y] == 0:
				fullLine = false
				break;
		if fullLine:
			cleared+=1
			printClearedBlockTypes(y)
			#Clear line
			for x in range(gridWidth):
				grid[x][y] = 0
			#Move everything down
			for j in range(y,0,-1):
				for i in range(gridWidth):
					if (grid[i][j] == 0) && (grid[i][j-1] != 0):
						grid[i][j] = grid[i][j-1]
						grid[i][j-1] = 0
			#Draw clear particle
			var particle = ClearParticle.instantiate()
			particle.position.x = gridOffsetX + spriteSize*gridWidth/2.0
			var pixelPosy = (y)* spriteSize
			particle.position.y = (pixelPosy) + gridOffsetY
			particle.setBoxRange(spriteSize*gridWidth/2.0)
			add_child(particle)
			particle.emit()
	#Scoring
	if cleared != 0:
		hasCleared = true
		combo += 1
		var newScore
		if tSpinType:
			print("T-Spin detected: " + tSpinType)
		match (cleared):
			1: newScore=100*level
			2: newScore=300*level
			3: newScore=500*level
			4: newScore=800*level
		#if lastPiece.getShapeName() == "T" && lastPiece.rotationState != 0: #Detect T spin (Can be optimized)
			#print("T SPIN!!!" + str(lastPiece.rotationState))
		score += newScore
		lines += cleared
		# $UI/Score/ScoreNumber.text = str(score)
		# $UI/Lines/LinesNumber.text = str(lines)
		clearedLines += cleared
		# if (clearedLines >= 10):
		# 	clearedLines = clearedLines-10
			# level+=1
			# speed = pow(0.8-(level-1)*0.007,level-1)
			# $UI/Level/LevelNumber.text = str(level)
		clearLines.emit(cleared, combo)
	else:
		hasCleared = false
		combo = 0

func movePieceInGrid(xMovement, yMovement):
	deletePieceFromGrid()
	#Write new position
	for x in range(0,currentPiece.shape.size()):
		for y in range(0,currentPiece.shape[0].size()):
			if currentPiece.shape[x][y] != 0:
				grid[x+xMovement+currentPiece.positionInGrid.x][y+yMovement+currentPiece.positionInGrid.y] = currentPiece.shape[x][y]
	currentPiece.positionInGrid.x = currentPiece.positionInGrid.x+xMovement
	currentPiece.positionInGrid.y = currentPiece.positionInGrid.y+yMovement

func spawnFromBag():
	if (!currentBag):
		currentBag = nextBag.duplicate()
		nextBag = newBag()
	currentPiece = currentBag.pop_front()
	pieceCount += 1
	if pieceCount % 3 == 0:
		currentPiece.assignOrb()
	elif PlayerManager.nextPiecePoison:
		currentPiece.assignAllElemental(3)
		PlayerManager.nextPiecePoison = false
	spawnPiece()
	$UI/NextPieces.drawPieces(currentBag, nextBag)

func spawnPiece():
	var spawnIn = 1
	var startingX = (gridWidth - currentPiece.shape[0].size())/2
	for i in range(currentPiece.shape.size()):
		if currentPiece.shape[i][2] != 0 && grid[startingX + i][3] != 0:
			spawnIn = 0
			break;
	currentPiece.positionInGrid = Vector2((gridWidth - currentPiece.shape[0].size())/2, spawnIn)
	currentPiece.rotationState = 0
	addPiece()
	# print("Check shape" + str(currentPiece.getShapeName()))

func canPieceMoveDown():
	for i in range(0,currentPiece.shape.size()):
		for j in range(currentPiece.shape[0].size()-1,-1,-1):
			if currentPiece.shape[i][j] != 0:
				if currentPiece.positionInGrid.y + j + 1 >= gridHeight:
					return false
				if grid[currentPiece.positionInGrid.x + i][currentPiece.positionInGrid.y + j + 1] != 0:
					return false
				else: break
	return true

func canPieceMoveRight():
	for j in currentPiece.shape[0].size():
		for i in range (currentPiece.shape.size()-1,-1,-1):
			if currentPiece.shape[i][j] != 0:
				if currentPiece.positionInGrid.x + i + 1 >= gridWidth:
					return false
				if grid[currentPiece.positionInGrid.x + i +1][currentPiece.positionInGrid.y + j] != 0:
					return false
				else: break
	return true

func canPieceMoveLeft():
	for j in currentPiece.shape[0].size():
		for i in currentPiece.shape.size():
			if currentPiece.shape[i][j] != 0:
				if currentPiece.positionInGrid.x + i <= 0:
					return false
				if grid[currentPiece.positionInGrid.x + i -1][currentPiece.positionInGrid.y + j] != 0:
					return false
				else: break
	return true

func rotatePiece(direction, kickValues: Vector2):
	deletePieceFromGrid()
	var newShape = MatrixOperations.invert2DMatrix(currentPiece.shape)
	if (direction == Direction.CLOCKWISE):
		newShape = MatrixOperations.swap2DMatrixColumns(newShape)
		currentPiece.rotationState = (currentPiece.rotationState+1)%4
	else:
		newShape = MatrixOperations.swap2DMatrixRows(newShape)
		currentPiece.rotationState = (currentPiece.rotationState+3)%4 # +3 mod 4 goes to the left (0 1<--(2) 3)
	currentPiece.shape = newShape
	currentPiece.positionInGrid += kickValues
	addPiece()

func getPosibleRotation(direction):
	var newShape = MatrixOperations.invert2DMatrix(currentPiece.shape)
	if (direction == Direction.CLOCKWISE):
		newShape = MatrixOperations.swap2DMatrixColumns(newShape)
	else:
		newShape = MatrixOperations.swap2DMatrixRows(newShape)

	var rotationState = currentPiece.rotationState
	# rotation state for 0>>1 is the same as 1>>0 but negative,
	# so if anticlowise we go to the next state (0 to 1) by adding 3 and modding by 4
	if (direction == Direction.ANTICLOCKWISE):
		rotationState = (rotationState+3)%4

	var rotationArray
	if (currentPiece.shape.size() == 4): #Check for I and O shapes
		rotationArray = Constants.KICK_TABLE_I[rotationState]
	else:
		rotationArray = Constants.KICK_TABLE[rotationState]

	for r in rotationArray.size():
		var kickValues = rotationArray[r]
		if (direction == Direction.ANTICLOCKWISE):
			kickValues = -kickValues
		var newPosition = currentPiece.positionInGrid + kickValues
		var canRotate = true
		deletePieceFromGrid()
		for i in newShape.size():
			for j in newShape[i].size():
				if (newShape[i][j]) != 0:
					#Check borders
					if (newPosition.x + i < 0) || (newPosition.x + i >= gridWidth):
						addPiece()
						canRotate = false
						break
					if (newPosition.y + j + 1 > gridHeight):
						addPiece()
						canRotate = false
						break
					if (grid[newPosition.x + i][newPosition.y + j] != 0):
						addPiece()
						canRotate = false
						break
		addPiece()
		if canRotate:
			return kickValues
	return null

func deletePieceFromGrid():
	#Delete old position
	for x in currentPiece.shape.size():
		for y in currentPiece.shape[0].size():
			if currentPiece.shape[x][y] != 0:
				grid[x+currentPiece.positionInGrid.x][y+currentPiece.positionInGrid.y] = 0

func addGarbageRows(count):
	deletePieceFromGrid()
	for _i in range(count):
		for y in range(0, gridHeight - 1):
			for x in range(gridWidth):
				grid[x][y] = grid[x][y + 1]
		var hole = randi() % gridWidth
		for x in range(gridWidth):
			grid[x][gridHeight - 1] = 0 if x == hole else Constants.GARBAGE
	var isGameOver = checkGameOver()
	addPiece()
	drawGrid()
	drawDroppingPoint()
	if isGameOver:
		grid_gameover.emit()
		gameover()

func clearBottomRows(count: int):
	deletePieceFromGrid()
	var cleared = 0
	for i in range(count):
		var y = gridHeight - 1
		printClearedBlockTypes(y)
		for x in range(gridWidth):
			grid[x][y] = 0
		for j in range(y, 0, -1):
			for x in range(gridWidth):
				if grid[x][j] == 0 and grid[x][j-1] != 0:
					grid[x][j] = grid[x][j-1]
					grid[x][j-1] = 0
		cleared += 1
		var particle = ClearParticle.instantiate()
		particle.position.x = gridOffsetX + spriteSize * gridWidth / 2.0
		particle.position.y = y * spriteSize + gridOffsetY
		particle.setBoxRange(spriteSize * gridWidth / 2.0)
		add_child(particle)
		particle.emit()
	addPiece()
	combo += 1
	clearLines.emit(cleared, combo)
	drawGrid()
	drawDroppingPoint()

func hardDropShake():
	var tween = create_tween()
	tween.finished.connect(func():
		position = Vector2(0, 0)
	)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "position:y", 2, 0.1)

func purifyGarbage():
	deletePieceFromGrid()
	for x in range(gridWidth):
		for y in range(gridHeight):
			if grid[x][y] == Constants.GARBAGE:
				grid[x][y] = 1
	addPiece()
	drawGrid()
	drawDroppingPoint()

func shuffleBottomRows(count: int):
	deletePieceFromGrid()
	var startY = gridHeight - count
	var flat = []
	for y in range(startY, gridHeight):
		for x in range(gridWidth):
			flat.append(grid[x][y])
	flat.shuffle()
	var idx = 0
	for y in range(startY, gridHeight):
		for x in range(gridWidth):
			grid[x][y] = flat[idx]
			idx += 1
	addPiece()
	drawGrid()
	drawDroppingPoint()

# Rows in the playable area holding at least one block. Abilities that scale off
# board danger (damage_per_row) read this, so the falling piece is lifted out
# first — a piece in flight is not board state yet.
func occupiedRowCount() -> int:
	deletePieceFromGrid()
	var count = 0
	for y in range(vanishZone, gridHeight):
		for x in range(gridWidth):
			if grid[x][y] != 0:
				count += 1
				break
	addPiece()
	return count

# Recolour every block of the falling piece to one elemental type (see
# Constants.Elemental). The piece is already stamped into `grid`, so it has to be
# lifted out, retyped and re-stamped for the change to show.
func enchantCurrentPiece(elemental: int):
	if currentPiece == null:
		return
	deletePieceFromGrid()
	currentPiece.assignAllElemental(elemental)
	addPiece()
	drawGrid()
	drawDroppingPoint()

func holyBeam():
	deletePieceFromGrid()
	var bestRow = -1
	var bestCount = 0
	for y in range(vanishZone, gridHeight):
		var count = 0
		for x in range(gridWidth):
			if grid[x][y] != 0:
				count += 1
		if count > bestCount:
			bestCount = count
			bestRow = y
	if bestRow == -1 or bestCount == 0:
		addPiece()
		return
	for x in range(gridWidth):
		grid[x][bestRow] = 0
	for j in range(bestRow, 0, -1):
		for x in range(gridWidth):
			if grid[x][j] == 0 and grid[x][j-1] != 0:
				grid[x][j] = grid[x][j-1]
				grid[x][j-1] = 0
	var particle = ClearParticle.instantiate()
	particle.position.x = gridOffsetX + spriteSize * gridWidth / 2.0
	particle.position.y = bestRow * spriteSize + gridOffsetY
	particle.setBoxRange(spriteSize * gridWidth / 2.0)
	add_child(particle)
	particle.emit()
	addPiece()
	drawGrid()
	drawDroppingPoint()

# Global gravity: every block falls straight down until it rests on the stack,
# closing every hole. Unlike a line clear this moves blocks *within* a column, so
# a swiss-cheese board becomes a dense one, and any row completed on the way down
# clears through checkAndClearFullLines — normal damage, combo and elementals.
#
# One pass is always enough. Afterwards no column holds a hole, so clearing rows
# only shifts solid mass down and can never expose a new gap or complete a new
# row: there is no cascade to loop over.
func compactBoard():
	# The falling piece is not board state yet, so it must neither plug a column
	# nor help complete a row. Lifted out here, stamped back at the end.
	deletePieceFromGrid()
	for x in range(gridWidth):
		var stack = []
		for y in range(gridHeight):
			if grid[x][y] != 0:
				stack.append(grid[x][y])
		var writeY = gridHeight - 1
		for i in range(stack.size() - 1, -1, -1):
			grid[x][writeY] = stack[i]
			writeY -= 1
		while writeY >= 0:
			grid[x][writeY] = 0
			writeY -= 1
	# Only clear when a row actually completed: checkAndClearFullLines zeroes
	# `combo` when it clears nothing, and casting this must not silently break a
	# combo the player is holding.
	if _hasFullRow():
		checkAndClearFullLines()
	_liftPieceClearOfStack()
	addPiece()
	drawGrid()
	drawDroppingPoint()

func _hasFullRow() -> bool:
	for y in range(gridHeight):
		var full = true
		for x in range(gridWidth):
			if grid[x][y] == 0:
				full = false
				break
		if full:
			return true
	return false

# Compaction drops settled blocks downward, which can land them on cells the
# falling piece occupies (a piece sitting under an overhang). Stamping the piece
# back over them would silently eat those blocks, so walk it up to clear air
# first. Bounded by the top of the grid.
func _liftPieceClearOfStack():
	if currentPiece == null:
		return
	while currentPiece.positionInGrid.y > 0 and _pieceOverlapsStack():
		currentPiece.positionInGrid.y -= 1

func _pieceOverlapsStack() -> bool:
	for x in range(currentPiece.shape.size()):
		for y in range(currentPiece.shape[0].size()):
			if currentPiece.shape[x][y] == 0:
				continue
			var gx = int(currentPiece.positionInGrid.x) + x
			var gy = int(currentPiece.positionInGrid.y) + y
			if gx < 0 or gx >= gridWidth or gy < 0 or gy >= gridHeight:
				continue
			if grid[gx][gy] != 0:
				return true
	return false

# Garbage blocks sitting on the board. Abilities that turn the enemy's own
# pressure into damage (damage_per_garbage) price themselves off this. No need to
# lift the falling piece out the way occupiedRowCount does — a piece is never
# made of garbage, so it cannot inflate the count.
func garbageBlockCount() -> int:
	var count = 0
	for x in range(gridWidth):
		for y in range(gridHeight):
			if grid[x][y] == Constants.GARBAGE:
				count += 1
	return count

# Push a specific tetromino (an index into Constants.SHAPES) to the front of the
# queue, so it is the very next piece to spawn. Elementals are rolled the usual
# way, so once it lands a queued piece is no different from a bag piece.
func queuePiece(shapeIndex: int):
	if shapeIndex < 0 or shapeIndex >= Constants.SHAPES.size():
		return
	var piece = Piece.new()
	piece.shape = Constants.SHAPES[shapeIndex].duplicate(true)
	piece.assignRandomElemental()
	if currentBag == null:
		currentBag = []
	currentBag.push_front(piece)
	$UI/NextPieces.drawPieces(currentBag, nextBag)
