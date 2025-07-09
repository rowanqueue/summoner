extends Agent

class_name FreeAgent
@onready var rich_text_label: RichTextLabel = $RichTextLabel

var steam_id : int
var steam_name : String

var proper_pos:Vector2
var last_sent_pos : Vector2
var next_send_time : float

func _ready() -> void:

	age_bar.get_parent().queue_free()
	body.modulate = Color.hex(0x6464ff)
	speed = 250
	reach = 3
	if debug_player:
		if starting_point != Vector2i.ZERO:
			point = starting_point
	else:
		body.modulate = Color.VIOLET
	position = Util.grid_to_real(point)

func _process(delta: float) -> void:
	if state == AgentState.Working:
		anim_duration += delta
		if anim_duration >= 1:
			finish_craft()
		body.position = Vector2.UP*10* sin(anim_duration*PI)
	else:
		body.position = Vector2.ZERO
	if Util.debug_hex:
		point = Util.real_to_grid(position)
	else:
		point = Util.real_to_grid(position+(Vector2.ONE*0.5*Util.tile_size))
	
	
	if debug_player:
		next_send_time-= delta
		if next_send_time < 0:
			send_position()
		return
	rich_text_label.text = steam_name
	#not the player
	if proper_pos.distance_to(position) < 0.5:
		position = proper_pos
		return
	var diff = proper_pos-position
	position += (proper_pos-position)*0.1*delta*100
	
	body.rotation = lerp_angle(body.rotation,diff.angle(),0.25)
	

#region multiplayer
func send_position():
	if last_sent_pos.distance_to(position) < 0.5:
		return
	next_send_time = 0.2
	last_sent_pos = position
	var pos_data : Dictionary = {"type":"pos","x":position.x,"y":position.y}
	Steamworks.send_p2p_packet(0, pos_data)
func place_position(pos):
	proper_pos = pos
	
#endregion

func move(vel : Vector2,delta :float):
	vel = vel.normalized()*speed*delta;
	
	
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
