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
	
	var equipmentData = Consts.equipmentNormalItems[randi_range(0, Consts.equipmentNormalItems.size())]
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
			color = Color.GREEN
		Consts.RARE:
			color = Color.BLUE
		Consts.EPIC:
			color = Color.PURPLE
		Consts.LEGENDARY:
			color = Color.GOLD
			
	itemName.label_settings.font_color = color
	item.tooltip_text = itemData.description
	item.connect("mouse_entered", Utilities.scaleUp.bind(item))
	item.connect("mouse_exited", Utilities.scaleDown.bind(item))
	container.add_child(item)

