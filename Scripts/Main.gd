extends Control

signal stage_victory
signal stage_gameover

# UI
@onready var comboMultText = $Stats/ComboMult/Number
@onready var shieldText = $Stats/Shield/Number

@onready var enemyHealth = $EnemyHealth
@onready var victoryLabel = $VictoryLabel
@onready var rewardLabel = $RewardLabel
@onready var enemyAttackTimer = $EnemyAttackBar/EnemyAttackTimer
@onready var enemyAttackBar = $EnemyAttackBar/ProgressBar
@onready var playerHealthLabel = $PlayerHealthLabel
var enemyAttackInterval = 10.0
var enemyAttackDamage = 20
var enemyAttackAddsGarbage = false

@onready var holdLock = $Grid/UI/Hold/TextureRect/Lock
@onready var nextPieceLock2 = $Grid/UI/NextPieces/VBoxContainer/TextureRect2/Lock2
@onready var nextPieceLock3 = $Grid/UI/NextPieces/VBoxContainer/TextureRect3/Lock3
@onready var nextPieceLock4 = $Grid/UI/NextPieces/VBoxContainer/TextureRect4/Lock4
@onready var nextPieceLock5 = $Grid/UI/NextPieces/VBoxContainer/TextureRect5/Lock5
# Battle
@onready var player = $Battle/Player
@onready var enemy = $Battle/Enemy
@onready var animationPlayer = $AnimationPlayer
var currentEnemyHealth = 0
var currentEnemyMaxHealth = 0
var reward = 0
var damageReductionFlat = 0
var damageReduction = 1
var _enemyFlashing = false
var _playerFlashing = false
const PLAYER_ORIGINAL_POS = Vector2(729, 230)
const ENEMY_ORIGINAL_POS = Vector2(1019, 236)

func _ready():
	updateUI()
	randomize()
	connectSignals()

func connectSignals():
	$Grid.clearLines.connect(attack)
	$Grid.hardDrop.connect(hardDrop)
	$Grid.shieldChanged.connect(updateShieldUI)
	PlayerManager.unlockHold.connect(unlockHold)
	PlayerManager.unlockNextPiece.connect(unlockNextPiece)
	enemyAttackTimer.timeout.connect(enemyAttack)
	$Grid.grid_gameover.connect(gameover)

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
	enemyAttackInterval = enemyInfo.attackInterval
	enemyAttackDamage = enemyInfo.attackDamage
	enemyAttackAddsGarbage = enemyInfo.attackAddsGarbage
	match enemyInfo.id:
		5:
			damageReductionFlat = 5
		9:
			damageReductionFlat = 15
		10:
			damageReductionFlat = 10
		14:
			PlayerManager.holdPieceDebuff = true
			unlockHold(true)
		15:
			damageReductionFlat = 20
		17:
			damageReductionFlat = 10
		18:
			damageReductionFlat = 15
		19:
			PlayerManager.holdPieceDebuff = true
			damageReductionFlat = 10
			unlockHold(true)
		20:
			damageReduction = 0.5
		_:
			damageReductionFlat = 0
			damageReduction = 1
			PlayerManager.holdPieceDebuff = false
			if(PlayerManager.canHoldPiece):
				unlockHold(false)


func _process(_delta):
	if enemyAttackTimer.is_stopped():
		return
	var timeLeft = enemyAttackTimer.time_left
	enemyAttackBar.value = enemyAttackInterval - timeLeft
	if timeLeft <= 2.0:
		var pulse = abs(sin(Time.get_ticks_msec() * 0.008))
		enemyAttackBar.modulate = Color(1.0, pulse * 0.35, pulse * 0.1)
		if not _enemyFlashing:
			enemy.self_modulate = Color(1.0, 0.55 + pulse * 0.45, 0.55 + pulse * 0.45)
	else:
		enemyAttackBar.modulate = Color.WHITE
		if not _enemyFlashing:
			enemy.self_modulate = Color.WHITE

func gameover():
	enemyAttackTimer.stop()
	$Grid.stopGrid()
	stage_gameover.emit()

func stageReady():
	enemyAttackBar.max_value = enemyAttackInterval
	enemyAttackBar.modulate = Color.WHITE
	enemy.self_modulate = Color.WHITE
	player.self_modulate = Color.WHITE
	enemyAttackTimer.start(enemyAttackInterval)

func updateUI():
	comboMultText.text = str(PlayerManager.comboMult)
	updateShieldUI()
	updatePlayerHealthUI()

func updatePlayerHealthUI():
	playerHealthLabel.text = "HP: %d / %d" % [PlayerManager.playerHealth, PlayerManager.maxPlayerHealth]

func updateShieldUI():
	shieldText.text = str(PlayerManager.shieldNum) + " / " + str(PlayerManager.maxShieldNum)

func attack(clearedLines, combo):
	attackAnim()
	var damageDealt = clearedLines * 10
	if clearedLines == 4 and PlayerManager.treasureBox:
		showTreasureboxReward()
	match combo:
		1:
			AudioManager.combo_1.play()
		2:
			AudioManager.combo_2.play()
		3:
			AudioManager.combo_3.play()
		4:
			AudioManager.combo_4.play()
		_:
			AudioManager.combo_5.play()

	var elementalBonus = PlayerManager.pendingElementalBonus
	PlayerManager.pendingElementalBonus = 0
	damageDealt = ((damageDealt * pow(PlayerManager.comboMult, combo - 1))- damageReductionFlat) * damageReduction + elementalBonus
	PopupNumbers.displayNumber(damageDealt, Vector2(ENEMY_ORIGINAL_POS.x, ENEMY_ORIGINAL_POS.y - 60))
	const ANNOUNCE_POS = Vector2(620, 160)
	match clearedLines:
		2: PopupNumbers.displayText("DOUBLE!", ANNOUNCE_POS, Color.CYAN)
		3: PopupNumbers.displayText("TRIPLE!", ANNOUNCE_POS, Color.YELLOW)
		4: PopupNumbers.displayText("TETRIS!", ANNOUNCE_POS, Color(1.0, 0.5, 0.0))
	if combo >= 2:
		PopupNumbers.displayText(str(combo) + "x COMBO!", ANNOUNCE_POS + Vector2(0, 70), Color(0.8, 0.3, 1.0))
	PlayerManager.totalDamageDealt += damageDealt
	PlayerManager.linesCleared += clearedLines
	if (combo > PlayerManager.highestCombo):
		PlayerManager.highestCombo = combo
	updateEnemyHealth(damageDealt)

func hardDrop():
	if PlayerManager.hardDropDamage:
		var damageDealt = (20 - damageReductionFlat) * damageReduction
		PopupNumbers.displayNumber(damageDealt, Vector2(ENEMY_ORIGINAL_POS.x, ENEMY_ORIGINAL_POS.y - 60))
		updateEnemyHealth(damageDealt)

func flashEnemy():
	_enemyFlashing = true
	enemy.self_modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(enemy, "self_modulate", Color.WHITE, 0.3)
	tween.finished.connect(func(): _enemyFlashing = false)

func flashPlayer():
	_playerFlashing = true
	player.self_modulate = Color(1.0, 0.2, 0.2)
	var tween = create_tween()
	tween.tween_property(player, "self_modulate", Color.WHITE, 0.4)
	tween.finished.connect(func(): _playerFlashing = false)

func screenShake():
	var tween = create_tween()
	tween.finished.connect(func(): position = Vector2.ZERO)
	for i in 10:
		var intensity = 10.0 * (1.0 - i / 10.0)
		tween.tween_property(self, "position", Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		), 0.04)

func updateEnemyHealth(damageDealt):
	Utilities.shakeNode(enemyHealth, Vector2(862, 85))
	flashEnemy()
	currentEnemyHealth -= damageDealt
	enemyHealth.text = str(Utilities.floorNum(currentEnemyHealth)) + " / " + str(currentEnemyMaxHealth)
	if currentEnemyHealth <= 0:
		victory()

func enemyAttack():
	var overflow = enemyAttackDamage - PlayerManager.shieldNum
	PlayerManager.shieldNum = maxi(PlayerManager.shieldNum - enemyAttackDamage, 0)
	if overflow > 0:
		PlayerManager.playerHealth -= 1
	flashPlayer()
	screenShake()
	updateShieldUI()
	updatePlayerHealthUI()
	if enemyAttackAddsGarbage:
		$Grid.addGarbageRows(1)
	if PlayerManager.playerHealth <= 0:
		gameover()
		return
	enemyAttackTimer.start(enemyAttackInterval)

func victory():
	enemyAttackTimer.stop()
	PlayerManager.currentLevel += 1
	animationPlayer.play("EnemyDeath")
	$Grid.stopGrid()
	showVictory()

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
	AudioManager.victory.play()
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
	AudioManager.kaching.play()
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
		stage_victory.emit()
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
