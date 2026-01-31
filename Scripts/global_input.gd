extends Node

signal input_scheme_changed(is_gamepad: bool)

var is_using_gamepad: bool = false

func _input(event):
	if event is InputEventKey or event is InputEventMouseButton:
		if is_using_gamepad:
			is_using_gamepad = false
			input_scheme_changed.emit(false)
			
	elif event is InputEventJoypadButton:
		if not is_using_gamepad:
			is_using_gamepad = true
			input_scheme_changed.emit(true)
