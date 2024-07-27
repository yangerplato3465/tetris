extends Control

@onready var PrepareScene = $PrepareScene
@onready var MainScene = $Main
@onready var GameoverPanel = $GameoverPanel

@onready var enemyOptionPrefab = $PrepareScene/Option
@onready var enemyOptionContainer = $PrepareScene/EnemyOptionContainer
@onready var levelText = $Main/Grid/UI/Level/LevelNumber

@onready var gameoverClose = $GameoverPanel/NinePatchRect/Close

func _ready():
	generateRandomEnemies()
	levelText.text = "level " + str(PlayerManager.currentLevel)
	gameoverClose.connect("mouse_entered", Utilities.scaleUp.bind(gameoverClose))
	gameoverClose.connect("mouse_exited", Utilities.scaleDown.bind(gameoverClose))
	SignalManager.gameoverFromGrid.connect(showGameoverPanel)
	SignalManager.gameoverFromTimer.connect(showGameoverPanel)

func generateRandomEnemies():
	match PlayerManager.currentLevel:
		1, 2:
			for index in Utilities.chooseRandom(Consts.tier1Enemy.size(), 3):
				setOptions(Consts.tier1Enemy[index])
		3:
			pass
		4, 5:
			for index in Utilities.chooseRandom(Consts.tier2Enemy.size(), 3):
				setOptions(Consts.tier2Enemy[index])
		6:
			pass
		7, 8:
			for index in Utilities.chooseRandom(Consts.tier3Enemy.size(), 3):
				setOptions(Consts.tier3Enemy[index])
		9:
			pass


func setOptions(enemy):
	for option in enemyOptionContainer.get_children():
		option.queue_free()
	var newOption = enemyOptionPrefab.duplicate()
	newOption.get_node("Name").text = enemy.name
	newOption.get_node("Icon").frame = enemy.frame
	newOption.get_node("Description").text = str(enemy.time)
	newOption.visible = true

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
		Utilities.slideIn(MainScene)

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
