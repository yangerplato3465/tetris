extends Control

@onready var container = $ShopPanel/MarginContainer/GridContainer
@onready var shopItem = preload("res://Scene/Component/Item.tscn")

func _ready():
	generateItems()

func generateItems():
	for i in PlayerManager.numberStoreItem:
		var item = shopItem.instantiate()
		var icon = item.find_child("Icon")
		var price = item.find_child("Price")
