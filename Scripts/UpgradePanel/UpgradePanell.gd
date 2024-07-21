extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_option_1_mouse_entered():
	scaleUp($HBoxContainer/Option1)

func _on_option_1_mouse_exited():
	scaleDown($HBoxContainer/Option1)

func _on_option_2_mouse_entered():
	scaleUp($HBoxContainer/Option2)

func _on_option_2_mouse_exited():
	scaleDown($HBoxContainer/Option2)

func _on_option_3_mouse_entered():
	scaleUp($HBoxContainer/Option3)

func _on_option_3_mouse_exited():
	scaleDown($HBoxContainer/Option3)

func scaleUp(node):
	node.pivot_offset = Vector2(184, 248)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC) 
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2(1.05, 1.05), 0.5)

func scaleDown(node):
	node.pivot_offset = Vector2(184, 248)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC) 
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2(1, 1), 0.5)
