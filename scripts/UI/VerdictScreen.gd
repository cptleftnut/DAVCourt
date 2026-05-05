extends Control
## VerdictScreen - Final scores, winner reveal, and play again

var _anim_time := 0.0
var _winner: Dictionary = {}
var _confetti_nodes: Array = []

const COLORS := [Color(0.95,0.3,0.3), Color(0.3,0.5,0.95), Color(0.3,0.85,0.4),
				 Color(0.95,0.75,0.1), Color(0.85,0.3,0.85), Color(0.95,0.55,0.1)]

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	_winner = GameManager.get_winner()
	_build_ui()
	_spawn_confetti()
	AudioMgr.play_bling()
	AudioMgr.play_crowd_cheer()

func _process(delta: float) -> void:
	_anim_time += delta
	_animate_confetti(delta)

# ─── UI ──────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	# Deep dark background
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.01, 0.08)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	# Gold top bar
	var bar := ColorRect.new()
	bar.color = Color(0.85, 0.65, 0.1)
	bar.anchor_right = 1.0
	bar.offset_bottom = 10.0
	add_child(bar)

	# Bottom bar
	var bar2 := ColorRect.new()
	bar2.color = Color(0.85, 0.65, 0.1)
	bar2.anchor_right = 1.0
	bar2.anchor_bottom = 1.0
	bar2.offset_top = -10.0
	add_child(bar2)

	# Scroll container
	var scroll := ScrollContainer.new()
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_top = 15.0
	scroll.offset_bottom = -15.0
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.offset_left = 40.0
	vbox.offset_right = -40.0
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	scroll.add_child(vbox)

	vbox.add_child(_spacer(30))

	# DOMMEN header
	var verdict_header := Label.new()
	verdict_header.text = "🔨 DOMMEN ER AFSAGT 🔨"
	verdict_header.add_theme_font_size_override("font_size", 52)
	verdict_header.add_theme_color_override("font_color", Color(0.95, 0.75, 0.1))
	verdict_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	verdict_header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(verdict_header)

	vbox.add_child(_spacer(20))

	# Winner block
	_build_winner_block(vbox)

	vbox.add_child(_spacer(30))

	# Score table
	_build_score_table(vbox)

	vbox.add_child(_spacer(30))

	# Snoop quote
	_build_snoop_quote(vbox)

	vbox.add_child(_spacer(30))

	# Action buttons
	_build_buttons(vbox)

	vbox.add_child(_spacer(50))

func _build_winner_block(parent: VBoxContainer) -> void:
	var panel := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.07, 0.02)
	style.border_color = Color(0.85, 0.65, 0.1)
	style.set_border_width_all(4)
	style.set_corner_radius_all(24)
	style.shadow_color = Color(0.85, 0.65, 0.1, 0.5)
	style.shadow_size = 20
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size.y = 280
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 30.0
	vbox.offset_right = -30.0
	vbox.offset_top = 20.0
	vbox.offset_bottom = -20.0
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var crown := Label.new()
	crown.text = "👑"
	crown.add_theme_font_size_override("font_size", 80)
	crown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(crown)

	var winner_lbl := Label.new()
	winner_lbl.text = "VINDER"
	winner_lbl.add_theme_font_size_override("font_size", 28)
	winner_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	winner_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(winner_lbl)

	var name_lbl := Label.new()
	name_lbl.text = _winner.get("name", "???")
	name_lbl.add_theme_font_size_override("font_size", 72)
	var win_idx: int = _winner.get("index", 0)
	name_lbl.add_theme_color_override("font_color", COLORS[win_idx % COLORS.size()])
	name_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	name_lbl.add_theme_constant_override("shadow_offset_x", 3)
	name_lbl.add_theme_constant_override("shadow_offset_y", 3)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	var score_lbl := Label.new()
	score_lbl.text = "%d point 🌿" % _winner.get("score", 0)
	score_lbl.add_theme_font_size_override("font_size", 36)
	score_lbl.add_theme_color_override("font_color", Color(0.95, 0.75, 0.1))
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(score_lbl)

func _build_score_table(parent: VBoxContainer) -> void:
	var header := Label.new()
	header.text = "📊 ALLE RESULTATER"
	header.add_theme_font_size_override("font_size", 32)
	header.add_theme_color_override("font_color", Color(0.85, 0.65, 0.1))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(header)

	parent.add_child(_spacer(15))

	# Sort players by score desc
	var sorted_players := GameManager.players.duplicate()
	sorted_players.sort_custom(func(a, b): return a.get("score", 0) > b.get("score", 0))

	for i in range(sorted_players.size()):
		var p: Dictionary = sorted_players[i]
		var row := _build_score_row(p, i)
		parent.add_child(row)
		parent.add_child(_spacer(8))

func _build_score_row(p: Dictionary, rank: int) -> Control:
	var panel := Panel.new()
	panel.custom_minimum_size.y = 88
	var style := StyleBoxFlat.new()
	var idx: int = p.get("index", 0)
	var col := COLORS[idx % COLORS.size()]
	style.bg_color = Color(col.r * 0.15, col.g * 0.15, col.b * 0.15, 0.9)
	style.border_color = col
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.anchor_right = 1.0
	hbox.anchor_bottom = 1.0
	hbox.offset_left = 20.0
	hbox.offset_right = -20.0
	hbox.offset_top = 8.0
	hbox.offset_bottom = -8.0
	panel.add_child(hbox)

	var medals := ["🥇", "🥈", "🥉", "4️⃣", "5️⃣", "6️⃣"]
	var medal := Label.new()
	medal.text = medals[rank] if rank < medals.size() else "🎭"
	medal.add_theme_font_size_override("font_size", 38)
	medal.custom_minimum_size.x = 65
	hbox.add_child(medal)

	var name_role := VBoxContainer.new()
	name_role.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_role)

	var name_lbl := Label.new()
	name_lbl.text = p.get("name", "?")
	name_lbl.add_theme_font_size_override("font_size", 32)
	name_lbl.add_theme_color_override("font_color", col)
	name_role.add_child(name_lbl)

	var role_lbl := Label.new()
	role_lbl.text = p.get("role", "")
	role_lbl.add_theme_font_size_override("font_size", 20)
	role_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75))
	name_role.add_child(role_lbl)

	var pts := Label.new()
	pts.text = "%d pt" % p.get("score", 0)
	pts.add_theme_font_size_override("font_size", 40)
	pts.add_theme_color_override("font_color", Color(0.95, 0.75, 0.1))
	pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pts.custom_minimum_size.x = 110
	hbox.add_child(pts)

	return panel

func _build_snoop_quote(parent: VBoxContainer) -> void:
	var panel := Panel.new()
	panel.custom_minimum_size.y = 160
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.04, 0.14, 0.95)
	style.border_color = Color(0.5, 0.25, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 25.0
	vbox.offset_right = -25.0
	vbox.offset_top = 18.0
	vbox.offset_bottom = -18.0
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var snoop_lbl := Label.new()
	snoop_lbl.text = "🧑‍⚖️ Dommer Snoop Dogg's afsluttende ord:"
	snoop_lbl.add_theme_font_size_override("font_size", 22)
	snoop_lbl.add_theme_color_override("font_color", Color(0.85, 0.65, 0.1))
	snoop_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(snoop_lbl)

	vbox.add_child(_spacer(10))

	var quotes := [
		"Retten er hævet! Og mine hjerneceller er aldrig kommet sig. Fo' shizzle! 🌿",
		"Jeg har presideRET over mange sager, men denne her... denne her er SPECIAL. Drop it like it's hot! 🌿",
		"Ya'll some CREATIVE fools, ya dig? Tha D-O-double-G er imponeret. Næste gang: bring MERE absurditet! 🌿",
		"Gin and juice, min retssal, mine regler. Og reglerne siger: I er ALLE vindere i mine øjne. Men %s vandt altså. 🌿" % _winner.get("name", "Nogen"),
		"Laid back... med domstolen i krise og retfærdigheden på ferie. Det er perfekt. Snoop ud! 🌿",
	]
	var quote_lbl := Label.new()
	quote_lbl.text = quotes[randi() % quotes.size()]
	quote_lbl.add_theme_font_size_override("font_size", 26)
	quote_lbl.add_theme_color_override("font_color", Color(0.88, 0.85, 0.92))
	quote_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quote_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(quote_lbl)

func _build_buttons(parent: VBoxContainer) -> void:
	# Play again — new case
	var again_btn := Button.new()
	again_btn.text = "⚖️  ENDNU EN SAG!"
	again_btn.custom_minimum_size.y = 110
	again_btn.add_theme_font_size_override("font_size", 38)
	again_btn.add_theme_color_override("font_color", Color(0.05, 0.02, 0.08))
	var s1 := StyleBoxFlat.new()
	s1.bg_color = Color(0.85, 0.65, 0.1)
	s1.set_corner_radius_all(18)
	s1.shadow_color = Color(0.85, 0.65, 0.1, 0.45)
	s1.shadow_size = 8
	again_btn.add_theme_stylebox_override("normal", s1)
	again_btn.pressed.connect(_on_play_again)
	parent.add_child(again_btn)

	parent.add_child(_spacer(15))

	# New players
	var new_btn := Button.new()
	new_btn.text = "👥  SKIFT SPILLERE"
	new_btn.custom_minimum_size.y = 88
	new_btn.add_theme_font_size_override("font_size", 32)
	new_btn.add_theme_color_override("font_color", Color(0.85, 0.65, 0.1))
	var s2 := StyleBoxFlat.new()
	s2.bg_color = Color(0.08, 0.05, 0.18)
	s2.border_color = Color(0.85, 0.65, 0.1)
	s2.set_border_width_all(2)
	s2.set_corner_radius_all(18)
	new_btn.add_theme_stylebox_override("normal", s2)
	new_btn.pressed.connect(_on_new_players)
	parent.add_child(new_btn)

	parent.add_child(_spacer(10))

	# Main menu
	var menu_btn := Button.new()
	menu_btn.text = "🏠  MAIN MENU"
	menu_btn.custom_minimum_size.y = 80
	menu_btn.add_theme_font_size_override("font_size", 28)
	menu_btn.pressed.connect(_on_main_menu)
	parent.add_child(menu_btn)

# ─── Confetti ────────────────────────────────────────────────────────────────

func _spawn_confetti() -> void:
	for i in range(55):
		var c := ColorRect.new()
		var col := COLORS[i % COLORS.size()]
		c.color = col
		var w := randf_range(12, 28)
		var h := randf_range(8, 18)
		c.size = Vector2(w, h)
		c.rotation = randf_range(0, TAU)
		c.position = Vector2(randf_range(0, 1080), randf_range(-400, -10))
		c.set_meta("vx", randf_range(-60, 60))
		c.set_meta("vy", randf_range(200, 550))
		c.set_meta("vrot", randf_range(-4, 4))
		add_child(c)
		_confetti_nodes.append(c)

func _animate_confetti(delta: float) -> void:
	var screen_h: float = get_viewport_rect().size.y
	for c: ColorRect in _confetti_nodes:
		if not is_instance_valid(c):
			continue
		var vx: float = c.get_meta("vx")
		var vy: float = c.get_meta("vy")
		var vrot: float = c.get_meta("vrot")
		c.position.x += vx * delta
		c.position.y += vy * delta
		c.rotation += vrot * delta
		# Wind wobble
		c.position.x += sin(_anim_time * 2.0 + c.position.y * 0.01) * 30.0 * delta
		if c.position.y > screen_h + 50:
			c.position.y = randf_range(-200, -20)
			c.position.x = randf_range(0, 1080)

# ─── Callbacks ───────────────────────────────────────────────────────────────

func _on_play_again() -> void:
	GameManager.reset_for_new_game()
	GameManager.start_new_case()
	AudioMgr.play_swoosh()
	SceneTransition.goto("res://scenes/Courtroom.tscn")

func _on_new_players() -> void:
	GameManager.reset_for_new_game()
	SceneTransition.goto("res://scenes/PlayerSetup.tscn")

func _on_main_menu() -> void:
	GameManager.reset_for_new_game()
	SceneTransition.goto("res://scenes/MainMenu.tscn")

func _spacer(h: float) -> Control:
	var s := Control.new()
	s.custom_minimum_size.y = h
	return s
