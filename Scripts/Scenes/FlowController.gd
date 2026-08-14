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

# One transition may be requested while another is running; it is held here and
# dispatched once the running one lands. Requests used to be dropped on the
# floor instead, which could strand a panel that had already locked its own
# input waiting on a transition that was never going to come.
var _pending: Array = []

# Deliberately returns nothing: goto awaits, so callers cannot read a return
# value without awaiting the whole transition themselves. Whether the request
# ran now or was held is not the caller's problem — _pending guarantees it runs.
func goto(to: Control, prep := Callable(), onArrive := Callable()):
	if to == current:
		return
	if busy:
		# A single slot, last request wins: a burst of clicks can never build up
		# a queue of panels for the player to sit through.
		_pending = [to, prep, onArrive]
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
	_runPending()

func jump(to: Control, prep := Callable()) -> bool:
	if busy:
		return false
	_pending.clear() # a dev jump overrides whatever was waiting behind it
	if prep.is_valid():
		prep.call()
	if current and current != to:
		current.visible = false
	to.visible = true
	to.position.y = 0
	current = to
	return true

func overlay(panel: Control):
	if busy:
		return
	busy = true
	await _slideIn(panel)
	busy = false
	# An overlay ends the run. Anything queued behind it would slide the panel
	# straight back off again, so it is dropped rather than dispatched.
	_pending.clear()

# Dispatch the held request, clearing the slot *before* the call so a transition
# that queues another one can never build a chain or recurse.
func _runPending():
	if _pending.is_empty():
		return
	var req = _pending
	_pending = []
	goto(req[0], req[1], req[2])

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
