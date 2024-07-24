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
