extends TextureRect

class_name TextCircle

@onready var rich_text_label: RichTextLabel = $RichTextLabel
var text : String

func set_text(s: String):
	text = s
	if rich_text_label != null:
		rich_text_label.text = text

func _ready() -> void:
	rich_text_label.text = text
