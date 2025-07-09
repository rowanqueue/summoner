extends Container

const RECIPE_BADGE = preload("res://ui/recipe_badge.tscn")
@export var custom_size : float = 128

func _ready() -> void:
	#print(Data.recipes)
	custom_minimum_size.x = custom_size
	for recipe_cat in Data.all_recipes.values():
		for recipe in recipe_cat:
			var recipe_badge = RECIPE_BADGE.instantiate()
			recipe_badge.recipe = recipe
			recipe_badge.custom_minimum_size = Vector2.ONE*custom_size
			get_child(0).add_child(recipe_badge)
			#recipe_badge.set_recipe(recipe)
