extends Container

class_name ItemMenu

const text_button = preload("res://ui/text_button.tscn")
@export var custom_size : float = 128



func open() -> void:
	move_to_front()
	custom_minimum_size.x = custom_size
	for item_name in Data.item_names.keys():
		var _button = text_button.instantiate()
		_button.info = item_name
		_button.set_text(Data.item_names[item_name])
		_button.custom_minimum_size = Vector2.ONE*custom_size
		get_child(0).add_child(_button)
		_button.pressed.connect(click_button)
		#recipe_badge.set_recipe(recipe)
		
func click_button(info):
	Util.main.player.inventory.add(info)
	Util.input_controller.switch_state(Util.InputState.Default)
	
func close() -> void:
	for child in get_child(0).get_children():
		child.queue_free()
