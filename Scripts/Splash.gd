extends Control


func _ready():
	showLogo()

func showLogo():
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property($TextureRect, "modulate:a", 1, 0.5)
	tween.tween_property($TextureRect2, "modulate:a", 1, 0.5)
	
	tween.finished.connect(func():
		await get_tree().create_timer(1.5).timeout
		get_tree().change_scene_to_file("res://Scene/Menu.tscn")
	)
