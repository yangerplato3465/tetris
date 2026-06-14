extends Control

# Post-battle ability draft: offers 3 random abilities (free, choose 1) that the
# player drags into one of the 5 ability slots. Slots 1-2 start filled with the
# class's default abilities. Filled slots show the ability card and can be dragged
# onto another slot to move (empty target) or swap (filled target) abilities.

signal draftFinished

@onready var optionContainer = $OptionContainer
@onready var slotContainer = $SlotContainer
@onready var continueButton = $Continue

const ABILITY_CARD = preload("res://Scene/Component/Equipment.tscn")
const CARD_SIZE = Vector2(138, 186)

var _chosen = false

func _ready():
	continueButton.pressed.connect(_onContinue)

# Called on stage_victory (see GameplayScene).
func generateDraft():
	_chosen = false
	_buildSlots()
	_buildOptions()

# --- Slots (drop targets; filled slots are also drag sources) ---

func _buildSlots():
	for child in slotContainer.get_children():
		child.queue_free()
	for i in PlayerManager.ABILITY_SLOTS:
		slotContainer.add_child(_makeSlotNode(i))

func _makeSlotNode(index: int) -> Control:
	var ability = PlayerManager.getEquippedAbilityAt(index)
	if ability.is_empty():
		return _makeEmptySlot(index)
	# Filled slot: show the ability card, draggable to move/swap between slots.
	var card = _makeAbilityCard(ability)
	card.add_child(_makeSlotNumber(index))
	card.set_drag_forwarding(
		_slotDragData.bind(card, index),
		_canDropOnSlot.bind(index),
		_dropOnSlot.bind(index))
	return card

func _makeEmptySlot(index: int) -> Panel:
	var slot = Panel.new()
	slot.custom_minimum_size = CARD_SIZE
	var label = Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = "Empty"
	slot.add_child(label)
	slot.add_child(_makeSlotNumber(index))
	slot.set_drag_forwarding(Callable(), _canDropOnSlot.bind(index), _dropOnSlot.bind(index))
	return slot

func _makeSlotNumber(index: int) -> Label:
	var number = Label.new()
	number.text = "[%d]" % (index + 1)
	number.position = Vector2(8, 4)
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return number

func _canDropOnSlot(_at_position, data, _index) -> bool:
	if not (data is Dictionary and data.has("abilityId")):
		return false
	if data.get("from") == "slot":
		return true             # rearranging existing slots is always allowed
	return not _chosen          # option cards: only one pick per draft

func _dropOnSlot(_at_position, data, index) -> void:
	if data.get("from") == "slot":
		if data["slotIndex"] == index:
			return
		PlayerManager.swapAbilitySlots(data["slotIndex"], index)
		AudioManager.money.play()
		_buildSlots()
	else:
		if _chosen:
			return
		PlayerManager.setEquippedAbility(index, data["abilityId"])
		_chosen = true
		AudioManager.money.play()
		_buildSlots()
		_clearOptions()         # 3-choose-1: the offer is consumed once placed

func _slotDragData(_at_position, card, index):
	var id = PlayerManager.equippedAbilities[index]
	card.set_drag_preview(_makeDragPreview(card))
	return {"abilityId": id, "from": "slot", "slotIndex": index}

# --- Options (3 draggable ability cards) ---

func _buildOptions():
	_clearOptions()
	var pool = PlayerManager.getCharacter(PlayerManager.characterClass).abilityPool
	for index in Utilities.chooseRandom(pool.size(), 3):
		var ability = PlayerManager.getAbility(pool[index])
		var card = _makeAbilityCard(ability)
		card.set_drag_forwarding(_optionDragData.bind(card, ability.id), Callable(), Callable())
		optionContainer.add_child(card)

func _clearOptions():
	for child in optionContainer.get_children():
		child.queue_free()

func _optionDragData(_at_position, card, abilityId):
	if _chosen:
		return null
	card.set_drag_preview(_makeDragPreview(card))
	return {"abilityId": abilityId, "from": "option"}

# --- Shared card visuals ---

func _makeAbilityCard(ability: Dictionary) -> Control:
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
	return card

func _makeDragPreview(card: Control) -> TextureRect:
	var preview = TextureRect.new()
	preview.texture = card.texture
	preview.custom_minimum_size = CARD_SIZE
	preview.size = CARD_SIZE
	preview.modulate = Color(1, 1, 1, 0.85)
	return preview

# --- Continue ---

func _onContinue():
	AudioManager.kaching.play()
	draftFinished.emit()
