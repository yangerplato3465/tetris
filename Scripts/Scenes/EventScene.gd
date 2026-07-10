extends Control

# Event screen (Slay the Spire style). Reads event definitions from the
# Events autoload — see Scripts/Utils/Events.gd for the full schema
# (options with costs, declarative effects, weighted random outcomes,
# follow-up pages, and a Callable escape hatch).
#
# Flow: showEvent(id or Dictionary) -> player picks an affordable option ->
# cost is paid, an outcome is resolved and applied -> result text + Continue.
# Continue opens the outcome's "next" page, or emits eventFinished.

signal eventFinished

const FONT = preload("res://Font/ThaleahFat/ThaleahFat.ttf")

var titleLabel: Label
var bodyLabel: Label
var optionContainer: VBoxContainer
var resultLabel: Label
var continueButton: Button

var _nextPage := "" # follow-up page queued by the resolved outcome

func _ready():
	titleLabel = _makeLabel(64, Vector2(0, 60), Vector2(1200, 90))
	bodyLabel = _makeLabel(30, Vector2(250, 180), Vector2(700, 200))
	resultLabel = _makeLabel(30, Vector2(250, 420), Vector2(700, 180))
	resultLabel.visible = false

	optionContainer = VBoxContainer.new()
	optionContainer.position = Vector2(350, 410)
	optionContainer.size = Vector2(500, 260)
	optionContainer.add_theme_constant_override("separation", 16)
	add_child(optionContainer)

	continueButton = _makeButton("Continue")
	continueButton.position = Vector2(500, 640)
	continueButton.size = Vector2(200, 60)
	continueButton.visible = false
	continueButton.pressed.connect(_onContinuePressed)
	add_child(continueButton)

func _makeLabel(fontSize: int, pos: Vector2, size: Vector2) -> Label:
	var label = Label.new()
	var settings = LabelSettings.new()
	settings.font = FONT
	settings.font_size = fontSize
	label.label_settings = settings
	label.position = pos
	label.size = size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)
	return label

func _makeButton(text: String) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_override("font", FONT)
	btn.add_theme_font_size_override("font_size", 30)
	return btn

# Accepts an event id from Events.events or an inline event Dictionary.
func showEvent(event = "abandoned_cart"):
	if event is String:
		event = Events.events[event]
	titleLabel.text = event.title
	bodyLabel.text = event.body
	resultLabel.visible = false
	continueButton.visible = false
	optionContainer.visible = true
	_nextPage = ""
	# Detach immediately (not just queue_free) so rebuilding within the same
	# frame — e.g. a follow-up page — never shows stale option buttons.
	for child in optionContainer.get_children():
		optionContainer.remove_child(child)
		child.queue_free()
	for option in event.options:
		var btn = _makeButton(option.text)
		btn.custom_minimum_size = Vector2(500, 60)
		btn.pressed.connect(_onOptionPressed.bind(option))
		if not _canAfford(option.get("cost", [])):
			btn.disabled = true
			btn.modulate = Color(0.35, 0.35, 0.35, 0.7)
		optionContainer.add_child(btn)

# --- Costs & effects ---

func _canAfford(cost: Array) -> bool:
	for desc in cost:
		match desc.type:
			"coins":
				if PlayerManager.coin < desc.amount:
					return false
			"magic":
				if PlayerManager.magicMeter < desc.amount:
					return false
			"hp": # an HP cost may hurt, but never kill
				if PlayerManager.playerHealth <= desc.amount:
					return false
	return true

func _payCost(cost: Array):
	for desc in cost:
		match desc.type:
			"coins":
				PlayerManager.coin -= desc.amount
			"magic":
				PlayerManager.magicMeter -= desc.amount
			"hp":
				PlayerManager.playerHealth -= desc.amount

func _applyEffect(desc: Dictionary):
	match desc.type:
		"coins":
			PlayerManager.coin += desc.amount
		"heal":
			PlayerManager.playerHealth = mini(PlayerManager.playerHealth + desc.amount, PlayerManager.maxPlayerHealth)
		"damage":
			PlayerManager.playerHealth -= desc.amount
		"max_hp":
			PlayerManager.maxPlayerHealth += desc.amount
		"shield":
			PlayerManager.shieldNum += desc.amount
		"magic":
			PlayerManager.magicMeter = mini(PlayerManager.magicMeter + desc.amount, PlayerManager.maxMagicMeter)
		"max_magic":
			PlayerManager.maxMagicMeter += desc.amount
		_:
			push_warning("EventScene: unknown effect type '%s'" % desc.type)

# Weighted roll over an option's "outcomes"; a flat option is its own outcome.
func _resolveOutcome(option: Dictionary) -> Dictionary:
	if not option.has("outcomes"):
		return option
	var total = 0
	for outcome in option.outcomes:
		total += outcome.weight
	var roll = randi_range(1, total)
	for outcome in option.outcomes:
		roll -= outcome.weight
		if roll <= 0:
			return outcome
	return option.outcomes.back()

# --- Interaction ---

func _onOptionPressed(option: Dictionary):
	AudioManager.button_press.play()
	_payCost(option.get("cost", []))
	var outcome = _resolveOutcome(option)
	for desc in outcome.get("effects", []):
		_applyEffect(desc)
	if outcome.has("effect"):
		outcome.effect.call()
	_nextPage = outcome.get("next", "")
	optionContainer.visible = false
	resultLabel.text = outcome.get("result", "")
	resultLabel.visible = true
	continueButton.visible = true

func _onContinuePressed():
	AudioManager.button_press.play()
	if _nextPage != "":
		showEvent(_nextPage)
	else:
		eventFinished.emit()
