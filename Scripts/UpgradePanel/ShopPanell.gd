extends Control

@onready var container = $ShopPanel/MarginContainer/GridContainer
@onready var shopItem = preload("res://Scene/Component/Item.tscn")
@onready var equipmentItem = preload("res://Scene/Component/Equipment.tscn")
@onready var coinLabel = $CoinIcon/Label
@onready var skipButton = $Skip

func _ready():
	generateItems()
	coinLabel.text = str(PlayerManager.coin)
	skipButton.connect("mouse_entered", Utilities.scaleUp.bind(skipButton))
	skipButton.connect("mouse_exited", Utilities.scaleDown.bind(skipButton))

func generateItems():
	for item in container.get_children():
		item.queue_free()
	
	for index in Utilities.chooseRandom(Consts.alchemyItems.size(), 5):
		setItem(Consts.alchemyItems[index], true)
	
	var equipmentData = Consts.equipmentNormalItems[randi_range(0, Consts.equipmentNormalItems.size() - 1)]
	setItem(equipmentData, false)

func setItem(itemData, isAlchemy):
	var item
	if isAlchemy:
		item = shopItem.instantiate()
	else:
		item = equipmentItem.instantiate()
	var icon = item.find_child("Icon")
	var price = item.find_child("Price")
	var itemName = item.find_child("Name")
	itemName.label_settings = LabelSettings.new()

	icon.frame = itemData.frame
	price.text = str(itemData.price)
	itemName.text = itemData.name
	var color
	match itemData.tier:
		Consts.COMMON:
			color = Color.SEA_GREEN
		Consts.RARE:
			color = Color.STEEL_BLUE
		Consts.EPIC:
			color = Color.REBECCA_PURPLE
		Consts.LEGENDARY:
			color = Color.GOLD
			
	itemName.label_settings.font_color = color
	item.tooltip_text = formatDescriptionText(itemData.description, itemData.id)
	item.connect("mouse_entered", Utilities.scaleUp.bind(item))
	item.connect("mouse_exited", Utilities.scaleDown.bind(item))
	container.add_child(item)

func formatDescriptionText(text, id):
	var finalText = text
	match id:
		0, 6, 13:
			finalText = text.replace("%1", str(PlayerManager.singleDamage))
		1, 7, 14:
			finalText = text.replace("%1", str(PlayerManager.doubleDamage))
		2, 8, 15:
			finalText = text.replace("%1", str(PlayerManager.tripleDamage))
		3, 9, 16:
			finalText = text.replace("%1", str(PlayerManager.tetrisDamage))
	return finalText
			

func _on_skip_pressed():
	Utilities.onPressed(skipButton)
	SignalManager.shopFinished.emit()
