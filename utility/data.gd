extends Node
const tile_data = preload("res://data/tiles.json")
const recipe_data = preload("res://data/recipes.json")

var tiles : Dictionary[String,Array]
var tiles_by_id : Dictionary[String,Dictionary]


var all_recipes : Dictionary[String,Array]
#item string to skill string to tile 
var recipes : Dictionary[String,Dictionary]

var item_names: Dictionary

func _ready() -> void:
	for _tile_data in tile_data.data["tiles"]:
		tiles[_tile_data] = tile_data.data["tiles"][_tile_data]
		for _tile in tiles[_tile_data]:
			ensure_tile_data(_tile)
			tiles_by_id[_tile.id] = _tile
	for _recipe_data in recipe_data.data["recipes"]:
		all_recipes[_recipe_data] = recipe_data.data["recipes"][_recipe_data]
		for _recipe in all_recipes[_recipe_data]:
			ensure_recipe_data(_recipe)
			if recipes.has(_recipe.id) == false:
				recipes[_recipe.id] = {}
			var skill_name : String
			if "skill" in _recipe:
				skill_name = _recipe.skill
			else:
				skill_name = "*"
			if recipes[_recipe.id].has(skill_name) == false:
				recipes[_recipe.id][skill_name] = {}
			if "tile" in _recipe:
				recipes[_recipe.id][skill_name][_recipe.tile] = _recipe
			else:
				recipes[_recipe.id][skill_name]["*"] = _recipe
	#print(recipes)
	for _item_name in recipe_data.data["items"]:
		item_names[_item_name] = "[img=18]art/items/"+_item_name+".png[/img]"

func ensure_tile_data(tile_data : Dictionary):
	if "id" not in tile_data:
		tile_data.id = tile_data.name
	tile_data["description"] = tile_data.name
	var a = "\n"
	#if "cost" in tile_data:
		#var done_one = false
		#for _item_name in tile_data.cost:
			#if done_one:
				#a += ","
			#var _item = Item.new(_item_name,tile_data.cost[_item_name])
			#a += str(_item)
			#done_one = true
		#tile_data.description += a


	return a
func ensure_recipe_data(recipe_data : Dictionary):
	if "input" not in recipe_data:
		recipe_data.input = []
	if "output" not in recipe_data:
		recipe_data.output = []
	recipe_data.id = item_list_to_id(recipe_data.input)
	
	

func pretty_num(_num : float) -> String:
	if is_equal_approx(_num,_num as int):
		return str(_num as int)
	return str(_num)

func item_list_to_id(items : Array) -> String:
	var id : String = ""
	var _items = items.duplicate()
	_items.sort()
	for item in _items:
		id += item
	return id

func is_recipe_input(input : Array[String],skills: Array,tile : String) -> bool:
	var id : String = item_list_to_id(input)
	if recipes.has(id) == false:
		return false
	for skill in skills:
		if recipes[id].has(skill):
			if recipes[id][skill].has(tile):
				return true
			if recipes[id][skill].has("*"):
				return true
	if recipes[id].has("*") == false:
		return false
	if recipes[id]["*"].has(tile):
		return true
	if recipes[id]["*"].has("*"):
		return true
	return false

func get_recipe_from_input(input : Array[String],skills: Array, tile : String) -> Dictionary:
	var id : String = item_list_to_id(input)
	if recipes.has(id) == false:
		return {}
	for skill in skills:
		if recipes[id].has(skill):
			if recipes[id][skill].has(tile):
				return recipes[id][skill][tile]
			if recipes[id][skill].has("*"):
				return recipes[id][skill]["*"]
	if recipes[id].has("*") == false:
		return {}
	if recipes[id][ "*"].has(tile):
		return recipes[id][ "*"][tile]
	if recipes[id][ "*"].has("*"):
		return recipes[id][ "*"]["*"]
	
	return {}
