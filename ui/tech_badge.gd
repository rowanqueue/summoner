extends Control

@export var tech_name : String
@onready var name_text: RichTextLabel = $VBoxContainer/HBoxContainer/Name
@onready var cost: RichTextLabel = $VBoxContainer/HBoxContainer/Cost
@onready var effects: RichTextLabel = $VBoxContainer/Effects

func _ready() -> void:
	if tech_name in Progress.techs:
		name_text.text = tech_name.capitalize()
		var _tech : Dictionary = Progress.techs[tech_name]
		cost.text = str(int(_tech.cost))+"x"
		var done_one := false
		for c in _tech.cost_type:
			cost.text+=Data.item_names[c]
			done_one = true
		effects.text = "Unlock\n"
		for effect in _tech.effects:
			match effect.type:
				"unlock-tile":
					for tile in effect.tiles:
						effects.text +=  "[img=36]art/tiles/"+tile+".png[/img]"


func _on_button_pressed() -> void:
	Progress.connect_tech_to_altar(tech_name,Util.main.player.point)
	Util.main.input_controller.switch_state(Util.InputState.Default)
