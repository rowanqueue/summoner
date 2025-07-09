extends PanelContainer

class_name ChoiceMenu

var preview_scene = load("res://ui/choice_preview.tscn")

@export var active : bool = false

var containers : Array[Container]

var choices : Array[Array]

var num_containers : int = 1

func _ready() -> void:
	for i in num_containers:
		var container = HBoxContainer.new()
		$VBoxContainer.add_child(container)
		containers.append(container)
	if active:
		open()
	else:
		close()
		
func open() -> void:
	active = true
	visible = true
	get_options()
	for i in containers.size():
		make_choices(i)

func close() -> void:
	active = false
	visible = false
	
func get_options():
	pass
	
func make_choices(index: int) -> void:
	allocate_children(index)
	var count : int = 0
	for data in choices[index]:
		var _preview = containers[index].get_child(count)
		var _text = ""
		if data is String:
			_text += data
		else:
			if "description" in data:
				_text += data.description
			else:
				_text += data.name
		_preview.setup(index,count,_text)
		count+=1
	
func allocate_children(index: int) -> void:
	while containers[index].get_child_count() > choices[index].size():
		var _child = containers[index].get_child(containers[index].get_child_count()-1)
		containers[index].remove_child(_child)
		_child.queue_free()
	while containers[index].get_child_count() < choices[index].size():
		var _preview = preview_scene.instantiate()
		containers[index].add_child(_preview)
		_preview.pressed.connect(click_choice)
	
func click_choice(_cat: int,_num : int) -> void:
	print(_cat," ",_num)
