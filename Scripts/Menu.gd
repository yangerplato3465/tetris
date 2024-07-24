extends Control

@onready var start = $VBoxContainer/Start
@onready var rules = $VBoxContainer/Rules
@onready var settings = $VBoxContainer/Settings
@onready var rulesClose = $RulesPanel/Close

func _ready():
	start.pivot_offset = Vector2(112, 56)
	rules.pivot_offset = Vector2(112, 56)
	settings.pivot_offset = Vector2(112, 56)
	start.connect("mouse_entered", Utilities.scaleUp.bind(start))
	start.connect("mouse_exited", Utilities.scaleDown.bind(start))
	rules.connect("mouse_entered", Utilities.scaleUp.bind(rules))
	rules.connect("mouse_exited", Utilities.scaleDown.bind(rules))
	settings.connect("mouse_entered", Utilities.scaleUp.bind(settings))
	settings.connect("mouse_exited", Utilities.scaleDown.bind(settings))
	rulesClose.connect("mouse_entered", Utilities.scaleUp.bind(rulesClose))
	rulesClose.connect("mouse_exited", Utilities.scaleDown.bind(rulesClose))
	pass

func _on_animation_player_animation_finished(anim_name):
	if(anim_name == "FadeOut"):
		get_tree().change_scene_to_file("res://Scene/GameplayScene.tscn")

func _on_start_pressed():
	disableAll(true)
	Utilities.onPressed(start)
	$AnimationPlayer.play("FadeOut")

func _on_rules_pressed():
	disableAll(true)
	rulesClose.disabled = false
	Utilities.showPanel($RulesPanel)
	Utilities.onPressed(rules)

func _on_settings_pressed():
	disableAll(true)
	Utilities.onPressed(settings)

func disableAll(disable): 
	start.disabled = disable
	rules.disabled = disable
	settings.disabled = disable


func _on_close_pressed():
	disableAll(false)
	rulesClose.disabled = true
	Utilities.onPressed(rulesClose)
	Utilities.hidePanel($RulesPanel)
