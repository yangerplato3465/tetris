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

