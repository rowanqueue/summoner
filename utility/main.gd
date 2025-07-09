extends Node

class_name Main

@export var game_size : int = 25
@onready var debug_text: RichTextLabel = %Debug
@onready var input_controller: InputController = %InputController

@onready var tile_parent : Node2D = $Tiles
@onready var agent_parent : Node2D = $Agents

var time_banked : float = 0
var time_start_session : float = 0

var tiles : Dictionary[Vector2i,Tile]
var agents : Dictionary[Vector2i,Agent]
var player : Agent

func _ready() -> void:
	Util.main = self
	Util.camera = %Camera2D
	time_start_session = Time.get_unix_time_from_system()
	for child in agent_parent.get_children():
		if child.debug_player:
			player = child
	player.skills = ["science_1"]
	var tile : Tile = place_tile(Vector2i(4,2),"bush")
	tile.inventory.add("science_1")
	var _tiles : Array[Vector2i] = Util.spiral(player.point,game_size)
	for _tile in _tiles:
		if randf_range(0,100) < 5:
			place_tile(_tile,"rock")
			continue
		if randf_range(0,100) < 25:
			place_tile(_tile,"bush")
	#for x in range(-24,24):
		#for y in range(-24,24):
			
	#tile.inventory.add("leaf")
	Util.input_controller.create_astar_grid()
	#tile = place_tile(Vector2i(2,2),"arrow")
	#tile.rotate_facing(true)
	#tile = place_tile(Vector2i(3,3),"dropoff")
	#tile = place_tile(Vector2i(4,4),"arrow")
	#tile.inventory.add("branch")
	#tile.rotate_facing(false)
	#tile = place_tile(Vector2i(5,3),"pickup")
	#tile.inventory.add("leaf")
	##spawn_agent(Vector2i(14,2))
	##spawn_agent(Vector2i(16,2))
	#tile = place_tile(Vector2i(6,2),"bird",3)
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("save"):
		SaveLoad.Save()
	if Input.is_action_just_pressed("load"):
		if SaveLoad.HasSave():
			SaveLoad.Load()

func spawn_tile(tile_type: String) -> Tile:
	var _tile = Util.tile_scene.instantiate()
	if tile_type == "splitter":
		_tile.set_script(Util.splitter_script)
	_tile.tile_type = tile_type
	add_child(_tile)
	return _tile
	
func delete_tile(tile : Tile):
	tile.queue_free()
	tiles.erase(tile.point)

func place_tile(point : Vector2i, tile_type: String = "",facing: int = 0,is_ghost : bool = false,) -> Tile:
	var _tile = Util.tile_scene.instantiate()
	if tile_type == "splitter":
		_tile.set_script(Util.splitter_script)
	_tile.setup(point,tile_type)
	_tile.facing = facing
	_tile.ghost = is_ghost
	add_child(_tile)
	if tiles.has(point):
		#todo: transfer inventory over!
		tiles[point].queue_free()
	tiles[point] = _tile
	return _tile
	
func which_tile_here(point : Vector2i) -> Tile:
	if point in tiles:
		return tiles[point]
	return null
	
func spawn_agent(point : Vector2i, stats: Dictionary, facing: int = 0,is_player:bool = false) -> Agent:
	var agent = Util.agent_scene.instantiate()
	agent.debug_player = is_player
	agent.setup(point,stats)
	agent.facing = facing
	agent_parent.add_child(agent)
	agents[point] = agent
	return agent
	
func spawn_free_agent(point : Vector2i, stats: Dictionary, facing: int = 0,is_player:bool = false) -> Agent:
	var agent = Util.free_agent_scene.instantiate()
	agent.debug_player = is_player
	agent.setup(point,stats)
	agent.facing = facing
	agent_parent.add_child(agent)
	agents[point] = agent
	return agent
	
func make_new_character(steam_id, steam_name):
	var new_agent = Util.free_agent_scene.instantiate()
	agent_parent.add_child(new_agent)
	Steamworks.lobby_agents[steam_id] = new_agent
	new_agent.steam_id =steam_id
	new_agent.steam_name = steam_name
	
func delete_agent(agent : Agent):
	agents.erase(agent.point)
	if agent in agents.values():
		agents.erase(agent.point)
	agent.queue_free()
	

#region saving
func Save() -> Dictionary:
	var data : Dictionary = {
		"tiles" : [],
		"agents" : [],
		"player" : {}
	}
	for tile in tiles.values():
		data.tiles.append(tile.Save())
	for agent in agents.values():
		if agent.debug_player:
			continue
		data.agents.append(agent.Save())
	data.player = player.Save()
	return data
	
func Load(data : Dictionary) -> void:
	for tile_data in data.tiles:
		var tile : Tile = place_tile(Vector2i(tile_data.point.x,tile_data.point.y),tile_data.tile_type)
		tile.Load(tile_data)
	for agent_data in data.agents:
		var agent : Agent = spawn_agent(Vector2i(agent_data.point.x,agent_data.point.y),agent_data.stats,agent_data.facing)
		agent.Load(agent_data)
	player = spawn_free_agent(Vector2i(data.player.point.x,data.player.point.y),data.player.stats,data.player.facing,true)
	player.Load(data.player)

func Clear() -> void:
	for tile in tiles.values():
		tile.queue_free()
	for agent in agents.values():
		agent.queue_free()
	tiles.clear()
	agents.clear()
	player.queue_free()
func ClearMap():
	for tile in tiles.values():
		tile.queue_free()
	for agent in agents.values():
		agent.queue_free()
	tiles.clear()
	agents.clear()
#endregion

func display_total_time(_seconds : int = -1) -> String:
	if _seconds < 0:
		_seconds = Util.main.time_banked + (Time.get_unix_time_from_system() as int-Util.main.time_start_session)
	var _minutes : int = _seconds/60
	var _hours : int = _minutes /60
	_seconds %= 60
	_minutes %= 60
	
	var s = ""
	if _hours < 10:
		s += "0"
	s+= str(_hours)+":"
	if _minutes < 10:
		s += "0"
	s+= str(_minutes)+":"
	if _seconds < 10:
		s += "0"
	s+= str(_seconds)
	
	
	return s

#region multiplayer
func send_map_over(change_id: int):
	var map_data:Dictionary = {"type":"map","tiles":[],"agents":[]}
	for tile in tiles.values():
		map_data.tiles.append(tile.Save())
	for agent in agents.values():
		if agent.debug_player:
			continue
		map_data.agents.append(agent.Save())
	Steamworks.send_p2p_packet(change_id,map_data)
	
func read_map(map_data:Dictionary):
	#todo: replace this with Clear when you handle agents
	ClearMap()
	for tile_data in map_data.tiles:
		var tile : Tile = place_tile(Vector2i(tile_data.point.x,tile_data.point.y),tile_data.tile_type)
		tile.Load(tile_data)
	for agent_data in map_data.agents:
		var agent : Agent = spawn_agent(Vector2i(agent_data.point.x,agent_data.point.y),agent_data.stats,agent_data.facing)
		agent.Load(agent_data)
		
func send_tile(tile : Tile):
	var data = tile.Save()
	data.type = "tile"
	Steamworks.send_p2p_packet(0,data)
	
func read_tile(tile_data: Dictionary):
	var pos = Vector2i(tile_data.point.x,tile_data.point.y)
	#todo: optimize this
	if tiles.has(pos):
		delete_tile(tiles[pos])
	var tile : Tile = place_tile(Vector2i(tile_data.point.x,tile_data.point.y),tile_data.tile_type)
	tile.Load(tile_data)
	
func send_delete_tile(pos: Vector2i):
	var data =  {"type":"tile_delete","x":pos.x,"y":pos.y}
	Steamworks.send_p2p_packet(0,data)
	
func read_delete_tile(data):
	var pos = Vector2i(data.x,data.y)
	if tiles.has(pos):
		delete_tile(tiles[pos])
		
func send_spawn(agent : Agent):
	var data = agent.Save()
	data.type = "spawn"
	Steamworks.send_p2p_packet(0,data)
	
func read_spawn(agent_data: Dictionary):
	#todo: optimize this
	var agent : Agent = spawn_agent(Vector2i(agent_data.point.x,agent_data.point.y),agent_data.stats,agent_data.facing)
	agent.Load(agent_data)
#endregion
