extends Tile

class_name Splitter

var current : int = 0
var used_arrows : Array[bool]
var arrows : Array[Sprite2D]
#put in dir number of other arrows 
#how does player decide how many directions it can split to

func _ready() -> void:
	super()
	var image_path : String = "res://art/tiles/"+"arrow"+".png"
	if ResourceLoader.exists(image_path):
		type_visual.texture = load(image_path)
	if "visual_scale" in data:
		type_visual.scale = Vector2.ONE*data.visual_scale
	arrows.append(type_visual)
	used_arrows.append(true)
	for i in Util.directions.size()-1:
		var index = i+1
		var arrow = type_visual.duplicate()
		arrow.rotation = deg_to_rad(Util.angles[index])
		type_visual.get_parent().add_child(arrow)
		arrows.append(arrow)
		used_arrows.append(true)
		if i > 0:
			used_arrows[i] = false
	turn_on_arrow(0)

func increment_arrow():
	current += 1
	current %= arrows.size()
	for i in arrows.size():
		if used_arrows[current]:
			break
		current+=1
		current %= arrows.size()
	turn_on_arrow(current)

func turn_on_arrow(index : int):
	current = index
	for i in arrows.size():
		arrows[i].visible = used_arrows[i]
		arrows[i].modulate = Color.DIM_GRAY
	arrows[current].modulate = Color.WHITE
	arrows[current].move_to_front()
	
func swap_arrow_on(sub_pos : Vector2):
	var angle = rad_to_deg(sub_pos.angle())
	for i in Util.angles.size():
		var _angle : float = Util.angles[i]
		var angle_diff = abs(rad_to_deg(angle_difference(deg_to_rad(angle),deg_to_rad(_angle))))
		if angle_diff < (360.0/(Util.angles.size()*2)):
			used_arrows[i] = !used_arrows[i]
			if current == i:
				increment_arrow()
			break
	for i in arrows.size():
		arrows[i].visible = used_arrows[i]
		
#region saving
func Save() -> Dictionary:
	var data : Dictionary = {
		"point": {"x": point.x,"y":point.y},
		"tile_type": tile_type,
		"inventory" : inventory.Save(),
		"current": current,
		"used_arrows": used_arrows
	}
	if facing != 0:
		data.facing = facing
	if ghost:
		data.ghost = true
	return data
	
func Load(data : Dictionary) -> void:
	setup(Vector2i(data.point.x,data.point.y),data.tile_type)
	if "facing" in data:
		facing = data.facing
	if "ghost" in data:
		ghost = data.ghost
	inventory.Load(data.inventory)
	if "current" in data:
		current = data.current
	if "used_arrows" in data:
		used_arrows.clear()
		for a in data.used_arrows:
			used_arrows.append(a)
#endregion
