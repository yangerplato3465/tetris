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
var alchemyArray
var equipmentArray
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

var _upgrade_effects: Dictionary = {}

func _ready():
	_setDefaults()
	_initUpgradeEffects()

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
	magicMeter = 5
	maxMagicMeter = 10
	spawnBag = [0,1,2,3,4,5,6,0,1,2,3,4,5,6]
	alchemyArray = Consts.alchemyCommonItems
	equipmentArray = Consts.equipmentCommonItems
	holdPieceDebuff = false
	shieldNum = 0
	playerHealth = 100
	maxPlayerHealth = 100
	characterClass = "wizard"
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
	# Mutable copies of the static definitions so a run can retext/upgrade
	# abilities without mutating Consts.abilities.
	abilityState = Consts.abilities.duplicate(true)
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

func getCharacter(id: String) -> Dictionary:
	for character in Consts.characters:
		if character.id == id:
			return character
	return {}

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
	if character.is_empty():
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

func _initUpgradeEffects():
	_upgrade_effects = {
		4:  func(): comboMult += 0.1,
		11: func(): spawnBag.append_array([0, 0]),
		12: func(): comboMult += 0.2,
		18: func(): comboMult += 0.5,
		19: func(): _applyUnlockHold(),
		20: func(): _applyUnlockNext(20),
		21: func(): _applyUnlockNext(21),
		22: func(): _applyUnlockNext(22),
		23: func(): _applyTierUnlock(1, 23),
		24: func(): hardDropDamage = true; removeEquipment(24),
		25: func(): treasureBox = true; removeEquipment(25),
		26: func(): _applyTierUnlock(2, 26),
		28: func(): fireBlocks = true,
		29: func(): poisonBlocks = true,
		30: func(): goldBlocks = true,
	}

func applyUpgrades(id: int, price: int):
	coin -= price
	if _upgrade_effects.has(id):
		_upgrade_effects[id].call()

func _applyUnlockHold():
	canHoldPiece = true
	unlockHold.emit(false)
	removeEquipment(19)

func _applyUnlockNext(equipment_id: int):
	visibleNextPiece += 1
	unlockNextPiece.emit()
	removeEquipment(equipment_id)

func _applyTierUnlock(tier: int, equipment_id: int):
	_updateItemArrays(tier)
	removeEquipment(equipment_id)

func _updateItemArrays(tier: int):
	match tier:
		1:
			alchemyArray.append_array(Consts.alchemyRareItems)
			equipmentArray.append_array(Consts.equipmentRareItems)
		2:
			alchemyArray.append_array(Consts.alchemyLegendaryItems)
			equipmentArray.append_array(Consts.equipmentLegendaryItems)

func removeEquipment(id: int):
	for index in range(equipmentArray.size()):
		if equipmentArray[index]["id"] == id:
			equipmentArray.remove_at(index)
			return
