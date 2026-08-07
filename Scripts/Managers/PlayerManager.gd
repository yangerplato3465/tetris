extends Node

signal unlockHold(unlock)
signal unlockNextPiece

# Level vars============
var currentLevel = 1

# Player stat vars============
var visibleNextPiece
var canHoldPiece
var comboMult
var numberStoreItem
var coin
var hardDropDamage
var treasureBox
var fireBlocks
var poisonBlocks
var goldBlocks
var pendingElementalBonus
var pendingGoldCoins
var magicMeter
var maxMagicMeter
var spawnBag
var ownedKeepsakes   # Array of keepsake ids bought this run
var holdPieceDebuff
var shieldNum
var playerHealth
var maxPlayerHealth
var characterClass
var nextPiecePoison

# Ability vars============
const ABILITY_SLOTS = 5
var equippedAbilities   # Array of ABILITY_SLOTS ability ids in slot order ("" = empty)
var abilityState        # Dictionary[id] -> mutable ability data (text/cost/value)

var startGrid = [
	[0,0,0,0,0,  0,0,0,0,0,  0,0,0,0,0,  0,0,0,0,0,  0,0,0],
	[0,0,0,0,0,  0,0,0,0,0,  0,0,0,0,0,  0,0,0,0,0,  0,0,0],
	[0,0,0,0,0,  0,0,0,0,0,  0,0,0,0,0,  0,0,0,0,0,  0,0,0],
	[0,0,0,0,0,  0,0,0,0,0,  0,0,0,0,0,  0,0,0,0,0,  0,0,0],
	[0,0,0,0,0,  0,0,0,0,0,  0,0,0,0,0,  0,0,0,0,0,  0,0,0],
	[0,0,0,0,0,  0,0,0,0,0,  0,0,0,0,0,  0,0,0,0,0,  0,0,0],
	[0,0,0,0,0,  0,0,0,0,0,  0,0,0,0,0,  0,0,0,0,0,  0,0,0],
	[0,0,0,0,0,  0,0,0,0,0,  0,0,0,0,0,  0,0,0,0,0,  0,0,0],
	[0,0,0,0,0,  0,0,0,0,0,  0,0,0,0,0,  0,0,0,0,0,  0,0,0],
	[0,0,0,0,0,  0,0,0,0,0,  0,0,0,0,0,  0,0,0,0,0,  0,0,0],
]

# End stats
var currentEnemy
var coinsSpent
var itemsBought
var linesCleared
var highestCombo
var totalDamageDealt

func _ready():
	_setDefaults()

func _setDefaults():
	visibleNextPiece = 1
	canHoldPiece = false
	comboMult = 1.1
	numberStoreItem = 6
	coin = 50
	hardDropDamage = false
	treasureBox = false
	fireBlocks = false
	poisonBlocks = false
	goldBlocks = false
	pendingElementalBonus = 0
	pendingGoldCoins = 0
	magicMeter = 0
	maxMagicMeter = 5
	spawnBag = [0,1,2,3,4,5,6,0,1,2,3,4,5,6]
	ownedKeepsakes = []
	holdPieceDebuff = false
	shieldNum = 0
	playerHealth = 100
	maxPlayerHealth = 100
	characterClass = "weaver"
	nextPiecePoison = false
	_initAbilities()
	currentEnemy = null
	coinsSpent = 0
	itemsBought = 0
	linesCleared = 0
	highestCombo = 0
	totalDamageDealt = 0

func reset():
	currentLevel = 1
	_setDefaults()

# --- Abilities ---

func _initAbilities():
	# Mutable dictionary copies of the static AbilityData definitions so a run can
	# retext/upgrade abilities (see updateAbility) without touching Consts.abilities.
	abilityState = {}
	for id in Consts.abilities:
		abilityState[id] = Consts.abilities[id].to_dict()
	# Fixed-size slot array: "" marks an empty slot. The first slots are filled
	# with the class's starting abilities; the rest start empty for drafting.
	equippedAbilities = []
	for _i in ABILITY_SLOTS:
		equippedAbilities.append("")
	var character = getCharacter(characterClass)
	if character:
		var starting = character.startingAbilities
		for i in mini(starting.size(), ABILITY_SLOTS):
			equippedAbilities[i] = starting[i]

# Lock in the chosen class at character select. Sets the energy cap from the
# character (maxEnergy) and re-equips that class's starting abilities — the
# defaults set in _setDefaults are for the placeholder class, so without this
# every class would start with the default class's kit and energy cap.
func selectCharacter(id: String):
	characterClass = id
	_initAbilities()
	var character = getCharacter(id)
	if character:
		maxMagicMeter = character.maxEnergy
	magicMeter = 0

func getCharacter(id: String) -> CharacterData:
	for character in Consts.characters:
		if character.id == id:
			return character
	return null

func getAbility(id: String) -> Dictionary:
	return abilityState.get(id, {})

func getEquippedAbilities() -> Array:
	# Non-empty equipped ability data (skips empty slots).
	var result = []
	for id in equippedAbilities:
		if abilityState.has(id):
			result.append(abilityState[id])
	return result

func getAbilitySlots() -> Array:
	# One entry per slot in order; empty slots are {}.
	var slots = []
	for id in equippedAbilities:
		slots.append(abilityState.get(id, {}))
	return slots

func getEquippedAbilityAt(slot: int) -> Dictionary:
	if slot < 0 or slot >= equippedAbilities.size():
		return {}
	return abilityState.get(equippedAbilities[slot], {})

func setEquippedAbility(slot: int, id: String):
	if slot >= 0 and slot < equippedAbilities.size() and abilityState.has(id):
		equippedAbilities[slot] = id

func swapAbilitySlots(a: int, b: int):
	# Swap two slots' contents. Works with empty ("") slots, so dragging onto an
	# empty slot moves the ability and onto a filled slot swaps the two.
	var n = equippedAbilities.size()
	if a >= 0 and a < n and b >= 0 and b < n:
		var tmp = equippedAbilities[a]
		equippedAbilities[a] = equippedAbilities[b]
		equippedAbilities[b] = tmp

func updateAbility(id: String, fields: Dictionary):
	# Merge changed fields (name/cost/costLabel/value/description) into the
	# runtime ability so the upgrade system can update its displayed text.
	if abilityState.has(id):
		for key in fields:
			abilityState[id][key] = fields[key]

func getCharacterDescription(charId: String) -> String:
	# Built from current ability state so it reflects switches/upgrades.
	var character = getCharacter(charId)
	if character == null:
		return ""
	var lines = [character.tagline, ""]
	var slot = 1
	for abilityId in character.startingAbilities:
		var ability = abilityState.get(abilityId, {})
		if ability.is_empty():
			continue
		lines.append("[%d] %s %s" % [slot, str(ability.name).rpad(14), ability.costLabel])
		slot += 1
	return "\n".join(lines)

# --- Keepsakes ---

func addKeepsake(keepsake: KeepsakeData):
	# Pay for a keepsake and apply its data-driven effects (see KeepsakeData
	# for the schema). Owned keepsakes are excluded from future shop rolls.
	coin -= keepsake.price
	ownedKeepsakes.append(keepsake.id)
	for desc in keepsake.effects:
		applyKeepsakeEffect(desc)

func applyKeepsakeEffect(desc: Dictionary):
	match desc.type:
		"combo_mult":
			comboMult += desc.amount
		"max_hp":
			maxPlayerHealth += desc.amount
			playerHealth += desc.amount
		"heal":
			playerHealth = mini(playerHealth + desc.amount, maxPlayerHealth)
		"max_magic":
			maxMagicMeter += desc.amount
		"unlock_hold":
			canHoldPiece = true
			unlockHold.emit(false)
		"next_piece":
			visibleNextPiece += desc.get("amount", 1)
			unlockNextPiece.emit()
		"hard_drop_damage":
			hardDropDamage = true
		"treasure_box":
			treasureBox = true
		"fire_blocks":
			fireBlocks = true
		"poison_blocks":
			poisonBlocks = true
		"gold_blocks":
			goldBlocks = true
		_:
			push_warning("PlayerManager: unknown keepsake effect '%s'" % desc.type)
