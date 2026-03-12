extends Node

signal unlockHold(unlock)
signal unlockNextPiece

# Level vars============
var currentLevel = 1

# Player stat vars============
var visibleNextPiece
var canHoldPiece
var singleDamage
var doubleDamage
var tripleDamage
var tetrisDamage
var comboMult
var numberStoreItem
var coin
var hardDropDamage
var treasureBox
var fireBlocks
var poisonBlocks
var pendingElementalBonus
var spawnBag
var alchemyArray
var equipmentArray
var holdPieceDebuff
var shieldNum
var maxShieldNum

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
	singleDamage = 10
	doubleDamage = 30
	tripleDamage = 50
	tetrisDamage = 80
	comboMult = 1.1
	numberStoreItem = 6
	coin = 50
	hardDropDamage = false
	treasureBox = false
	fireBlocks = false
	poisonBlocks = false
	pendingElementalBonus = 0
	spawnBag = [0,1,2,3,4,5,6,0,1,2,3,4,5,6]
	alchemyArray = Consts.alchemyCommonItems
	equipmentArray = Consts.equipmentCommonItems
	holdPieceDebuff = false
	shieldNum = 0
	maxShieldNum = 100
	currentEnemy = null
	coinsSpent = 0
	itemsBought = 0
	linesCleared = 0
	highestCombo = 0
	totalDamageDealt = 0

func reset():
	currentLevel = 1
	_setDefaults()

func _initUpgradeEffects():
	_upgrade_effects = {
		0:  func(): singleDamage += 20,
		1:  func(): doubleDamage += 20,
		2:  func(): tripleDamage += 20,
		3:  func(): tetrisDamage += 20,
		4:  func(): comboMult += 0.1,
		6:  func(): singleDamage += 40,
		7:  func(): doubleDamage += 40,
		8:  func(): tripleDamage += 40,
		9:  func(): tetrisDamage += 40,
		11: func(): spawnBag.append_array([0, 0]),
		12: func(): comboMult += 0.1,
		13: func(): _applyAllDamage(30),
		14: func(): singleDamage *= 2,
		15: func(): doubleDamage *= 2,
		16: func(): tripleDamage *= 2,
		17: func(): tetrisDamage *= 2,
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
	}

func applyUpgrades(id: int, price: int):
	coin -= price
	if _upgrade_effects.has(id):
		_upgrade_effects[id].call()

func _applyAllDamage(amount: int):
	singleDamage += amount
	doubleDamage += amount
	tripleDamage += amount
	tetrisDamage += amount

func _applyUnlockHold():
	canHoldPiece = true
	unlockHold.emit(false)
	removeEquipment(Consts.UpgradeID.OLD_KEY)

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

			
