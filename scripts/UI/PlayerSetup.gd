extends Control
## PlayerSetup - Choose number of players and enter names

var _player_count := 3
var _name_inputs: Array = []
const MAX_PLAYERS := 6
const MIN_PLAYERS := 2

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	_build_ui()

func _build_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.02, 0.1)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	# Decorative top bar
	var bar := ColorRect.new()
	bar.color = Color(0.85, 0.65, 0.1)
	bar.anchor_right = 1.0
	bar.offset_bottom = 8.0
	add_child(bar)

	# Scroll container for long player lists
	var scroll := ScrollContainer.new()
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_top = 40.0
	scroll.offset_bottom = -10.0
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.offset_left = 50.0
	vbox.offset_right = -50.0
	scroll.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "🧑‍⚖️ SPILLERE"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.95, 0.75, 0.1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size.y = 110
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "Hvem er med i retssalen i dag?"
	sub.add_theme_font_size_override("font_size", 28)
	sub.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.custom_minimum_size.y = 50
	vbox.add_child(sub)

	vbox.add_child(_spacer(20))

	# Player count selector
	var count_box := HBoxContainer.new()
	count_box.alignment = BoxContainer.ALIGNMENT_CENTER
	count_box.custom_minimum_size.y = 90
	vbox.add_child(count_box)

	var minus_btn := Button.new()
	minus_btn.text = "−"
	minus_btn.custom_minimum_size = Vector2(80, 80)
	minus_btn.add_theme_font_size_override("font_size", 44)
	minus_btn.pressed.connect(_on_minus)
	count_box.add_child(minus_btn)

	var count_label_box := VBoxContainer.new()
	count_label_box.custom_minimum_size = Vector2(260, 80)
	count_box.add_child(count_label_box)

	var count_title := Label.new()
	count_title.text = "ANTAL SPILLERE"
	count_title.add_theme_font_size_override("font_size", 20)
	count_title.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75))
	count_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label_box.add_child(count_title)

	var count_num := Label.new()
	count_num.name = "CountLabel"
	count_num.text = str(_player_count)
	count_num.add_theme_font_size_override("font_size", 52)
	count_num.add_theme_color_override("font_color", Color(0.95, 0.75, 0.1))
	count_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label_box.add_child(count_num)

	var plus_btn := Button.new()
	plus_btn.text = "+"
	plus_btn.custom_minimum_size = Vector2(80, 80)
	plus_btn.add_theme_font_size_override("font_size", 44)
	plus_btn.pressed.connect(_on_plus)
	count_box.add_child(plus_btn)

	vbox.add_child(_spacer(20))

	# Player name inputs container
	var names_container := VBoxContainer.new()
	names_container.name = "NamesContainer"
	vbox.add_child(names_container)

	vbox.add_child(_spacer(30))

	# Start button
	var start_btn := Button.new()
	start_btn.name = "StartBtn"
	start_btn.text = "⚖️  ÅBEN RETSSALEN!"
	start_btn.custom_minimum_size = Vector2(0, 110)
	start_btn.add_theme_font_size_override("font_size", 38)
	start_btn.add_theme_color_override("font_color", Color(0.05, 0.02, 0.08))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.85, 0.65, 0.1)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.shadow_color = Color(0.85, 0.65, 0.1, 0.5)
	style.shadow_size = 8
	start_btn.add_theme_stylebox_override("normal", style)
	start_btn.pressed.connect(_on_start)
	vbox.add_child(start_btn)

	# Back button
	var back_btn := Button.new()
	back_btn.text = "← Tilbage"
	back_btn.custom_minimum_size = Vector2(0, 70)
	back_btn.add_theme_font_size_override("font_size", 26)
	back_btn.pressed.connect(func(): SceneTransition.goto("res://scenes/MainMenu.tscn"))
	vbox.add_child(back_btn)

	vbox.add_child(_spacer(40))

	_refresh_name_inputs()

func _refresh_name_inputs() -> void:
	var container := get_node_or_null("*/NamesContainer")
	if container == null:
		# fallback: find it
		for c in get_children():
			var found := c.find_child("NamesContainer", true, false)
			if found:
				container = found
				break
	if container == null:
		return

	# Clear existing
	for c in container.get_children():
		c.queue_free()
	_name_inputs.clear()

	# Update count label
	var count_lbl := find_child("CountLabel", true, false)
	if count_lbl:
		count_lbl.text = str(_player_count)

	var role_labels := ["Spiller 1 (Anklager 🔴)", "Spiller 2 (Tiltalte 🔵)", "Spiller 3 (Vidne 🟢)", "Spiller 4 (Vidne 🟡)", "Spiller 5 (Vidne 🟣)", "Spiller 6 (Vidne 🟠)"]
	var placeholder_names := ["Joanna", "Mikkel", "Sofie", "Lars", "Emma", "Thomas"]
	var colors := [Color(0.95, 0.3, 0.3), Color(0.3, 0.5, 0.95), Color(0.3, 0.85, 0.4), Color(0.95, 0.75, 0.1), Color(0.85, 0.3, 0.85), Color(0.95, 0.55, 0.1)]

	for i in range(_player_count):
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 90

		var dot := ColorRect.new()
		dot.color = colors[i]
		dot.custom_minimum_size = Vector2(8, 70)
		row.add_child(dot)

		var lbl := Label.new()
		lbl.text = role_labels[i] if i < role_labels.size() else "Spiller %d" % (i + 1)
		lbl.custom_minimum_size = Vector2(320, 70)
		lbl.add_theme_font_size_override("font_size", 22)
		lbl.add_theme_color_override("font_color", colors[i])
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(lbl)

		var input := LineEdit.new()
		input.placeholder_text = placeholder_names[i % placeholder_names.size()]
		input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		input.custom_minimum_size.y = 70
		input.add_theme_font_size_override("font_size", 28)
		input.max_length = 18
		row.add_child(input)

		container.add_child(row)
		_name_inputs.append(input)

		container.add_child(_spacer(8))

func _on_minus() -> void:
	if _player_count > MIN_PLAYERS:
		_player_count -= 1
		_refresh_name_inputs()

func _on_plus() -> void:
	if _player_count < MAX_PLAYERS:
		_player_count += 1
		_refresh_name_inputs()

func _on_start() -> void:
	var names: Array = []
	for inp: LineEdit in _name_inputs:
		var n := inp.text.strip_edges()
		if n.is_empty():
			n = inp.placeholder_text
		names.append(n)

	if names.size() < MIN_PLAYERS:
		return

	GameManager.setup_players(names)
	AudioMgr.play_gavel()
	SceneTransition.goto("res://scenes/Courtroom.tscn")

func _spacer(h: float) -> Control:
	var s := Control.new()
	s.custom_minimum_size.y = h
	return s
