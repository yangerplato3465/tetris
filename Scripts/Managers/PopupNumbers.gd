extends Node

# Popup labels are spawned on every hit, line clear and announcement, so the
# font is preloaded once here — the old per-call load() put a resource-cache
# lookup in the hottest UI path in the game.
const FONT: Font = preload("res://Font/ThaleahFat/ThaleahFat.ttf")

const NUMBER_FONT_SIZE := 50
const TEXT_FONT_SIZE := 64
const CRIT_FONT_SIZE := 68
const CRIT_COLOR := Color(1.0, 0.85, 0.2)

# Damage-number motion. Rise and drift are applied as *relative* offsets, so
# callers keep passing a plain spawn position and two hits landing on the same
# pixel still fan out instead of stacking into an unreadable smear.
const NUMBER_POP_SCALE := 0.35
const NUMBER_POP_TIME := 0.22
const NUMBER_RISE := -70.0
const NUMBER_DRIFT := 18.0
const NUMBER_TRAVEL_TIME := 0.55
const NUMBER_FADE_TIME := 0.3
const NUMBER_FADE_DELAY := 0.45

# Announcement motion ("TETRIS!", "3x COMBO!", "+20 SHIELD").
const TEXT_POP_SCALE := 0.4
const TEXT_POP_TIME := 0.3
const TEXT_RISE := -50.0
const TEXT_RISE_TIME := 0.5
const TEXT_RISE_DELAY := 0.2
const TEXT_FADE_TIME := 0.3
const TEXT_FADE_DELAY := 0.5


func displayText(text: String, position: Vector2, color: Color = Color.WHITE) -> void:
	var label := _makeLabel(text, position, color, TEXT_FONT_SIZE, 6, 5)
	await _present(label)
	var tween := label.create_tween().set_parallel(true)
	# One tweener, not the old grow-then-shrink pair: TRANS_BACK overshoots past
	# the target and settles back by itself, so the punch is a single line whose
	# timing can be retuned without recomputing a second step's delay.
	tween.tween_property(label, "scale", Vector2.ONE, TEXT_POP_TIME) \
		.from(Vector2.ONE * TEXT_POP_SCALE) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", TEXT_RISE, TEXT_RISE_TIME) \
		.as_relative().set_delay(TEXT_RISE_DELAY) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, TEXT_FADE_TIME) \
		.set_delay(TEXT_FADE_DELAY)
	# chain() drops back to sequential, so the free waits for every tweener above
	# no matter which one currently runs longest.
	tween.chain().tween_callback(label.queue_free)


func displayNumber(value: int, position: Vector2, isCritical: bool = false) -> void:
	var color := Color.SLATE_GRAY if value == 0 else (CRIT_COLOR if isCritical else Color.RED)
	var fontSize := CRIT_FONT_SIZE if isCritical else NUMBER_FONT_SIZE
	var label := _makeLabel(str(-value), position, color, fontSize, 5, 0)
	await _present(label)
	var tween := label.create_tween().set_parallel(true)
	# Crits wobble on the way in (elastic); normal hits get a clean overshoot.
	tween.tween_property(label, "scale", Vector2.ONE, NUMBER_POP_TIME) \
		.from(Vector2.ONE * NUMBER_POP_SCALE) \
		.set_trans(Tween.TRANS_ELASTIC if isCritical else Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", NUMBER_RISE, NUMBER_TRAVEL_TIME) \
		.as_relative().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:x", randf_range(-NUMBER_DRIFT, NUMBER_DRIFT), NUMBER_TRAVEL_TIME) \
		.as_relative().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, NUMBER_FADE_TIME) \
		.set_delay(NUMBER_FADE_DELAY)
	if isCritical:
		tween.tween_property(label, "rotation", 0.0, NUMBER_POP_TIME * 1.5) \
			.from(randf_range(-0.2, 0.2)) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(label.queue_free)


func _makeLabel(text: String, position: Vector2, color: Color, fontSize: int,
		zIndex: int, outlineSize: int) -> Label:
	var label := Label.new()
	label.text = text
	label.global_position = position
	label.z_index = zIndex
	var settings := LabelSettings.new()
	settings.font = FONT
	settings.font_color = color
	settings.font_size = fontSize
	if outlineSize > 0:
		settings.outline_size = outlineSize
		settings.outline_color = Color.BLACK
	label.label_settings = settings
	return label


func _present(label: Label) -> void:
	# Deferred: popups are spawned from Main's handlers for Grid's signals, which
	# fire inside Grid's physics step, where a direct add_child is unsafe.
	call_deferred("add_child", label)
	await label.resized
	# Centre the pivot so the scale punch expands from the middle of the label
	# instead of dragging it down-and-right out of its top-left corner.
	label.pivot_offset = label.size / 2.0
