extends Node

func delete_children(node):
	for n in node.get_children():
		if n is Sprite2D:
			n.queue_free()

# --- Tween helpers ---

func _tween_scale(node, target: Vector2, duration: float = 0.5):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", target, duration)

func scaleUp(node):
	AudioManager.hover.play()
	_tween_scale(node, Vector2(1.05, 1.05))

func scaleDown(node):
	_tween_scale(node, Vector2(1, 1))

func onPressed(node):
	AudioManager.button_press.play()
	_tween_scale(node, Vector2(0.9, 0.9))

func showPanel(node):
	node.scale = Vector2(0.5, 0.5)
	node.visible = true
	_tween_scale(node, Vector2(1, 1), 0.7)

func hidePanel(node):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(node, "scale", Vector2(0.5, 0.5), 0.3)
	tween.finished.connect(func(): node.visible = false)

func slideOut(outNode):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(outNode, "position:y", outNode.position.y + 500, 0.5)
	await tween.finished
	outNode.visible = false
	outNode.position.y = 0

func slideIn(node, callback: Callable = Callable()):
	node.visible = true
	node.position.y = 900
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position:y", 0, 1).set_delay(1)
	if callback.is_valid():
		tween.finished.connect(callback)

# --- Board generation ---

func _generateMessyBoard(filledRows: int):
	var messyGrid = []
	for _x in range(10):
		var col = []
		for _y in range(23 - filledRows):
			col.append(0)
		for _y in range(filledRows):
			col.append(randomNum())
		messyGrid.append(col)
	return messyGrid

func generateSmallMessyBoard():
	return _generateMessyBoard(2)

func generateMediumMessyBoard():
	return _generateMessyBoard(4)

func generateLargeMessyBoard():
	return _generateMessyBoard(6)

func randomNum():
	return 8 if randi_range(0, 1) == 1 else 0

# --- Misc ---

func chooseRandom(arraySize: int, size: int) -> Array:
	var indices = range(arraySize)
	indices.shuffle()
	return indices.slice(0, size)

func shakeNode(node, originalPos):
	var tween = create_tween()
	var shake = 5
	var shake_duration = 0.05
	var shake_count = 20
	tween.finished.connect(func(): node.position = originalPos)
	for i in shake_count:
		tween.tween_property(node, "position", Vector2(
			originalPos.x + randf_range(-shake, shake),
			originalPos.y + randf_range(-shake, shake)
		), shake_duration)

func floorNum(number):
	return floor(number * 10) / 10.0
