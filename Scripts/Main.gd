extends Control

# UI
@onready var singleText = $Stats/Single/Number
@onready var doubleText = $Stats/Double/Number
@onready var tripleText = $Stats/Triple/Number
@onready var tetrisText = $Stats/Tetris/Number
@onready var comboMultText = $Stats/ComboMult/Number

@onready var timeLabel = $Timer/TimeLabel
@onready var timer = $Timer/Timer
var timerStarted = false

# Battle
@onready var player = $Battle/Player
@onready var enemy = $Battle/Enemy

func _ready():
	updateUI()
	randomize()
	SignalManager.setStage.connect(setStage)
	SignalManager.stageReady.connect(stageReady)

func setStage(enemyInfo):
	timer.wait_time = enemyInfo.time
	print("%02d:%02d" % timerLeft(true, enemyInfo.time))
	timeLabel.text = "%02d:%02d" % timerLeft(true, enemyInfo.time)
	enemy.frame = enemyInfo.frame

func stageReady():
	timer.start()
	timerStarted = true

func _process(delta):
	if timerStarted:
		timeLabel.text = "%02d:%02d" % timerLeft()

func updateUI():
	singleText.text = str(PlayerManager.singleDamage)
	doubleText.text = str(PlayerManager.doubleDamage)
	tripleText.text = str(PlayerManager.tripleDamage)
	tetrisText.text = str(PlayerManager.tetrisDamage)
	comboMultText.text = str(PlayerManager.comboMult)

func timerLeft(isInit = false, initTime = 30):
	var timeLeft
	if isInit:
		timeLeft = initTime
	else:
		timeLeft = timer.time_left
	var minute = floor(timeLeft / 60)
	var second = int(timeLeft) % 60
	return [minute, second]
