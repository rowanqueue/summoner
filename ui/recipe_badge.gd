extends Control

class_name RecipeBadge

@onready var skill: TextCircle = $VBoxContainer/HBoxContainer/Skill

@onready var tile: TextCircle = $VBoxContainer/HBoxContainer/Tile

@onready var result: HBoxContainer = $VBoxContainer/Result
@onready var input: HBoxContainer = $VBoxContainer/Input

@onready var item: TextCircle = $VBoxContainer/Result/Item

var recipe : Dictionary

func _ready() -> void:
	if recipe != {}:
		set_recipe(recipe)
	#set_recipe(Data.recipes["leaf"]["*"]["*"])

func set_recipe(_recipe : Dictionary):
	recipe = _recipe
	#skill.visible = false
	#tile.visible = false
	skill.modulate.a = 0
	tile.modulate.a = 0
	if "skill" in recipe:
		skill.modulate.a = 1
		skill.set_text(recipe.skill)
	if "tile" in recipe:
		tile.modulate.a = 1
		var s = "[img=25]art/tiles/"+recipe.tile+".png[/img]"
		tile.set_text(s)
	for _item_name in recipe.input:
		var _item = item.duplicate()
		_item.set_text(Data.item_names[_item_name].replace("18","36"))
		input.add_child(_item)
	#if recipe.output.size() <= 2:
		#result.size.y = 128
		#result.position.y = 64
	#else:
		#result.size.y = 64
		#result.position.y = 96
	for i in recipe.output.size():
		var _item : TextCircle
		if i > 0:
			_item = item.duplicate()
		else:
			_item = item

		_item.set_text(Data.item_names[recipe.output[i]].replace("18","36"))
		result.add_child(_item)
