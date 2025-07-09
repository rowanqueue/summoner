extends Node
const research_data = preload("res://data/research.json")

#name to tech
var techs : Dictionary[String,Dictionary]
#name to how many research points it has
var available_techs : Dictionary[String,int]
#hmm how to connect each altar with a specific research
var tech_altars : Dictionary[Vector2i,String]

var completed_techs : Array[String]

var tiles : Array[String]

func _init() -> void:
	for tech in research_data.data.techs:
		techs[tech.name] = tech
		if "start" in tech:
			unlock_tech(tech.name)
			continue
		if "prereqs" in tech:
			if tech.prereqs.size() == 0:
				available_techs[tech.name] = 0
		else:
			available_techs[tech.name] = 0
			
func check_for_prereqs():
	#todo: lol optimize this
	for tech_name in techs.keys():
		if completed_techs.has(tech_name):
			continue
		if "prereqs" not in techs[tech_name]:
			continue
		if available_techs.has(tech_name):
			continue
		var good : bool = true
		for prereq in techs[tech_name].prereqs:
			if completed_techs.has(prereq) == false:
				good = false
				break
		if good == false:
			continue
		available_techs[tech_name] = 0

func _process(delta: float) -> void:
	var deleted_altars : Array[Vector2i]
	for altar in tech_altars.keys():
		var tile : Tile = Util.main.which_tile_here(altar)
		if tile == null:
			deleted_altars.append(altar)
			continue
		if tile.tile_type != "altar":
			deleted_altars.append(altar)
	for altar in deleted_altars:
		tech_altars.erase(altar)

func get_all_available_unbuilt_techs() -> Array[String]:
	var _techs : Array[String]
	for _tech in available_techs.keys():
		if _tech not in tech_altars.values():
			_techs.append(_tech)
	return _techs

func connect_tech_to_altar(tech_name : String, altar : Vector2i):
	tech_altars[altar] = tech_name
	Util.main.send_tech_update()

func is_altar_completed(altar : Vector2i) -> bool:
	if altar not in tech_altars:
		return false
	var tech_name = tech_altars[altar]
	return tech_name in completed_techs

func get_tech_recipe(tech_name : String, inv : Inventory):
	if completed_techs.has(tech_name):
		return {}
	var recipe : Dictionary = {"input":[],"output":[],"research":tech_name}
	#todo: implement techs that need more than one science
	if inv.has_item(techs[tech_name].cost_type[0]):
		recipe.input.append(techs[tech_name].cost_type[0])
		return recipe
	return {}
	
func try_advance_tech(tech_name : String):
	if completed_techs.has(tech_name):
		return
	
	advance_tech(tech_name)
	

func advance_tech(tech_name : String):
	available_techs[tech_name] += 1
	
	if available_techs[tech_name] >= techs[tech_name].cost:
		unlock_tech(tech_name)
	Util.main.send_tech_update()
		
func unlock_tech(tech_name : String):
	if tech_name in completed_techs:
		return
	completed_techs.append(tech_name)
	if available_techs.has(tech_name):
		available_techs.erase(tech_name)
	check_for_prereqs()
	for effect in techs[tech_name].effects:
		do_effect(effect)
		
func do_effect(effect: Dictionary):
	match effect.type:
		"unlock-tile":
			for tile in effect.tiles:
				tiles.append(tile)
	
#region saving
func Save() -> Dictionary:
	var data : Dictionary = {
		"techs":[]
	}
	for altar in tech_altars:
		var tech_data = {"name":tech_altars[altar]}
		tech_data.point = {"x":altar.x,"y":altar.y}
		if tech_data.name in completed_techs:
			tech_data["complete"] = true
		if tech_data.name in available_techs:
			if available_techs[tech_data.name] > 0:
				tech_data["amount"] = available_techs[tech_data.name]
		data.techs.append(tech_data)
	return data
	
func Load(data : Dictionary) -> void:
	_init()
	print(data)
	for tech in data.techs:
		var point = Vector2i(tech.point.x,tech.point.y)
		connect_tech_to_altar(tech.name,point)
		if "complete" in tech:
			unlock_tech(tech.name)
		if "amount" in tech:
			available_techs[tech.name] = tech.amount
		

func Clear() -> void:
	available_techs.clear()
	tech_altars.clear()
	completed_techs.clear()
	tiles.clear()
#endregion
