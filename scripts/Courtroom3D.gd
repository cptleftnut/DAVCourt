extends Node
## Courtroom - 2D gameplay scene (reliable on all Android devices)

var _phase := "intro"
var _intro_done := false
var _statement_timer := 0.0
var _statement_duration := 60.0
var _timer_active := false
var _case_data: Dictionary = {}
var _current_vote_idx := 0
var _anim_time := 0.0

const COLORS := [
	Color(0.95, 0.3,  0.3),
	Color(0.3,  0.5,  0.95),
	Color(0.3,  0.85, 0.4),
	Color(0.95, 0.75, 0.1),
	Color(0.85, 0.3,  0.85),
	Color(0.95, 0.55, 0.1),
]

var _root: Control
var _phase_lbl: Label
var _case_panel: Panel
var _case_title_lbl: Label
var _case_desc_lbl: Label
var _case_emoji_lbl: Label
var _judge_panel: Panel
var _judge_text: Label
var _thinking_lbl: Label
var _player_panel: Panel
var _player_name_lbl: Label
var _player_role_lbl: Label
var _stmt_input: TextEdit
var _submit_btn: Button
var _timer_lbl: Label
var _vote_panel: Panel
var _score_list: VBoxContainer
var _snoop_lbl: Label

func _ready() -> void:
	_build_ui()
	GameManager.scores_updated.connect(func(_s): _refresh_scores())
	await get_tree().create_timer(0.2).timeout
	_start_intro()

func _process(delta: float) -> void:
	_anim_time += delta
	if _snoop_lbl and is_instance_valid(_snoop_lbl):
		_snoop_lbl.position.y = 30.0 + sin(_anim_time * 2.2) * 8.0
	if _timer_active:
		_statement_timer -= delta
		_update_timer()
		if _statement_timer <= 0.0:
			_timer_active = false
			_on_submit()

func _start_intro() -> void:
	_phase = "intro"
	_case_data = GameManager.current_case
	if _case_data.is_empty():
		GameManager.start_new_case()
		_case_data = GameManager.current_case
	_show_case_panel()
	_set_phase_lbl("🔔  NY SAG ANNONCERES")
	AudioMgr.play_gavel()
	await get_tree().create_timer(0.8).timeout
	if not is_inside_tree(): return
	_judge_say("Yo yo YO! Retten er sat!\n\n%s\n\n%s\n\nLad os GORE DET! Fo shizzle! 🌿" % [
		_case_data.get("title", ""), _case_data.get("accusation", ""),
	])

func _begin_statements() -> void:
	if _intro_done: return
	_intro_done = true
	_phase = "statement"
	var player := GameManager.get_current_player()
	if player.is_empty():
		_begin_voting()
		return
	_hide_case_panel()
	_hide_judge()
	_show_player_panel(player)
	_statement_timer = _statement_duration
	_timer_active = true
	_stmt_input.text = ""
	_stmt_input.editable = true
	_submit_btn.disabled = false
	_set_phase_lbl("🎤  %s taler nu" % player.get("name", "?"))
	AudioMgr.play_swoosh()

func _on_submit() -> void:
	if _phase != "statement": return
	if _submit_btn.disabled: return
	_timer_active = false
	_submit_btn.disabled = true
	_stmt_input.editable = false
	var player := GameManager.get_current_player()
	var text := _stmt_input.text.strip_edges()
	if text.is_empty():
		text = "[spilleren stirrede tavst pa dommeren]"
	GameManager.submit_statement(player.get("name", "?"), text)
	_phase = "judge"
	_set_phase_lbl("⚖️  Dommer Snoop overvejer...")
	_show_thinking()
	JudgeAI.react_to_statement(
		player.get("name", "?"), player.get("role", "Spiller"),
		text, _case_data.get("title", "Sagen"), _on_judge_reaction
	)

func _on_judge_reaction(reaction: String) -> void:
	_hide_thinking()
	_judge_say(reaction)
	AudioMgr.play_gavel()
	AudioMgr.play_crowd_cheer()
	await get_tree().create_timer(5.0).timeout
	if not is_inside_tree(): return
	if GameManager.all_players_have_spoken():
		_begin_voting()
	else:
		_phase = "statement"
		var next := GameManager.get_current_player()
		if next.is_empty():
			_begin_voting()
			return
		_hide_judge()
		_show_player_panel(next)
		_statement_timer = _statement_duration
		_timer_active = true
		_stmt_input.text = ""
		_stmt_input.editable = true
		_submit_btn.disabled = false
		_set_phase_lbl("🎤  %s taler nu" % next.get("name", "?"))
		AudioMgr.play_swoosh()

func _begin_voting() -> void:
	_phase = "voting"
	_hide_judge()
	_hide_player_panel()
	_current_vote_idx = 0
	_set_phase_lbl("🗳️  AFSTEMNING")
	_show_vote_panel()

func _on_vote(voter_name: String, voted_for: String) -> void:
	GameManager.add_score(voted_for, 1)
	_current_vote_idx += 1
	if _current_vote_idx >= GameManager.players.size():
		_hide_vote_panel()
		_begin_verdict()
	else:
		_refresh_vote_panel()

func _begin_verdict() -> void:
	_phase = "verdict"
	_set_phase_lbl("🔨  DOMMEN AFSIGES...")
	_show_thinking()
	AudioMgr.play_gavel()
	JudgeAI.deliver_verdict(_case_data, GameManager.statements, _on_verdict)

func _on_verdict(text: String) -> void:
	_hide_thinking()
	_judge_say(text, true)
	AudioMgr.play_bling()
	await get_tree().create_timer(7.0).timeout
	if not is_inside_tree(): return
	SceneTransition.goto("res://scenes/VerdictScreen.tscn")

# ── UI Build ──────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_root)

	# Background wall
	_root.add_child(_rect(Color(0.85, 0.82, 0.75), 0, 0, 1080, 850))
	# Wainscoting
	_root.add_child(_rect(Color(0.38, 0.20, 0.06), 0, 580, 1080, 270))
	# Floor
	_root.add_child(_rect(Color(0.20, 0.10, 0.03), 0, 820, 1080, 300))
	# Spotlight
	var spot := ColorRect.new()
	spot.color = Color(1.0, 0.97, 0.85, 0.09)
	spot.position = Vector2(380, 0)
	spot.size = Vector2(320, 800)
	_root.add_child(spot)
	# Judge bench
	_root.add_child(_rect(Color(0.32, 0.14, 0.03), 240, 490, 600, 190))
	_root.add_child(_rect(Color(0.80, 0.60, 0.07), 232, 484, 616, 16))
	# Columns
	for x in [55, 240, 784, 969]:
		_root.add_child(_rect(Color(0.88, 0.85, 0.78), x, 70, 56, 530))
		_root.add_child(_rect(Color(0.80, 0.60, 0.07), x - 8, 64, 72, 18))
		_root.add_child(_rect(Color(0.80, 0.60, 0.07), x - 8, 594, 72, 16))
	# Gold rail
	_root.add_child(_rect(Color(0.80, 0.60, 0.07), 0, 710, 1080, 12))
	# Flags
	_add_flag(Color(0.1, 0.15, 0.55), 120, 110)
	_add_flag(Color(0.55, 0.12, 0.08), 910, 110)
	# Dark overlay at bottom so panels read well
	_root.add_child(_rect(Color(0, 0, 0, 0.45), 0, 700, 1080, 420))

	# Snoop emoji (animated)
	_snoop_lbl = Label.new()
	_snoop_lbl.text = "🧑‍⚖️"
	_snoop_lbl.add_theme_font_size_override("font_size", 120)
	_snoop_lbl.position = Vector2(440, 30)
	_root.add_child(_snoop_lbl)

	# Gavel + mic
	var gavel_lbl := Label.new()
	gavel_lbl.text = "🔨"
	gavel_lbl.add_theme_font_size_override("font_size", 58)
	gavel_lbl.position = Vector2(690, 480)
	_root.add_child(gavel_lbl)
	var mic_lbl := Label.new()
	mic_lbl.text = "🎤"
	mic_lbl.add_theme_font_size_override("font_size", 52)
	mic_lbl.position = Vector2(478, 488)
	_root.add_child(mic_lbl)

	# Scores (left strip)
	var score_bg := Panel.new()
	score_bg.position = Vector2(0, 72)
	score_bg.size = Vector2(185, 520)
	var sbs := StyleBoxFlat.new()
	sbs.bg_color = Color(0.04, 0.02, 0.10, 0.90)
	sbs.border_color = Color(0.80, 0.60, 0.07)
	sbs.border_width_right = 2
	score_bg.add_theme_stylebox_override("panel", sbs)
	_root.add_child(score_bg)
	var svbox := VBoxContainer.new()
	svbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	svbox.offset_left = 10; svbox.offset_right = -10
	svbox.offset_top = 10; svbox.offset_bottom = -10
	score_bg.add_child(svbox)
	var shdr := Label.new()
	shdr.text = "🏆 POINT"
	shdr.add_theme_font_size_override("font_size", 20)
	shdr.add_theme_color_override("font_color", Color(0.80, 0.60, 0.07))
	shdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	svbox.add_child(shdr)
	_score_list = VBoxContainer.new()
	_score_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	svbox.add_child(_score_list)
	_refresh_scores()

	# Phase label (top)
	_phase_lbl = Label.new()
	_phase_lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_phase_lbl.offset_bottom = 72.0
	_phase_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_phase_lbl.add_theme_font_size_override("font_size", 26)
	_phase_lbl.add_theme_color_override("font_color", Color(0.95, 0.75, 0.1))
	var pls := StyleBoxFlat.new()
	pls.bg_color = Color(0, 0, 0, 0.70)
	_phase_lbl.add_theme_stylebox_override("normal", pls)
	_root.add_child(_phase_lbl)

	_build_case_panel()
	_build_judge_panel()
	_build_player_panel()
	_build_vote_panel()

func _add_flag(color: Color, x: float, y: float) -> void:
	_root.add_child(_rect(Color(0.80, 0.60, 0.07), x, y, 8, 280))
	_root.add_child(_rect(color, x + 8, y, 76, 48))

func _rect(color: Color, x: float, y: float, w: float, h: float) -> ColorRect:
	var r := ColorRect.new(); r.color = color
	r.position = Vector2(x, y); r.size = Vector2(w, h)
	return r

func _build_case_panel() -> void:
	_case_panel = Panel.new()
	_case_panel.position = Vector2(165, 72)
	_case_panel.size = Vector2(750, 900)
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.04, 0.02, 0.12, 0.97)
	s.border_color = Color(0.80, 0.60, 0.07)
	s.set_border_width_all(3); s.set_corner_radius_all(18)
	s.shadow_color = Color(0, 0, 0, 0.6); s.shadow_size = 14
	_case_panel.add_theme_stylebox_override("panel", s)
	_root.add_child(_case_panel)
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 26; vbox.offset_right = -26
	vbox.offset_top = 22; vbox.offset_bottom = -22
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_case_panel.add_child(vbox)
	_case_emoji_lbl = Label.new()
	_case_emoji_lbl.add_theme_font_size_override("font_size", 88)
	_case_emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_case_emoji_lbl)
	_case_title_lbl = Label.new()
	_case_title_lbl.add_theme_font_size_override("font_size", 34)
	_case_title_lbl.add_theme_color_override("font_color", Color(0.95, 0.75, 0.1))
	_case_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_case_title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_case_title_lbl)
	vbox.add_child(_sp(14))
	_case_desc_lbl = Label.new()
	_case_desc_lbl.add_theme_font_size_override("font_size", 25)
	_case_desc_lbl.add_theme_color_override("font_color", Color(0.88, 0.85, 0.92))
	_case_desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_case_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_case_desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_case_desc_lbl)
	vbox.add_child(_sp(12))
	var roles_lbl := Label.new()
	roles_lbl.name = "RolesLabel"
	roles_lbl.add_theme_font_size_override("font_size", 22)
	roles_lbl.add_theme_color_override("font_color", Color(0.68, 0.68, 0.80))
	roles_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	roles_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(roles_lbl)
	vbox.add_child(_sp(18))
	var btn := Button.new()
	btn.text = "⚖️  FORSTÅET — LET'S GO!"
	btn.custom_minimum_size.y = 92
	btn.add_theme_font_size_override("font_size", 30)
	btn.add_theme_color_override("font_color", Color(0.04, 0.02, 0.1))
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(0.80, 0.60, 0.07)
	bs.set_corner_radius_all(16)
	bs.shadow_color = Color(0.80, 0.60, 0.07, 0.4); bs.shadow_size = 8
	btn.add_theme_stylebox_override("normal", bs)
	btn.pressed.connect(func():
		if _intro_done: return
		_begin_statements()
	)
	vbox.add_child(btn)
	_case_panel.visible = false

func _build_judge_panel() -> void:
	_judge_panel = Panel.new()
	_judge_panel.position = Vector2(175, 720)
	_judge_panel.size = Vector2(730, 480)
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.06, 0.03, 0.15, 0.97)
	s.border_color = Color(0.80, 0.60, 0.07)
	s.set_border_width_all(3); s.set_corner_radius_all(20)
	s.shadow_color = Color(0.80, 0.60, 0.07, 0.4); s.shadow_size = 14
	_judge_panel.add_theme_stylebox_override("panel", s)
	_root.add_child(_judge_panel)
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 22; vbox.offset_right = -22
	vbox.offset_top = 16; vbox.offset_bottom = -16
	_judge_panel.add_child(vbox)
	var hdr := Label.new()
	hdr.text = "🧑‍⚖️  Dommer Snoop Dogg:"
	hdr.add_theme_font_size_override("font_size", 24)
	hdr.add_theme_color_override("font_color", Color(0.80, 0.60, 0.07))
	vbox.add_child(hdr)
	_thinking_lbl = Label.new()
	_thinking_lbl.text = "🌿  Delibererer... fo shizzle..."
	_thinking_lbl.add_theme_font_size_override("font_size", 28)
	_thinking_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.72))
	_thinking_lbl.visible = false
	vbox.add_child(_thinking_lbl)
	_judge_text = Label.new()
	_judge_text.add_theme_font_size_override("font_size", 24)
	_judge_text.add_theme_color_override("font_color", Color(0.92, 0.9, 0.96))
	_judge_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_judge_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_judge_text)
	_judge_panel.visible = false

func _build_player_panel() -> void:
	_player_panel = Panel.new()
	_player_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_player_panel.offset_top = -620.0
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.04, 0.02, 0.12, 0.98)
	s.border_color = Color(0.40, 0.20, 0.65); s.border_width_top = 3
	_player_panel.add_theme_stylebox_override("panel", s)
	_root.add_child(_player_panel)
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 22; vbox.offset_right = -22
	vbox.offset_top = 14; vbox.offset_bottom = -14
	_player_panel.add_child(vbox)
	var hrow := HBoxContainer.new()
	vbox.add_child(hrow)
	_player_name_lbl = Label.new()
	_player_name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_player_name_lbl.add_theme_font_size_override("font_size", 42)
	_player_name_lbl.add_theme_color_override("font_color", Color(0.95, 0.75, 0.1))
	hrow.add_child(_player_name_lbl)
	_player_role_lbl = Label.new()
	_player_role_lbl.add_theme_font_size_override("font_size", 26)
	_player_role_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.85))
	_player_role_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hrow.add_child(_player_role_lbl)
	_timer_lbl = Label.new()
	_timer_lbl.add_theme_font_size_override("font_size", 38)
	_timer_lbl.add_theme_color_override("font_color", Color(0.95, 0.75, 0.1))
	_timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_timer_lbl.custom_minimum_size.x = 120
	hrow.add_child(_timer_lbl)
	var case_hint := Label.new()
	case_hint.name = "CaseHint"
	case_hint.add_theme_font_size_override("font_size", 20)
	case_hint.add_theme_color_override("font_color", Color(0.58, 0.58, 0.70))
	case_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(case_hint)
	var hint := Label.new()
	hint.text = "Skriv din forklaring (jo mere absurd, jo bedre!):"
	hint.add_theme_font_size_override("font_size", 22)
	hint.add_theme_color_override("font_color", Color(0.55, 0.55, 0.68))
	vbox.add_child(hint)
	_stmt_input = TextEdit.new()
	_stmt_input.placeholder_text = "Din version af hvad der skete..."
	_stmt_input.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stmt_input.add_theme_font_size_override("font_size", 26)
	_stmt_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	vbox.add_child(_stmt_input)
	_submit_btn = Button.new()
	_submit_btn.text = "🎤  FREMFOR MIN FORKLARING"
	_submit_btn.custom_minimum_size.y = 90
	_submit_btn.add_theme_font_size_override("font_size", 32)
	_submit_btn.add_theme_color_override("font_color", Color(0.04, 0.02, 0.1))
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(0.80, 0.60, 0.07)
	bs.set_corner_radius_all(16)
	bs.shadow_color = Color(0.80, 0.60, 0.07, 0.4); bs.shadow_size = 6
	_submit_btn.add_theme_stylebox_override("normal", bs)
	_submit_btn.pressed.connect(_on_submit)
	vbox.add_child(_submit_btn)
	_player_panel.visible = false

func _build_vote_panel() -> void:
	_vote_panel = Panel.new()
	_vote_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.04, 0.02, 0.12, 0.99)
	s.border_color = Color(0.80, 0.60, 0.07); s.set_border_width_all(3)
	_vote_panel.add_theme_stylebox_override("panel", s)
	_root.add_child(_vote_panel)
	_vote_panel.visible = false

func _show_case_panel() -> void:
	_case_title_lbl.text = _case_data.get("title", "")
	_case_desc_lbl.text = _case_data.get("accusation", "") + "\n\n" + _case_data.get("context", "")
	_case_emoji_lbl.text = _case_data.get("emoji", "⚖️")
	var roles_lbl := _case_panel.find_child("RolesLabel", true, false) as Label
	if roles_lbl:
		var roles := ""
		for p: Dictionary in GameManager.players:
			roles += "• %s → %s\n" % [p.get("name", "?"), p.get("role", "?")]
		roles_lbl.text = roles.strip_edges()
	_case_panel.visible = true

func _hide_case_panel() -> void: _case_panel.visible = false
func _judge_say(text: String, big: bool = false) -> void:
	_thinking_lbl.visible = false
	_judge_text.text = text
	_judge_text.add_theme_font_size_override("font_size", 28 if big else 23)
	_judge_panel.visible = true
func _hide_judge() -> void: _judge_panel.visible = false
func _show_thinking() -> void:
	_judge_text.text = ""
	_thinking_lbl.visible = true
	_judge_panel.visible = true
func _hide_thinking() -> void: _thinking_lbl.visible = false

func _show_player_panel(player: Dictionary) -> void:
	var idx: int = player.get("index", 0)
	_player_name_lbl.text = player.get("name", "?")
	_player_name_lbl.add_theme_color_override("font_color", COLORS[idx % COLORS.size()])
	_player_role_lbl.text = player.get("role", "")
	var hint := _player_panel.find_child("CaseHint", true, false) as Label
	if hint: hint.text = "📋 " + _case_data.get("accusation", "")
	_player_panel.visible = true

func _hide_player_panel() -> void: _player_panel.visible = false
func _set_phase_lbl(text: String) -> void: _phase_lbl.text = text
func _update_timer() -> void:
	var s := int(ceil(_statement_timer))
	_timer_lbl.text = "⏱ %d" % s
	_timer_lbl.add_theme_color_override("font_color",
		Color(0.95, 0.25, 0.25) if s <= 10 else Color(0.95, 0.75, 0.1))

func _show_vote_panel() -> void:
	_vote_panel.visible = true
	_refresh_vote_panel()
func _hide_vote_panel() -> void: _vote_panel.visible = false

func _refresh_vote_panel() -> void:
	for c in _vote_panel.get_children(): c.queue_free()
	if _current_vote_idx >= GameManager.players.size(): return
	var voter: Dictionary = GameManager.players[_current_vote_idx]
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vote_panel.add_child(scroll)
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.offset_left = 55; vbox.offset_right = -55
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	scroll.add_child(vbox)
	vbox.add_child(_sp(180))
	var q := Label.new()
	q.text = "🗳️  %s\nHvem var MEST underholdende?" % voter.get("name", "?")
	q.add_theme_font_size_override("font_size", 42)
	q.add_theme_color_override("font_color", Color(0.95, 0.75, 0.1))
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(q)
	vbox.add_child(_sp(28))
	for i in range(GameManager.players.size()):
		var p: Dictionary = GameManager.players[i]
		if p.get("name") == voter.get("name"): continue
		var btn := Button.new()
		btn.text = "%s   %s" % [p.get("name", "?"), p.get("role", "")]
		btn.custom_minimum_size.y = 100
		btn.add_theme_font_size_override("font_size", 32)
		btn.add_theme_color_override("font_color", COLORS[i % COLORS.size()])
		var s := StyleBoxFlat.new()
		s.bg_color = Color(COLORS[i].r * 0.18, COLORS[i].g * 0.18, COLORS[i].b * 0.18)
		s.border_color = COLORS[i % COLORS.size()]
		s.set_border_width_all(2); s.set_corner_radius_all(16)
		btn.add_theme_stylebox_override("normal", s)
		btn.pressed.connect(func(): _on_vote(voter.get("name"), p.get("name")))
		vbox.add_child(btn)
		vbox.add_child(_sp(12))

func _refresh_scores() -> void:
	if not _score_list or not is_instance_valid(_score_list): return
	for c in _score_list.get_children(): c.queue_free()
	for i in range(GameManager.players.size()):
		var p: Dictionary = GameManager.players[i]
		var lbl := Label.new()
		lbl.text = "%s\n%d pt" % [p.get("name", "?"), p.get("score", 0)]
		lbl.add_theme_font_size_override("font_size", 17)
		lbl.add_theme_color_override("font_color", COLORS[i % COLORS.size()])
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_score_list.add_child(lbl)
		var sep := HSeparator.new()
		sep.add_theme_color_override("color", Color(0.3, 0.3, 0.4))
		_score_list.add_child(sep)

func _sp(h: float) -> Control:
	var s := Control.new(); s.custom_minimum_size.y = h; return s
