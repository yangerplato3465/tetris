extends Control

@onready var container = $ShopPanel/MarginContainer/GridContainer
@onready var shopItem = preload("res://Scene/Component/Item.tscn")
@onready var equipmentItem = preload("res://Scene/Component/Equipment.tscn")
@onready var coinLabel = $CoinIcon/Label
@onready var skipButton = $Skip
var currentItemData = []

func _ready():
	skipButton.connect("mouse_entered", Utilities.scaleUp.bind(skipButton))
	skipButton.connect("mouse_exited", Utilities.scaleDown.bind(skipButton))
	SignalManager.victory.connect(generateItems)

func generateItems():
	coinLabel.text = str(PlayerManager.coin) # Init coin count
	for item in container.get_children():
		item.queue_free()
	
	for index in Utilities.chooseRandom(PlayerManager.alchemyArray.size(), 5):
		setItem(PlayerManager.alchemyArray[index], true)
		currentItemData.append(PlayerManager.alchemyArray[index])
	
	var equipmentData = Consts.equipmentCommonItems[randi_range(0, PlayerManager.equipmentArray.size() - 1)]
	currentItemData.append(equipmentData)
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
			color = Color.GOLDENROD
			
	itemName.label_settings.font_color = color
	item.tooltip_text = formatDescriptionText(itemData.description, itemData.id)
	item.connect("mouse_entered", Utilities.scaleUp.bind(item))
	item.connect("mouse_exited", Utilities.scaleDown.bind(item))
	item.gui_input.connect(onPressed.bind(itemData, item))
	container.add_child(item)

func onPressed(event: InputEvent, itemData, node):
	if(event.is_pressed()):
		if PlayerManager.coin < itemData.price:
			return
		AudioManager.money.play()
		node.tooltip_text = ""
		shrinkAndHide(node)
		node.gui_input.disconnect(onPressed)
		PlayerManager.applyUpgrades(itemData.id, itemData.price)
		coinLabel.text = str(PlayerManager.coin) # coin count
		PlayerManager.coinsSpent += itemData.price # End stats
		PlayerManager.itemsBought += 1 # End stats
		updateTooltipInfo()

func updateTooltipInfo():
	var child = container.get_children()
	for index in range(container.get_child_count()):
		child[index].tooltip_text = formatDescriptionText(currentItemData[index].description, currentItemData[index].id)


func shrinkAndHide(node):
	var tween = create_tween()
	tween.finished.connect(func():
		node.modulate.a = 0
		node.scale = Vector2(0, 0)
	)
	tween.set_trans(Tween.TRANS_BACK) 
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(node, "scale", Vector2(0.3, 0.3), 0.2)


func formatDescriptionText(text, id):
	var finalText = text
	match id:
		0, 6, 13, 19:
			finalText = text.replace("%1", str(PlayerManager.singleDamage))
		1, 7, 14:
			finalText = text.replace("%1", str(PlayerManager.doubleDamage))
		2, 8, 15:
			finalText = text.replace("%1", str(PlayerManager.tripleDamage))
		3, 9, 16:
			finalText = text.replace("%1", str(PlayerManager.tetrisDamage))
		4, 12, 18:
			finalText = text.replace("%1", str(PlayerManager.comboMult))
		5, 10:
			finalText = text.replace("%1", str(PlayerManager.timer))
	return finalText
			

func _on_skip_pressed():
	AudioManager.kaching.play()
	Utilities.onPressed(skipButton)
	SignalManager.shopFinished.emit()
