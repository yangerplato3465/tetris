extends Control

# UI
@onready var singleText = $Stats/Single/Number
@onready var doubleText = $Stats/Double/Number
@onready var tripleText = $Stats/Triple/Number
@onready var tetrisText = $Stats/Tetris/Number
@onready var comboMultText = $Stats/ComboMult/Number

@onready var timeLabel = $Timer/TimeLabel
@onready var timer = $Timer/Timer
@onready var enemyHealth = $EnemyHealth
var timerStarted = false

# Battle
@onready var player = $Battle/Player
@onready var enemy = $Battle/Enemy
@onready var animationPlayer = $AnimationPlayer
var currentEnemyHealth = 0
var currentEnemyMaxHealth = 0
const PLAYER_ORIGINAL_POS = Vector2(729, 230)

func _ready():
	updateUI()
	randomize()
	connectSignals()

func connectSignals():
	SignalManager.setStage.connect(setStage)
	SignalManager.stageReady.connect(stageReady)
	SignalManager.gameoverFromTimer.connect(gameover)
	SignalManager.clearLines.connect(attack)
	timer.timeout.connect(func():
		SignalManager.gameoverFromTimer.emit()
		gameover()
	)

func setStage(enemyInfo):
	timer.wait_time = PlayerManager.timer
	timeLabel.text = "%02d:%02d" % timerLeft(true, PlayerManager.timer)
	enemy.frame = enemyInfo.frame
	currentEnemyHealth = enemyInfo.health
	currentEnemyMaxHealth = enemyInfo.health
	enemyHealth.text = str(currentEnemyHealth) + " / " + str(currentEnemyMaxHealth)

func gameover():
	set_process(false)

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

func attack(clearedLines, combo):
	var damageDealt = 0
	attackAnim()
	match clearedLines:
		1:
			damageDealt = PlayerManager.singleDamage
		2:
			damageDealt = PlayerManager.doubleDamage
		3:
			damageDealt = PlayerManager.tripleDamage
		4:
			damageDealt = PlayerManager.tetrisDamage
	damageDealt = damageDealt * pow(PlayerManager.comboMult, combo)
	PopupNumbers.displayNumber(damageDealt, Vector2(PLAYER_ORIGINAL_POS.x, PLAYER_ORIGINAL_POS.y - 60))
	updateEnemyHealth(damageDealt)

func updateEnemyHealth(damageDealt):
	currentEnemyHealth -= damageDealt
	enemyHealth.text = str(currentEnemyHealth) + " / " + str(currentEnemyMaxHealth)
	if currentEnemyHealth <= 0:
		victory()

func victory():
	animationPlayer.play("EnemyDeath")

func attackAnim():
	var tween = create_tween()
	tween.finished.connect(func():
		player.position = PLAYER_ORIGINAL_POS
	)
	tween.set_trans(Tween.TRANS_BACK) 
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "position:x", player.position.x + 100, 0.1)


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "EnemyDeath":
		animationPlayer.play("RESET")
		PlayerManager.currentLevel += 1
		SignalManager.victory.emit()
