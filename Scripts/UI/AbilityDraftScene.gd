extends Control

# Post-battle ability draft: offers 3 random abilities (free, choose 1) that the
# player drags into one of the 5 ability slots. Slots 1-2 start filled with the
# class's default abilities; dropping onto any slot fills or replaces it.

signal draftFinished

@onready var optionContainer = $OptionContainer
@onready var slotContainer = $SlotContainer
@onready var continueButton = $Continue

const ABILITY_CARD = preload("res://Scene/Component/Equipment.tscn")
const CARD_SIZE = Vector2(138, 186)
const SLOT_SIZE = Vector2(150, 175)

var _chosen = false

func _ready():
	continueButton.pressed.connect(_onContinue)

# Called on stage_victory (see GameplayScene).
func generateDraft():
	_chosen = false
	_buildSlots()
	_buildOptions()

# --- Slots (drop targets) ---

func _buildSlots():
	for child in slotContainer.get_children():
		child.queue_free()
	for i in PlayerManager.ABILITY_SLOTS:
		slotContainer.add_child(_makeSlot(i))

func _makeSlot(index: int) -> Panel:
	var slot = Panel.new()
	slot.custom_minimum_size = SLOT_SIZE

	var number = Label.new()
	number.text = "[%d]" % (index + 1)
	number.position = Vector2(8, 4)

	var nameLabel = Label.new()
	nameLabel.name = "AbilityName"
	nameLabel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	nameLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nameLabel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nameLabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nameLabel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var ability = PlayerManager.getEquippedAbilityAt(index)
	nameLabel.text = ability.name if not ability.is_empty() else "Empty"

	slot.add_child(nameLabel)
	slot.add_child(number)
	slot.set_drag_forwarding(Callable(), _canDropOnSlot.bind(index), _dropOnSlot.bind(index))
	return slot

func _canDropOnSlot(_at_position, data, _index) -> bool:
	return not _chosen and data is Dictionary and data.has("abilityId")

func _dropOnSlot(_at_position, data, index) -> void:
	PlayerManager.setEquippedAbility(index, data["abilityId"])
	_chosen = true
	AudioManager.money.play()
	_buildSlots()      # refresh to show the placed ability
	_clearOptions()    # 3-choose-1: the offer is consumed once a card is placed

# --- Options (3 draggable ability cards) ---

func _buildOptions():
	_clearOptions()
	var pool = PlayerManager.getCharacter(PlayerManager.characterClass).abilityPool
	for index in Utilities.chooseRandom(pool.size(), 3):
		optionContainer.add_child(_makeCard(PlayerManager.getAbility(pool[index])))

func _clearOptions():
	for child in optionContainer.get_children():
		child.queue_free()

func _makeCard(ability: Dictionary) -> Control:
	var card = ABILITY_CARD.instantiate()
	var nameLabel = card.find_child("Name")
	var valueLabel = card.find_child("Price")
	nameLabel.label_settings = LabelSettings.new()
	valueLabel.label_settings = LabelSettings.new()
	nameLabel.text = ability.name
	valueLabel.text = str(ability.value)
	nameLabel.label_settings.font_color = Color.REBECCA_PURPLE
	valueLabel.label_settings.font_color = Color.BLACK
	card.tooltip_text = ability.description
	card.mouse_entered.connect(Utilities.scaleUp.bind(card))
	card.mouse_exited.connect(Utilities.scaleDown.bind(card))
	card.set_drag_forwarding(_getCardDrag.bind(card, ability.id), Callable(), Callable())
	return card

func _getCardDrag(_at_position, card, abilityId):
	if _chosen:
		return null
	var preview = TextureRect.new()
	preview.texture = card.texture
	preview.custom_minimum_size = CARD_SIZE
	preview.size = CARD_SIZE
	preview.modulate = Color(1, 1, 1, 0.8)
	card.set_drag_preview(preview)
	return {"abilityId": abilityId, "card": card}

# --- Continue ---

func _onContinue():
	AudioManager.kaching.play()
	draftFinished.emit()
