extends Control

@onready var singleText = $Stats/Single/Number
@onready var doubleText = $Stats/Double/Number
@onready var tripleText = $Stats/Triple/Number
@onready var tetrisText = $Stats/Tetris/Number
@onready var comboMultText = $Stats/ComboMult/Number

func _ready():
	updateUI()
	randomize()

func updateUI():
	singleText.text = str(PlayerManager.singleDamage)
	doubleText.text = str(PlayerManager.doubleDamage)
	tripleText.text = str(PlayerManager.tripleDamage)
	tetrisText.text = str(PlayerManager.tetrisDamage)
	comboMultText.text = str(PlayerManager.comboMult)
