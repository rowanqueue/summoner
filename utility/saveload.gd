class_name SaveLoad

const version : int = 0
const file_path : String = "res://debug/save.json"
const user_file_path : String = "user://save.json"

var save_path : String :
	get :
		if OS.has_feature("editor"):
			return file_path
		match OS.get_name():
			"Web":
				return user_file_path
		return user_file_path

static func Clear():
	Util.main.Clear()
	Progress.Clear()
	
static func HasSave() -> bool:
	if not FileAccess.file_exists(file_path):
		return false
	return true

static func Save():
	var save : Dictionary = {
		"version": version,
		"name":"me",
		"elapsedTime" : Util.main.time_banked + (Time.get_unix_time_from_system()-Util.main.time_start_session),
		"progress" : {},
		"world" : {},
	}
	#actual saving
	save.progress = Progress.Save()
	save.world = Util.main.Save()
	#finish saving
	var save_game = FileAccess.open(file_path,FileAccess.WRITE)
	var json_string = JSON.stringify(save)
	#print(json_string)
	save_game.store_string(json_string)
	save_game.close()
	Util.main.time_banked = save.elapsedTime
	Util.main.time_start_session = Time.get_unix_time_from_system()

static func Load():
	if not FileAccess.file_exists(file_path):
		return false
	var save_game = FileAccess.open(file_path,FileAccess.READ)
	var json_string = save_game.get_as_text()
	save_game.close()
	var save = JSON.parse_string(json_string)
	#load everything
	Clear()
	Util.main.time_banked = save.elapsedTime
	Util.main.time_start_session = Time.get_unix_time_from_system()
	Util.main.Load(save.world)
	Progress.Load(save.progress)
	return true
