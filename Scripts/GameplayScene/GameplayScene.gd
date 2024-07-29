extends Control

@onready var PrepareScene = $PrepareScene
@onready var MainScene = $Main
@onready var GameoverPanel = $GameoverPanel
@onready var ShopPanel = $ShopPanel

@onready var enemyOptionPrefab = preload("res://Scene/Component/enemyOption.tscn")
@onready var enemyOptionContainer = $PrepareScene/EnemyOptionContainer
@onready var levelText = $PrepareScene/LevelNumber

@onready var gameoverClose = $GameoverPanel/NinePatchRect/Close

func _ready():
	PlayerManager.reset() # Reset all upgrades and stats
	generateRandomEnemies()
	gameoverClose.connect("mouse_entered", Utilities.scaleUp.bind(gameoverClose))
	gameoverClose.connect("mouse_exited", Utilities.scaleDown.bind(gameoverClose))
	SignalManager.gameoverFromGrid.connect(showGameoverPanel)
	SignalManager.gameoverFromTimer.connect(showGameoverPanel)
	SignalManager.victory.connect(victory)
	SignalManager.shopFinished.connect(shopFinished)

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
	var descriptionText = "health: %s\nreward: %s" % [str(enemy.health), str(enemy.reward)]
	newOption.find_child("Description").text = descriptionText

	newOption.pivot_offset = Vector2(184, 300)
	newOption.mouse_entered.connect(Utilities.scaleUp.bind(newOption))
	newOption.mouse_exited.connect(Utilities.scaleDown.bind(newOption))
	newOption.gui_input.connect(onPressed.bind(enemy, newOption))

	enemyOptionContainer.add_child(newOption)

func onPressed(event: InputEvent, enemy, node: Control):
	if(event.is_pressed()):
		disableOthers()
		Utilities.onPressed(node)
		SignalManager.setStage.emit(enemy)
		await Utilities.slideOut(PrepareScene)
		Utilities.slideIn(MainScene, func(): 
			SignalManager.stageReady.emit()	
		)
		SignalManager.resetGrid.emit()

func disableOthers():
	for child in enemyOptionContainer.get_children():
		child.gui_input.disconnect(onPressed)

func _on_close_pressed():
	$AnimationPlayer.play("FadeOut")
	gameoverClose.disabled = true
	Utilities.onPressed(gameoverClose)

func showGameoverPanel():
	Utilities.slideIn(GameoverPanel)

func _on_animation_player_animation_finished(anim_name):
	if(anim_name == "FadeOut"):
		backToMenu()

func backToMenu():
	get_tree().change_scene_to_file("res://Scene/Menu.tscn")

func victory():
	await Utilities.slideOut(MainScene)
	Utilities.slideIn(ShopPanel)

func shopFinished():
	await Utilities.slideOut(ShopPanel)
	generateRandomEnemies()
	Utilities.slideIn(PrepareScene)
