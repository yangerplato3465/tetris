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
@onready var victoryLabel = $VictoryLabel
@onready var rewardLabel = $RewardLabel

@onready var holdLock = $Grid/UI/Hold/TextureRect/Lock
@onready var nextPieceLock2 = $Grid/UI/NextPieces/VBoxContainer/TextureRect2/Lock2
@onready var nextPieceLock3 = $Grid/UI/NextPieces/VBoxContainer/TextureRect3/Lock3
@onready var nextPieceLock4 = $Grid/UI/NextPieces/VBoxContainer/TextureRect4/Lock4
@onready var nextPieceLock5 = $Grid/UI/NextPieces/VBoxContainer/TextureRect5/Lock5
var timerStarted = false

# Battle
@onready var player = $Battle/Player
@onready var enemy = $Battle/Enemy
@onready var animationPlayer = $AnimationPlayer
var currentEnemyHealth = 0
var currentEnemyMaxHealth = 0
var reward = 0
var timerReduction = 0
var damageReductionFlat = 0
var damageReduction = 1
const PLAYER_ORIGINAL_POS = Vector2(729, 230)

func _ready():
	updateUI()
	randomize()
	connectSignals()
	timeLabel.label_settings = LabelSettings.new()
	timeLabel.label_settings.font_size = 80

func connectSignals():
	SignalManager.setStage.connect(setStage)
	SignalManager.stageReady.connect(stageReady)
	# SignalManager.gameoverFromTimer.connect(gameover)
	SignalManager.clearLines.connect(attack)
	SignalManager.unlockHold.connect(unlockHold)
	SignalManager.unlockNextPiece.connect(unlockNextPiece)
	SignalManager.hardDrop.connect(hardDrop)
	timer.timeout.connect(func():
		SignalManager.gameoverFromTimer.emit()
		gameover()
	)

func unlockHold(unlock):
	holdLock.visible = unlock

func unlockNextPiece():
	match PlayerManager.visibleNextPiece:
		2:
			nextPieceLock2.visible = false
		3:
			nextPieceLock3.visible = false
		4:
			nextPieceLock4.visible = false
		5:
			nextPieceLock5.visible = false

			
func setStage(enemyInfo): # Set stage base on enemy abilities and stats
	updateUI()
	reward = enemyInfo.reward
	animationPlayer.play("RESET")
	enemy.frame = enemyInfo.frame
	currentEnemyHealth = enemyInfo.health
	currentEnemyMaxHealth = enemyInfo.health
	enemyHealth.text = str(currentEnemyHealth) + " / " + str(currentEnemyMaxHealth)
	match enemyInfo.id:
		4:
			timerReduction = 10
		5:
			damageReductionFlat = 10
		7:
			timerReduction = 15
		8:
			timerReduction = 10
		9:
			damageReductionFlat = 10
		10:
			damageReductionFlat = 5
			timerReduction = 10
		13:
			timerReduction = 15
		14:
			PlayerManager.holdPieceDebuff = true
			unlockHold(true)
		15:
			damageReductionFlat = 20
		16:
			timerReduction = 15
		17:
			damageReductionFlat = 10
		18:
			damageReductionFlat = 10
			timerReduction = 20
		19:
			PlayerManager.holdPieceDebuff = true
			damageReductionFlat = 10
			unlockHold(true)
		20:
			damageReduction = 0.5
		_:
			timerReduction = 0
			damageReductionFlat = 0
			damageReduction = 1
			PlayerManager.holdPieceDebuff = false
			if(PlayerManager.canHoldPiece):
				unlockHold(false)

	timer.wait_time = PlayerManager.timer - timerReduction
	timeLabel.text = "%d" % timerLeft(true, PlayerManager.timer - timerReduction)


func gameover():
	SignalManager.stopGrid.emit()
	timerStarted = false
	timer.stop()
	set_process(false)

func stageReady():
	set_process(true)
	timer.start()
	timerStarted = true

func _process(delta):
	if timerStarted:
		if timerLeft() < 10:
			timeLabel.label_settings.font_color = Color.RED
		else:
			timeLabel.label_settings.font_color = Color.FLORAL_WHITE
		timeLabel.text = "%d" % timerLeft()

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
	
	return timeLeft

func attack(clearedLines, combo):
	var damageDealt = 0
	attackAnim()
	match clearedLines:
		1:
			damageDealt = PlayerManager.singleDamage
		2:
			damageDealt = PlayerManager.doubleDamage
			if PlayerManager.ocarina:
				var timeLeft = timer.time_left
				timer.stop()
				timer.wait_time = timeLeft + 5
				timer.start()
		3:
			damageDealt = PlayerManager.tripleDamage
		4:
			damageDealt = PlayerManager.tetrisDamage
			if PlayerManager.treasureBox:
				showTreasureboxReward()

	damageDealt = ((damageDealt * pow(PlayerManager.comboMult, combo - 1))- damageReductionFlat) * damageReduction
	PopupNumbers.displayNumber(damageDealt, Vector2(PLAYER_ORIGINAL_POS.x, PLAYER_ORIGINAL_POS.y - 60))
	PlayerManager.totalDamageDealt += damageDealt
	PlayerManager.linesCleared += clearedLines
	if (combo > PlayerManager.highestCombo):
		PlayerManager.highestCombo = combo
	updateEnemyHealth(damageDealt)

func hardDrop():
	if PlayerManager.hardDropDamage:
		var damageDealt = (PlayerManager.singleDamage - damageReductionFlat) * damageReduction
		PopupNumbers.displayNumber(damageDealt, Vector2(PLAYER_ORIGINAL_POS.x, PLAYER_ORIGINAL_POS.y - 60))
		updateEnemyHealth(damageDealt)

func updateEnemyHealth(damageDealt):
	Utilities.shakeNode(enemyHealth, Vector2(862, 85))
	currentEnemyHealth -= damageDealt
	enemyHealth.text = str(Utilities.floorNum(currentEnemyHealth)) + " / " + str(currentEnemyMaxHealth)
	if currentEnemyHealth <= 0:
		victory()

func victory():
	PlayerManager.currentLevel += 1
	animationPlayer.play("EnemyDeath")
	SignalManager.stopGrid.emit()
	showVictory()
	timer.stop()
	set_process(false)

func attackAnim():
	var tween = create_tween()
	tween.finished.connect(func():
		player.position = PLAYER_ORIGINAL_POS
	)
	tween.set_trans(Tween.TRANS_BACK) 
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "position:x", player.position.x + 100, 0.1)
		
func showVictory():
	await get_tree().create_timer(1).timeout
	victoryLabel.scale = Vector2(0.5, 0.5)
	victoryLabel.visible = true
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC) 
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(victoryLabel, "scale", Vector2(1, 1), 1.2)
	tween.finished.connect(func():
		victoryLabel.visible = false
		showReward()
	)

func showReward():
	await get_tree().create_timer(0.7).timeout
	PlayerManager.coin += reward
	var tween = create_tween()
	rewardLabel.scale = Vector2(0.5, 0.5)
	rewardLabel.visible = true
	rewardLabel.text = "+$%d" % reward
	tween.set_trans(Tween.TRANS_ELASTIC) 
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(rewardLabel, "scale", Vector2(1, 1), 2)
	tween.finished.connect(func():
		rewardLabel.visible = false
		SignalManager.victory.emit()
	)

func showTreasureboxReward():
	PlayerManager.coin += 50
	var tween = create_tween()
	rewardLabel.scale = Vector2(0.5, 0.5)
	rewardLabel.visible = true
	rewardLabel.text = "+$%d" % 50
	tween.set_trans(Tween.TRANS_ELASTIC) 
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(rewardLabel, "scale", Vector2(1, 1), 2)
	tween.finished.connect(func():
		rewardLabel.visible = false
	)


