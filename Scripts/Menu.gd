extends Control

func _on_button_pressed():
	$AnimationPlayer.play("FadeOut")

func _on_animation_player_animation_finished(anim_name):
	if(anim_name == "FadeOut"):
		get_tree().change_scene_to_file("res://Scene/Main.tscn")
