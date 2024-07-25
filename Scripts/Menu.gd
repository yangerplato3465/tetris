extends Control

@onready var start = $VBoxContainer/Start
@onready var rules = $VBoxContainer/Rules
@onready var settings = $VBoxContainer/Settings
@onready var rulesClose = $RulesPanel/Close
@onready var settingsClose = $Settings/Close

# Setting menu
@onready var inputButton = preload("res://Scene/Component/button.tscn")
@onready var actionList = $Settings/MarginContainer/ActionList
var isRemapping = false
var actionToRemap = null
var remappingButton = null
var inputActions = {
	"right": "right",
	"left": "left",
	"soft_drop": "soft drop",
	"hard_drop": "hard drop",
	"rotate_right": "rotate right",
	"rotate_left": "rotate left",
	"hold_piece": "hold piece",
}

func _ready():
	createActionList()
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
	settingsClose.connect("mouse_entered", Utilities.scaleUp.bind(settingsClose))
	settingsClose.connect("mouse_exited", Utilities.scaleDown.bind(settingsClose))
	pass

func createActionList():
	InputMap.load_from_project_settings()
	for item in actionList.get_children():
		item.queue_free()
	
	for action in inputActions:
		var button = inputButton.instantiate()
		var actionLabel = button.find_child("LabelAction")
		var inputLabel = button.find_child("LabelInput")
		
		actionLabel.text = inputActions[action]
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			inputLabel.text = events[0].as_text().trim_suffix(" (Physical)")
		else:
			inputLabel.text = ""
		actionList.add_child(button)
		button.pressed.connect(onInputButtonPressed.bind(button, action))
	
func onInputButtonPressed(button, action):
	if !isRemapping:
		isRemapping = true
		actionToRemap = action
		remappingButton = button
		button.find_child("LabelInput").text = "Press key to bind"

func _input(event):
	if isRemapping:
		if event is InputEventKey:
			InputMap.action_erase_events(actionToRemap)
			InputMap.action_add_event(actionToRemap, event)
			updateActionList(remappingButton, event)
			isRemapping = false
			actionToRemap = null
			remappingButton = null
			accept_event()

func updateActionList(button, event):
	button.find_child("LabelInput").text = event.as_text().trim_suffix(" (Physical)")

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
	settingsClose.disabled = false
	Utilities.showPanel($Settings)
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

func _on_settings_close_pressed():
	disableAll(false)
	settingsClose.disabled = true
	Utilities.onPressed(settingsClose)
	Utilities.hidePanel($Settings)
