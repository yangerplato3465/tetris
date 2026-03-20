extends Control

@onready var CharacterSelectScene = $CharacterSelectScene
@onready var characterOptionPrefab = preload("res://Scene/Component/characterOption.tscn")
@onready var characterOptionContainer = $CharacterSelectScene/CharacterOptionContainer

@onready var PrepareScene = $PrepareScene
@onready var MainScene = $Main
@onready var GameoverPanel = $GameoverPanel
@onready var ShopPanel = $ShopPanel
@onready var grid = $Main/Grid

@onready var enemyOptionPrefab = preload("res://Scene/Component/enemyOption.tscn")
@onready var enemyOptionContainer = $PrepareScene/EnemyOptionContainer
@onready var levelText = $PrepareScene/LevelNumber

@onready var gameoverClose = $GameoverPanel/NinePatchRect/Close

const CHARACTERS = [
	{
		"id": "wizard",
		"name": "Wizard",
		"frame": 0,
		"description": "Amplification & Burst\n\n[1] Magic Bolt     1 orb\n[2] Earthquake     1 orb\n[3] Arcane Echo    2 orbs\n[4] Mana Burst     all orbs"
	},
	{
		"id": "knight",
		"name": "Knight",
		"frame": 5,
		"description": "Defense to Offense\n\n[1] Earthquake     1 orb\n[2] Shield Bash    1 orb\n[3] Battle Cry     2 orbs\n[4] Iron Wall      1 orb"
	},
	{
		"id": "rogue",
		"name": "Rogue",
		"frame": 10,
		"description": "Board Manipulation\n\n[1] Purify         1 orb\n[2] Venom          1 orb\n[3] Assassinate    2 orbs\n[4] Smoke Bomb     2 orbs"
	},
	{
		"id": "cleric",
		"name": "Cleric",
		"frame": 15,
		"description": "Sustain & Burst\n\n[1] Heal           1 orb\n[2] Holy Beam      1 orb\n[3] Smite          1 orb\n[4] Sanctuary      3 orbs"
	}
]

func _ready():
	PlayerManager.reset() # Reset all upgrades and stats
	grid.stopGrid()
	generateCharacterOptions()
	gameoverClose.connect("mouse_entered", Utilities.scaleUp.bind(gameoverClose))
	gameoverClose.connect("mouse_exited", Utilities.scaleDown.bind(gameoverClose))
	MainScene.stage_gameover.connect(showGameoverPanel)
	MainScene.stage_victory.connect(victory)
	MainScene.stage_victory.connect(ShopPanel.generateItems)
	ShopPanel.shopFinished.connect(shopFinished)

func generateCharacterOptions():
	for child in characterOptionContainer.get_children():
		child.queue_free()
	for character in CHARACTERS:
		setCharacterOption(character)

func setCharacterOption(character):
	var newOption = characterOptionPrefab.instantiate()
	newOption.find_child("Name").text = character.name
	newOption.find_child("Icon").frame = character.frame
	newOption.find_child("Description").text = character.description
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
		generateRandomEnemies()
		await Utilities.slideOut(CharacterSelectScene)
		Utilities.slideIn(PrepareScene)

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
		Utilities.slideIn(ShopPanel)

func shopFinished():
	await Utilities.slideOut(ShopPanel)
	generateRandomEnemies()
	Utilities.slideIn(PrepareScene)
