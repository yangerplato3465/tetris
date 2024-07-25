extends Control

@onready var PrepareScene = $PrepareScene
@onready var MainScene = $Main

@onready var enemyOptionPrefab = $PrepareScene/Option
@onready var enemyOptionContainer = $PrepareScene/EnemyOptionContainer
@onready var levelText = $Main/Grid/UI/Level/LevelNumber

func _ready():
	generateRandomEnemies()
	levelText.text = "level " + str(PlayerManager.currentLevel)

func generateRandomEnemies():
	match PlayerManager.currentLevel:
		1, 2:
			for enemy in chooseRandom(Consts.tier1Enemy):
				setOptions(enemy)
		3:
			pass
		4, 5:
			for enemy in chooseRandom(Consts.tier1Enemy):
				setOptions(enemy)
		6:
			pass
		7, 8:
			for enemy in chooseRandom(Consts.tier1Enemy):
				setOptions(enemy)
		9:
			pass

func chooseRandom(array: Array):
	var indices = []
	
	while indices.size() < 3:
		var index = randi() % array.size()
		if index not in indices:
			indices.append(index)
	
	return [array[indices[0]], array[indices[1]], array[indices[2]]]

func setOptions(enemy):
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
	

