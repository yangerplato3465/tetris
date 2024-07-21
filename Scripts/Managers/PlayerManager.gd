extends Node

var health = 30
var maxHealth = 30
var visibleNextPiece = 1
var singleDamage = 10
var doubleDamage = 30
var tripleDamage = 50
var tetrisDamage = 80
var damageMult = 1
var comboMult = 1.2

func _ready():
	pass

func reset(): 
	health = 30
	maxHealth = 30
	visibleNextPiece = 1
	singleDamage = 10
	doubleDamage = 30
	tripleDamage = 50
	tetrisDamage = 80
	damageMult = 1
	comboMult = 1.2

