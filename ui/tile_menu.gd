extends ChoiceMenu

func get_options():
	choices.clear()
	choices.append([])
	for _tile in Progress.tiles:
		choices[0].append(_tile)

func click_choice(_cat: int,_num : int) -> void:
	Util.input_controller.set_held_tile(choices[_cat][_num])#Util.input_controller.switch_state(Util.InputState.HoldingTile)
	
func _process(delta: float) -> void:
	pass
	#if choices.size() != Progress.tiles.size():
		#open()
