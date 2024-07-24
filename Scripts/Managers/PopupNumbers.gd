extends Node


func displayNumber(value: int, position: Vector2, isCritical: bool = false):
	var number = Label.new()
	number.global_position = position
	number.text = str(value)
	number.z_index = 5
	number.label_settings = LabelSettings.new()
	
	var color = Color.CORNFLOWER_BLUE
	if isCritical:
		color = Color.RED
	if value == 0:
		color = Color.SLATE_GRAY
		
	number.label_settings.font = load("res://Font/ThaleahFat/ThaleahFat.ttf")
	number.label_settings.font_color = color
	number.label_settings.font_size = 50
	
	call_deferred("add_child", number)
	
	await number.resized
	number.pivot_offset = Vector2(number.size / 2)
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(number, "position:y", number.position.y - 60, 0.25)
	tween.tween_property(number, "position:y", number.position.y, 0.25).set_delay(0.25)
	tween.tween_property(number, "modulate:a", 0, 0.25).set_delay(0.5)
	
	await tween.finished
	number.queue_free()
	
