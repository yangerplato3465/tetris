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
var damageMult = 1
var comboMult = 1.1
var numberStoreItem = 6
var timer = 60
var hardDropDamage = false
var treasureBox = false
var ocarina = false
var spawnBag = [0,1,2,3,4,5,6]

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
var coin = 10

func _ready():
	pass

func reset(): 
	visibleNextPiece = 1
	canHoldPiece = false
	singleDamage = 10
	doubleDamage = 30
	tripleDamage = 50
	tetrisDamage = 80
	damageMult = 1
	comboMult = 1.1
	numberStoreItem = 6
	timer = 60
	coin = 10
	hardDropDamage = false
	treasureBox = false
	ocarina = false

func applyUpgrades(id, price):
	coin -= price
	match id:
		0:
			singleDamage += 10
		1:
			doubleDamage += 20
		2:
			tripleDamage += 30
		3:
			tetrisDamage += 50
		4:
			comboMult += 0.1
		5:
			timer += 5
		6:
			singleDamage += 20
		7:
			doubleDamage += 40
		8:
			tripleDamage += 60
		9:
			tetrisDamage += 100
		10:
			spawnBag.append(1)
		11:
			pass # crit
		12:
			singleDamage += 30
			doubleDamage += 30
			tripleDamage += 30
			tetrisDamage += 30
		13:
			singleDamage *= 2
		14:
			doubleDamage *= 2
		15:
			tripleDamage *= 2
		16:
			tetrisDamage *= 2
		17:
			canHoldPiece = true
		18:
			visibleNextPiece += 1
		19:
			hardDropDamage = true
		20:
			treasureBox = true
		21:
			ocarina = true
			
