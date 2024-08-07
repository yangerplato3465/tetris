extends Node

# Level vars============
var currentLevel = 1

# Player stat vars============
var visibleNextPiece = 1
var canHoldPiece = false
var singleDamage = 10
var doubleDamage = 30
var tripleDamage = 50
var tetrisDamage = 80
var comboMult = 1.1
var numberStoreItem = 6
var timer = 60
var coin = 10
var hardDropDamage = false
var treasureBox = false
var ocarina = false
var spawnBag = [0,1,2,3,4,5,6,0,1,2,3,4,5,6]
var alchemyArray = []
var equipmentArray = []
var holdPieceDebuff = false

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
var currentEnemy = null;
var coinsSpent = 0
var itemsBought = 0
var linesCleared = 0
var highestCombo = 0
var totalDamageDealt = 0

func _ready():
	pass

func reset(): 
	currentLevel = 1
	visibleNextPiece = 1
	canHoldPiece = false
	singleDamage = 10
	doubleDamage = 30
	tripleDamage = 50
	tetrisDamage = 80
	comboMult = 1.1
	numberStoreItem = 6
	timer = 60
	coin = 50
	hardDropDamage = false
	treasureBox = false
	ocarina = false
	spawnBag = [0,1,2,3,4,5,6,0,1,2,3,4,5,6]
	alchemyArray = Consts.alchemyCommonItems
	equipmentArray = Consts.equipmentCommonItems
	holdPieceDebuff = false

	currentEnemy = null;
	coinsSpent = 0
	itemsBought = 0
	linesCleared = 0
	highestCombo = 0
	totalDamageDealt = 0

func applyUpgrades(id, price):
	coin -= price
	match id:
		0: # Alchemy
			singleDamage += 20
		1:
			doubleDamage += 20
		2:
			tripleDamage += 20
		3:
			tetrisDamage += 20
		4:
			comboMult += 0.1
		5:
			timer += 10
		6:
			singleDamage += 40
		7:
			doubleDamage += 40
		8:
			tripleDamage += 40
		9:
			tetrisDamage += 40
		10:
			timer += 15
		11:
			spawnBag.append_array([0, 0])
		12:
			comboMult += 0.1
		13:
			singleDamage += 30
			doubleDamage += 30
			tripleDamage += 30
			tetrisDamage += 30
		14:
			singleDamage *= 2
		15:
			doubleDamage *= 2
		16:
			tripleDamage *= 2
		17:
			tetrisDamage *= 2
		18:
			comboMult += 0.5
		19: # Equipments
			canHoldPiece = true
			SignalManager.unlockHold.emit(false)
			removeEquipment(19)
		20:
			visibleNextPiece += 1
			SignalManager.unlockNextPiece.emit()
			removeEquipment(20)
		21:
			visibleNextPiece += 1
			SignalManager.unlockNextPiece.emit()
			removeEquipment(21)
		22:
			visibleNextPiece += 1
			SignalManager.unlockNextPiece.emit()
			removeEquipment(22)
		23:
			updateItemArrays(1)
			removeEquipment(23)
		24:
			hardDropDamage = true
			removeEquipment(24)
		25:
			treasureBox = true
			removeEquipment(25)
		26:
			updateItemArrays(2)
			removeEquipment(26)
		27:
			ocarina = true
			removeEquipment(27)

func updateItemArrays(tier):
	match tier:
		1:
			alchemyArray.append_array(Consts.alchemyRareItems)
			equipmentArray.append_array(Consts.equipmentRareItems)
		2:
			alchemyArray.append_array(Consts.alchemyLegendaryItems)
			equipmentArray.append_array(Consts.equipmentLegendaryItems)

func removeEquipment(id):
	for index in range(equipmentArray.size() - 1):
		if equipmentArray[index]["id"] == id:
			equipmentArray.remove_at(index)
	print(equipmentArray)

			
