extends Node

# Panel flow controller for GameplayScene. Owns which panel is on screen and
# the slide transitions between them, so route handlers never need to know
# the "from" panel and overlapping transitions are impossible.
#
# goto()    animated transition (the normal path)
# jump()    instant switch (dev tools) — still keeps `current` accurate
# overlay() slide a panel in on top without removing `current` (gameover)

const SLIDE_OUT_TIME = 0.8
const SLIDE_IN_TIME = 1
const OFFSCREEN_Y = 900.0

var current: Control = null
var busy := false

func goto(to: Control, prep := Callable(), onArrive := Callable()):
	if busy or to == current:
		return
	busy = true
	if prep.is_valid():
		prep.call()
	if current:
		await _slideOut(current)
	await _slideIn(to)
	current = to
	busy = false
	if onArrive.is_valid():
		onArrive.call()

func jump(to: Control, prep := Callable()):
	if busy:
		return
	if prep.is_valid():
		prep.call()
	if current and current != to:
		current.visible = false
	to.visible = true
	to.position.y = 0
	current = to

func overlay(panel: Control):
	if busy:
		return
	busy = true
	await _slideIn(panel)
	busy = false

func _slideOut(node: Control):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(node, "position:y", node.position.y + 500, SLIDE_OUT_TIME)
	await tween.finished
	node.visible = false
	node.position.y = 0

func _slideIn(node: Control):
	node.visible = true
	node.position.y = OFFSCREEN_Y
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position:y", 0, SLIDE_IN_TIME)
	await tween.finished
