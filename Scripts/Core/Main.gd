extends Control

signal stage_victory
signal stage_gameover

# UI
@onready var comboMultText = $Stats/ComboMult/Number
@onready var shieldText = $Stats/Shield/Number
@onready var magicMeterText = $Stats/MagicMeter/Number

@onready var enemyHealth = $EnemyHealth
@onready var victoryLabel = $VictoryLabel
@onready var rewardLabel = $RewardLabel
@onready var enemyAttackLabel = $EnemyAttackBar/StepsLabel
@onready var playerHealthLabel = $PlayerHealthLabel
var enemyAttackSteps = 5
var enemyAttackDamage = 20
var enemyAttackAddsGarbage = false
var dropsSinceAttack = 0
var battleActive = false

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
var damageReduction = 1
var _enemyFlashing = false
var _playerFlashing = false
const PLAYER_ORIGINAL_POS = Vector2(729, 230)
const ENEMY_ORIGINAL_POS = Vector2(1019, 236)
const ENERGY_OVERFLOW_DAMAGE = 5 # HP burned per overflowed orb, "overload" passive only
# An enemy's attackDamage is a hit against *shield*, not against HP. Only what
# leaks past the shield touches HP, and it is divided down by this before it
# does. HP is a single pool spent across all 15 floors (nothing refills it but
# Rest, Mend and events), while a long fight can eat a dozen-plus attacks — so
# one leaked hit has to cost single-digit HP for a run to be survivable.
const ATTACK_DAMAGE_PER_HP = 10.0

var _skill_rows: Array = []
# Remaining cooldown per ability slot, counted down in pieces dropped. 0 = ready.
# Reset at the start of each battle; set to the ability's cooldown when cast.
var _slotCooldown: Array[int] = []
# Skill presses recorded this frame, resolved at end-of-frame by _resolvePendingCasts
# so a coincident piece drop has already ticked cooldowns before the cast is decided.
var _pendingCasts: Array[int] = []

func _ready():
	_buildSkillRows()
	_resetCooldowns()
	populateSkillPanel()
	updateUI()
	randomize()
	connectSignals()

# Two skill rows exist in the scene; duplicate the first to build the rest so
# all PlayerManager.ABILITY_SLOTS slots have a matching panel row.
func _buildSkillRows():
	_skill_rows = [$SkillPanel/Skill1, $SkillPanel/Skill2]
	for slot in range(_skill_rows.size(), PlayerManager.ABILITY_SLOTS):
		var row = $SkillPanel/Skill1.duplicate()
		row.name = "Skill%d" % (slot + 1)
		row.get_node("Key").text = "[%d]" % (slot + 1)
		$SkillPanel.add_child(row)
		_skill_rows.append(row)

func connectSignals():
	$Grid.clearLines.connect(attack)
	$Grid.hardDrop.connect(hardDrop)
	$Grid.magicMeterChanged.connect(updateMagicMeterUI)
	$Grid.energyOverflow.connect(onEnergyOverflow)
	PlayerManager.unlockHold.connect(unlockHold)
	PlayerManager.unlockNextPiece.connect(unlockNextPiece)
	$Grid.pieceDropped.connect(onPieceDropped)
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
	populateSkillPanel()
	updateUI()
	reward = enemyInfo.reward
	animationPlayer.play("RESET")
	enemy.frame = enemyInfo.frame
	currentEnemyHealth = enemyInfo.health
	currentEnemyMaxHealth = enemyInfo.health
	enemyHealth.text = str(currentEnemyHealth) + " / " + str(currentEnemyMaxHealth)
	enemyAttackSteps = enemyInfo.attackSteps
	enemyAttackDamage = enemyInfo.attackDamage
	enemyAttackAddsGarbage = enemyInfo.attackAddsGarbage
	dropsSinceAttack = 0
	updateAttackStepsUI()
	# Debuffs now travel with the enemy (see EnemyData). Every stage sets them
	# from the enemy's own data, so nothing leaks from the previous fight.
	damageReduction = enemyInfo.damageReduction
	if enemyInfo.disablesHold:
		PlayerManager.holdPieceDebuff = true
		unlockHold(true)
	else:
		PlayerManager.holdPieceDebuff = false
		if PlayerManager.canHoldPiece:
			unlockHold(false)


# --- Dev helpers (called from the GameplayScene dev panel) ---

func devKillEnemy():
	if battleActive:
		updateEnemyHealth(currentEnemyHealth)

func _input(event):
	if not battleActive:
		return
	# Record the press and resolve it at end-of-frame (see _resolvePendingCasts),
	# rather than casting straight from this event callback — that keeps the cast
	# ordered after any piece dropped on the same frame. Duplicate deferred calls
	# are harmless: the resolver drains and clears the queue.
	for slot in PlayerManager.ABILITY_SLOTS:
		if event.is_action_pressed("skill_%d" % (slot + 1)):
			_pendingCasts.append(slot)
			call_deferred("_resolvePendingCasts")

# End-of-frame cast resolution. By now every piece dropped this frame has run
# _tickCooldowns, so the cast reads the post-tick cooldown. This makes the
# cooldown==1 boundary deterministic and player-favorable: an unlocking drop on
# the same frame as the press lets the cast go through.
func _resolvePendingCasts():
	if not battleActive:
		_pendingCasts.clear()
		return
	for slot in _pendingCasts:
		useSkill(slot)
	_pendingCasts.clear()

func _resetCooldowns():
	_slotCooldown = []
	for _i in PlayerManager.ABILITY_SLOTS:
		_slotCooldown.append(0)
	_pendingCasts.clear() # drop any press left unresolved across a battle boundary

# Mirror the equipped ability slots into the skill panel rows. Slot order maps
# skill_1 -> Skill1, skill_2 -> Skill2, ... Empty slots show a placeholder.
# `costLabel` is stashed as row meta so _updateSkillAvailability can restore it
# after the Cost label is temporarily repurposed to show a cooldown countdown.
func populateSkillPanel():
	for i in _skill_rows.size():
		var row = _skill_rows[i]
		var ability = PlayerManager.getEquippedAbilityAt(i)
		row.visible = true
		if ability.is_empty():
			row.set_meta("cost", 9999) # unaffordable -> dimmed by _updateSkillAvailability
			row.set_meta("costLabel", "")
			row.get_node("Name").text = "—"
			row.get_node("Cost").text = ""
		else:
			row.set_meta("cost", ability.cost)
			row.set_meta("costLabel", ability.costLabel)
			row.get_node("Name").text = ability.name
			row.get_node("Cost").text = ability.costLabel
	_updateSkillAvailability()

# --- Abilities ---

func useSkill(slot: int):
	var ability = PlayerManager.getEquippedAbilityAt(slot)
	if ability.is_empty():
		return
	if _slotCooldown[slot] > 0:
		return
	if PlayerManager.magicMeter < ability.cost:
		return
	# Pay once up front, then run the ability's authored effects in order — so a
	# multi-effect ability is charged for one cast, not one charge per effect.
	PlayerManager.magicMeter -= ability.cost
	updateMagicMeterUI()
	for effect in ability.get("effects", []):
		# Stop if the battle ended part-way through a multi-effect ability: the
		# enemy died on an earlier effect, or self-inflicted garbage topped the
		# player out. Running on would fire victory()/gameover() a second time.
		if not battleActive:
			break
		_applyAbilityEffect(effect)
	# Start the cooldown; onPieceDropped counts it down one per dropped piece.
	_slotCooldown[slot] = ability.get("cooldown", 0)
	_updateSkillAvailability()

# The single place that knows what an ability effect type means. Adding a type
# here is what makes it available to every .tres under Data/Abilities — see the
# vocabulary listed in Scripts/Data/AbilityData.gd.
func _applyAbilityEffect(effect: Dictionary):
	var amount = effect.get("amount", 0)
	match effect.get("type", ""):
		"damage_enemy":
			_dealAbilityDamage(amount)
		# Board danger as a weapon: the fuller the board, the harder it hits.
		# Pairs naturally with an effect that clears afterwards.
		"damage_per_row":
			_dealAbilityDamage(amount * maxi($Grid.occupiedRowCount(), 1))
		# Scales with the combo running *right now*, so it wants to be cast
		# between clears rather than on cooldown.
		"damage_per_combo":
			_dealAbilityDamage(amount * maxi($Grid.combo, 1))
		"shield":
			PlayerManager.shieldNum += amount
			updateShieldUI()
			PopupNumbers.displayText("+%d SHIELD" % amount, Vector2(PLAYER_ORIGINAL_POS.x, PLAYER_ORIGINAL_POS.y - 60), Color(0.4, 0.8, 1.0))
		"heal":
			PlayerManager.playerHealth = mini(PlayerManager.playerHealth + amount, PlayerManager.maxPlayerHealth)
			updatePlayerHealthUI()
			PopupNumbers.displayText("+%d HP" % amount, Vector2(PLAYER_ORIGINAL_POS.x, PLAYER_ORIGINAL_POS.y - 60), Color(0.4, 0.9, 0.4))
		"magic":
			PlayerManager.magicMeter = mini(PlayerManager.magicMeter + amount, PlayerManager.maxMagicMeter)
			updateMagicMeterUI()
			PopupNumbers.displayText("+%d ORB" % amount, Vector2(PLAYER_ORIGINAL_POS.x, PLAYER_ORIGINAL_POS.y - 60), Color(0.8, 0.5, 1.0))
		"clear_rows":
			# Grid.clearBottomRows emits clearLines, which is wired to attack()
			# — so this also deals normal line-clear damage and extends the
			# combo. Price these abilities with that in mind.
			$Grid.clearBottomRows(amount)
		# Unlike clear_rows this one is silent: holyBeam does not emit clearLines,
		# so it deals no damage and does not extend the combo. Pure board relief.
		"holy_beam":
			$Grid.holyBeam()
			PopupNumbers.displayText("HOLY BEAM", Vector2(620, 160), Color(1.0, 0.95, 0.6))
		"purify_garbage":
			$Grid.purifyGarbage()
			PopupNumbers.displayText("PURIFIED", Vector2(620, 160), Color(0.7, 1.0, 0.9))
		"shuffle_rows":
			$Grid.shuffleBottomRows(amount)
			PopupNumbers.displayText("SHUFFLE", Vector2(620, 160), Color(0.9, 0.6, 1.0))
		# Self-inflicted garbage — the cost half of a bargain ability. It can top
		# the player out, which is the risk being paid for.
		"add_garbage":
			$Grid.addGarbageRows(amount)
			PopupNumbers.displayText("+%d GARBAGE" % amount, Vector2(PLAYER_ORIGINAL_POS.x, PLAYER_ORIGINAL_POS.y - 60), Color(0.6, 0.6, 0.6))
		# Retypes the falling piece (see Constants.Elemental). Carried in `element`
		# rather than `amount` so card UI doesn't print the enum as a headline number.
		"enchant_piece":
			$Grid.enchantCurrentPiece(effect.get("element", 0))
		# Banks flat damage onto the next line clear, the same pot fire/poison
		# blocks fill. Setup now, payoff on the clear.
		"charge":
			PlayerManager.pendingElementalBonus += amount
			PopupNumbers.displayText("+%d CHARGED" % amount, Vector2(PLAYER_ORIGINAL_POS.x, PLAYER_ORIGINAL_POS.y - 60), Color(1.0, 0.7, 0.2))
		# Strips the enemy's damage reduction for the rest of the fight. setStage
		# re-reads it from EnemyData, so this never leaks to the next one.
		"cleanse":
			damageReduction = 1
			PopupNumbers.displayText("DISPELLED", Vector2(ENEMY_ORIGINAL_POS.x, ENEMY_ORIGINAL_POS.y - 60), Color(0.6, 1.0, 1.0))
		"delay_attack":
			dropsSinceAttack = maxi(dropsSinceAttack - amount, 0)
			updateAttackStepsUI()
			PopupNumbers.displayText("STASIS", Vector2(ENEMY_ORIGINAL_POS.x, ENEMY_ORIGINAL_POS.y - 60), Color(0.5, 0.8, 1.0))
		_:
			push_warning("Main: unknown ability effect type '%s'" % effect.get("type", ""))

# Shared tail of every damaging ability effect: apply the enemy's reduction,
# never below zero, then animate.
func _dealAbilityDamage(raw: int):
	var damageDealt = maxi(roundi(raw * damageReduction), 0)
	attackAnim()
	PopupNumbers.displayNumber(damageDealt, Vector2(ENEMY_ORIGINAL_POS.x, ENEMY_ORIGINAL_POS.y - 60))
	updateEnemyHealth(damageDealt)

func _process(_delta):
	if not battleActive:
		return
	if enemyAttackSteps - dropsSinceAttack <= 1:
		var pulse = abs(sin(Time.get_ticks_msec() * 0.008))
		enemyAttackLabel.modulate = Color(1.0, pulse * 0.35, pulse * 0.1)
		if not _enemyFlashing:
			enemy.self_modulate = Color(1.0, 0.55 + pulse * 0.45, 0.55 + pulse * 0.45)
	else:
		enemyAttackLabel.modulate = Color.WHITE
		if not _enemyFlashing:
			enemy.self_modulate = Color.WHITE

func gameover():
	battleActive = false
	_updateSkillAvailability()
	$Grid.stopGrid()
	stage_gameover.emit()

func stageReady():
	dropsSinceAttack = 0
	_resetCooldowns()
	updateAttackStepsUI()
	enemyAttackLabel.modulate = Color.WHITE
	enemy.self_modulate = Color.WHITE
	player.self_modulate = Color.WHITE
	battleActive = true
	_updateSkillAvailability()

func updateAttackStepsUI():
	enemyAttackLabel.text = "attack : %d / %d" % [dropsSinceAttack, enemyAttackSteps]

func onPieceDropped():
	if not battleActive:
		return
	dropsSinceAttack += 1
	updateAttackStepsUI()
	_tickCooldowns()
	if dropsSinceAttack >= enemyAttackSteps:
		enemyAttack()

# One dropped piece = one tick off every active cooldown.
func _tickCooldowns():
	var changed = false
	for i in _slotCooldown.size():
		if _slotCooldown[i] > 0:
			_slotCooldown[i] -= 1
			changed = true
	if changed:
		_updateSkillAvailability()

func updateUI():
	comboMultText.text = str(PlayerManager.comboMult)
	updateShieldUI()
	updateMagicMeterUI()
	updatePlayerHealthUI()

func updatePlayerHealthUI():
	playerHealthLabel.text = "HP: %d / %d" % [PlayerManager.playerHealth, PlayerManager.maxPlayerHealth]

func updateShieldUI():
	shieldText.text = str(PlayerManager.shieldNum)

func updateMagicMeterUI():
	magicMeterText.text = str(PlayerManager.magicMeter) + " / " + str(PlayerManager.maxMagicMeter)
	_updateSkillAvailability()

func _updateSkillAvailability():
	for i in _skill_rows.size():
		var row = _skill_rows[i]
		var cost = row.get_meta("cost")
		var cd = _slotCooldown[i] if i < _slotCooldown.size() else 0
		var can_cast = battleActive and cd == 0 and (cost == -1 or PlayerManager.magicMeter >= cost)
		row.modulate = Color.WHITE if can_cast else Color(0.35, 0.35, 0.35, 0.7)
		# While on cooldown the Cost label shows the drops remaining instead of the
		# orb cost (which is moot until the spell is ready again).
		var costNode = row.get_node("Cost")
		if cd > 0:
			costNode.text = "CD %d" % cd
			costNode.add_theme_color_override("font_color", Color(1.0, 0.55, 0.2))
		else:
			costNode.text = row.get_meta("costLabel", "")
			costNode.remove_theme_color_override("font_color")

func attack(clearedLines, combo):
	attackAnim()
	var damageDealt = clearedLines * 100
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
	var goldCoins = PlayerManager.pendingGoldCoins
	PlayerManager.pendingGoldCoins = 0
	if goldCoins > 0:
		PlayerManager.coin += goldCoins
		PopupNumbers.displayText("+$%d" % goldCoins, Vector2(620, 220), Color(1.0, 0.85, 0.0))
	damageDealt = roundi(damageDealt * pow(PlayerManager.comboMult, combo - 1) * damageReduction + elementalBonus)
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
		var damageDealt = roundi(20 * damageReduction)
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
		# Rounded up, so a hit that gets through always costs at least 1 HP —
		# shaving an attack down to a 1-point leak is a win, not a free pass.
		var hpLost = ceili(overflow / ATTACK_DAMAGE_PER_HP)
		PlayerManager.playerHealth -= hpLost
		PopupNumbers.displayText("-%d HP" % hpLost, Vector2(PLAYER_ORIGINAL_POS.x, PLAYER_ORIGINAL_POS.y - 60), Color(1.0, 0.3, 0.3))
	else:
		PopupNumbers.displayText("BLOCKED", Vector2(PLAYER_ORIGINAL_POS.x, PLAYER_ORIGINAL_POS.y - 60), Color(0.4, 0.8, 1.0))
	flashPlayer()
	screenShake()
	updateShieldUI()
	updatePlayerHealthUI()
	if enemyAttackAddsGarbage:
		$Grid.addGarbageRows(1)
	if PlayerManager.playerHealth <= 0:
		gameover()
		return
	dropsSinceAttack = 0
	updateAttackStepsUI()

# The Weaver's "overload" passive: collecting energy orbs while already at the
# cap burns HP directly (shield does not absorb it), one hit per wasted orb.
# Grid always reports the overflow (see Grid.printClearedBlockTypes); classes
# without the passive just waste the orbs silently.
func onEnergyOverflow(count):
	if not PlayerManager.hasPassive("overload"):
		return
	var damage = count * ENERGY_OVERFLOW_DAMAGE
	PlayerManager.playerHealth -= damage
	PopupNumbers.displayText("-%d OVERLOAD" % damage, Vector2(PLAYER_ORIGINAL_POS.x, PLAYER_ORIGINAL_POS.y - 60), Color(1.0, 0.4, 0.3))
	flashPlayer()
	screenShake()
	updatePlayerHealthUI()
	if PlayerManager.playerHealth <= 0:
		gameover()

func victory():
	battleActive = false
	_updateSkillAvailability()
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
