extends Node


func displayText(text: String, position: Vector2, color: Color = Color.WHITE):
	var label = Label.new()
	label.global_position = position
	label.text = text
	label.z_index = 6
	label.label_settings = LabelSettings.new()
	label.label_settings.font = load("res://Font/ThaleahFat/ThaleahFat.ttf")
	label.label_settings.font_color = color
	label.label_settings.font_size = 64
	label.label_settings.outline_size = 5
	label.label_settings.outline_color = Color.BLACK
	call_deferred("add_child", label)
	await label.resized
	label.pivot_offset = Vector2(label.size / 2)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "scale", Vector2(1.3, 1.3), 0.08)
	tween.chain().tween_property(label, "scale", Vector2(1.0, 1.0), 0.12)
	tween.tween_property(label, "position:y", label.position.y - 50, 0.5).set_delay(0.2)
	tween.tween_property(label, "modulate:a", 0.0, 0.3).set_delay(0.5)
	await tween.finished
	label.queue_free()

func displayNumber(value: int, position: Vector2, isCritical: bool = false):
	var number = Label.new()
	number.global_position = position
	number.text = str(-value)
	number.z_index = 5
	number.label_settings = LabelSettings.new()
	
	var color = Color.RED
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
