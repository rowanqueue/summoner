extends Node2D

class_name Tile

@onready var visual: Sprite2D = $Sprite2D
@onready var inventory: Inventory = $Inventory
@onready var type_visual: Sprite2D = $TypeVisual
@onready var text: RichTextLabel = $RichTextLabel

var point : Vector2i
var tile_type: String
var data : Dictionary :
	get: return Data.tiles_by_id[tile_type]
var facing : int = 0
var ghost : bool = false
var angry_ghost : bool = false
var to_be_demolished : bool = false

func setup(p: Vector2i, _tile_type :String) -> void:
	point = p
	tile_type = _tile_type
	position = Util.grid_to_real(point)

func _ready() -> void:
	if ghost and ("cost" not in data or Util.debug_free_build):
		ghost = false
	if "cost" not in data:
		ghost = false
	scale = Vector2.ONE*(Util.hex_size/128.0)
	if Util.debug_hex == false:
		scale = Vector2.ONE*(Util.tile_size/256.0)
	inventory.scale = Vector2.ONE * (1.0/scale.x)
	var image_path : String = "res://art/tiles/"+tile_type+".png"
	if ResourceLoader.exists(image_path):
		type_visual.texture = load(image_path)
	if "visual_scale" in data:
		type_visual.scale = Vector2.ONE*data.visual_scale
		
func _process(delta: float) -> void:
	text.text = ""
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if to_be_demolished:
		text.text = "[color=red][font_size=100]X[/font_size]"
	if tile_type == "altar":
		if Progress.tech_altars.has(point):
			text.text = Progress.tech_altars[point]
			if Progress.available_techs.has(text.text):
				var so_far : int = Progress.available_techs[text.text]
				text.text += "\n"+str(so_far)+"/"+str(int(Progress.techs[text.text].cost))
				for c in Progress.techs[Progress.tech_altars[point]].cost_type:
					text.text+=Data.item_names[c]
			text.text = text.text.replace("18","60")
	type_visual.rotation = deg_to_rad(Util.angles[facing])
	if ghost:
		modulate = Color.SKY_BLUE
		if angry_ghost:
			modulate = Color.INDIAN_RED
		modulate.a = 0.5
	else:
		modulate = Color.WHITE
	if ghost and "cost" in data:
		text.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		for item in data.cost:
			if Data.item_names.has(item):
				text.text += Data.item_names[item]
			else :
				text.text += item
		text.text = text.text.replace("18","100")
		return
				

func rotate_facing(right: bool) -> void:
	if "can_rotate" not in data:
		return
	if right:
		facing += 1
	else:
		facing -= 1
	facing %= Util.directions.size()

func spawn_agent(data : Dictionary) -> Agent:
	#if Util.main.agents.has(point):
		#return
	return Util.main.spawn_agent(point,data,facing)

func try_build(inv : Inventory) -> Dictionary:
	if "cost" not in data:
		build()
		return {}
	var recipe : Dictionary = {"input":[],"output":[],"build":true}
	var needed: Dictionary[String,int]
	for item in data.cost:
		recipe.input.append(item)
		if needed.has(item):
			needed[item] += 1
		else:
			needed[item] = 1
	for item in inv.items:
		if needed.has(item):
			needed[item] -= 1
	for num in needed.values():
		if num > 0:
			return {}
	return recipe

func build():
	ghost = false
	Util.main.send_tile(self)
	
func mark_to_demolish():
	if tile_type == "altar":
		if Progress.is_altar_completed(point):
			return
	if ghost or Util.debug_free_build:
		Util.main.delete_tile(self)
		Util.main.send_tile_delete(point)
		return
	to_be_demolished = true
	Util.main.send_tile(self)
 
#region saving
func Save() -> Dictionary:
	var data : Dictionary = {
		"point": {"x": point.x,"y":point.y},
		"tile_type": tile_type,
		"inventory" : inventory.Save()
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
#endregion
