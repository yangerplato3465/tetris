class_name DataValidator
extends RefCounted

# Boot-time checks for the content under Data/. Every .tres is plain data wired
# together by strings — effect types, trigger names, ability ids — and a typo in
# any of them otherwise fails silently: a skipped match branch, a key nobody
# reads, an ability that can never be drafted. Consts and Keepsakes call these
# from _init, so a bad file is a red error on launch instead of a bug found
# mid-run.
#
# Each check reports every problem it finds rather than stopping at the first,
# and returns how many it found. Nothing here stops the game from running.

const RARITIES := ["common", "uncommon", "rare"]
# Keys that must hold a number wherever they appear in an effect descriptor.
const NUMERIC_KEYS := ["amount", "min_lines", "element", "shape", "drops"]
# Keys that must hold text wherever they appear in an event.
const STRING_KEYS := ["id", "title", "start", "body", "text", "result", "next", "locked_text", "speaker", "name", "description", "board", "intent"]
# Keys that must hold text wherever they appear in an effect descriptor.
const EFFECT_STRING_KEYS := ["id", "rarity", "method", "flag"]
const Constants = preload("res://Scripts/Utils/Constants.gd")

static func validateAbilities(abilities: Array) -> int:
	var errors := 0
	for ability in abilities:
		var where := _where(ability)
		errors += _checkIdentity(ability, where)
		if ability.burn and ability.cooldown > 0:
			push_warning("Data: %s sets both burn and cooldown — burn outranks cooldown, so leave cooldown at 0" % where)
		for i in ability.effects.size():
			errors += _checkEffect(ability.effects[i], AbilityData.EFFECT_KEYS, [], "%s effects[%d]" % [where, i])
	return errors

static func validateKeepsakes(keepsakes: Array) -> int:
	var errors := 0
	# Keepsakes validates itself from its own _init, before the autoload is
	# reachable by name — so gain_keepsake ids are checked against this instead.
	var byId := {}
	for keepsake in keepsakes:
		byId[keepsake.id] = keepsake
	for keepsake in keepsakes:
		var where := _where(keepsake)
		errors += _checkIdentity(keepsake, where)
		for i in keepsake.effects.size():
			var desc = keepsake.effects[i]
			var at := "%s effects[%d]" % [where, i]
			if not desc is Dictionary:
				errors += _fail(at, "is not a Dictionary")
				continue
			var trigger = desc.get("trigger", "")
			if not trigger in KeepsakeData.TRIGGERS:
				errors += _fail(at, "has unknown trigger '%s' (expected one of %s)" % [trigger, KeepsakeData.TRIGGERS])
				continue
			# acquire changes run state outside a battle (RunEffects); every other
			# trigger runs through Main._applyAbilityEffect.
			var vocabulary = _acquireVocabulary() if trigger == "acquire" else AbilityData.EFFECT_KEYS
			var extraKeys = ["trigger"]
			if trigger == "line_clear":
				extraKeys.append("min_lines")
			errors += _checkEffect(desc, vocabulary, extraKeys, at, {"keepsakes": byId})
	return errors

static func validateCharacters(characters: Array, abilities: Dictionary) -> int:
	var errors := 0
	for character in characters:
		var where := _where(character)
		if character.id.is_empty():
			errors += _fail(where, "has no id")
		if not character.passive in CharacterData.PASSIVES:
			errors += _fail(where, "has unknown passive '%s'" % character.passive)
		for field in ["abilityPool", "startingAbilities"]:
			for abilityId in character.get(field):
				if not abilities.has(abilityId):
					errors += _fail(where, "%s lists unknown ability id '%s'" % [field, abilityId])
	return errors

# `tiers` maps each Data/Enemies/ folder name to its Array[EnemyData]; each enemy's
# `source` is the authored dictionary checked here.
static func validateEnemies(tiers: Dictionary) -> int:
	var errors := 0
	var seenIds := {}
	var bossFloors := {}
	for tier in tiers:
		for enemy in tiers[tier]:
			var data: Dictionary = enemy.source
			var where: String = enemy.path
			errors += _checkKeys(data, EnemyData.ENEMY_KEYS, where)
			var id = data.get("id", "")
			if id is String and id != "":
				if where.get_file().get_basename() != id:
					errors += _fail(where, "has id '%s', which does not match its filename" % id)
				if seenIds.has(id):
					errors += _fail(where, "reuses enemy id '%s' (also %s)" % [id, seenIds[id]])
				seenIds[id] = where
			for key in ["health", "reward", "frame", "boss_floor"]:
				if data.has(key) and typeof(data[key]) != TYPE_INT:
					errors += _fail(where, "key '%s' must be an integer" % key)
			if data.get("health") is int and data.health <= 0:
				errors += _fail(where, "health must be above 0")
			if data.get("board") is String and not data.board in EnemyData.BOARDS:
				errors += _fail(where, "has unknown board '%s' (expected one of %s)" % [data.board, EnemyData.BOARDS])
			# Boss/ is what makes an enemy a boss; boss_floor is which floor it owns.
			if tier == "Boss":
				if not data.get("boss_floor") is int:
					errors += _fail(where, "is in Boss/ but has no boss_floor")
				elif bossFloors.has(data.boss_floor):
					errors += _fail(where, "shares boss_floor %d with %s" % [data.boss_floor, bossFloors[data.boss_floor]])
				else:
					bossFloors[data.boss_floor] = where
			elif data.has("boss_floor"):
				errors += _fail(where, "has boss_floor but is not in Boss/")
			errors += _checkEffectList(data.get("passives", []), EnemyData.PASSIVE_KEYS, where + " passives")
			errors += _checkEnemyMoves(data, where, enemy.fileScript)
	return errors

# `fileScript` is the enemy file's GDScript, which call moves run a function from.
static func _checkEnemyMoves(data: Dictionary, where: String, fileScript = null) -> int:
	var errors := 0
	var moves = data.get("moves", {})
	if not moves is Dictionary or moves.is_empty():
		return _fail(where, "has no moves")
	for moveId in moves:
		var move = moves[moveId]
		var at := "%s move '%s'" % [where, moveId]
		if not move is Dictionary:
			errors += _fail(at, "is not a Dictionary")
			continue
		errors += _checkKeys(move, EnemyData.MOVE_KEYS, at)
		if typeof(move.get("steps")) != TYPE_INT or move.get("steps") < 1:
			errors += _fail(at, "steps must be an integer of at least 1")
		var effects = move.get("effects", [])
		errors += _checkEffectList(effects, EnemyData.EFFECT_KEYS, at + " effects")
		if effects is Array:
			for j in effects.size():
				if effects[j] is Dictionary:
					errors += _checkEnemyEffectRefs(effects[j], fileScript, "%s effects[%d]" % [at, j])
	var phases = data.get("phases", [])
	if not phases is Array or phases.is_empty():
		return errors + _fail(where, "has no phases")
	var usedMoves := {}
	var threshold := 1.0   # the previous phase's hp_below; each one must go lower
	for i in phases.size():
		var phase = phases[i]
		var at := "%s phases[%d]" % [where, i]
		if not phase is Dictionary:
			errors += _fail(at, "is not a Dictionary")
			continue
		errors += _checkKeys(phase, EnemyData.PHASE_KEYS, at)
		# EnemyBrain uses the last phase whose hp_below HP is under, so the opening
		# phase needs none and the rest must step down in order.
		if i == 0:
			if phase.has("hp_below"):
				errors += _fail(at, "is the opening phase and can't have hp_below")
		elif not phase.has("hp_below"):
			errors += _fail(at, "needs hp_below (the HP fraction it starts under, e.g. 0.5)")
		elif typeof(phase.hp_below) != TYPE_FLOAT and typeof(phase.hp_below) != TYPE_INT:
			errors += _fail(at, "hp_below must be a number")
		elif phase.hp_below <= 0 or phase.hp_below >= threshold:
			errors += _fail(at, "hp_below must be above 0 and below %s (the phase before it)" % threshold)
		else:
			threshold = phase.hp_below
		var pattern = phase.get("pattern")
		if not pattern is Dictionary:
			errors += _fail(at, "pattern must be a Dictionary")
			continue
		errors += _checkKeys(pattern, EnemyData.PATTERN_KEYS, at + " pattern")
		if pattern.get("type") is String and not pattern.type in EnemyData.PATTERN_TYPES:
			errors += _fail(at, "has unknown pattern type '%s'" % pattern.type)
		var ids = pattern.get("moves", [])
		if not ids is Array or ids.is_empty():
			errors += _fail(at, "pattern needs at least one move")
			continue
		for moveId in ids:
			usedMoves[moveId] = true
			if not moves.has(moveId):
				errors += _fail(at, "pattern names unknown move '%s'" % moveId)
	for moveId in moves:
		if not usedMoves.has(moveId):
			push_warning("Data: %s move '%s' is in no phase's pattern, so it is never used" % [where, moveId])
	return errors

# What an enemy effect's values mean, beyond their keys and types: a whole number
# of drops, a weaken multiplier that can't zero damage out, and a call target the
# enemy's file defines taking the battle as its one argument.
static func _checkEnemyEffectRefs(effect: Dictionary, fileScript, where: String) -> int:
	var errors := 0
	var type = effect.get("type", "")
	var drops = effect.get("drops")
	if (drops is float or drops is int) and (not drops is int or drops < 1):
		errors += _fail(where, "'%s' drops must be a whole number of at least 1" % type)
	var amount = effect.get("amount")
	if type == "weaken" and (amount is float or amount is int) and amount <= 0:
		errors += _fail(where, "'weaken' amount multiplies the player's damage and must be above 0")
	if type == "call" and effect.get("method") is String:
		var methods = fileScript.get_script_method_list().filter(func(m): return m.name == effect.method) if fileScript else []
		if methods.is_empty():
			errors += _fail(where, "calls '%s', which this enemy file does not define" % effect.method)
		elif methods[0].args.size() != 1:
			errors += _fail(where, "calls '%s', which must take exactly one argument: func %s(battle)" % [effect.method, effect.method])
	return errors

# Events are nested dictionaries rather than Resources, so this walks the whole
# tree: event -> pages -> options -> outcomes -> effects/costs. `paths` maps each
# id to the file it came from, for the filename check and error messages.
# `scripts` maps each id to its GDScript (for "call" methods) and `keepsakes` is
# Keepsakes.keepsakes (for gain_keepsake ids).
# `classes` is every character id (for "class" conditions).
static func validateEvents(events: Dictionary, paths: Dictionary, scripts: Dictionary = {}, keepsakes: Dictionary = {}, classes: Array = []) -> int:
	var errors := 0
	# Every flag some event or keepsake sets, so a condition reading a flag nothing
	# sets — almost always a typo — can be flagged.
	var flagsSet := _collectFlagsSet(events, keepsakes)
	for id in events:
		var event = events[id]
		var where: String = paths.get(id, str(id))
		if id == "":
			errors += _fail(where, "has no id")
		elif where.get_file().get_basename() != id:
			errors += _fail(where, "has id '%s', which does not match its filename" % id)
		errors += _checkKeys(event, EventData.EVENT_KEYS, where)
		var refs := {"keepsakes": keepsakes, "script": scripts.get(id), "classes": classes, "flagsSet": flagsSet}
		errors += _checkConditions(event.get("requires", []), refs, where + " requires")
		var pages = event.get("pages", {})
		if not pages is Dictionary or pages.is_empty():
			errors += _fail(where, "has no pages")
			continue
		if not pages.has(event.get("start", "")):
			errors += _fail(where, "has start page '%s', which does not exist" % event.get("start", ""))
		for pageId in pages:
			errors += _checkEventPage(pages[pageId], pages, refs, "%s page '%s'" % [where, pageId])
		for pageId in _unreachablePages(event):
			push_warning("Data: %s page '%s' is never reached from the start page" % [where, pageId])
	return errors

static func _checkEventPage(page, pages: Dictionary, refs: Dictionary, where: String) -> int:
	if not page is Dictionary:
		return _fail(where, "is not a Dictionary")
	var errors := _checkKeys(page, EventData.PAGE_KEYS, where)
	if not page.has("body") and not page.has("lines"):
		errors += _fail(where, "needs a body, lines, or both")
	if page.has("lines"):
		var lines = page.lines
		if not lines is Array or lines.is_empty():
			errors += _fail(where, "has 'lines', which must be a non-empty Array")
		else:
			for i in lines.size():
				var at := "%s lines[%d]" % [where, i]
				if lines[i] is Dictionary:
					errors += _checkKeys(lines[i], EventData.LINE_KEYS, at)
				else:
					errors += _fail(at, "is not a Dictionary")
	var options = page.get("options", [])
	if not options is Array or options.is_empty():
		return errors + _fail(where, "has no options")
	for i in options.size():
		var option = options[i]
		var at := "%s options[%d]" % [where, i]
		if not option is Dictionary:
			errors += _fail(at, "is not a Dictionary")
			continue
		errors += _checkKeys(option, EventData.OPTION_KEYS, at)
		errors += _checkEffectList(option.get("cost", []), EventData.COST_KEYS, at + " cost")
		errors += _checkConditions(option.get("requires", []), refs, at + " requires")
		if option.has("locked_text") and not option.has("requires"):
			errors += _fail(at, "has locked_text but no requires, so it would never be shown")
		if not option.has("outcomes"):
			errors += _checkEventOutcome(option, pages, refs, at)
			continue
		for flat in ["result", "effects", "next"]:
			if option.has(flat):
				errors += _fail(at, "has both 'outcomes' and '%s' — move it into each outcome" % flat)
		var outcomes = option.outcomes
		if not outcomes is Array or outcomes.is_empty():
			errors += _fail(at, "has empty 'outcomes'")
			continue
		for j in outcomes.size():
			var outcome = outcomes[j]
			var oat := "%s outcomes[%d]" % [at, j]
			if not outcome is Dictionary:
				errors += _fail(oat, "is not a Dictionary")
				continue
			errors += _checkKeys(outcome, EventData.OUTCOME_KEYS, oat)
			if typeof(outcome.get("weight")) != TYPE_INT or outcome.get("weight") <= 0:
				errors += _fail(oat, "weight must be a positive integer")
			errors += _checkEventOutcome(outcome, pages, refs, oat)
	return errors

# The parts an option and a weighted outcome share: effects and the next page.
static func _checkEventOutcome(outcome: Dictionary, pages: Dictionary, refs: Dictionary, where: String) -> int:
	var errors := _checkEffectList(outcome.get("effects", []), RunEffects.EFFECT_KEYS, where + " effects", refs)
	var next = outcome.get("next", "")
	if next is String and next != "" and not pages.has(next):
		errors += _fail(where, "has next page '%s', which does not exist in this event" % next)
	return errors

static func _checkEffectList(list, vocabulary: Dictionary, where: String, refs: Dictionary = {}) -> int:
	if not list is Array:
		return _fail(where, "must be an Array")
	var errors := 0
	for i in list.size():
		errors += _checkEffect(list[i], vocabulary, [], "%s[%d]" % [where, i], refs)
	return errors

# A `requires` list: one-key Dictionaries naming a RunConditions.KEYS condition,
# with a value of the right type pointing at something that exists. `refs` may
# carry "keepsakes", "classes" and "flagsSet".
static func _checkConditions(list, refs: Dictionary, where: String) -> int:
	if not list is Array:
		return _fail(where, "must be an Array")
	var errors := 0
	for i in list.size():
		var condition = list[i]
		var at := "%s[%d]" % [where, i]
		if not condition is Dictionary or condition.size() != 1:
			errors += _fail(at, "must be a Dictionary with exactly one key, like {\"min_floor\": 4}")
			continue
		var key = condition.keys()[0]
		if not RunConditions.KEYS.has(key):
			errors += _fail(at, "has unknown condition '%s'" % key)
			continue
		var value = condition[key]
		if typeof(value) != RunConditions.KEYS[key]:
			errors += _fail(at, "'%s' must be of type %s" % [key, type_string(RunConditions.KEYS[key])])
			continue
		match key:
			"has_keepsake", "lacks_keepsake":
				if refs.has("keepsakes") and not refs.keepsakes.is_empty() and not refs.keepsakes.has(value):
					errors += _fail(at, "'%s' names unknown keepsake id '%s'" % [key, value])
			"class":
				if not refs.get("classes", []).is_empty() and not value in refs.classes:
					errors += _fail(at, "names unknown class '%s'" % value)
			"flag", "not_flag":
				if refs.has("flagsSet") and not refs.flagsSet.has(value):
					push_warning("Data: %s reads flag '%s', which no event or keepsake sets (fine if a custom function does)" % [at, value])
	return errors

# Every flag name a set_flag effect writes, across all events and keepsakes.
static func _collectFlagsSet(events: Dictionary, keepsakes: Dictionary) -> Dictionary:
	var effectLists := []
	for keepsake in keepsakes.values():
		effectLists.append(keepsake.effects)
	for event in events.values():
		var pages = event.get("pages", {})
		if not pages is Dictionary:
			continue
		for page in pages.values():
			if not page is Dictionary or not page.get("options") is Array:
				continue
			for option in page.options:
				if not option is Dictionary:
					continue
				var outcomes = option.get("outcomes", [option])
				if not outcomes is Array:
					continue
				for outcome in outcomes:
					if outcome is Dictionary and outcome.get("effects") is Array:
						effectLists.append(outcome.effects)
	var flags := {}
	for list in effectLists:
		for desc in list:
			if desc is Dictionary and desc.get("type") == "set_flag" and desc.get("flag") is String:
				flags[desc.flag] = true
	return flags

# The acquire trigger's vocabulary: RunEffects minus the types that need an event.
static func _acquireVocabulary() -> Dictionary:
	var vocabulary = RunEffects.EFFECT_KEYS.duplicate()
	for type in RunEffects.EVENT_ONLY:
		vocabulary.erase(type)
	return vocabulary

# Beyond key shape: what an effect points at must exist. Runs for every effect in
# every vocabulary; each check only applies where its key or type appears.
# `refs` may carry "keepsakes" (id -> KeepsakeData) and "script" (the event's GDScript).
static func _checkEffectRefs(desc: Dictionary, refs: Dictionary, where: String) -> int:
	var errors := 0
	var type = desc.get("type", "")
	var shapeCount = Constants.SHAPES.size()
	if desc.get("shape") is int and (desc.shape < 0 or desc.shape >= shapeCount):
		errors += _fail(where, "'%s' shape %d is out of range (0-%d, see Constants.SHAPES)" % [type, desc.shape, shapeCount - 1])
	if type == "gain_keepsake" and refs.has("keepsakes") and desc.get("id") is String and not refs.keepsakes.has(desc.id):
		errors += _fail(where, "gains unknown keepsake id '%s'" % desc.id)
	if type == "gain_random_keepsake" and desc.get("rarity") is String and not desc.rarity in RARITIES:
		errors += _fail(where, "has unknown rarity '%s'" % desc.rarity)
	# Events only: enemy call moves are checked by _checkEnemyEffectRefs, against the enemy's file.
	if type == "call" and refs.has("script") and desc.get("method") is String:
		var script = refs.get("script")
		if script == null or not script.get_script_method_list().any(func(m): return m.name == desc.method):
			errors += _fail(where, "calls '%s', which this event file does not define" % desc.method)
	return errors

# Pages no chain of "next" links reaches from "start". Not an error — a page can
# be parked while being written — so validateEvents only warns.
static func _unreachablePages(event: Dictionary) -> Array:
	var pages = event.get("pages", {})
	var seen := {}
	var queue := [event.get("start", "")]
	while not queue.is_empty():
		var pageId = queue.pop_back()
		if seen.has(pageId) or not pages.has(pageId) or not pages[pageId] is Dictionary:
			continue
		seen[pageId] = true
		for option in pages[pageId].get("options", []):
			if not option is Dictionary:
				continue
			var targets = option.get("outcomes", [option])
			if not targets is Array:
				continue
			for target in targets:
				if target is Dictionary and target.get("next", "") is String:
					queue.append(target.get("next", ""))
	return pages.keys().filter(func(p): return not seen.has(p))

# Required/optional/unexpected keys for a dictionary whose shape is a flat key
# list ("?" = optional), plus a type check on the keys that must hold text.
static func _checkKeys(dict: Dictionary, specs: Array, where: String) -> int:
	var errors := 0
	var allowed := []
	for spec in specs:
		var key = spec.trim_suffix("?")
		allowed.append(key)
		if not spec.ends_with("?") and not dict.has(key):
			errors += _fail(where, "is missing required key '%s'" % key)
	for key in dict:
		if not key in allowed:
			errors += _fail(where, "has unexpected key '%s'" % key)
		elif key in STRING_KEYS and typeof(dict[key]) != TYPE_STRING:
			errors += _fail(where, "key '%s' must be a String" % key)
	return errors

# id present and matching the filename (CLAUDE.md: each file is named for its id),
# and a rarity from the shared tiers.
static func _checkIdentity(res, where: String) -> int:
	var errors := 0
	if res.id.is_empty():
		errors += _fail(where, "has no id")
	elif res.resource_path.get_file().get_basename() != res.id:
		errors += _fail(where, "has id '%s', which does not match its filename" % res.id)
	if not res.rarity in RARITIES:
		errors += _fail(where, "has unknown rarity '%s'" % res.rarity)
	return errors

# `vocabulary` maps type -> keys that type reads ("?" suffix = optional).
# `extraKeys` are keys the caller consumes itself (a keepsake's trigger).
static func _checkEffect(desc, vocabulary: Dictionary, extraKeys: Array, where: String, refs: Dictionary = {}) -> int:
	if not desc is Dictionary:
		return _fail(where, "is not a Dictionary")
	var type = desc.get("type", "")
	if not vocabulary.has(type):
		return _fail(where, "has unknown effect type '%s'" % type)
	var errors := 0
	var allowed = extraKeys.duplicate()
	allowed.append("type")
	for spec in vocabulary[type]:
		var key = spec.trim_suffix("?")
		allowed.append(key)
		if not spec.ends_with("?") and not desc.has(key):
			errors += _fail(where, "'%s' is missing required key '%s'" % [type, key])
	for key in desc:
		if not key in allowed:
			errors += _fail(where, "'%s' has unexpected key '%s'" % [type, key])
		elif key in NUMERIC_KEYS and typeof(desc[key]) != TYPE_INT and typeof(desc[key]) != TYPE_FLOAT:
			errors += _fail(where, "'%s' key '%s' must be a number" % [type, key])
		elif key in EFFECT_STRING_KEYS and typeof(desc[key]) != TYPE_STRING:
			errors += _fail(where, "'%s' key '%s' must be a String" % [type, key])
	return errors + _checkEffectRefs(desc, refs, where)

static func _where(res) -> String:
	return res.resource_path if res.resource_path != "" else str(res)

static func _fail(where: String, message: String) -> int:
	push_error("Data: %s %s" % [where, message])
	return 1
