extends Control

@onready var statsContainer = $NinePatchRect/Stats
@onready var statsBlock = preload("res://Scene/Component/Statsblock.tscn")
@onready var enemyName = $NinePatchRect/Enemy
@onready var enemySprite = $NinePatchRect/Enemy/Sprite
@onready var endLabel = $NinePatchRect/Label

var statsToShow = [
	"Level",
	"coins spent",
	"items bought",
	"lines cleared",
	"highest combo",
	"total damage dealt"
]

func _ready():
	SignalManager.setStats.connect(setStats)

func setStats(isWin = false):
	endLabel.text = "you win!!" if isWin else "Game over!"
	if isWin:
		enemyName.text = "you defeated:\n" + PlayerManager.currentEnemy.name
	else:
		enemyName.text = "defeated by:\n" + PlayerManager.currentEnemy.name
	enemySprite.frame = PlayerManager.currentEnemy.frame
	for stat in statsToShow:
		var block = statsBlock.instantiate()
		var num = 0
		match stat:
			"Level":
				if PlayerManager.currentLevel > 15:
					num = 15
				else:
					num = PlayerManager.currentLevel
			"coins spent":
				num = PlayerManager.coinsSpent
			"items bought":
				num = PlayerManager.itemsBought
			"lines cleared":
				num = PlayerManager.linesCleared
			"highest combo":
				num = PlayerManager.highestCombo
			"total damage dealt":
				num = PlayerManager.totalDamageDealt
		block.find_child("StatName").text = stat
		block.find_child("StatNum").text = str(num)
		statsContainer.add_child(block)
