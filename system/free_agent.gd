extends Agent

class_name FreeAgent


func _process(delta: float) -> void:
	if state == AgentState.Working:
		anim_duration += delta
		if anim_duration >= 1:
			finish_craft()
		body.position = Vector2.UP*10* sin(anim_duration*PI)
	else:
		body.position = Vector2.ZERO
	point = Util.real_to_grid(position)
	if debug_player:
		return

func move(vel : Vector2):
	vel = vel.normalized()*speed;
	
	
	position += vel
	if vel != Vector2.ZERO:
		body.rotation = lerp_angle(body.rotation,vel.angle(),0.25)

#region saving
func Save() -> Dictionary:
	var data : Dictionary = {
		"point": {"x": point.x,"y":point.y},
		"position":{"x":position.x,"y":position.y},
		"angle":body.rotation,
		"facing": facing,
		"stats": stats,
		"age": age,
		"state" : state as int,
		"anim_duration": anim_duration,
		"current_recipe": current_recipe,
		"inventory" : inventory.Save()
	}
	#todo: runtime stuff of moving/crafting state later etc.
	return data
	
func Load(data : Dictionary) -> void:
	age = data.age
	inventory.Load(data.inventory)
	
	state = data.state as AgentState
	anim_duration = data.anim_duration
	current_recipe = data.current_recipe
	position = Vector2(data.position.x,data.position.y)
	body.rotation = data.angle
#endregion
