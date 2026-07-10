extends Control

# Prototype run map (Cobalt Core / Slay the Spire style): columns of nodes
# flowing left to right with branching, non-crossing paths. Column 0 is the
# start marker; columns 1..15 correspond to the 15 run levels, with bosses on
# their usual levels (3/6/9/12/15) as single mandatory nodes.
#
# Node types: enemy encounters, bosses, and "?" event nodes (randomly
# sprinkled outside the opening column and boss columns). Other types
# (shop, rest, ...) can later be added the same way in _assignEncounters.

signal nodeSelected(node)

const LEVELS = 15
const MAX_ROWS = 4
const BOSS_LEVELS = [15]
const EVENT_CHANCE = 0.25   # roll per eligible node
const FIRST_EVENT_LEVEL = 2 # level 1 is always a fight

const LEFT_X = 60.0
const COLUMN_SPACING = 72.0
const TOP_Y = 240.0
const ROW_SPACING = 90.0

const NODE_SIZE = 46.0
const BOSS_NODE_SIZE = 62.0

const MONSTER_SHEET = preload("res://Sprite/Character/monsters.png")
const FONT = preload("res://Font/ThaleahFat/ThaleahFat.ttf")

class MapNode:
	var col: int
	var row: int
	var type: String # "start" | "enemy" | "boss" | "event"
	var enemy: Dictionary
	var next: Array = [] # MapNodes in the following column
	var visited := false
	var button: Button

var columns = [] # Array of columns, each an Array[MapNode]
var currentNode: MapNode = null
var locked := false # blocks input while a battle transition is underway

func _ready():
	_buildTitle()

func _buildTitle():
	var title = Label.new()
	title.text = "Choose your path"
	var settings = LabelSettings.new()
	settings.font = FONT
	settings.font_size = 64
	title.label_settings = settings
	title.anchors_preset = Control.PRESET_TOP_WIDE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.offset_top = 40
	title.offset_bottom = 120
	add_child(title)

# --- Generation ---

func generateMap():
	for colArr in columns:
		for node in colArr:
			node.button.queue_free()
	columns = []

	# Start marker column, then one column per level.
	columns.append([_makeNode(0, MAX_ROWS / 2, "start")])
	for level in range(1, LEVELS + 1):
		var colArr = []
		if level in BOSS_LEVELS:
			colArr.append(_makeNode(level, MAX_ROWS / 2, "boss"))
		else:
			var rows = Utilities.chooseRandom(MAX_ROWS, randi_range(2, 3))
			rows.sort()
			for row in rows:
				colArr.append(_makeNode(level, row, "enemy"))
		columns.append(colArr)

	for col in columns.size() - 1:
		_connectColumns(columns[col], columns[col + 1])
	_assignEncounters()
	for colArr in columns:
		for node in colArr:
			_buildNodeButton(node)

	currentNode = columns[0][0]
	currentNode.visited = true
	locked = false
	refreshMap()

func _makeNode(col: int, row: int, type: String) -> MapNode:
	var node = MapNode.new()
	node.col = col
	node.row = row
	node.type = type
	return node

# Connect two adjacent columns with a monotonic "staircase" walk so every
# node gets at least one edge in and out, and edges never cross.
func _connectColumns(colA: Array, colB: Array):
	var i = 0
	var j = 0
	colA[i].next.append(colB[j])
	while i < colA.size() - 1 or j < colB.size() - 1:
		var canI = i < colA.size() - 1
		var canJ = j < colB.size() - 1
		var step = randi_range(0, 2)
		if step == 2 and canI and canJ:
			i += 1
			j += 1
		elif step == 0 and canI:
			i += 1
		elif canJ:
			j += 1
		else:
			i += 1
		colA[i].next.append(colB[j])

func _assignEncounters():
	for level in range(1, LEVELS + 1):
		var colArr = columns[level]
		if level in BOSS_LEVELS:
			colArr[0].enemy = Consts.BossEnemy[BOSS_LEVELS.find(level)]
			continue
		# Sprinkle "?" event nodes among the regular encounters.
		if level >= FIRST_EVENT_LEVEL:
			for node in colArr:
				if randf() < EVENT_CHANCE:
					node.type = "event"
		# Distinct picks so one column never offers the same enemy twice.
		var pool = _tierPool(level)
		var picks = Utilities.chooseRandom(pool.size(), colArr.size())
		for k in colArr.size():
			if colArr[k].type == "enemy":
				colArr[k].enemy = pool[picks[k]]

func _tierPool(level: int) -> Array:
	match level:
		1, 2:
			return Consts.tier1Enemy
		4, 5:
			return Consts.tier2Enemy
		_:
			return Consts.tier3Enemy

# --- Node visuals ---

func _nodeCenter(node: MapNode) -> Vector2:
	return Vector2(LEFT_X + node.col * COLUMN_SPACING, TOP_Y + node.row * ROW_SPACING)

func _buildNodeButton(node: MapNode):
	var size = BOSS_NODE_SIZE if node.type == "boss" else NODE_SIZE
	var btn = Button.new()
	btn.size = Vector2(size, size)
	btn.position = _nodeCenter(node) - Vector2(size, size) / 2
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(_onNodePressed.bind(node))
	if node.type == "start":
		btn.text = "GO"
	elif node.type == "event":
		btn.text = "?"
		btn.add_theme_font_override("font", FONT)
		btn.add_theme_font_size_override("font_size", 34)
		btn.tooltip_text = "Something awaits..."
	else:
		btn.tooltip_text = "%s\nHP: %d  ATK: %d\n%s" % [
			node.enemy.name, node.enemy.health, node.enemy.attackDamage, node.enemy.description
		]
		var icon = Sprite2D.new()
		icon.texture = MONSTER_SHEET
		icon.hframes = 7
		icon.vframes = 8
		icon.frame = node.enemy.frame
		icon.position = Vector2(size, size) / 2
		icon.scale = Vector2(1.6, 1.6) if node.type == "boss" else Vector2(1.2, 1.2)
		btn.add_child(icon)
	add_child(btn)
	node.button = btn

func refreshMap():
	for colArr in columns:
		for node in colArr:
			var btn = node.button
			if node == currentNode:
				btn.disabled = true
				btn.modulate = Color.WHITE
				btn.self_modulate = Color(1.0, 0.85, 0.4) # gold = you are here
			elif not locked and currentNode.next.has(node):
				btn.disabled = false
				btn.modulate = Color.WHITE
			elif node.visited:
				btn.disabled = true
				btn.modulate = Color(0.45, 0.45, 0.45, 0.6)
			else:
				btn.disabled = true
				btn.modulate = Color(1, 1, 1, 0.4)
	queue_redraw()

func _draw():
	for colArr in columns:
		for node in colArr:
			for next in node.next:
				var color = Color(1, 1, 1, 0.2)
				var width = 2.0
				if node.visited and next.visited:
					color = Color(1.0, 0.85, 0.4, 0.9) # traveled path
					width = 3.0
				elif node == currentNode:
					color = Color(1, 1, 1, 0.8) # available choices
					width = 3.0
				draw_dashed_line(_nodeCenter(node), _nodeCenter(next), color, width, 8.0)

# --- Interaction ---

func _onNodePressed(node: MapNode):
	if locked or not currentNode.next.has(node):
		return
	locked = true
	AudioManager.button_press.play()
	currentNode = node
	node.visited = true
	refreshMap()
	nodeSelected.emit(node)

# Called by GameplayScene before sliding the map back in after a battle.
func reopen():
	locked = false
	refreshMap()
