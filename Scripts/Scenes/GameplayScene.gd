extends Control

# Set false to hide the dev tools overlay (see _buildDevPanel).
const DEV_MODE := true

const FLOW_CONTROLLER = preload("res://Scripts/Scenes/FlowController.gd")

@onready var CharacterSelectScene = $CharacterSelectScene
@onready var characterOptionPrefab = preload("res://Scene/Component/characterOption.tscn")
@onready var characterOptionContainer = $CharacterSelectScene/CharacterOptionContainer

@onready var PrepareScene = $PrepareScene
@onready var MapScene = $MapScene
@onready var EventScene = $EventScene
@onready var MainScene = $Main
@onready var GameoverPanel = $GameoverPanel
@onready var ShopPanel = $ShopPanel
@onready var AbilityDraftScene = $AbilityDraftScene
@onready var grid = $Main/Grid

@onready var enemyOptionPrefab = preload("res://Scene/Component/enemyOption.tscn")
@onready var enemyOptionContainer = $PrepareScene/EnemyOptionContainer
@onready var levelText = $PrepareScene/LevelNumber

@onready var gameoverClose = $GameoverPanel/NinePatchRect/Close

var flow # FlowController: owns panel transitions and the current-panel state

func _ready():
	PlayerManager.reset() # Reset all upgrades and stats
	grid.stopGrid()
	generateCharacterOptions()
	Utilities.makeJuicy(gameoverClose)
	flow = FLOW_CONTROLLER.new()
	flow.name = "FlowController"
	add_child(flow)
	flow.current = CharacterSelectScene
	_connectFlow()
	if DEV_MODE:
		_buildDevPanel()

# --- Flow routes -----------------------------------------------------------
# Every "this panel is done" signal is wired here, so the run's whole flow
# reads top-to-bottom in one place. Routes that branch get a named handler.
func _connectFlow():
	MainScene.stage_victory.connect(victory)
	MainScene.stage_gameover.connect(showGameoverPanel)
	MapScene.nodeSelected.connect(onMapNodeSelected)
	AbilityDraftScene.draftFinished.connect(func(): flow.goto(MapScene, MapScene.reopen))
	EventScene.eventFinished.connect(func(): flow.goto(MapScene, MapScene.reopen))
	ShopPanel.shopFinished.connect(func(): flow.goto(MapScene, MapScene.reopen))
	# A bought spell pops up the equip screen; Continue returns to the shop
	# without regenerating, so the remaining stock is kept.
	ShopPanel.spellPurchased.connect(func(ability):
		flow.goto(AbilityDraftScene, AbilityDraftScene.generateEquip.bind(ability.id)))
	AbilityDraftScene.equipFinished.connect(func(): flow.goto(ShopPanel))

# A reachable map node was clicked: start its encounter.
func onMapNodeSelected(node):
	if node.type == "event":
		flow.goto(EventScene, EventScene.showEvent.bind(Events.pool.pick_random()))
		return
	if node.type == "shop":
		flow.goto(ShopPanel, ShopPanel.generateItems)
		return
	# Battles may be skipped by event/shop nodes, so sync the level to the map
	# column here instead of relying on the per-victory increment alone.
	PlayerManager.currentLevel = node.col
	PlayerManager.currentEnemy = node.enemy
	flow.goto(MainScene, _prepBattle.bind(node.enemy), _startBattle)

# Battle prep runs while Main is still offscreen; stageReady only fires once
# the panel has landed so gameplay never starts mid-transition.
func _prepBattle(enemy):
	MainScene.setStage(enemy)
	grid.setStage(enemy)
	grid.resetGrid()

func _startBattle():
	MainScene.stageReady()
	grid.stageReady()

func victory():
	if PlayerManager.currentLevel > 15:
		GameoverPanel.setStats(true)
		flow.overlay(GameoverPanel)
	else:
		flow.goto(AbilityDraftScene, AbilityDraftScene.generateDraft)

func showGameoverPanel():
	GameoverPanel.setStats()
	flow.overlay(GameoverPanel)

# --- Dev tools -------------------------------------------------------------
# A code-built overlay (CanvasLayer so it sits above every panel) with buttons
# to jump straight to features for testing. Add more buttons here as needed.
func _buildDevPanel():
	var layer = CanvasLayer.new()
	layer.layer = 100
	layer.name = "DevPanel"
	add_child(layer)

	var vbox = VBoxContainer.new()
	vbox.position = Vector2(12, 12)
	layer.add_child(vbox)

	# Clicking the header collapses/expands the buttons below it.
	var header = Button.new()
	header.text = "— DEV —"
	header.flat = true
	header.focus_mode = Control.FOCUS_NONE
	vbox.add_child(header)

	var buttons = VBoxContainer.new()
	vbox.add_child(buttons)
	header.pressed.connect(func(): buttons.visible = not buttons.visible)

	_addDevButton(buttons, "Open Ability Draft", _devOpenDraft)
	_addDevButton(buttons, "Open Shop", _devOpenShop)
	_addDevButton(buttons, "Show Map", _devShowMap)
	_addDevButton(buttons, "Show Event", _devShowEvent)
	_addDevButton(buttons, "Win Battle", _devWinBattle)
	_addDevButton(buttons, "Fill Magic", _devFillMagic)
	_addDevButton(buttons, "Full Heal", _devFullHeal)
	_addDevButton(buttons, "+100 Coins", _devAddCoins)
	_addDevButton(buttons, "Add Garbage Row", _devAddGarbage)

func _addDevButton(parent: Node, text: String, callback: Callable):
	var btn = Button.new()
	btn.text = text
	btn.focus_mode = Control.FOCUS_NONE # don't steal keyboard focus from gameplay
	btn.pressed.connect(callback)
	parent.add_child(btn)

func _devOpenDraft():
	flow.jump(AbilityDraftScene, AbilityDraftScene.generateDraft)

func _devOpenShop():
	flow.jump(ShopPanel, ShopPanel.generateItems)

func _devShowMap():
	if MapScene.columns.is_empty():
		MapScene.generateMap()
	flow.jump(MapScene, MapScene.reopen)

func _devShowEvent():
	flow.jump(EventScene, EventScene.showEvent)

func _devWinBattle():
	MainScene.devKillEnemy()

func _devFillMagic():
	PlayerManager.magicMeter = PlayerManager.maxMagicMeter
	MainScene.updateMagicMeterUI()

func _devFullHeal():
	PlayerManager.playerHealth = PlayerManager.maxPlayerHealth
	PlayerManager.shieldNum = 0
	MainScene.updateUI()

func _devAddCoins():
	PlayerManager.coin += 100

func _devAddGarbage():
	if MainScene.battleActive:
		grid.addGarbageRows(1)

# --- Character select ------------------------------------------------------

func generateCharacterOptions():
	for child in characterOptionContainer.get_children():
		child.queue_free()
	for character in Consts.characters:
		setCharacterOption(character)

func setCharacterOption(character):
	var newOption = characterOptionPrefab.instantiate()
	newOption.find_child("Name").text = character.name
	newOption.find_child("Icon").frame = character.frame
	newOption.find_child("Description").text = PlayerManager.getCharacterDescription(character.id)
	newOption.pivot_offset = Vector2(110, 155)
	Utilities.makeJuicy(newOption)
	newOption.gui_input.connect(onCharacterPressed.bind(character, newOption))
	characterOptionContainer.add_child(newOption)

func onCharacterPressed(event: InputEvent, character, node: Control):
	if event.is_pressed():
		disableCharacterOptions()
		PlayerManager.characterClass = character.id
		Utilities.onPressed(node)
		flow.goto(MapScene, MapScene.generateMap)

func disableCharacterOptions():
	for child in characterOptionContainer.get_children():
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE

# --- Legacy prepare flow (replaced by the run map, kept for reference) ------

func generateRandomEnemies():
	levelText.text = "level %d" % PlayerManager.currentLevel
	for option in enemyOptionContainer.get_children():
		option.queue_free()
	match PlayerManager.currentLevel:
		1, 2:
			for index in Utilities.chooseRandom(Consts.tier1Enemy.size(), 3):
				setOptions(Consts.tier1Enemy[index])
		3:
			setOptions(Consts.BossEnemy[0])
		4, 5:
			for index in Utilities.chooseRandom(Consts.tier2Enemy.size(), 3):
				setOptions(Consts.tier2Enemy[index])
		6:
			setOptions(Consts.BossEnemy[1])
		7, 8:
			for index in Utilities.chooseRandom(Consts.tier2Enemy.size(), 3):
				setOptions(Consts.tier3Enemy[index])
		9:
			setOptions(Consts.BossEnemy[2])
		10, 11:
			for index in Utilities.chooseRandom(Consts.tier3Enemy.size(), 3):
				setOptions(Consts.tier3Enemy[index])
		12:
			setOptions(Consts.BossEnemy[3])
		13, 14:
			for index in Utilities.chooseRandom(Consts.tier3Enemy.size(), 3):
				setOptions(Consts.tier3Enemy[index])
		15:
			setOptions(Consts.BossEnemy[4])

func setOptions(enemy):
	var newOption = enemyOptionPrefab.instantiate()
	newOption.find_child("Name").text = enemy.name
	newOption.find_child("Icon").frame = enemy.frame
	var descriptionText = "health: %s\nreward: %s\n%s" % [str(enemy.health), str(enemy.reward), enemy.description]
	newOption.find_child("Description").text = descriptionText

	newOption.pivot_offset = Vector2(184, 300)
	Utilities.makeJuicy(newOption)
	newOption.gui_input.connect(onPressed.bind(enemy, newOption))

	enemyOptionContainer.add_child(newOption)

func onPressed(event: InputEvent, enemy, node: Control):
	if(event.is_pressed()):
		disableOthers()
		PlayerManager.currentEnemy = enemy
		Utilities.onPressed(node)
		flow.goto(MainScene, _prepBattle.bind(enemy), _startBattle)

func disableOthers():
	for child in enemyOptionContainer.get_children():
		child.gui_input.disconnect(onPressed)

# --- Game over / exit ------------------------------------------------------

func _on_close_pressed():
	$AnimationPlayer.play("FadeOut")
	gameoverClose.disabled = true
	Utilities.onPressed(gameoverClose)

func _on_animation_player_animation_finished(anim_name):
	if(anim_name == "FadeOut"):
		backToMenu()

func backToMenu():
	get_tree().change_scene_to_file("res://Scene/Menu.tscn")
