extends Control

# Set false to hide the dev tools overlay (see _buildDevPanel).
const DEV_MODE := true

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

func _ready():
	PlayerManager.reset() # Reset all upgrades and stats
	grid.stopGrid()
	generateCharacterOptions()
	gameoverClose.connect("mouse_entered", Utilities.scaleUp.bind(gameoverClose))
	gameoverClose.connect("mouse_exited", Utilities.scaleDown.bind(gameoverClose))
	MainScene.stage_gameover.connect(showGameoverPanel)
	MainScene.stage_victory.connect(victory)
	ShopPanel.shopFinished.connect(shopFinished)
	ShopPanel.spellPurchased.connect(onSpellPurchased)
	AbilityDraftScene.equipFinished.connect(equipFinished)
	MainScene.stage_victory.connect(AbilityDraftScene.generateDraft)
	AbilityDraftScene.draftFinished.connect(draftFinished)
	MapScene.nodeSelected.connect(onMapNodeSelected)
	EventScene.eventFinished.connect(eventFinished)
	if DEV_MODE:
		_buildDevPanel()

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
	AbilityDraftScene.generateDraft()
	AbilityDraftScene.visible = true
	AbilityDraftScene.position.y = 0

func _devOpenShop():
	ShopPanel.generateItems()
	ShopPanel.visible = true
	ShopPanel.position.y = 0

func _devShowMap():
	if MapScene.columns.is_empty():
		MapScene.generateMap()
	MapScene.reopen()
	MapScene.visible = true
	MapScene.position.y = 0

func _devShowEvent():
	EventScene.showEvent()
	EventScene.visible = true
	EventScene.position.y = 0

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
	newOption.mouse_entered.connect(Utilities.scaleUp.bind(newOption))
	newOption.mouse_exited.connect(Utilities.scaleDown.bind(newOption))
	newOption.gui_input.connect(onCharacterPressed.bind(character, newOption))
	characterOptionContainer.add_child(newOption)

func onCharacterPressed(event: InputEvent, character, node: Control):
	if event.is_pressed():
		disableCharacterOptions()
		PlayerManager.characterClass = character.id
		Utilities.onPressed(node)
		# --- OLD prepare flow (replaced by the run map) ---
		#generateRandomEnemies()
		#await Utilities.slideOut(CharacterSelectScene)
		#Utilities.slideIn(PrepareScene)
		MapScene.generateMap()
		await Utilities.slideOut(CharacterSelectScene)
		Utilities.slideIn(MapScene)

func disableCharacterOptions():
	for child in characterOptionContainer.get_children():
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE

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
	newOption.mouse_entered.connect(Utilities.scaleUp.bind(newOption))
	newOption.mouse_exited.connect(Utilities.scaleDown.bind(newOption))
	newOption.gui_input.connect(onPressed.bind(enemy, newOption))

	enemyOptionContainer.add_child(newOption)

func onPressed(event: InputEvent, enemy, node: Control):
	if(event.is_pressed()):
		disableOthers()
		PlayerManager.currentEnemy = enemy
		Utilities.onPressed(node)
		MainScene.setStage(enemy)
		grid.setStage(enemy)
		await Utilities.slideOut(PrepareScene)
		Utilities.slideIn(MainScene, func():
			MainScene.stageReady()
			grid.stageReady()
		)
		grid.resetGrid()

func disableOthers():
	for child in enemyOptionContainer.get_children():
		child.gui_input.disconnect(onPressed)

# A reachable map node was clicked: start its encounter.
func onMapNodeSelected(node):
	if node.type == "event":
		EventScene.showEvent(Events.pool.pick_random())
		await Utilities.slideOut(MapScene)
		Utilities.slideIn(EventScene)
		return
	if node.type == "shop":
		ShopPanel.generateItems()
		await Utilities.slideOut(MapScene)
		Utilities.slideIn(ShopPanel)
		return
	# Battles may be skipped by event nodes, so sync the level to the map
	# column here instead of relying on the per-victory increment alone.
	PlayerManager.currentLevel = node.col
	PlayerManager.currentEnemy = node.enemy
	MainScene.setStage(node.enemy)
	grid.setStage(node.enemy)
	await Utilities.slideOut(MapScene)
	Utilities.slideIn(MainScene, func():
		MainScene.stageReady()
		grid.stageReady()
	)
	grid.resetGrid()

func _on_close_pressed():
	$AnimationPlayer.play("FadeOut")
	gameoverClose.disabled = true
	Utilities.onPressed(gameoverClose)

func showGameoverPanel():
	GameoverPanel.setStats()
	Utilities.slideIn(GameoverPanel)

func _on_animation_player_animation_finished(anim_name):
	if(anim_name == "FadeOut"):
		backToMenu()

func backToMenu():
	get_tree().change_scene_to_file("res://Scene/Menu.tscn")

func victory():
	if PlayerManager.currentLevel > 15:
		GameoverPanel.setStats(true)
		Utilities.slideIn(GameoverPanel)
	else:
		await Utilities.slideOut(MainScene)
		Utilities.slideIn(AbilityDraftScene)

func draftFinished():
	await Utilities.slideOut(AbilityDraftScene)
	MapScene.reopen()
	Utilities.slideIn(MapScene)

# An event was resolved: return to the map (events will later be map nodes).
func eventFinished():
	await Utilities.slideOut(EventScene)
	MapScene.reopen()
	Utilities.slideIn(MapScene)

# A spell was bought: pop up the ability slots so the player places it.
func onSpellPurchased(ability):
	AbilityDraftScene.generateEquip(ability.id)
	await Utilities.slideOut(ShopPanel)
	Utilities.slideIn(AbilityDraftScene)

# Equip popup closed: return to the shop with its remaining stock intact
# (no generateItems here — the bought card is already gone).
func equipFinished():
	await Utilities.slideOut(AbilityDraftScene)
	Utilities.slideIn(ShopPanel)

# Shop closed: return to the map (same as events; also fine for the dev
# panel shortcut since the map slides in over whatever was showing).
func shopFinished():
	await Utilities.slideOut(ShopPanel)
	MapScene.reopen()
	Utilities.slideIn(MapScene)
