extends Container

class_name TechMenu

const TECH_BADGE = preload("res://ui/tech_badge.tscn")
@export var custom_size : float = 128


func open() -> void:
	move_to_front()
	custom_minimum_size.x = custom_size
	var _techs : Array[String] = Progress.get_all_available_unbuilt_techs()
	if _techs.size() == 0:
		Util.main.input_controller.switch_state(Util.InputState.Default)
	for _tech in _techs:
		var tech_badge = TECH_BADGE.instantiate()
		tech_badge.tech_name = _tech
		tech_badge.custom_minimum_size = Vector2.ONE*custom_size
		get_child(0).add_child(tech_badge)
		#recipe_badge.set_recipe(recipe)
		
func close() -> void:
	for child in get_child(0).get_children():
		child.queue_free()
