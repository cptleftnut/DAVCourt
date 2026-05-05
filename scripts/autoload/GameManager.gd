extends Node
## GameManager - Core game state machine and data store

enum GameState {
	MAIN_MENU,
	PLAYER_SETUP,
	CASE_INTRO,
	STATEMENT_PHASE,
	JUDGE_REACTION,
	VOTING,
	VERDICT,
	SCORE_SCREEN
}

var state: GameState = GameState.MAIN_MENU
var players: Array = []
var current_case: Dictionary = {}
var current_player_idx: int = 0
var statements: Array = []
var api_key: String = ""

signal state_changed(new_state: int)
signal case_set(case_data: Dictionary)
signal statement_added(player_name: String, statement: String, role: String)
signal judge_reaction_ready(text: String)
signal verdict_ready(verdict_text: String)
signal scores_updated(scores: Dictionary)

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		api_key = config.get_value("api", "key", "")

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("api", "key", api_key)
	config.save("user://settings.cfg")

func set_api_key(key: String) -> void:
	api_key = key.strip_edges()
	save_settings()

func setup_players(player_names: Array) -> void:
	players.clear()
	statements.clear()
	var colors := [
		Color(0.95, 0.25, 0.25),
		Color(0.25, 0.55, 0.95),
		Color(0.25, 0.85, 0.35),
		Color(0.95, 0.75, 0.1),
		Color(0.85, 0.25, 0.85),
		Color(0.95, 0.5, 0.1),
	]
	for i in range(player_names.size()):
		players.append({
			"name": player_names[i],
			"index": i,
			"color": colors[i % colors.size()],
			"score": 0,
			"role": "",
		})

func start_new_case() -> void:
	current_case = CaseGenerator.get_random_case()
	statements.clear()
	current_player_idx = 0
	_assign_roles()
	emit_signal("case_set", current_case)
	change_state(GameState.CASE_INTRO)

func _assign_roles() -> void:
	var shuffled := players.duplicate()
	shuffled.shuffle()
	if shuffled.size() >= 1:
		current_case["prosecutor_name"] = shuffled[0]["name"]
		for p in players:
			if p["name"] == shuffled[0]["name"]:
				p["role"] = "Anklager ⚖️"
	if shuffled.size() >= 2:
		current_case["defendant_name"] = shuffled[1]["name"]
		for p in players:
			if p["name"] == shuffled[1]["name"]:
				p["role"] = "Tiltalte 👤"
	var witnesses := []
	for i in range(2, shuffled.size()):
		witnesses.append(shuffled[i]["name"])
		for p in players:
			if p["name"] == shuffled[i]["name"]:
				p["role"] = "Vidne #%d 🗣️" % (i - 1)
	current_case["witnesses"] = witnesses

func get_current_player() -> Dictionary:
	if current_player_idx < players.size():
		return players[current_player_idx]
	return {}

func get_player_role(player_name: String) -> String:
	for p in players:
		if p["name"] == player_name:
			return p.get("role", "Tilskuer")
	return "Tilskuer"

func submit_statement(player_name: String, statement: String) -> void:
	var role := get_player_role(player_name)
	statements.append({
		"player": player_name,
		"text": statement,
		"role": role,
		"timestamp": Time.get_unix_time_from_system()
	})
	emit_signal("statement_added", player_name, statement, role)
	current_player_idx += 1

func all_players_have_spoken() -> bool:
	return current_player_idx >= players.size()

func add_score(player_name: String, points: int) -> void:
	for p in players:
		if p["name"] == player_name:
			p["score"] += points
	emit_signal("scores_updated", get_scores())

func get_scores() -> Dictionary:
	var scores := {}
	for p in players:
		scores[p["name"]] = p.get("score", 0)
	return scores

func get_winner() -> Dictionary:
	var winner := {}
	var max_score := -999
	for p in players:
		if p["score"] > max_score:
			max_score = p["score"]
			winner = p
	return winner

func change_state(new_state: GameState) -> void:
	state = new_state
	emit_signal("state_changed", new_state)

func reset_for_new_game() -> void:
	statements.clear()
	current_player_idx = 0
	current_case = {}
	for p in players:
		p["score"] = 0
		p["role"] = ""
