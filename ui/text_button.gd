extends TextCircle

class_name TextButton

signal pressed(info)

var info

func _on_button_pressed() -> void:
	pressed.emit(info)
