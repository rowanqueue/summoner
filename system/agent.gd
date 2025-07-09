extends Node2D

class_name Agent

enum AgentState{
	Idle,
	Moving,
	WaitingToMove,
	Working,
	Dead
}

@export var debug_player : bool = false
@export var starting_point : Vector2i
@onready var body: Sprite2D = $Body
@onready var age_bar: Line2D = $Line2D/AgeBar
@onready var inventory: Inventory = $Inventory

var point : Vector2i
var facing : int = 3

#stats
var stats : Dictionary
var reach : int = 1
var speed : float = 1
var lifespan : float = 10
var skills : Array


#runtime
var state : AgentState = AgentState.Idle
var current_recipe : Dictionary
var anim_duration : float = 0
var age : float = 0

#debug player doesn't run this
func setup(p : Vector2i, _stats : Dictionary):
	point = p
	stats = _stats
	if "reach" in stats:
		reach =stats.reach
	if "speed" in stats:
		speed = stats.speed
	if "lifespan" in stats:
		lifespan = stats.lifespan
	if "skills" in stats:
		skills = stats.skills

func _ready() -> void:
	if debug_player:
		age_bar.get_parent().queue_free()
		body.modulate = Color.hex(0x6464ff)
		speed = 5
		reach = 3
		if starting_point != Vector2i.ZERO:
			point = starting_point
	position = Util.grid_to_real(point)
	if "color" in stats:
		body.modulate = Color.from_string(stats.color,Color.SADDLE_BROWN)

func _process(delta: float) -> void:
	
	if state == AgentState.Moving:
		anim_duration += delta*speed
		if anim_duration >= 1:
			state = AgentState.Idle
		position = lerp(Util.grid_to_real(point-Util.directions[facing]),Util.grid_to_real(point),anim_duration)
	else:
		position = Util.grid_to_real(point)
	if state == AgentState.Working:
		anim_duration += delta
		if anim_duration >= 1:
			finish_craft()
		position = Util.grid_to_real(point) + Vector2.UP*10* sin(anim_duration*PI)
	body.rotation = deg_to_rad(Util.angles[facing])
	
	if debug_player:
		return
	age += delta
	var percent : float = inverse_lerp(0,lifespan,age)
	age_bar.points[0].x = lerp(11,-11,percent)
	if age >= lifespan:
		die()
	#ai logic time
	
	match state:
		AgentState.WaitingToMove:
			if Util.main.agents.has(point+Util.directions[facing]) == false:
				move_forward()
			else:
				if Util.main.agents[point+Util.directions[facing]] != self:
					move_forward()
	if state == AgentState.Idle:
		#read tile
		var _tile = Util.main.which_tile_here(point)
		if _tile != null:
			parse_tile(_tile)
			
		if state != AgentState.Working:
			if Util.main.agents.has(point+Util.directions[facing]):
				state = AgentState.WaitingToMove
			else:
				if state == AgentState.Idle:
					move_forward()
	
#region movement
func move_forward() -> void:
	anim_duration = 0
	state = AgentState.Moving
	if debug_player == false:
		Util.main.agents.erase(point)
	point += Util.directions[facing]
	if debug_player == false:
		Util.main.agents[point] = self

func move_backward() -> void:
	point += Util.directions[(facing+(Util.directions.size()/2))%Util.directions.size()]

func rotate_facing(right: bool) -> void:
	if right:
		facing += 1
	else:
		facing -= 1
	facing %= Util.directions.size()

func set_facing(dir: int) -> void:
	facing = dir
 #endregion
func parse_tile(_tile : Tile):
	#todo: should this be automatic??
	if _tile.to_be_demolished:
		try_demolishing(_tile)
		return
	if _tile.ghost == false:
		var same_inv : bool = false
		if _tile.inventory.not_empty():
			same_inv = _tile.inventory.is_equal(inventory)
		else:
			same_inv = true
		match  _tile.tile_type:
			"splitter":
				var splitter : Splitter = _tile as Splitter
				set_facing(splitter.current)
				splitter.increment_arrow()
			"kill":
				die()
			"arrow":
				if same_inv:
					set_facing(_tile.facing)
			"dropoff":
				inventory.try_transfer_first_to(_tile.inventory)
			"pickup":
				look_for_item_to_pickup()
			_:
				if same_inv:
					try_craft()
	else:
		#todo: see if the _tile needs an item you're holding
		try_building(_tile)
#region craft
func try_craft():
	var _tile : Tile = Util.main.which_tile_here(point)
	var tile_type : String = ""
	if _tile != null:
		tile_type = _tile.tile_type
	if tile_type == "altar":
		#todo: make this return a recipe!
		if Progress.tech_altars.has(point):
			var recipe = Progress.get_tech_recipe(Progress.tech_altars[point],inventory)
			if recipe != {}:
				start_craft(recipe)
				return
	if Data.is_recipe_input(inventory.items,skills,tile_type):
		start_craft(Data.get_recipe_from_input(inventory.items,skills,tile_type))
		
func start_craft(recipe : Dictionary):
	current_recipe = recipe
	state = AgentState.Working
	anim_duration = 0
	
	
func finish_craft():
	if "research" in current_recipe:
		Progress.try_advance_tech(current_recipe.research)
	if "demolish" in current_recipe:
		Util.main.delete_tile(Util.main.tiles[point])
		Util.main.send_delete_tile(point)
	if "build" in current_recipe:
		Util.main.tiles[point].build()
	for item in current_recipe.input:
		inventory.remove(item)
	for item in current_recipe.output:
		inventory.add(item)
	if "spawn" in current_recipe:
		var _agent =Util.main.tiles[point].spawn_agent(current_recipe.spawn)
		Util.main.send_spawn(_agent)
	current_recipe = {}
	state = AgentState.WaitingToMove
#endregion
#region searching
func look_for_item_to_pickup():
	var nearby_points : Array[Vector2i] = Util.spiral(point,reach)
	var item_hint : String = ""
	if Util.main.tiles[point].inventory.not_empty():
		item_hint = Util.main.tiles[point].inventory.items[0]
	for _point in nearby_points:
		if _point == point:
			continue
		if Util.main.tiles.has(_point) == false:
			continue
		var tile : Tile = Util.main.tiles[_point]
		if tile.inventory.is_empty():
			continue
		if tile.tile_type == "pickup":
			continue
		if item_hint == "":
			tile.inventory.try_transfer_first_to(inventory)
			break
		if tile.inventory.has_item(item_hint):
			tile.inventory.get_item(item_hint)
			inventory.add(item_hint)
			break
func try_building(tile : Tile):
	var _recipe : Dictionary = tile.try_build(inventory)
	if "input" in _recipe:
		start_craft(_recipe)
 	#for needed_item in tile.build_inventory.items:
		#if inventory.has_item(needed_item):
			#inventory.remove(needed_item)
			#tile.inventory.add(needed_item)
func try_demolishing(tile : Tile):
	var _recipe : Dictionary = {"input":[],"output":[],"demolish":true}
	if "cost" in tile.data:
		for item in tile.data.cost:
			_recipe.output.append(item)
	start_craft(_recipe)
#endregion
func die():
	var _tile = Util.main.which_tile_here(point)
	if _tile != null:
		for i in inventory.size:
			if inventory.is_empty():
				break
			if _tile.inventory.has_space() == false:
				break
			inventory.try_transfer_first_to(_tile.inventory)
	Util.main.delete_agent(self)
	state = AgentState.Dead

#region saving
func Save() -> Dictionary:
	var data : Dictionary = {
		"point": {"x": point.x,"y":point.y},
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
#endregion
