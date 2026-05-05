extends CanvasLayer
## SceneTransition - Smooth fade transitions between scenes

var _overlay: ColorRect
var _is_transitioning := false

func _ready() -> void:
	layer = 100  # Always on top
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

func goto(scene_path: String, duration: float = 0.4) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Fade to black
	var tw := create_tween()
	tw.tween_property(_overlay, "color", Color(0, 0, 0, 1), duration)
	await tw.finished
	
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Fade from black
	var tw2 := create_tween()
	tw2.tween_property(_overlay, "color", Color(0, 0, 0, 0), duration)
	await tw2.finished
	
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_transitioning = false

func flash(color: Color = Color.WHITE, duration: float = 0.2) -> void:
	var orig := _overlay.color
	_overlay.color = color
	var tw := create_tween()
	tw.tween_property(_overlay, "color", Color(color.r, color.g, color.b, 0), duration)
	await tw.finished
	_overlay.color = orig
