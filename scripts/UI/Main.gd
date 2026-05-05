extends Node
## Main - Entry point, immediately goes to main menu

func _ready() -> void:
	# Short delay then go to main menu
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
