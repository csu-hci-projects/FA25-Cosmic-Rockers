extends BoxContainer

var awaiting_action: String = ""
var awaiting_alternate: bool = false

var actions = ["move_left", "move_right", "jump"]

var primary_buttons := {}
var alternate_buttons := {}

var project_defaults := {}

@onready var grid = $MarginContainer/VBoxContainer/GridContainer

func _ready():
	for action in actions:
		project_defaults[action] = []
		for ev in InputMap.action_get_events(action):
			project_defaults[action].append(ev.duplicate())
	
	for action in actions:
		var label = Label.new()
		label.text = action.capitalize()
		grid.add_child(label)
		
		var primary_btn = Button.new()
		primary_btn.text = _get_key_name(action, 0)
		primary_btn.pressed.connect(_on_primary_rebind_pressed.bind(action))
		primary_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		primary_btn.focus_mode = Control.FOCUS_NONE
		primary_btn.custom_minimum_size.x = 200
		grid.add_child(primary_btn)
		primary_buttons[action] = primary_btn
		
		var alt_btn = Button.new()
		alt_btn.text = _get_key_name(action, 1)
		alt_btn.pressed.connect(_on_alternate_rebind_pressed.bind(action))
		alt_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		alt_btn.focus_mode = Control.FOCUS_NONE
		alt_btn.custom_minimum_size.x = 200
		grid.add_child(alt_btn)
		alternate_buttons[action] = alt_btn

func _on_primary_rebind_pressed(action_name: String):
	if awaiting_action == "":
		awaiting_action = action_name
		awaiting_alternate = false
		primary_buttons[action_name].text = "Press a key..."

func _on_alternate_rebind_pressed(action_name: String):
	if awaiting_action == "":
		awaiting_action = action_name
		awaiting_alternate = true
		alternate_buttons[action_name].text = "Press a key..."

func _unhandled_input(event):
	if awaiting_action != "" and event is InputEventKey and event.pressed:
		var keycode = event.physical_keycode
		
		if keycode == KEY_ESCAPE:
			rebind_action(awaiting_action, -1, awaiting_alternate)
		else:
			rebind_action(awaiting_action, keycode, awaiting_alternate)
		
		awaiting_action = ""
		awaiting_alternate = false
		
		get_viewport().set_input_as_handled()

func rebind_action(action_name: String, keycode: int, alternate: bool = false):
	var events = InputMap.action_get_events(action_name)
	
	if alternate:
		if events.size() >= 2:
			InputMap.action_erase_event(action_name, events[1])
		if keycode >= 0:
			var new_event := InputEventKey.new()
			new_event.physical_keycode = keycode as Key
			InputMap.action_add_event(action_name, new_event)
	else:
		if events.size() >= 1:
			InputMap.action_erase_event(action_name, events[0])
		if keycode >= 0:
			var new_event := InputEventKey.new()
			new_event.physical_keycode = keycode as Key
			InputMap.action_add_event(action_name, new_event)
	
	_update_button_text(action_name)



func _on_reset_pressed() -> void:
	for action_name in actions:
		for ev in InputMap.action_get_events(action_name):
			InputMap.action_erase_event(action_name, ev)
		
		for ev in project_defaults[action_name]:
			InputMap.action_add_event(action_name, ev.duplicate())
		
		_update_button_text(action_name)

func _update_button_text(action_name: String) -> void:
	var events = InputMap.action_get_events(action_name)
	
	if action_name in primary_buttons:
		if events.size() >= 1 and events[0] is InputEventKey:
			primary_buttons[action_name].text = OS.get_keycode_string(events[0].physical_keycode)
		else:
			primary_buttons[action_name].text = "Unassigned"
	
	if action_name in alternate_buttons:
		if events.size() >= 2 and events[1] is InputEventKey:
			alternate_buttons[action_name].text = OS.get_keycode_string(events[1].physical_keycode)
		else:
			alternate_buttons[action_name].text = "Unassigned"

func _get_key_name(action_name: String, index: int) -> String:
	var events = InputMap.action_get_events(action_name)
	if events.size() > index and events[index] is InputEventKey:
		return OS.get_keycode_string(events[index].physical_keycode)
	return "Unassigned"
