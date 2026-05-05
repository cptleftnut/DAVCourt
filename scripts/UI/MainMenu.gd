extends Node3D
## MainMenu - 3D animated main menu

var _camera: Camera3D
var _ui_layer: CanvasLayer
var _spin_time := 0.0
var _courtroom_root: Node3D
var _snoop: Node3D
var _api_panel: Control
var _api_input: LineEdit
var _api_visible := false

func _ready() -> void:
	_build_3d_background()
	_build_ui()
	AudioMgr.play_bling()

func _process(delta: float) -> void:
	_spin_time += delta
	if _courtroom_root:
		_courtroom_root.rotation.y = _spin_time * 0.3
	if _snoop:
		_snoop.position.y = sin(_spin_time * 2.0) * 0.05 + 0.5

# ─── 3D Background ────────────────────────────────────────────────────────────

func _build_3d_background() -> void:
	# World environment
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.04, 0.02, 0.08)
	env.ambient_light_color = Color(0.15, 0.1, 0.25)
	env.ambient_light_energy = 0.8
	env_node.environment = env
	add_child(env_node)

	# Camera
	_camera = Camera3D.new()
	_camera.position = Vector3(0, 2, 6)
	_camera.rotation_degrees = Vector3(-15, 0, 0)
	_camera.fov = 60
	add_child(_camera)

	# Lighting
	var sun := DirectionalLight3D.new()
	sun.position = Vector3(5, 8, 5)
	sun.look_at(Vector3.ZERO, Vector3.UP)
	sun.light_color = Color(1.0, 0.9, 0.7)
	sun.light_energy = 1.5
	sun.shadow_enabled = true
	add_child(sun)

	var fill := OmniLight3D.new()
	fill.position = Vector3(-3, 3, 3)
	fill.light_color = Color(0.4, 0.3, 0.8)
	fill.light_energy = 1.2
	fill.omni_range = 12.0
	add_child(fill)

	# Spinning courtroom in background
	_courtroom_root = Node3D.new()
	_courtroom_root.position = Vector3(0, -1, 0)
	_courtroom_root.scale = Vector3(0.5, 0.5, 0.5)
	add_child(_courtroom_root)
	_build_mini_courtroom(_courtroom_root)

	# Snoop character in foreground
	_snoop = _build_snoop_character()
	_snoop.position = Vector3(0, 0.5, 2)
	_snoop.scale = Vector3(0.7, 0.7, 0.7)
	add_child(_snoop)

func _build_mini_courtroom(parent: Node3D) -> void:
	# Floor
	_add_box(parent, Vector3(0, -0.1, 0), Vector3(8, 0.2, 6), Color(0.35, 0.2, 0.08))
	# Walls
	_add_box(parent, Vector3(0, 2, -3), Vector3(8, 4, 0.2), Color(0.9, 0.88, 0.82))
	_add_box(parent, Vector3(-4, 2, 0), Vector3(0.2, 4, 6), Color(0.85, 0.83, 0.78))
	_add_box(parent, Vector3(4, 2, 0), Vector3(0.2, 4, 6), Color(0.85, 0.83, 0.78))
	# Judge bench
	_add_box(parent, Vector3(0, 0.5, -2), Vector3(3, 1.0, 1), Color(0.45, 0.25, 0.05))
	_add_box(parent, Vector3(0, 0.8, -2.1), Vector3(2.8, 0.15, 0.8), Color(0.6, 0.4, 0.1))
	# Columns
	for x in [-3.0, 3.0]:
		_add_cylinder(parent, Vector3(x, 2, -2.8), 0.2, 4.0, Color(0.9, 0.88, 0.82))
	# Audience benches
	for z in [0.5, 1.5, 2.2]:
		_add_box(parent, Vector3(-1.5, 0.3, z), Vector3(2.5, 0.2, 0.7), Color(0.4, 0.22, 0.05))
		_add_box(parent, Vector3(1.5, 0.3, z), Vector3(2.5, 0.2, 0.7), Color(0.4, 0.22, 0.05))
	# Gold rail
	_add_box(parent, Vector3(0, 0.5, 0), Vector3(7, 0.1, 0.1), Color(0.85, 0.65, 0.1))
	# Ceiling lights
	for x in [-2.0, 0.0, 2.0]:
		var light := OmniLight3D.new()
		light.position = Vector3(x, 3.5, 0)
		light.light_color = Color(1.0, 0.95, 0.8)
		light.light_energy = 2.0
		light.omni_range = 5.0
		parent.add_child(light)

func _build_snoop_character() -> Node3D:
	var root := Node3D.new()
	# Body (dark blue tracksuit)
	var body := _make_mesh_node(CapsuleMesh.new(), Color(0.1, 0.1, 0.3))
	var cm := body.mesh as CapsuleMesh
	cm.radius = 0.25
	cm.height = 1.0
	body.position.y = 0.5
	root.add_child(body)
	# Head
	var head := _make_mesh_node(SphereMesh.new(), Color(0.7, 0.5, 0.3))
	var hm := head.mesh as SphereMesh
	hm.radius = 0.22
	head.position.y = 1.2
	root.add_child(head)
	# Hat brim (wide)
	var brim := _make_mesh_node(CylinderMesh.new(), Color(0.95, 0.92, 0.85))
	var bm := brim.mesh as CylinderMesh
	bm.top_radius = 0.42
	bm.bottom_radius = 0.42
	bm.height = 0.06
	brim.position.y = 1.38
	root.add_child(brim)
	# Hat top
	var hat_top := _make_mesh_node(CylinderMesh.new(), Color(0.95, 0.92, 0.85))
	var htm := hat_top.mesh as CylinderMesh
	htm.top_radius = 0.22
	htm.bottom_radius = 0.22
	htm.height = 0.28
	hat_top.position.y = 1.55
	root.add_child(hat_top)
	# Gold chain
	var chain := _make_mesh_node(TorusMesh.new(), Color(0.9, 0.75, 0.1))
	var tm := chain.mesh as TorusMesh
	tm.inner_radius = 0.18
	tm.outer_radius = 0.28
	chain.position.y = 0.85
	chain.rotation_degrees.x = 90.0
	root.add_child(chain)
	# Sunglasses
	for dx in [-0.1, 0.1]:
		var lens := _make_mesh_node(CylinderMesh.new(), Color(0.05, 0.05, 0.05))
		var lm := lens.mesh as CylinderMesh
		lm.top_radius = 0.07
		lm.bottom_radius = 0.07
		lm.height = 0.02
		lens.position = Vector3(dx, 1.18, 0.2)
		lens.rotation_degrees.x = 90.0
		root.add_child(lens)
	# Gavel in hand
	var gavel_handle := _make_mesh_node(CylinderMesh.new(), Color(0.5, 0.3, 0.1))
	var ghm := gavel_handle.mesh as CylinderMesh
	ghm.top_radius = 0.03
	ghm.bottom_radius = 0.03
	ghm.height = 0.4
	gavel_handle.position = Vector3(0.35, 0.7, 0.0)
	gavel_handle.rotation_degrees.z = 45.0
	root.add_child(gavel_handle)
	var gavel_head := _make_mesh_node(CylinderMesh.new(), Color(0.85, 0.65, 0.1))
	var ghm2 := gavel_head.mesh as CylinderMesh
	ghm2.top_radius = 0.08
	ghm2.bottom_radius = 0.08
	ghm2.height = 0.14
	gavel_head.position = Vector3(0.52, 0.85, 0.0)
	gavel_head.rotation_degrees.x = 90.0
	root.add_child(gavel_head)
	return root

# ─── UI ────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 10
	add_child(_ui_layer)

	var root := Control.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	_ui_layer.add_child(root)

	# Dark gradient overlay at bottom
	var grad := ColorRect.new()
	grad.anchor_right = 1.0
	grad.anchor_bottom = 1.0
	grad.color = Color(0, 0, 0, 0.55)
	root.add_child(grad)

	# TITLE
	var title := Label.new()
	title.text = "🧑‍⚖️ SNOOP DOGG'S\nKAOTISKE RETSSAL 🌿"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.anchor_right = 1.0
	title.offset_top = 80.0
	title.offset_bottom = 280.0
	title.add_theme_font_size_override("font_size", 58)
	title.add_theme_color_override("font_color", Color(0.95, 0.75, 0.1))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	root.add_child(title)

	var sub := Label.new()
	sub.text = "Det ultimative AI-drevne selskabsspil"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.anchor_right = 1.0
	sub.offset_top = 285.0
	sub.offset_bottom = 340.0
	sub.add_theme_font_size_override("font_size", 28)
	sub.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	root.add_child(sub)

	# Buttons
	var btn_y := 500.0
	_make_button(root, "⚖️  SPIL NU", btn_y, Color(0.85, 0.65, 0.1), Color(0.05, 0.03, 0.1), _on_play_pressed)
	_make_button(root, "🔑  API NØGLE", btn_y + 140, Color(0.2, 0.4, 0.8), Color(0.95, 0.95, 1.0), _on_api_pressed)
	_make_button(root, "📖  REGLER", btn_y + 260, Color(0.3, 0.6, 0.3), Color(0.95, 1.0, 0.95), _on_rules_pressed)

	# Version label
	var ver := Label.new()
	ver.text = "v1.0 • Lanceret på Amazon Luna • October 2025"
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.anchor_right = 1.0
	ver.anchor_bottom = 1.0
	ver.offset_bottom = 0.0
	ver.offset_top = -60.0
	ver.add_theme_font_size_override("font_size", 18)
	ver.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	root.add_child(ver)

	# API Key Panel (hidden)
	_api_panel = _build_api_panel(root)
	_api_panel.visible = false

func _make_button(parent: Control, text: String, y: float, bg_color: Color, fg_color: Color, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.anchor_right = 1.0
	btn.offset_left = 80.0
	btn.offset_right = -80.0
	btn.offset_top = y
	btn.offset_bottom = y + 110.0
	btn.add_theme_font_size_override("font_size", 34)
	btn.add_theme_color_override("font_color", fg_color)
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 6
	btn.add_theme_stylebox_override("normal", style)
	var hover_style := style.duplicate() as StyleBoxFlat
	hover_style.bg_color = bg_color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn

func _build_api_panel(parent: Control) -> Control:
	var panel := Panel.new()
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.05, 0.03, 0.12, 0.97)
	ps.corner_radius_top_left = 20
	ps.corner_radius_top_right = 20
	ps.corner_radius_bottom_left = 20
	ps.corner_radius_bottom_right = 20
	panel.add_theme_stylebox_override("panel", ps)
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 60.0
	vbox.offset_right = -60.0
	vbox.offset_top = 300.0
	vbox.offset_bottom = -300.0
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var lbl := Label.new()
	lbl.text = "🔑 Anthropic API Nøgle"
	lbl.add_theme_font_size_override("font_size", 36)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.75, 0.1))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl)

	vbox.add_child(_make_spacer(20))

	var info := Label.new()
	info.text = "Med en API nøgle bruger Dommer Snoop\nægte AI til at reagere på dine forklaringer!\nFå din nøgle på anthropic.com"
	info.add_theme_font_size_override("font_size", 22)
	info.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(info)

	vbox.add_child(_make_spacer(30))

	_api_input = LineEdit.new()
	_api_input.placeholder_text = "sk-ant-..."
	_api_input.secret = true
	_api_input.custom_minimum_size = Vector2(0, 70)
	_api_input.add_theme_font_size_override("font_size", 24)
	if not GameManager.api_key.is_empty():
		_api_input.text = GameManager.api_key
	vbox.add_child(_api_input)

	vbox.add_child(_make_spacer(20))

	var save_btn := Button.new()
	save_btn.text = "💾 GEM NØGLE"
	save_btn.custom_minimum_size = Vector2(0, 70)
	save_btn.add_theme_font_size_override("font_size", 28)
	save_btn.pressed.connect(_on_save_api)
	vbox.add_child(save_btn)

	vbox.add_child(_make_spacer(10))

	var close_btn := Button.new()
	close_btn.text = "✕ Luk"
	close_btn.custom_minimum_size = Vector2(0, 60)
	close_btn.add_theme_font_size_override("font_size", 24)
	close_btn.pressed.connect(func(): _api_panel.visible = false)
	vbox.add_child(close_btn)

	return panel

func _make_spacer(h: float) -> Control:
	var s := Control.new()
	s.custom_minimum_size.y = h
	return s

# ─── Callbacks ───────────────────────────────────────────────────────────────

func _on_play_pressed() -> void:
	AudioMgr.play_swoosh()
	SceneTransition.goto("res://scenes/PlayerSetup.tscn")

func _on_api_pressed() -> void:
	_api_panel.visible = not _api_panel.visible

func _on_rules_pressed() -> void:
	_show_rules()

func _on_save_api() -> void:
	GameManager.set_api_key(_api_input.text)
	_api_panel.visible = false

func _show_rules() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "⚖️ Regler"
	dialog.dialog_text = """SNOOP DOGG'S KAOTISKE RETSSAL

📋 SETUP:
• 2-6 spillere
• Vælg antal spillere & skriv navne

⚖️ SPILLET:
• Dommer Snoop uddeler en absurd sag
• Rollerne fordeles: Anklager, Tiltalte, Vidner
• Hver spiller forklarer sin version i 60 sekunder
• Dommer Snoop reagerer med sjove kommentarer

🏆 POINT:
• Alle spillere stemmer efter hver runde
• Mest sjove / kreative vinder ekstra point
• Dommeren afsiger den endelige dom

🎯 MÅL:
Vind ikke sagen — underhold! Det er pointen!

Fo' shizzle, ya dig? 🌿"""
	dialog.min_size = Vector2(600, 700)
	add_child(dialog)
	dialog.popup_centered()

# ─── Helpers ────────────────────────────────────────────────────────────────

func _add_box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	mi.material_override = mat
	parent.add_child(mi)
	return mi

func _add_cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mi.mesh = mesh
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.6
	mi.material_override = mat
	parent.add_child(mi)
	return mi

func _make_mesh_node(mesh: Mesh, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.5
	mat.metallic = 0.1
	mi.material_override = mat
	return mi
