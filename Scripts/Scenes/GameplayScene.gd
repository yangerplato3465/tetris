extends Control

# Set false to hide the dev tools overlay (see _buildDevPanel).
const DEV_MODE := true

const FLOW_CONTROLLER = preload("res://Scripts/Scenes/FlowController.gd")

@onready var CharacterSelectScene = $CharacterSelectScene
@onready var characterOptionPrefab = preload("res://Scene/Component/characterOption.tscn")
@onready var characterOptionContainer = $CharacterSelectScene/CharacterOptionContainer

@onready var PrepareScene = $PrepareScene
@onready var EventScene = $EventScene
@onready var MainScene = $Main
@onready var GameoverPanel = $GameoverPanel
@onready var ShopPanel = $ShopPanel
@onready var AbilityDraftScene = $AbilityDraftScene
@onready var grid = $Main/Grid

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
	PrepareScene.optionSelected.connect(onFloorOptionSelected)
	# Main.victory() already stepped the level, so the post-reward draft goes
	# straight to the next floor; event/shop spend the floor themselves.
	AbilityDraftScene.draftFinished.connect(showFloorOptions)
	EventScene.eventFinished.connect(advanceFloor)
	ShopPanel.shopFinished.connect(advanceFloor)
	# A bought spell pops up the equip screen; Continue returns to the shop
	# without regenerating, so the remaining stock is kept.
	ShopPanel.spellPurchased.connect(func(ability):
		flow.goto(AbilityDraftScene, AbilityDraftScene.generateEquip.bind(ability.id)))
	AbilityDraftScene.equipFinished.connect(func(): flow.goto(ShopPanel))

# A card on the floor choice screen was taken: run its encounter.
func onFloorOptionSelected(option):
	match option.type:
		"event":
			flow.goto(EventScene, EventScene.showEvent.bind(Events.pool.pick_random()))
		"shop":
			flow.goto(ShopPanel, ShopPanel.generateItems)
		_:
			PlayerManager.currentEnemy = option.enemy
			flow.goto(MainScene, _prepBattle.bind(option.enemy), _startBattle)

func showFloorOptions():
	# unlockCards as onArrive: the cards only become clickable once the panel has
	# landed, matching how _startBattle waits for Main to land below.
	flow.goto(PrepareScene, PrepareScene.generateFloor, PrepareScene.unlockCards)

# Taking a shop or event costs the floor just like winning a fight does.
func advanceFloor():
	PlayerManager.currentLevel += 1
	if PlayerManager.currentLevel > PrepareScene.FLOOR_COUNT:
		GameoverPanel.setStats(true)
		flow.overlay(GameoverPanel)
	else:
		showFloorOptions()

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
	_addDevButton(buttons, "Show Floor Options", _devShowFloor)
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

func _devShowFloor():
	# jump() has no onArrive and lands instantly, so arm the cards here — without
	# this the dev button would open a floor screen nothing could be clicked on.
	if flow.jump(PrepareScene, PrepareScene.generateFloor):
		PrepareScene.unlockCards()

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
		PlayerManager.selectCharacter(character.id)
		Utilities.onPressed(node)
		showFloorOptions()

func disableCharacterOptions():
	for child in characterOptionContainer.get_children():
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE

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
