extends Control

# Event screen (Slay the Spire style). Reads events from the Events autoload —
# see Scripts/Data/EventData.gd for the schema (pages, options with costs,
# effects applied by RunEffects, weighted random outcomes, follow-up pages).
#
# Flow: showEvent(id) opens the event's start page -> its body and dialogue lines
# play beat by beat (Next) -> player picks an affordable option -> cost is paid,
# an outcome is resolved and applied -> result text + Continue. Continue opens the outcome's "next" page in the same event, or emits
# eventFinished.

signal eventFinished

const FONT = preload("res://Font/ThaleahFat/ThaleahFat.ttf")

var titleLabel: Label
var bodyLabel: Label
var optionContainer: VBoxContainer
var resultLabel: Label
var continueButton: Button
var speakerLabel: Label
var nextButton: Button

var _beats: Array = []   # the page's body and lines, played one at a time
var _beatIndex := 0
var _typeTween: Tween

var _event: Dictionary = {} # the event being shown; "next" page ids resolve inside it
var _eventScript = null # a fresh instance of the event's file, which "call" effects run on
var _nextPage := "" # follow-up page queued by the resolved outcome

func _ready():
	titleLabel = _makeLabel(64, Vector2(0, 60), Vector2(1200, 90))
	bodyLabel = _makeLabel(30, Vector2(250, 180), Vector2(700, 200))
	resultLabel = _makeLabel(30, Vector2(250, 420), Vector2(700, 180))
	resultLabel.visible = false
	speakerLabel = _makeLabel(34, Vector2(250, 135), Vector2(700, 40))
	speakerLabel.label_settings.font_color = Color(1.0, 0.85, 0.4)
	speakerLabel.visible = false

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

	# Same spot as Continue: Next shows while dialogue is playing, Continue after a
	# choice, so the two are never visible together.
	nextButton = _makeButton("Next")
	nextButton.position = Vector2(500, 640)
	nextButton.size = Vector2(200, 60)
	nextButton.visible = false
	nextButton.pressed.connect(_onNextPressed)
	add_child(nextButton)

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

# Opens `eventId` at `pageId`. An empty id rolls one from Events.pool (the dev
# panel's no-argument call); an empty page means the event's "start" page.
func showEvent(eventId: String = "", pageId: String = ""):
	if eventId == "":
		eventId = Events.rollEvent()
	if eventId == "":
		# No event's requires hold. The floor screen doesn't offer an event card then,
		# so this is the dev panel — show any event rather than a blank screen.
		push_warning("EventScene: no event is eligible right now; ignoring requires")
		eventId = Events.pool.pick_random()
	_event = Events.events[eventId]
	# Fresh per showing, so a custom function can keep state across the event's
	# pages without leaking it into the next time the event comes up.
	_eventScript = Events.scripts[eventId].new()
	_showPage(pageId if pageId != "" else _event.start)

func _showPage(pageId: String):
	var page = _event.pages[pageId]
	titleLabel.text = page.get("title", _event.title)
	resultLabel.visible = false
	continueButton.visible = false
	# Options are built below but held back until every beat has been read.
	optionContainer.visible = false
	_nextPage = ""
	_beats = []
	if page.has("body"):
		_beats.append({"text": page.body})
	_beats.append_array(page.get("lines", []))
	if _beats.is_empty(): # the validator rejects this; never show a blank, stuck page
		_beats.append({"text": ""})
	_beatIndex = 0
	# Detach immediately (not just queue_free) so rebuilding within the same
	# frame — e.g. a follow-up page — never shows stale option buttons.
	for child in optionContainer.get_children():
		optionContainer.remove_child(child)
		child.queue_free()
	var usable := 0
	for option in page.options:
		# Unmet requires hide an option — unless it has locked_text, which is shown on
		# a disabled button instead, to hint at what another run could do here.
		var unlocked = RunConditions.met(option.get("requires", []))
		if not unlocked and not option.has("locked_text"):
			continue
		var btn = _makeButton(option.text if unlocked else option.locked_text)
		btn.custom_minimum_size = Vector2(500, 60)
		btn.pressed.connect(_onOptionPressed.bind(option))
		if not unlocked or not _canAfford(option.get("cost", [])):
			btn.disabled = true
			btn.modulate = Color(0.35, 0.35, 0.35, 0.7)
		else:
			usable += 1
		optionContainer.add_child(btn)
	# Every option hidden, locked or unaffordable would strand the player on this
	# page, so there is always a way out.
	if usable == 0:
		var leave = _makeButton("Leave")
		leave.custom_minimum_size = Vector2(500, 60)
		leave.pressed.connect(_onContinuePressed)
		optionContainer.add_child(leave)
	_showBeat()

# --- Dialogue ---

# A page's body and lines play as beats: one at a time in bodyLabel, with the
# speaker (if any) above it, typed out character by character. Next finishes the
# typing first, then advances. Once the last beat is fully shown, Next gives way
# to the options and that beat's text stays on screen with them. A page with only
# a body is a single beat and reads exactly as before: all at once, options up.
const TYPE_SECONDS_PER_CHAR := 0.02

func _showBeat():
	var beat = _beats[_beatIndex]
	var speaker = beat.get("speaker", "")
	speakerLabel.text = speaker
	speakerLabel.visible = speaker != ""
	bodyLabel.text = beat.text
	if _typeTween:
		_typeTween.kill()
	optionContainer.visible = false
	nextButton.visible = true
	if _beats.size() == 1:
		_finishBeat()
		return
	bodyLabel.visible_ratio = 0.0
	_typeTween = create_tween()
	_typeTween.tween_property(bodyLabel, "visible_ratio", 1.0, maxf(beat.text.length() * TYPE_SECONDS_PER_CHAR, 0.01))
	_typeTween.finished.connect(_finishBeat)

# The current beat is fully shown. On the last beat that means the options.
func _finishBeat():
	bodyLabel.visible_ratio = 1.0
	if _beatIndex == _beats.size() - 1:
		nextButton.visible = false
		optionContainer.visible = true

func _onNextPressed():
	AudioManager.button_press.play()
	if bodyLabel.visible_ratio < 1.0:
		_typeTween.kill()
		_finishBeat()
	elif _beatIndex < _beats.size() - 1:
		_beatIndex += 1
		_showBeat()

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
	# Notes are what the author couldn't write in advance — the keepsake a random
	# roll granted, a refused piece change, a custom function's text.
	var lines = [outcome.get("result", "")]
	for desc in outcome.get("effects", []):
		lines.append(RunEffects.apply(desc, {"event": _eventScript}))
	_nextPage = outcome.get("next", "")
	optionContainer.visible = false
	resultLabel.text = "\n".join(lines.filter(func(line): return line != ""))
	resultLabel.visible = true
	continueButton.visible = true

func _onContinuePressed():
	AudioManager.button_press.play()
	if _nextPage != "":
		_showPage(_nextPage)
	else:
		eventFinished.emit()
