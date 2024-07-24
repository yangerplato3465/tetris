extends Control

@onready var enemyOptionPrefab = $PrepareScene/EnemyOptionContainer/Option
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
			chooseRandom(Consts.tier2Enemy);
		6:
			pass
		7, 8:
			chooseRandom(Consts.tier3Enemy);

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
	newOption.connect("mouse_entered", Utilities.scaleUp.bind(newOption))
	newOption.connect("mouse_exited", Utilities.scaleDown.bind(newOption))

	enemyOptionContainer.add_child(newOption)

