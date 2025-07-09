extends RefCounted

class_name Item

var name : String = ""
var amount : int = 0

func _init(_name : String = "", _amount : int = 0) -> void:
	name = _name
	amount = _amount

func _to_string() -> String:
	var _name = name
	if "in_" in _name:
		_name = _name.substr(3,_name.length())
	if _name in Data.item_names:
		_name = Data.item_names[_name]
	if name.contains("hormone_0"):
		return ("✔️" if amount > 0 else "❌") + _name
	return Data.pretty_num(amount) + _name
	
func add(more : int):
	amount += more
	if name.contains("hormone_0"):
		amount = clamp(amount,0,1)
	
func subtract(less : int):
	amount -= less
	
func save() -> Dictionary:
	var _save = {}
	_save["name"] = name
	_save["amount"] = amount
	return _save
