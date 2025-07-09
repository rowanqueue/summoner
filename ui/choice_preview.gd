extends VBoxContainer

class_name ChoicePreview

signal pressed(category,num)

var num: int = -1
var category: int = -1
@onready var button: Button = $Button
@onready var rich_text_label: RichTextLabel = $Button/RichTextLabel

func setup(_cat: int,_num: int,text:String,image: Texture2D = null)->void:
	category = _cat
	num = _num
	#button.text = text
	rich_text_label.text = text
	if image != null:
		button.icon = image


func _on_button_pressed() -> void:
	pressed.emit(category,num)
