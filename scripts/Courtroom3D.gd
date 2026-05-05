extends Node3D
## Courtroom3D - The main 3D courtroom with full gameplay logic

# ─── 3D Scene Nodes ──────────────────────────────────────────────────────────
var _camera: Camera3D
var _snoop: Node3D
var _podium: Node3D
var _env_node: WorldEnvironment
var _particle_root: Node3D
var _gavel_head: MeshInstance3D

# ─── UI Layer ────────────────────────────────────────────────────────────────
var _ui: CanvasLayer
var _phase_label: Label
var _case_panel: Panel
var _case_title_lbl: Label
var _case_desc_lbl: Label
var _case_emoji_lbl: Label
var _player_panel: Panel
var _player_name_lbl: Label
var _player_role_lbl: Label
var _statement_input: TextEdit
var _submit_btn: Button
var _timer_ring: Control
var _timer_lbl: Label
var _judge_bubble: Panel
var _judge_text: Label
var _thinking_indicator: Label
var _vote_panel: Panel
var _score_bar: Control

# ─── State ───────────────────────────────────────────────────────────────────
var _phase: String = "intro"  # intro | statement | judge | voting | verdict
var _statement_timer := 0.0
var _statement_duration := 60.0
var _timer_active := false
var _snoop_anim_time := 0.0
var _gavel_angle := 0.0
var _gavel_striking := false
var _case_data: Dictionary = {}
var _votes: Dictionary = {}  # player_name -> voted_for
var _current_vote_idx := 0
var _score_anims: Array = []

const COLORS := [Color(0.95,0.3,0.3), Color(0.3,0.5,0.95), Color(0.3,0.85,0.4),
				 Color(0.95,0.75,0.1), Color(0.85,0.3,0.85), Color(0.95,0.55,0.1)]

# ─── Ready ───────────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_3d_scene()
	_build_ui()
	await get_tree().create_timer(0.3).timeout
	_start_case_intro()

func _process(delta: float) -> void:
	_snoop_anim_time += delta
	_animate_snoop(delta)
	if _gavel_striking:
		_animate_gavel(delta)
	if _timer_active:
		_statement_timer -= delta
		_update_timer_ring()
		if _statement_timer <= 0.0:
			_timer_active = false
			_on_timer_expired()
	_update_score_anims(delta)

# ─── 3D Scene Construction ───────────────────────────────────────────────────

func _build_3d_scene() -> void:
	# Environment
	_env_node = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.03, 0.12)
	env.ambient_light_color = Color(0.2, 0.15, 0.3)
	env.ambient_light_energy = 0.6
	env.fog_enabled = true
	env.fog_light_color = Color(0.15, 0.08, 0.2)
	env.fog_density = 0.01
	_env_node.environment = env
	add_child(_env_node)

	# Camera
	_camera = Camera3D.new()
	_camera.position = Vector3(0, 3.5, 7.5)
	_camera.rotation_degrees = Vector3(-18, 0, 0)
	_camera.fov = 55
	add_child(_camera)

	# Lights
	_add_light(DirectionalLight3D.new(), Vector3(4, 8, 4), Color(1.0, 0.9, 0.75), 1.8, true)

	var spot := SpotLight3D.new()
	spot.position = Vector3(0, 6, -1)
	spot.look_at(Vector3(0, 0, -1), Vector3.UP)
	spot.light_color = Color(1.0, 0.95, 0.8)
	spot.light_energy = 3.5
	spot.spot_range = 12.0
	spot.spot_angle = 30.0
	spot.shadow_enabled = true
	add_child(spot)

	var fill := OmniLight3D.new()
	fill.position = Vector3(-4, 3, 4)
	fill.light_color = Color(0.3, 0.2, 0.7)
	fill.light_energy = 1.5
	fill.omni_range = 14.0
	add_child(fill)

	var accent := OmniLight3D.new()
	accent.position = Vector3(4, 2, 4)
	accent.light_color = Color(0.85, 0.6, 0.1)
	accent.light_energy = 1.2
	accent.omni_range = 10.0
	add_child(accent)

	_particle_root = Node3D.new()
	add_child(_particle_root)

	_build_courtroom_geometry()

	_snoop = _build_judge_snoop()
	_snoop.position = Vector3(0, 1.2, -3.5)
	_snoop.scale = Vector3(1.1, 1.1, 1.1)
	add_child(_snoop)

	_podium = _build_witness_podium()
	_podium.position = Vector3(0, 0, 1.5)
	add_child(_podium)

func _add_light(light: Light3D, pos: Vector3, color: Color, energy: float, shadow: bool) -> void:
	light.position = pos
	light.look_at(Vector3.ZERO, Vector3.UP)
	light.light_color = color
	light.light_energy = energy
	light.shadow_enabled = shadow
	add_child(light)

func _build_courtroom_geometry() -> void:
	# Floor — polished dark wood
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.28, 0.15, 0.05)
	floor_mat.roughness = 0.3
	floor_mat.metallic = 0.05
	_mesh(BoxMesh.new(), Vector3(0,-0.1,0), Vector3(14,0.2,12), floor_mat)

	# Floor tiles overlay (lighter strip)
	var tile_mat := StandardMaterial3D.new()
	tile_mat.albedo_color = Color(0.38, 0.22, 0.08)
	tile_mat.roughness = 0.25
	for z in [-1.5, 0.0, 1.5, 3.0]:
		_mesh(BoxMesh.new(), Vector3(0, 0.001, z), Vector3(13.8, 0.01, 1.4), tile_mat)

	# Back wall
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.88, 0.85, 0.78)
	wall_mat.roughness = 0.8
	_mesh(BoxMesh.new(), Vector3(0, 3, -6), Vector3(14, 8, 0.3), wall_mat)

	# Side walls
	_mesh(BoxMesh.new(), Vector3(-7, 3, 0), Vector3(0.3, 8, 12), wall_mat)
	_mesh(BoxMesh.new(), Vector3(7, 3, 0), Vector3(0.3, 8, 12), wall_mat)

	# Ceiling
	var ceil_mat := StandardMaterial3D.new()
	ceil_mat.albedo_color = Color(0.92, 0.9, 0.85)
	_mesh(BoxMesh.new(), Vector3(0, 7, 0), Vector3(14, 0.3, 12), ceil_mat)

	# Wainscoting on back wall
	var wain_mat := StandardMaterial3D.new()
	wain_mat.albedo_color = Color(0.45, 0.28, 0.08)
	wain_mat.roughness = 0.4
	_mesh(BoxMesh.new(), Vector3(0, 1, -5.85), Vector3(13.8, 2, 0.1), wain_mat)

	# Judge bench — mahogany
	var bench_mat := StandardMaterial3D.new()
	bench_mat.albedo_color = Color(0.42, 0.2, 0.05)
	bench_mat.roughness = 0.35
	bench_mat.metallic = 0.02
	_mesh(BoxMesh.new(), Vector3(0, 0.6, -3), Vector3(5, 1.2, 1.4), bench_mat)
	_mesh(BoxMesh.new(), Vector3(0, 1.25, -3.2), Vector3(4.8, 0.1, 1.2), bench_mat)

	# Bench top gold trim
	var gold_mat := StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.85, 0.65, 0.1)
	gold_mat.metallic = 0.8
	gold_mat.roughness = 0.2
	_mesh(BoxMesh.new(), Vector3(0, 1.33, -3.15), Vector3(4.85, 0.06, 1.3), gold_mat)

	# Columns (4)
	var col_mat := StandardMaterial3D.new()
	col_mat.albedo_color = Color(0.85, 0.83, 0.78)
	col_mat.roughness = 0.5
	for x in [-5.0, -2.5, 2.5, 5.0]:
		var col_mesh := CylinderMesh.new()
		col_mesh.top_radius = 0.28
		col_mesh.bottom_radius = 0.35
		col_mesh.height = 7.0
		_mesh(col_mesh, Vector3(x, 3.5, -5.5), Vector3.ONE, col_mat)
		# Capital
		_mesh(BoxMesh.new(), Vector3(x, 7.1, -5.5), Vector3(0.85, 0.25, 0.85), gold_mat)

	# Jury box (left)
	var jury_mat := StandardMaterial3D.new()
	jury_mat.albedo_color = Color(0.35, 0.18, 0.06)
	jury_mat.roughness = 0.5
	for i in range(3):
		_mesh(BoxMesh.new(), Vector3(-5, 0.35 + i * 0.3, -1 + i * 0.6), Vector3(3, 0.15, 2.8), jury_mat)
	_mesh(BoxMesh.new(), Vector3(-5, 1.2, -2.5), Vector3(3.2, 2.5, 0.15), jury_mat)

	# Witness box (right)
	_mesh(BoxMesh.new(), Vector3(4.5, 0.3, 0.5), Vector3(2.5, 0.6, 2.5), bench_mat)
	_mesh(BoxMesh.new(), Vector3(4.5, 1.5, -0.7), Vector3(2.5, 2.4, 0.12), bench_mat)
	_mesh(BoxMesh.new(), Vector3(3.25, 1.5, 0.5), Vector3(0.12, 2.4, 2.5), bench_mat)

	# Gallery benches (back)
	for z in [3.5, 4.5, 5.0]:
		_mesh(BoxMesh.new(), Vector3(0, 0.45, z), Vector3(12, 0.18, 0.9), jury_mat)
		_mesh(BoxMesh.new(), Vector3(0, 1.0, z + 0.43), Vector3(12, 1.0, 0.1), jury_mat)

	# Central railing
	_mesh(BoxMesh.new(), Vector3(0, 1.1, 0.8), Vector3(12.5, 0.12, 0.12), gold_mat)
	for x in range(-6, 7):
		_mesh(CylinderMesh.new(), Vector3(x, 0.55, 0.8), Vector3.ONE * 0.4, gold_mat)

	# Flags
	_build_flag(Vector3(-6.2, 4.0, -5.3), Color(0.1, 0.1, 0.6))
	_build_flag(Vector3(6.2, 4.0, -5.3), Color(0.6, 0.1, 0.1))

	# Ceiling rosette / chandelier
	var chandelier := OmniLight3D.new()
	chandelier.position = Vector3(0, 6.5, 0)
	chandelier.light_color = Color(1.0, 0.95, 0.8)
	chandelier.light_energy = 2.5
	chandelier.omni_range = 14.0
	add_child(chandelier)
	_mesh(TorusMesh.new(), Vector3(0, 6.4, 0), Vector3(1.5, 1.5, 1.5), gold_mat)

func _build_flag(pos: Vector3, color: Color) -> void:
	# Pole
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.04
	pole_mesh.bottom_radius = 0.04
	pole_mesh.height = 3.5
	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.85, 0.65, 0.1)
	pole_mat.metallic = 0.8
	_mesh(pole_mesh, pos, Vector3.ONE, pole_mat)
	# Flag cloth
	var flag_mat := StandardMaterial3D.new()
	flag_mat.albedo_color = color
	flag_mat.roughness = 0.9
	_mesh(BoxMesh.new(), pos + Vector3(0.5, 0.7, 0), Vector3(1.0, 0.6, 0.05), flag_mat)

func _build_judge_snoop() -> Node3D:
	var root := Node3D.new()

	# Body — purple robe
	var body := _make_mesh(CapsuleMesh.new(), Color(0.35, 0.1, 0.5))
	var bm := body.mesh as CapsuleMesh
	bm.radius = 0.32
	bm.height = 1.3
	body.position.y = 0.65
	root.add_child(body)

	# Head
	var head := _make_mesh(SphereMesh.new(), Color(0.72, 0.52, 0.32))
	var hm := head.mesh as SphereMesh
	hm.radius = 0.28
	head.position.y = 1.5
	root.add_child(head)

	# Judge wig
	var wig := _make_mesh(CapsuleMesh.new(), Color(0.92, 0.9, 0.85))
	var wm := wig.mesh as CapsuleMesh
	wm.radius = 0.3
	wm.height = 0.5
	wig.position.y = 1.72
	root.add_child(wig)

	# Wig curls sides
	for dx in [-0.24, 0.24]:
		var curl := _make_mesh(CapsuleMesh.new(), Color(0.92, 0.9, 0.85))
		var cm := curl.mesh as CapsuleMesh
		cm.radius = 0.1
		cm.height = 0.35
		curl.position = Vector3(dx, 1.55, 0)
		root.add_child(curl)

	# Sunglasses
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.05, 0.05, 0.08)
	glass_mat.metallic = 0.7
	glass_mat.roughness = 0.1
	for dx in [-0.12, 0.12]:
		var lens := MeshInstance3D.new()
		var lm := CylinderMesh.new()
		lm.top_radius = 0.09
		lm.bottom_radius = 0.09
		lm.height = 0.025
		lens.mesh = lm
		lens.material_override = glass_mat
		lens.position = Vector3(dx, 1.48, 0.26)
		lens.rotation_degrees.x = 90.0
		root.add_child(lens)
	# Bridge
	_mesh_child(root, BoxMesh.new(), Vector3(0, 1.48, 0.26), Vector3(0.12, 0.03, 0.02), glass_mat)

	# Gold chain
	var chain_mat := StandardMaterial3D.new()
	chain_mat.albedo_color = Color(0.9, 0.75, 0.1)
	chain_mat.metallic = 0.9
	chain_mat.roughness = 0.15
	var chain := _make_mesh_mat(TorusMesh.new(), chain_mat)
	var tm := chain.mesh as TorusMesh
	tm.inner_radius = 0.22
	tm.outer_radius = 0.32
	chain.position.y = 1.0
	chain.rotation_degrees.x = 90.0
	root.add_child(chain)

	# Robe details — white collar
	var collar := _make_mesh(CylinderMesh.new(), Color(0.95, 0.93, 0.9))
	var colm := collar.mesh as CylinderMesh
	colm.top_radius = 0.25
	colm.bottom_radius = 0.28
	colm.height = 0.18
	collar.position.y = 1.22
	root.add_child(collar)

	# Gavel arm
	var arm := Node3D.new()
	arm.name = "GavelArm"
	arm.position = Vector3(0.45, 0.9, 0)
	root.add_child(arm)

	var handle := _make_mesh(CylinderMesh.new(), Color(0.55, 0.32, 0.1))
	var ghm := handle.mesh as CylinderMesh
	ghm.top_radius = 0.04
	ghm.bottom_radius = 0.04
	ghm.height = 0.55
	handle.rotation_degrees.z = -20.0
	arm.add_child(handle)

	_gavel_head = _make_mesh_mat(CylinderMesh.new(), chain_mat)
	var ghm2 := _gavel_head.mesh as CylinderMesh
	ghm2.top_radius = 0.1
	ghm2.bottom_radius = 0.1
	ghm2.height = 0.18
	_gavel_head.position.y = 0.3
	_gavel_head.rotation_degrees.x = 90.0
	arm.add_child(_gavel_head)

	return root

func _build_witness_podium() -> Node3D:
	var root := Node3D.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.2, 0.05)
	mat.roughness = 0.35

	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(1.8, 1.0, 1.0)
	var mi := MeshInstance3D.new()
	mi.mesh = base_mesh
	mi.material_override = mat
	root.add_child(mi)

	var top_mesh := BoxMesh.new()
	top_mesh.size = Vector3(1.85, 0.08, 1.05)
	var top := MeshInstance3D.new()
	top.mesh = top_mesh
	top.position.y = 0.54
	var top_mat := StandardMaterial3D.new()
	top_mat.albedo_color = Color(0.85, 0.65, 0.1)
	top_mat.metallic = 0.7
	top_mat.roughness = 0.2
	top.material_override = top_mat
	root.add_child(top)

	# Microphone
	var mic_stand := CylinderMesh.new()
	mic_stand.top_radius = 0.02
	mic_stand.bottom_radius = 0.02
	mic_stand.height = 0.6
	var ms := MeshInstance3D.new()
	ms.mesh = mic_stand
	ms.position = Vector3(0, 0.85, 0)
	var mic_mat := StandardMaterial3D.new()
	mic_mat.albedo_color = Color(0.5, 0.5, 0.55)
	mic_mat.metallic = 0.9
	ms.material_override = mic_mat
	root.add_child(ms)

	var mic_head := SphereMesh.new()
	mic_head.radius = 0.07
	var mh := MeshInstance3D.new()
	mh.mesh = mic_head
	mh.position = Vector3(0, 1.2, 0)
	mh.material_override = mic_mat
	root.add_child(mh)

	return root

# ─── Animation ───────────────────────────────────────────────────────────────

func _animate_snoop(delta: float) -> void:
	if not _snoop:
		return
	_snoop.rotation.y = sin(_snoop_anim_time * 0.4) * 0.08
	var head := _snoop.get_node_or_null("Node") 
	# Bob the whole character slightly
	_snoop.position.y = 1.2 + sin(_snoop_anim_time * 1.8) * 0.04

func _animate_gavel(delta: float) -> void:
	var arm := _snoop.get_node_or_null("GavelArm")
	if not arm:
		return
	_gavel_angle += delta * 720.0
	if _gavel_angle >= 360.0:
		_gavel_angle = 0.0
		_gavel_striking = false
		arm.rotation_degrees.z = 0.0
	else:
		arm.rotation_degrees.z = -abs(sin(deg_to_rad(_gavel_angle))) * 60.0

func _strike_gavel() -> void:
	_gavel_striking = true
	_gavel_angle = 0.0
	AudioMgr.play_gavel()

# ─── Gameplay Logic ───────────────────────────────────────────────────────────

func _start_case_intro() -> void:
	_phase = "intro"
	_case_data = GameManager.current_case
	if _case_data.is_empty():
		GameManager.start_new_case()
		_case_data = GameManager.current_case

	_show_case_panel()
	_update_phase_label("🔔  NYE SAG ANNONCERES")
	_strike_gavel()
	AudioMgr.play_dramatic_sting()

	await get_tree().create_timer(1.5).timeout
	_judge_say("Yo yo YO! Retten er sat! Tha D-O-double-G har sagen!\n\nSag: %s\n\n%s\n\nLad os GØRE DET! Fo' shizzle!" % [
		_case_data.get("title", ""),
		_case_data.get("accusation", "")
	])

	await get_tree().create_timer(5.0).timeout
	_begin_statement_phase()

func _begin_statement_phase() -> void:
	_phase = "statement"
	GameManager.change_state(GameManager.GameState.STATEMENT_PHASE)

	var player := GameManager.get_current_player()
	if player.is_empty():
		_begin_voting()
		return

	_hide_case_panel()
	_show_player_panel(player)
	_update_phase_label("🎤  VIDNEUDSAGN — %s" % player.get("name", "?"))
	_statement_timer = _statement_duration
	_timer_active = true
	_statement_input.text = ""
	_statement_input.editable = true
	_submit_btn.disabled = false
	_hide_judge_bubble()
	_strike_gavel()
	AudioMgr.play_swoosh()

func _on_statement_submitted() -> void:
	if not _timer_active and _statement_timer > 0:
		return
	_timer_active = false
	_statement_input.editable = false
	_submit_btn.disabled = true

	var player := GameManager.get_current_player()
	var statement := _statement_input.text.strip_edges()
	if statement.is_empty():
		statement = "[spilleren forblev mystisk tavs og blinkede kun til dommeren]"

	GameManager.submit_statement(player.get("name", "?"), statement)

	_phase = "judge"
	_update_phase_label("⚖️  DOMMER SNOOP REAGERER...")
	_show_thinking()

	JudgeAI.react_to_statement(
		player.get("name", "?"),
		player.get("role", "Spiller"),
		statement,
		_case_data.get("title", "Sagen"),
		_on_judge_reaction
	)

func _on_judge_reaction(text: String) -> void:
	_hide_thinking()
	_judge_say(text)
	GameManager.emit_signal("judge_reaction_ready", text)
	_strike_gavel()
	AudioMgr.play_crowd_cheer()
	SceneTransition.flash(Color(0.85, 0.65, 0.1, 0.3), 0.3)

	await get_tree().create_timer(5.5).timeout

	if GameManager.all_players_have_spoken():
		_begin_voting()
	else:
		_begin_statement_phase()

func _begin_voting() -> void:
	_phase = "voting"
	GameManager.change_state(GameManager.GameState.VOTING)
	_hide_judge_bubble()
	_hide_player_panel()
	_update_phase_label("🗳️  AFSTEMNING — Hvem var mest underholdende?")
	_current_vote_idx = 0
	_votes.clear()
	_show_vote_panel()

func _on_vote_cast(voter: String, voted_for: String) -> void:
	_votes[voter] = voted_for
	_current_vote_idx += 1

	# Award points
	GameManager.add_score(voted_for, 1)

	if _current_vote_idx >= GameManager.players.size():
		_hide_vote_panel()
		_begin_verdict()
	else:
		_refresh_vote_panel()

func _begin_verdict() -> void:
	_phase = "verdict"
	GameManager.change_state(GameManager.GameState.VERDICT)
	_update_phase_label("🔨  DOMMEN AFSIGES...")
	_show_thinking()
	_strike_gavel()

	JudgeAI.deliver_verdict(
		_case_data,
		GameManager.statements,
		_on_verdict_ready
	)

func _on_verdict_ready(text: String) -> void:
	_hide_thinking()
	_judge_say(text, true)
	GameManager.emit_signal("verdict_ready", text)
	AudioMgr.play_bling()
	_strike_gavel()
	SceneTransition.flash(Color(0.85, 0.65, 0.1, 0.4), 0.5)

	await get_tree().create_timer(7.0).timeout
	SceneTransition.goto("res://scenes/VerdictScreen.tscn")

func _on_timer_expired() -> void:
	_on_statement_submitted()

# ─── UI Construction ─────────────────────────────────────────────────────────

func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 10
	add_child(_ui)

	var root := Control.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.name = "UIRoot"
	_ui.add_child(root)

	# Phase label (top)
	_phase_label = Label.new()
	_phase_label.text = ""
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase_label.anchor_right = 1.0
	_phase_label.offset_top = 20.0
	_phase_label.offset_bottom = 80.0
	_phase_label.add_theme_font_size_override("font_size", 26)
	_phase_label.add_theme_color_override("font_color", Color(0.95, 0.75, 0.1))
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0, 0, 0, 0.6)
	_phase_label.add_theme_stylebox_override("normal", bg_style)
	root.add_child(_phase_label)

	# Case panel (center)
	_build_case_panel(root)

	# Judge speech bubble (bottom-right of 3D view)
	_build_judge_bubble(root)

	# Player statement panel (bottom)
	_build_player_panel(root)

	# Timer ring (top-right)
	_build_timer_widget(root)

	# Vote panel (hidden initially)
	_build_vote_panel(root)

	# Score bar (top-left)
	_build_score_bar(root)

func _build_case_panel(parent: Control) -> void:
	_case_panel = Panel.new()
	_case_panel.anchor_right = 1.0
	_case_panel.offset_left = 40.0
	_case_panel.offset_right = -40.0
	_case_panel.offset_top = 100.0
	_case_panel.offset_bottom = 580.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.02, 0.1, 0.95)
	style.border_color = Color(0.85, 0.65, 0.1)
	style.set_border_width_all(3)
	style.set_corner_radius_all(20)
	style.shadow_color = Color(0, 0, 0, 0.7)
	style.shadow_size = 12
	_case_panel.add_theme_stylebox_override("panel", style)
	parent.add_child(_case_panel)

	var vbox := VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 30.0
	vbox.offset_right = -30.0
	vbox.offset_top = 25.0
	vbox.offset_bottom = -25.0
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_case_panel.add_child(vbox)

	_case_emoji_lbl = Label.new()
	_case_emoji_lbl.text = "⚖️"
	_case_emoji_lbl.add_theme_font_size_override("font_size", 80)
	_case_emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_case_emoji_lbl)

	_case_title_lbl = Label.new()
	_case_title_lbl.text = ""
	_case_title_lbl.add_theme_font_size_override("font_size", 36)
	_case_title_lbl.add_theme_color_override("font_color", Color(0.95, 0.75, 0.1))
	_case_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_case_title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_case_title_lbl)

	vbox.add_child(_spacer(12))

	_case_desc_lbl = Label.new()
	_case_desc_lbl.text = ""
	_case_desc_lbl.add_theme_font_size_override("font_size", 26)
	_case_desc_lbl.add_theme_color_override("font_color", Color(0.88, 0.85, 0.9))
	_case_desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_case_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_case_desc_lbl)

	# Continue button
	vbox.add_child(_spacer(20))
	var cont_btn := Button.new()
	cont_btn.text = "Forstået — Lad os kæmpe! ⚖️"
	cont_btn.add_theme_font_size_override("font_size", 28)
	cont_btn.custom_minimum_size.y = 80
	cont_btn.pressed.connect(func():
		_case_panel.visible = false
		_begin_statement_phase()
	)
	vbox.add_child(cont_btn)

	_case_panel.visible = false

func _build_player_panel(parent: Control) -> void:
	_player_panel = Panel.new()
	_player_panel.anchor_right = 1.0
	_player_panel.anchor_bottom = 1.0
	_player_panel.offset_top = -620.0
	_player_panel.offset_bottom = 0.0
	_player_panel.offset_left = 0.0
	_player_panel.offset_right = 0.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.02, 0.12, 0.97)
	style.border_color = Color(0.4, 0.2, 0.6)
	style.set_border_width_all(2)
	_player_panel.add_theme_stylebox_override("panel", style)
	parent.add_child(_player_panel)

	var vbox := VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 30.0
	vbox.offset_right = -30.0
	vbox.offset_top = 20.0
	vbox.offset_bottom = -20.0
	_player_panel.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)

	_player_name_lbl = Label.new()
	_player_name_lbl.text = "Spiller"
	_player_name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_player_name_lbl.add_theme_font_size_override("font_size", 40)
	_player_name_lbl.add_theme_color_override("font_color", Color(0.95, 0.75, 0.1))
	header.add_child(_player_name_lbl)

	_player_role_lbl = Label.new()
	_player_role_lbl.text = ""
	_player_role_lbl.add_theme_font_size_override("font_size", 28)
	_player_role_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.85))
	header.add_child(_player_role_lbl)

	var hint := Label.new()
	hint.text = "Skriv din forklaring (op til 60 sek):"
	hint.add_theme_font_size_override("font_size", 22)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	vbox.add_child(hint)

	_statement_input = TextEdit.new()
	_statement_input.placeholder_text = "Beskriv din version af hændelserne... jo mere absurdt, jo bedre!"
	_statement_input.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_statement_input.add_theme_font_size_override("font_size", 26)
	_statement_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	vbox.add_child(_statement_input)

	_submit_btn = Button.new()
	_submit_btn.text = "🎤 FREMFØR MIN FORKLARING"
	_submit_btn.custom_minimum_size.y = 88
	_submit_btn.add_theme_font_size_override("font_size", 32)
	_submit_btn.add_theme_color_override("font_color", Color(0.05, 0.02, 0.08))
	var sbtn_style := StyleBoxFlat.new()
	sbtn_style.bg_color = Color(0.85, 0.65, 0.1)
	sbtn_style.set_corner_radius_all(16)
	sbtn_style.shadow_color = Color(0.85, 0.65, 0.1, 0.4)
	sbtn_style.shadow_size = 6
	_submit_btn.add_theme_stylebox_override("normal", sbtn_style)
	_submit_btn.pressed.connect(_on_statement_submitted)
	vbox.add_child(_submit_btn)

	_player_panel.visible = false

func _build_judge_bubble(parent: Control) -> void:
	_judge_bubble = Panel.new()
	_judge_bubble.anchor_right = 1.0
	_judge_bubble.offset_left = 30.0
	_judge_bubble.offset_right = -30.0
	_judge_bubble.offset_top = 90.0
	_judge_bubble.offset_bottom = 600.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.04, 0.18, 0.96)
	style.border_color = Color(0.85, 0.65, 0.1)
	style.set_border_width_all(3)
	style.set_corner_radius_all(22)
	style.shadow_color = Color(0.85, 0.65, 0.1, 0.35)
	style.shadow_size = 16
	_judge_bubble.add_theme_stylebox_override("panel", style)
	parent.add_child(_judge_bubble)

	var vbox := VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 25.0
	vbox.offset_right = -25.0
	vbox.offset_top = 20.0
	vbox.offset_bottom = -20.0
	_judge_bubble.add_child(vbox)

	var header := Label.new()
	header.text = "🧑‍⚖️ Dommer Snoop Dogg siger:"
	header.add_theme_font_size_override("font_size", 26)
	header.add_theme_color_override("font_color", Color(0.85, 0.65, 0.1))
	vbox.add_child(header)

	_thinking_indicator = Label.new()
	_thinking_indicator.text = "🌿 Delibererer... fo' shizzle..."
	_thinking_indicator.add_theme_font_size_override("font_size", 28)
	_thinking_indicator.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	_thinking_indicator.visible = false
	vbox.add_child(_thinking_indicator)

	_judge_text = Label.new()
	_judge_text.text = ""
	_judge_text.add_theme_font_size_override("font_size", 28)
	_judge_text.add_theme_color_override("font_color", Color(0.92, 0.9, 0.95))
	_judge_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_judge_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_judge_text)

	_judge_bubble.visible = false

func _build_timer_widget(parent: Control) -> void:
	var container := Control.new()
	container.anchor_right = 1.0
	container.offset_left = -200.0
	container.offset_right = 0.0
	container.offset_top = 90.0
	container.offset_bottom = 280.0
	parent.add_child(container)

	_timer_ring = container
	_timer_lbl = Label.new()
	_timer_lbl.anchor_right = 1.0
	_timer_lbl.anchor_bottom = 1.0
	_timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_timer_lbl.add_theme_font_size_override("font_size", 52)
	_timer_lbl.add_theme_color_override("font_color", Color(0.95, 0.75, 0.1))
	container.add_child(_timer_lbl)
	container.visible = false

func _build_score_bar(parent: Control) -> void:
	_score_bar = Control.new()
	_score_bar.anchor_right = 0.0
	_score_bar.offset_right = 220.0
	_score_bar.offset_top = 90.0
	_score_bar.offset_bottom = 500.0
	parent.add_child(_score_bar)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.02, 0.1, 0.85)
	style.set_corner_radius_all(12)
	var bg := Panel.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.add_theme_stylebox_override("panel", style)
	_score_bar.add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.name = "ScoreList"
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 12.0
	vbox.offset_right = -12.0
	vbox.offset_top = 12.0
	vbox.offset_bottom = -12.0
	_score_bar.add_child(vbox)

	var hdr := Label.new()
	hdr.text = "🏆 POINT"
	hdr.add_theme_font_size_override("font_size", 22)
	hdr.add_theme_color_override("font_color", Color(0.85, 0.65, 0.1))
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hdr)

	_refresh_score_bar()

func _build_vote_panel(parent: Control) -> void:
	_vote_panel = Panel.new()
	_vote_panel.anchor_right = 1.0
	_vote_panel.anchor_bottom = 1.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.02, 0.12, 0.98)
	style.border_color = Color(0.85, 0.65, 0.1)
	style.set_border_width_all(3)
	_vote_panel.add_theme_stylebox_override("panel", style)
	parent.add_child(_vote_panel)
	_vote_panel.visible = false

# ─── UI helpers ──────────────────────────────────────────────────────────────

func _show_case_panel() -> void:
	_case_title_lbl.text = _case_data.get("title", "")
	_case_desc_lbl.text = _case_data.get("accusation", "") + "\n\n" + _case_data.get("context", "")
	_case_emoji_lbl.text = _case_data.get("emoji", "⚖️")
	_case_panel.visible = true

func _hide_case_panel() -> void:
	_case_panel.visible = false

func _show_player_panel(player: Dictionary) -> void:
	_player_name_lbl.text = player.get("name", "Spiller")
	_player_name_lbl.add_theme_color_override("font_color",
		COLORS[player.get("index", 0) % COLORS.size()])
	_player_role_lbl.text = player.get("role", "")
	_player_panel.visible = true
	_timer_ring.visible = true

func _hide_player_panel() -> void:
	_player_panel.visible = false
	_timer_ring.visible = false

func _judge_say(text: String, big: bool = false) -> void:
	_judge_text.text = text
	_judge_text.add_theme_font_size_override("font_size", 30 if big else 26)
	_judge_bubble.visible = true

func _hide_judge_bubble() -> void:
	_judge_bubble.visible = false

func _show_thinking() -> void:
	_judge_bubble.visible = true
	_judge_text.text = ""
	_thinking_indicator.visible = true

func _hide_thinking() -> void:
	_thinking_indicator.visible = false

func _update_phase_label(text: String) -> void:
	_phase_label.text = text

func _update_timer_ring() -> void:
	var secs := int(ceil(_statement_timer))
	_timer_lbl.text = "⏱ %d" % secs
	if secs <= 10:
		_timer_lbl.add_theme_color_override("font_color", Color(0.95, 0.25, 0.25))
	else:
		_timer_lbl.add_theme_color_override("font_color", Color(0.95, 0.75, 0.1))

func _show_vote_panel() -> void:
	_vote_panel.visible = true
	_refresh_vote_panel()

func _hide_vote_panel() -> void:
	_vote_panel.visible = false

func _refresh_vote_panel() -> void:
	for c in _vote_panel.get_children():
		c.queue_free()

	var voter := GameManager.players[_current_vote_idx] if _current_vote_idx < GameManager.players.size() else {}
	if voter.is_empty():
		return

	var vbox := VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 60.0
	vbox.offset_right = -60.0
	vbox.offset_top = 200.0
	vbox.offset_bottom = -200.0
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_vote_panel.add_child(vbox)

	var q := Label.new()
	q.text = "🗳️ %s\nHvem var mest underholdende?" % voter.get("name", "?")
	q.add_theme_font_size_override("font_size", 40)
	q.add_theme_color_override("font_color", Color(0.95, 0.75, 0.1))
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(q)

	vbox.add_child(_spacer(30))

	for i in range(GameManager.players.size()):
		var p: Dictionary = GameManager.players[i]
		if p.get("name") == voter.get("name"):
			continue  # Can't vote for yourself

		var btn := Button.new()
		btn.text = "%s — %s" % [p.get("name", "?"), p.get("role", "")]
		btn.custom_minimum_size.y = 90
		btn.add_theme_font_size_override("font_size", 30)
		btn.add_theme_color_override("font_color", COLORS[i % COLORS.size()])
		btn.pressed.connect(func(): _on_vote_cast(voter.get("name"), p.get("name")))
		vbox.add_child(btn)
		vbox.add_child(_spacer(10))

func _refresh_score_bar() -> void:
	var list := _score_bar.find_child("ScoreList", true, false)
	if not list:
		return
	# Remove old rows (keep header)
	while list.get_child_count() > 1:
		list.get_child(list.get_child_count() - 1).queue_free()

	for i in range(GameManager.players.size()):
		var p: Dictionary = GameManager.players[i]
		var row := Label.new()
		row.text = "%s %d pt" % [p.get("name", "?"), p.get("score", 0)]
		row.add_theme_font_size_override("font_size", 20)
		row.add_theme_color_override("font_color", COLORS[i % COLORS.size()])
		list.add_child(row)

func _update_score_anims(_delta: float) -> void:
	if GameManager.players.is_empty():
		return
	# Refresh score bar every frame (cheap labels)
	_refresh_score_bar()

# ─── Mesh Helpers ─────────────────────────────────────────────────────────────

func _mesh(mesh: Mesh, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	if mesh is BoxMesh:
		(mesh as BoxMesh).size = size
	elif mesh is CylinderMesh:
		pass
	elif mesh is TorusMesh:
		pass
	mi.position = pos
	mi.material_override = mat
	add_child(mi)
	return mi

func _mesh_child(parent: Node3D, mesh: Mesh, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	if mesh is BoxMesh:
		(mesh as BoxMesh).size = size
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi

func _make_mesh(mesh: Mesh, color: Color) -> MeshInstance3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.55
	mat.metallic = 0.05
	return _make_mesh_mat(mesh, mat)

func _make_mesh_mat(mesh: Mesh, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	return mi

func _spacer(h: float) -> Control:
	var s := Control.new()
	s.custom_minimum_size.y = h
	return s
