extends Node

class_name Inventory

var items : Array[String]
var size : int = 4

@onready var label: RichTextLabel = $RichTextLabel

func _ready() -> void:
	label.text = ""

func _process(delta: float) -> void:
	label.text = ""
	#label.text = "[bgcolor=#ffffff55][/color]"
	for item in items:
		if Data.item_names.has(item):
			label.text += Data.item_names[item]
		else :
			label.text += item
	#for i in (size-items.size()):
		#label.text +=" _"
		
func is_equal(inv: Inventory) -> bool:
	var mine : String = Data.item_list_to_id(items)
	var theirs : String = Data.item_list_to_id(inv.items)
	if mine == theirs:
		return true
	return false
			
func add(item: String) -> void:
	items.append(item)

func remove(item: String) -> void:
	items.erase(item)
	
func get_first() -> String:
	return items.pop_front()
	
func has_item(item : String) -> bool:
	return items.has(item)
	
func get_item(item: String) -> String:
	items.erase(item)
	return item

func is_empty() -> bool:
	return items.size() == 0

func not_empty() -> bool:
	return items.size() > 0
	
func has_space() -> bool:
	return items.size() < size

func try_transfer_first_to(inv: Inventory) -> bool:
	if not_empty() == false:
		return false
	if has_space() == false:
		return false
	#check if inv is full
	var item = get_first()
	inv.add(item)
	return true
	
#region saving
func Save() -> Dictionary:
	var data : Dictionary = {
		"items": items
		}
	return data
	
func Load(data : Dictionary) -> void:
	for item in data.items:
		add(item)
#endregion
