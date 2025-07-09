extends Control

var hex = preload("res://art/hex_border.png")
var too_far : bool = false
func _draw():
	if Util.debug_hex:
		#draw_texture(hex,position,Color.WHITE)
		var _scale = Util.hex_size / 128.0
		draw_texture_rect(hex,Rect2(Vector2.ZERO-(Vector2.ONE*128*_scale),Vector2.ONE*256*_scale),false)
	else:
		draw_rect(Rect2(0,0,Util.tile_size,Util.tile_size),Color.CRIMSON if too_far else Color.WHITE,false,2)
		
		
func _process(_delta: float) -> void:
	
	queue_redraw()
	#scale = Vector2.ONE* (Util.hex_size/128.0)
	too_far = false
	var grid_pos
	if Util.debug_hex:
		grid_pos = Util.real_to_grid(Util.camera.get_global_mouse_position())
	else:
		grid_pos = Util.real_to_grid(Util.camera.get_global_mouse_position()+(Vector2.ONE*0.5*Util.tile_size))
	if abs(grid_pos.x-Util.main.player.point.x) > Util.main.player.reach or abs(grid_pos.y-Util.main.player.point.y) > Util.main.player.reach:
		too_far = true
	position = Util.grid_to_real(grid_pos)
	if Util.debug_hex == false:
		position -= Vector2.ONE*0.5*Util.tile_size
