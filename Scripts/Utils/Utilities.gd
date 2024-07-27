extends Node

func delete_children(node):
	for n in node.get_children():
		if n.is_class("Sprite2D"):
			node.remove_child(n)
			n.queue_free()

func scaleUp(node):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC) 
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2(1.05, 1.05), 0.5)

func scaleDown(node):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC) 
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2(1, 1), 0.5)

func onPressed(node):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC) 
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2(0.9, 0.9), 0.5)

func showPanel(node):
	node.scale = Vector2(0.5, 0.5)
	node.visible = true
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC) 
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2(1, 1), 0.7)

func hidePanel(node):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK) 
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(node, "scale", Vector2(0.5, 0.5), 0.3)
	tween.finished.connect(func():
		node.visible = false
	)

func slideOut(outNode):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK) 
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(outNode, "position:y", outNode.position.y + 500, 0.5)
	tween.finished.connect(func():
		outNode.visible = false
	)

func slideIn(node):
	node.visible = true
	node.position.y = 900
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT) 
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position:y", 0, 1).set_delay(1)
	tween.finished.connect(func():
		SignalManager.stageReady.emit()
	)

func chooseRandom(arraySize: int, size: int):
	var indices = []
	
	while indices.size() < size:
		var index = randi() % arraySize
		if index not in indices:
			indices.append(index)
	
	return indices
