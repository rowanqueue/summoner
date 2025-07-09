extends Node

class_name InputController

var state : Util.InputState = Util.InputState.Default

var player : Agent :
	get : return Util.main.player
	
var pf : AStar2D
var player_path : Array[Vector2i]
var moving_with_intent : int = 0 #0:nah,1:pickup,2:drop
@onready var choice_menu: PanelContainer = %ChoiceMenu
@onready var debug: RichTextLabel = %Debug
@onready var tech_menu: TechMenu = %TechMenu
@onready var item_menu: ItemMenu = %ItemMenu

var held_tile : Tile

func _ready() -> void:
	Util.input_controller = self
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("rotate_right"):
		Steamworks.create_lobby()
	if player_path.size() > 0:
		if player.state != Agent.AgentState.Moving:
			player.state = Agent.AgentState.Moving
			player.set_facing(Util.get_direction_between(player.point,player_path[0]))
			player.move_forward()
			player_path.pop_front()
	elif player.state != Agent.AgentState.Moving:
		if moving_with_intent > 0:
			if moving_with_intent == 1:
				var _tile = Util.main.which_tile_here(player.point)
				if _tile != null:
					if _tile.inventory.not_empty() and player.inventory.has_space():
						var _item : String = _tile.inventory.get_first()
						player.inventory.add(_item)
			elif moving_with_intent == 2:
				if player.inventory.not_empty():
					var _tile = Util.main.which_tile_here(player.point)
					if _tile == null:
						_tile = Util.main.place_tile(player.point)
					if _tile.inventory.has_space():
						var _item : String = player.inventory.get_first()
						_tile.inventory.add(_item)
			moving_with_intent = 0
	debug.text = Util.InputState.keys()[state]
	debug.text += "\n"+Util.main.display_total_time()+"|"+Util.main.display_total_time(Time.get_unix_time_from_system()-Util.main.time_start_session)
	debug.text += "\n"+str(Util.mouse_grid_pos)
	debug.text += "\n"+str(player.point)
	for member in Steamworks.lobby_members:
		debug.text += "\n"+str(member)
	var tile : Tile = Util.main.which_tile_here(Util.mouse_grid_pos)
	if tile != null:
		debug.text += "\n"+tile.tile_type
		match tile.tile_type:
			"altar":
				if Progress.tech_altars.has(Util.mouse_grid_pos):
					debug.text += "\ntech: "+Progress.tech_altars[Util.mouse_grid_pos]
				else :
					debug.text += "\ntech not set :("
	#if Util.main.agents.has(Util.mouse_grid_pos):
		#var agent : Agent = Util.main.agents[Util.mouse_grid_pos]
		#debug.text += "\n"+str(agent.stats.name)
	match state:
		Util.InputState.Default:
			handle_player_movement(delta)
			
		Util.InputState.Building:
			building_update()
		Util.InputState.HoldingTile:
			holding_tile_update()
		Util.InputState.SelectingTech:
			if Input.is_action_just_pressed("right_click"):
				switch_state(Util.InputState.Default)
		Util.InputState.GhostItem:
			if Input.is_action_just_pressed("item_menu"):
				switch_state(Util.InputState.Default)
	#if Input.is_action_just_pressed("click"):
		#Util.main.place_tile(Util.mouse_grid_pos)
	
func switch_state(new_state : Util.InputState):
	if state == new_state:
		return
	match state:
		Util.InputState.Building:
			choice_menu.close()
		Util.InputState.HoldingTile:
			held_tile.queue_free()
			held_tile = null
		Util.InputState.SelectingTech:
			tech_menu.close()
		Util.InputState.GhostItem:
			item_menu.close()
	state = new_state
	match state:
		Util.InputState.Building:
			choice_menu.open()
		Util.InputState.SelectingTech:
			tech_menu.open()
		Util.InputState.GhostItem:
			item_menu.open()
			
	
func actual_player_movement(delta: float):
	var vel = Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		vel.y -=1;
	if Input.is_action_pressed("move_down"):
		vel.y +=1;
	if Input.is_action_pressed("move_right"):
		vel.x +=1;
	if Input.is_action_pressed("move_left"):
		vel.x -=1;
	player.move(vel,delta)
	var mouse_too_far : bool = false
	if abs(Util.mouse_grid_pos.x-player.point.x) > player.reach or abs(Util.mouse_grid_pos.y-player.point.y) > player.reach:
		mouse_too_far = true
	if mouse_too_far:
		return
	if Input.is_action_just_pressed("click"):
		var _tile = Util.main.which_tile_here(Util.mouse_grid_pos)
		if _tile != null:
			if _tile.inventory.not_empty() and player.inventory.has_space():
				var _item : String = _tile.inventory.get_first()
				player.inventory.add(_item)
				Util.main.send_tile(_tile)
				return
	if Input.is_action_just_pressed("right_click"):
		if player.inventory.not_empty() == false:
			return
		var _tile = Util.main.which_tile_here(Util.mouse_grid_pos)
		if _tile == null:
			_tile = Util.main.place_tile(Util.mouse_grid_pos)
		if _tile.inventory.has_space():
			var _item : String = player.inventory.get_first()
			_tile.inventory.add(_item)
			Util.main.send_tile(_tile)
		return
	
func handle_player_movement(delta: float):
	if Input.is_action_just_pressed("item_menu"):
		switch_state(Util.InputState.GhostItem)
		return
	if Input.is_action_just_pressed("build_mode"):
		switch_state(Util.InputState.Building)
		return
	#pipette
	if Input.is_action_just_pressed("pipette"):
		if Util.main.tiles.has(Util.mouse_grid_pos) == false:
			return
		var hovered_tile : Tile = Util.main.tiles[Util.mouse_grid_pos]
	
		set_held_tile(hovered_tile.tile_type)
		held_tile.facing = hovered_tile.facing
	if Input.is_action_just_pressed("craft"):
		var _tile = Util.main.which_tile_here(player.point)
		if _tile != null:
			if _tile.to_be_demolished:
				player.try_demolishing(_tile)
				return
			if _tile.ghost:
				player.try_building(_tile)
				if player.state == Agent.AgentState.Working:
					return
		player.try_craft()
		if player.state == Agent.AgentState.Working:
			return
		if player.inventory.is_empty():
			
			if _tile != null and _tile.tile_type == "altar" and Progress.is_altar_completed(player.point) == false:
				#todo: check if altar is already done or not
				switch_state(Util.InputState.SelectingTech)
		return
	actual_player_movement(delta)
	return
	if Input.is_action_just_pressed("click"):
		if Util.mouse_grid_pos != player.point:
			player_find_path_to(Util.mouse_grid_pos)
			moving_with_intent = 1
			return
		var _tile = Util.main.which_tile_here(Util.mouse_grid_pos)
		if _tile != null:
			if _tile.inventory.not_empty() and player.inventory.has_space():
				var _item : String = _tile.inventory.get_first()
				player.inventory.add(_item)
				Util.main.send_tile(_tile)
				return
	if Input.is_action_just_pressed("right_click"):
		if Util.mouse_grid_pos != player.point:
			player_find_path_to(Util.mouse_grid_pos)
			moving_with_intent = 2
			return
		if player.inventory.not_empty() == false:
			return
		var _tile = Util.main.which_tile_here(Util.mouse_grid_pos)
		if _tile == null:
			_tile = Util.main.place_tile(Util.mouse_grid_pos)
		if _tile.inventory.has_space():
			var _item : String = player.inventory.get_first()
			_tile.inventory.add(_item)
			Util.main.send_tile(_tile)
		return

func building_update():
	if Input.is_action_just_pressed("build_mode"):
		switch_state(Util.InputState.Default)
		return
	
	
	if Util.main.tiles.has(Util.mouse_grid_pos) == false:
		return
	var hovered_tile : Tile = Util.main.tiles[Util.mouse_grid_pos]
	#pipette
	if Input.is_action_just_pressed("pipette"):
		set_held_tile(hovered_tile.tile_type)
		held_tile.facing = hovered_tile.facing
	#todo: let you rotate placed tiles
	if Input.is_action_just_pressed("rotate_right") and not Input.is_action_just_pressed("rotate_left"):
		hovered_tile.rotate_facing(true)
		Util.main.send_tile(hovered_tile)
	if Input.is_action_just_pressed("rotate_left"):
		hovered_tile.rotate_facing(false)
		Util.main.send_tile(hovered_tile)
	#todo: delete tiles
	if Input.is_action_just_pressed("right_click"):
		hovered_tile.mark_to_demolish()
	if Input.is_action_just_pressed("click"):
		if hovered_tile is Splitter:
			var sub_pos : Vector2 = Util.mouse_pos-Util.grid_to_real(Util.mouse_grid_pos)
			(hovered_tile as Splitter).swap_arrow_on(sub_pos)
		
func holding_tile_update():
	if Input.is_action_just_pressed("pipette"):
		switch_state(Util.InputState.Default)
		return
	if Input.is_action_just_pressed("build_mode"):
		switch_state(Util.InputState.Building)
		return
	held_tile.point = Util.mouse_grid_pos
	held_tile.position = Util.grid_to_real(held_tile.point)
	#todo: check for tiles already there
	held_tile.angry_ghost = false
	if Util.main.tiles.has(Util.mouse_grid_pos):
		if Util.main.tiles[Util.mouse_grid_pos].tile_type != "":
			held_tile.angry_ghost = true
	#rotate
	if Input.is_action_just_pressed("rotate_right") and not Input.is_action_just_pressed("rotate_left"):
		held_tile.rotate_facing(true)
	if Input.is_action_just_pressed("rotate_left"):
		held_tile.rotate_facing(false)
	#todo: blueprint mode
	
	if Input.is_action_just_pressed("click"):
		if held_tile.angry_ghost:
			pass
		else:
			var _tile =Util.main.place_tile(Util.mouse_grid_pos,held_tile.tile_type,held_tile.facing,true)
			Util.main.send_tile(_tile)

func set_held_tile(tile_type : String) -> Tile:
	if held_tile != null:
		held_tile.queue_free()
		held_tile = null
	held_tile = Util.main.spawn_tile(tile_type)
	held_tile.ghost =true
	switch_state(Util.InputState.HoldingTile)
	return held_tile
#region pathfinding
func create_astar_grid():
	pf = AStar2D.new()
	var tiles : Array[Vector2i] = Util.spiral(player.point,Util.main.game_size)
	for tile in tiles:
		pf.add_point(pf.get_available_point_id(),Vector2(tile.x,tile.y))
	for tile in tiles:
		var id : int = pf.get_closest_point(Vector2(tile.x,tile.y))
		for d in Util.directions:
			var n_tile : Vector2i = tile + d
			if n_tile not in tiles:
				continue
			var n_id : int= pf.get_closest_point(Vector2(n_tile.x,n_tile.y))
			pf.connect_points(id,n_id)
func update_astar_grid():
	pass

func player_find_path_to(point: Vector2i):
	var start_id: int = pf.get_closest_point(player.point)
	var end_id: int = pf.get_closest_point(point)
	var path = pf.get_point_path(start_id,end_id,true)
	player_path.clear()
	for p in path:
		player_path.append(Vector2i(p.x,p.y))
	player_path.pop_front()
		
#endregion
