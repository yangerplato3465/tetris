extends Control

signal shopFinished
signal spellPurchased(ability)

const SPELL_COUNT = 3
const KEEPSAKE_COUNT = 5

# Service cards shown to the right of the spells.
const HEAL_OPTION = {
	"name": "Rest",
	"description": "Restore 30 HP",
	"price": 30,
	"heal": 30,
}
const UPGRADE_OPTION = {
	"name": "Upgrade Spell",
	"description": "Upgrade one of your spells (coming soon)",
	"price": 100,
}

@onready var spellRow = $ShopPanel/MarginContainer/Sections/SpellRow
@onready var keepsakeRow = $ShopPanel/MarginContainer/Sections/KeepsakeRow
@onready var spellCard = preload("res://Scene/Component/Equipment.tscn")
@onready var keepsakeCard = preload("res://Scene/Component/Item.tscn")
@onready var coinLabel = $CoinIcon/Label
@onready var skipButton = $Skip

var currentCards = []   # [{"data": Dictionary, "node": Control}] for price refresh

func _ready():
	Utilities.makeJuicy(skipButton)

func generateItems():
	currentCards = []
	coinLabel.text = str(PlayerManager.coin) # Init coin count
	for card in spellRow.get_children() + keepsakeRow.get_children():
		card.queue_free()

	# --- Top row: 3 random spells from the class ability pool ---
	var pool = PlayerManager.getCharacter(PlayerManager.characterClass).abilityPool
	for index in Utilities.chooseRandom(pool.size(), SPELL_COUNT):
		setSpellCard(PlayerManager.getAbility(pool[index]))

	# --- Service cards to the right of the spells ---
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(10, 0)
	spellRow.add_child(spacer)
	var healCard = setupCard(spellCard, spellRow, HEAL_OPTION, Color.GOLDENROD)
	healCard.gui_input.connect(onHealPressed.bind(healCard))
	var upgradeCard = setupCard(spellCard, spellRow, UPGRADE_OPTION, Color.GOLDENROD)
	upgradeCard.gui_input.connect(onUpgradePressed)

	# --- Bottom row: 5 random keepsakes the player doesn't own yet ---
	var available = []
	for id in Keepsakes.pool:
		if not PlayerManager.ownedKeepsakes.has(id):
			available.append(id)
	for index in Utilities.chooseRandom(available.size(), KEEPSAKE_COUNT):
		setKeepsakeCard(Keepsakes.keepsakes[available[index]])

# Buying a spell pops up the equip screen (see GameplayScene.onSpellPurchased)
# so the player picks which slot it goes into.
func setSpellCard(abilityData):
	var card = setupCard(spellCard, spellRow, abilityData, Color.REBECCA_PURPLE)
	card.tooltip_text += AbilityData.cooldownLabel(abilityData) + AbilityData.burnLabel(abilityData)
	card.gui_input.connect(onSpellPressed.bind(abilityData, card))

func setKeepsakeCard(keepsakeData):
	var card = setupCard(keepsakeCard, keepsakeRow, keepsakeData, Color.SEA_GREEN)
	card.find_child("Icon").frame = keepsakeData.frame
	card.gui_input.connect(onKeepsakePressed.bind(keepsakeData, card))

func setupCard(scene, row, data, nameColor):
	var card = scene.instantiate()
	var price = card.find_child("Price")
	var cardName = card.find_child("Name")
	cardName.label_settings = LabelSettings.new()
	price.label_settings = LabelSettings.new()

	cardName.text = data.name
	price.text = str(data.price)
	cardName.label_settings.font_color = nameColor
	price.label_settings.font_color = Color.RED if data.price > PlayerManager.coin else Color.BLACK
	card.tooltip_text = data.description
	Utilities.makeJuicy(card)
	row.add_child(card)
	currentCards.append({"data": data, "node": card})
	return card

func onSpellPressed(event: InputEvent, abilityData, node):
	if event.is_pressed():
		if PlayerManager.coin < abilityData.price:
			return
		PlayerManager.coin -= abilityData.price
		completePurchase(abilityData, node, onSpellPressed)
		spellPurchased.emit(abilityData)

func onHealPressed(event: InputEvent, node):
	if event.is_pressed():
		if PlayerManager.coin < HEAL_OPTION.price:
			return
		if PlayerManager.playerHealth >= PlayerManager.maxPlayerHealth:
			return
		PlayerManager.coin -= HEAL_OPTION.price
		PlayerManager.playerHealth = mini(PlayerManager.playerHealth + HEAL_OPTION.heal, PlayerManager.maxPlayerHealth)
		completePurchase(HEAL_OPTION, node, onHealPressed)

# Placeholder: upgrading spells is not implemented yet.
func onUpgradePressed(event: InputEvent):
	if event.is_pressed():
		print("Shop: spell upgrade not implemented yet")

func onKeepsakePressed(event: InputEvent, keepsakeData, node):
	if event.is_pressed():
		if PlayerManager.coin < keepsakeData.price:
			return
		PlayerManager.addKeepsake(keepsakeData)
		completePurchase(keepsakeData, node, onKeepsakePressed)

func completePurchase(data, node, handler):
	AudioManager.money.play()
	node.tooltip_text = ""
	shrinkAndHide(node)
	node.gui_input.disconnect(handler)
	coinLabel.text = str(PlayerManager.coin) # coin count
	PlayerManager.coinsSpent += data.price # End stats
	PlayerManager.itemsBought += 1 # End stats
	updatePriceColors()

func updatePriceColors():
	for entry in currentCards:
		if entry.data.price > PlayerManager.coin:
			var price = entry.node.find_child("Price")
			price.label_settings.font_color = Color.RED

func shrinkAndHide(node):
	var tween = create_tween()
	tween.finished.connect(func():
		node.modulate.a = 0
		node.scale = Vector2(0, 0)
	)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(node, "scale", Vector2(0.3, 0.3), 0.2)

func _on_skip_pressed():
	AudioManager.kaching.play()
	Utilities.onPressed(skipButton)
	shopFinished.emit()
