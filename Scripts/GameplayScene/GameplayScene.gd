extends Control

@onready var enemyOptionPrefab = $PrepareScene/Option
@onready var enemyOptionContainer = $PrepareScene/EnemyOptionContainer

func _ready():
	generateRandomEnemies()

func generateRandomEnemies():
	match PlayerManager.curretnLevel:
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
	newOption.gui_input.connect(onPressed.bind(enemy.id, newOption))

	enemyOptionContainer.add_child(newOption)

func onPressed(event: InputEvent, enemyId, node):
	if(event.is_pressed()):
		Utilities.onPressed(node)
	

