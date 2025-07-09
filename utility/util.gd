extends Node

var debug_hex: bool = false
const tile_size : int = 64
const hex_size : float = 48
var hex_distance : Vector2

var debug_free_build : bool = false

var should_load : bool = false
var should_save : bool = false

var directions_rect : Array[Vector2i] = [Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT,Vector2i.UP]
var directions_hex : Array[Vector2i] = [
	Vector2i(2,0),
	Vector2i(1,1),
	Vector2i(-1,1),
	Vector2i(-2,0),
	Vector2i(-1,-1),
	Vector2i(1,-1)
]
var directions : Array[Vector2i] :
	get :
		if Util.debug_hex:
			return directions_hex
		else:
			return directions_rect

var angles_rect : Array[float] = [
	0,
	90,
	180,
	270
]
var angles_hex : Array[float] = [
	0,
	60,
	120,
	180,
	240,
	300
]
var angles : Array[float] :
	get :
		if Util.debug_hex:
			return angles_hex
		else:
			return angles_rect

enum InputState{
	Default,
	Building,
	HoldingTile,
	SelectingTech,
	GhostItem
}

const tile_scene = preload("res://system/tile.tscn")
const splitter_script = preload("res://system/splitter.gd")

const agent_scene = preload("res://system/agent.tscn")
const free_agent_scene = preload("res://system/free_agent.tscn")
var main : Main
var input_controller : InputController
var camera : Camera2D

var mouse_grid_pos : Vector2i
var mouse_pos : Vector2

func _init() -> void:
	hex_distance.x = sqrt(3.0)*hex_size
	hex_distance.y = 2.0* hex_size*0.75
	


func _process(_delta: float) -> void:
	if main:
		camera.position = main.player.position#+= (grid_to_real(main.player.point)-camera.position)*0.05
		mouse_pos = camera.get_global_mouse_position()#get_viewport().get_global_mouse_position()
	if Util.debug_hex:
		mouse_grid_pos = real_to_grid(mouse_pos)
	else:
		#mouse_pos += 
		mouse_grid_pos = real_to_grid(mouse_pos+(Vector2.ONE*0.5*Util.tile_size))
	
func grid_to_real(grid_pos : Vector2i) -> Vector2:
	if debug_hex:
		return hex_to_real(grid_pos)
	var real : Vector2 = grid_pos*Util.tile_size
	return real
	
func real_to_grid(real_pos : Vector2) -> Vector2i:
	if debug_hex:
		return real_to_hex(real_pos)
	var grid_pos : Vector2i
	#grid_pos.x = real_pos.x - (real_pos.x as int%Util.tile_size)
	#grid_pos.y = real_pos.y - (real_pos.y as int%Util.tile_size)
	#grid_pos /= Util.tile_size
	grid_pos.x = floori(real_pos.x / Util.tile_size)
	grid_pos.y = floori(real_pos.y / Util.tile_size)
	return grid_pos

	
func ring(center : Vector2i, radius : int) -> Array[Vector2i]:
	if debug_hex:
		return hex_ring(center,radius)
	var results : Array[Vector2i] = []
	var hex : Vector2i = center + (Vector2i(-1,-1)*radius)
	for x in 4:
		for j in radius*2:
			results.append(hex)
			hex += directions[x]
	return results
	
func hex_to_real(grid_pos : Vector2i) -> Vector2:
	var real_pos : Vector2 = grid_pos as Vector2
	real_pos.y *= hex_distance.y
	if grid_pos.y % 2 == 1:
		real_pos.x = ((real_pos.x -1)*0.5 * hex_distance.x) + (hex_distance.x/2)
	else:
		real_pos.x = real_pos.x * 0.5 * hex_distance.x
	return real_pos
	
func real_to_hex(real_pos : Vector2) -> Vector2i:
	var grid_pos : Vector2i = Vector2i.ZERO
	var q = ((sqrt(3.0)/3.0)*real_pos.x - (1.0/3.0)*real_pos.y)/hex_size
	var r = ((2.0/3.0)*real_pos.y)/hex_size
	var fractional_cube : Vector3 = Vector3.ZERO
	fractional_cube.x = q
	fractional_cube.z = r
	fractional_cube.y = -fractional_cube.x - fractional_cube.z
	var actual_cube : Vector3 = Vector3(roundf(fractional_cube.x),roundf(fractional_cube.y),roundf(fractional_cube.z))
	var x_diff = abs(actual_cube.x-fractional_cube.x)
	var y_diff = abs(actual_cube.y-fractional_cube.z)
	var z_diff = abs(actual_cube.y-fractional_cube.z)
	if x_diff > y_diff and x_diff > z_diff:
		actual_cube.x = -actual_cube.y - actual_cube.z
	elif y_diff > z_diff:
		actual_cube.y = -actual_cube.x - actual_cube.z
	else:
		actual_cube.z = -actual_cube.x - actual_cube.y
	grid_pos = cube_to_hex(Vector3i(roundi(actual_cube.x),roundi(actual_cube.y),roundi(actual_cube.z)))
	return grid_pos

func cube_to_hex(cube_pos : Vector3i) -> Vector2i:
	var col = 2 * cube_pos.x + cube_pos.z
	var row = cube_pos.z
	return Vector2i(col,row)

func hex_distance_check(a : Vector2i, b: Vector2i) -> int:
	var dx = abs(a.x-b.x)
	var dy = abs(a.y-b.y)
	return dy + max(0,(dx-dy)/2)

func hex_ring(center : Vector2i, radius : int) -> Array[Vector2i]:
	var results : Array[Vector2i] = []
	var hex : Vector2i = center + directions[4]*radius
	for x in 6:
		for j in radius:
			results.append(hex)
			hex += directions[x]
	return results
	
func spiral(center: Vector2i, radius : int) -> Array[Vector2i]:
	var results : Array[Vector2i] = []
	results.append(center)
	for i in radius:
		if i == 0:
			continue
		results.append_array(ring(center,i))
	return results
	

func get_direction_between(current: Vector2i,to:Vector2i) -> int:
	var between : Vector2i = to - current
	for i in directions.size():
		var dir = directions[i]
		if between == dir:
			return i
	return 0
