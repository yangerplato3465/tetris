extends Control

# Floor choice screen. After every reward the player is shown 2-3 cards and
# picks one: an enemy encounter, a "?" random event, or a "$" shop. Whichever
# they take consumes the floor, so a run is always FLOOR_COUNT choices long and
# a shop or event is spent instead of a fight, not on top of one.
#
# Floor rules, in the order they are applied:
#   - boss floors (BOSS_FLOORS) offer a single mandatory boss
#   - SHOP_FLOORS offer a single mandatory shop
#   - every other floor rolls 2-3 cards: at most one event (EVENT_CHANCE),
#     any number of shops (SHOP_CHANCE), and always at least one fight

signal optionSelected(option)

const FLOOR_COUNT = 15
const BOSS_FLOORS = [3, 6, 9, 12, 15]
const SHOP_FLOORS = [7] # guaranteed restock partway through the run

# Tuning knobs for how often the non-combat cards show up. Both are rolled
# per card, so raising them widens the odds on every floor at once.
const EVENT_CHANCE = 0.18   # capped at one event per floor by MAX_EVENTS
const SHOP_CHANCE = 0.12
const MAX_EVENTS = 1        # two "?" cards on one floor is never interesting
const FIRST_EVENT_FLOOR = 2 # floor 1 is always a plain fight
const FIRST_SHOP_FLOOR = 3  # let the player earn some coins first

const MIN_OPTIONS = 2
const MAX_OPTIONS = 3

const ICON_SHEET = preload("res://Sprite/Cards/Icons.png")
const ICON_HFRAMES = 16
const ICON_VFRAMES = 27
const EVENT_ICON_FRAME = 218 # sealed scroll
const SHOP_ICON_FRAME = 199  # gold coin

const OPTION_PREFAB = preload("res://Scene/Component/enemyOption.tscn")

# One card on the screen. `enemy` is only set when type == "enemy"/"boss".
class FloorOption:
	var type: String # "enemy" | "boss" | "event" | "shop"
	var enemy: EnemyData

@onready var optionContainer = $EnemyOptionContainer
@onready var levelText = $LevelNumber
@onready var title = $Title

var options: Array = [] # FloorOptions currently on screen
# Blocks input until the panel has landed, and again once a card has been taken.
# Cards are armed by unlockCards(), which GameplayScene passes to
# FlowController.goto as its onArrive hook — taking a card mid-slide used to
# lock the cards and then have its own transition refused by the flow's busy
# guard, stranding the run on a screen where nothing could be clicked again.
var locked := true

func generateFloor():
	locked = true
	# Detach immediately (not just queue_free) so the cards from the last floor
	# can never be seen alongside the new ones while the panel slides in.
	for child in optionContainer.get_children():
		optionContainer.remove_child(child)
		child.queue_free()

	var floorNum = PlayerManager.currentLevel
	levelText.text = "level %d" % floorNum
	options = _rollOptions(floorNum)
	title.text = "Choose your path" if options.size() > 1 else _soloTitle(options[0])
	for option in options:
		_buildCard(option)
	# Built inert; unlockCards arms them once the panel has finished sliding in.
	_setCardsInteractive(false)

func _soloTitle(option: FloorOption) -> String:
	match option.type:
		"boss":
			return "A boss blocks the way"
		"shop":
			return "A merchant appears"
		_:
			return "Choose enemy"

# --- Floor composition -----------------------------------------------------

func _rollOptions(floorNum: int) -> Array:
	if floorNum in BOSS_FLOORS:
		return [_makeOption("boss", _bossForFloor(floorNum))]
	if floorNum in SHOP_FLOORS:
		return [_makeOption("shop")]

	var count = randi_range(MIN_OPTIONS, MAX_OPTIONS)
	var types: Array = []
	var events = 0
	for i in count:
		if events < MAX_EVENTS and floorNum >= FIRST_EVENT_FLOOR and randf() < EVENT_CHANCE:
			types.append("event")
			events += 1
		elif floorNum >= FIRST_SHOP_FLOOR and randf() < SHOP_CHANCE:
			types.append("shop")
		else:
			types.append("enemy")
	# A floor with no way forward would dead-end the run's difficulty curve, so
	# one random card is always turned back into a fight.
	if not types.has("enemy"):
		types[randi() % types.size()] = "enemy"

	# Distinct picks so one floor never offers the same enemy twice.
	var pool = _tierPool(floorNum)
	var picks = Utilities.chooseRandom(pool.size(), count)
	var out: Array = []
	for i in count:
		out.append(_makeOption(types[i], pool[picks[i]] if types[i] == "enemy" else null))
	return out

func _makeOption(type: String, enemy = null) -> FloorOption:
	var option = FloorOption.new()
	option.type = type
	option.enemy = enemy
	return option

# Which boss owns this floor is authored on the boss itself (EnemyData.bossFloor),
# not implied by its position in Consts.BossEnemy. An unauthored floor is a loud
# error instead of a silent off-by-one handing the fight to whichever file
# happens to sort into that slot.
func _bossForFloor(floorNum: int) -> EnemyData:
	for enemy in Consts.BossEnemy:
		if enemy.bossFloor == floorNum:
			return enemy
	push_error("PrepareScene: no boss authored for floor %d" % floorNum)
	return Consts.BossEnemy[0] if not Consts.BossEnemy.is_empty() else null

func _tierPool(floorNum: int) -> Array:
	match floorNum:
		1, 2:
			return Consts.tier1Enemy
		4, 5:
			return Consts.tier2Enemy
		_:
			return Consts.tier3Enemy

# --- Cards -----------------------------------------------------------------

func _buildCard(option: FloorOption):
	var card = OPTION_PREFAB.instantiate()
	var icon = card.find_child("Icon")
	match option.type:
		"event":
			card.find_child("Name").text = "?"
			card.find_child("Description").text = "Something awaits..."
			_setIcon(icon, ICON_SHEET, ICON_HFRAMES, ICON_VFRAMES, EVENT_ICON_FRAME)
		"shop":
			card.find_child("Name").text = "Shop"
			card.find_child("Description").text = "Spend your coins\nYou have: %d" % PlayerManager.coin
			_setIcon(icon, ICON_SHEET, ICON_HFRAMES, ICON_VFRAMES, SHOP_ICON_FRAME)
		_:
			card.find_child("Name").text = option.enemy.name
			card.find_child("Description").text = "health: %s\nreward: %s\n%s" % [
				str(option.enemy.health), str(option.enemy.reward), option.enemy.description
			]
			icon.frame = option.enemy.frame

	card.pivot_offset = Vector2(184, 300)
	Utilities.makeJuicy(card)
	card.gui_input.connect(_onCardPressed.bind(option, card))
	# Remember the prefab's own filter rather than assuming a default, so arming
	# a card restores exactly what it shipped with (the root is a TextureRect,
	# which defaults to PASS, not the plain Control STOP).
	card.set_meta("baseMouseFilter", card.mouse_filter)
	optionContainer.add_child(card)

# The prefab's icon points at the monster sheet; event/shop cards borrow the
# shared item icon sheet instead, which has a different frame layout.
func _setIcon(icon: Sprite2D, sheet: Texture2D, hframes: int, vframes: int, frame: int):
	icon.texture = sheet
	icon.hframes = hframes
	icon.vframes = vframes
	icon.frame = frame

# --- Interaction -----------------------------------------------------------

# Arms the cards. Passed to FlowController.goto as its onArrive hook, so a card
# can only be taken once the panel has actually landed and the flow is free to
# act on the choice.
func unlockCards():
	locked = false
	_setCardsInteractive(true)

func _setCardsInteractive(on: bool):
	for child in optionContainer.get_children():
		if on:
			child.mouse_filter = child.get_meta("baseMouseFilter", Control.MOUSE_FILTER_PASS)
		else:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _onCardPressed(event: InputEvent, option: FloorOption, card: Control):
	if locked or not event.is_pressed():
		return
	locked = true
	_setCardsInteractive(false)
	Utilities.onPressed(card)
	optionSelected.emit(option)
