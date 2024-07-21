extends Sprite2D

const ORIGINAL_POS = Vector2(728, 188)

func _ready():
	pass

func _process(delta):
	if Input.is_action_just_pressed("hard_drop"):
		attackAnim()

func attackAnim():
	var tween = create_tween()
	tween.connect("finished", resetPosition)
	tween.set_trans(Tween.TRANS_BACK) 
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", position.x + 100, 0.1)

func resetPosition():
	position = ORIGINAL_POS
