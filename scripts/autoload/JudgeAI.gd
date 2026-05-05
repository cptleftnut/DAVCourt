extends Node
## JudgeAI - Anthropic API integration for Dommer Snoop Dogg

const API_URL := "https://api.anthropic.com/v1/messages"
const MODEL := "claude-haiku-4-5-20251001"
const MAX_TOKENS := 350

var _http: HTTPRequest
var _pending_callback: Callable
var _is_requesting := false

const SNOOP_SYSTEM := """Du er DOMMER SNOOP DOGG — den cooleste, mest uhøjtidelige og absolut mest uforudsigelige dommer i verdenshistorien. Du præsiderer over verdens mest kaotiske retssal.

PERSONLIGHED:
- Du taler dansk men med Snoop Doggs ikoniske flair og slang
- Du siger ting som: "fo' shizzle", "ya dig?", "tha D-O-double-G", "drop it like it's hot", "gin and juice", "laid back"
- Du er altid cool, aldrig stresset, altid i godt humør
- Du finder ALT underholdende — jo mere absurd, jo bedre
- Du prøver at virke autoritær men fejler spektakulært

REAKTIONSFORMAT (hold under 130 ord):
1. En eksplosiv, sjov kommentar til det du hørte
2. Din "juridiske" analyse (fuldstændig nonsens)
3. Et spøjst Snoop-ordspil eller reference til musik

Afslut ALTID præcis med denne linje: "⚖️ RETTEN ER SAT, YA FEEL ME! 🌿"
"""

const VERDICT_SYSTEM := """Du er DOMMER SNOOP DOGG og skal nu afsige den endelige, episke dom.

DOM-FORMAT (hold under 180 ord):
1. Dramatisk åbning ("Ahem, tha D-O-double-G har talt...")
2. Kort opsummering af det absurde i sagen
3. DOMMEN: skyldig/frifundet/noget tredje vanvittigt
4. STRAFFEN: Fuldstændig surrealistisk og urelateret til sagen
5. Et personligt råd til ALLE involverede parter

Tal dansk med Snoop-flair.
Afslut ALTID med: "🔨 HAMMEREN FALDER! COURT IS IN SESSION! 🌿"
"""

func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_completed)
	_http.timeout = 30.0

func react_to_statement(player: String, role: String, statement: String, case_title: String, callback: Callable) -> void:
	_pending_callback = callback
	var prompt := """SAG: "%s"

%s (%s) fremfører nu sin forklaring:
"%s"

Reagér som Dommer Snoop Dogg på denne vidneudsagn!""" % [case_title, player, role, statement]
	_call_api(prompt, SNOOP_SYSTEM)

func deliver_verdict(case_data: Dictionary, all_statements: Array, callback: Callable) -> void:
	_pending_callback = callback
	var stmts := ""
	for s in all_statements:
		stmts += "\n• %s [%s]: \"%s\"" % [s["player"], s["role"], s["text"]]

	var prompt := """SAG: "%s"
ANKLAGE: %s

ALLE VIDNEUDSAGN:%s

Afsig nu den ENDELIGE DOM i denne sag!""" % [
		case_data.get("title", "Ukendt sag"),
		case_data.get("accusation", ""),
		stmts
	]
	_call_api(prompt, VERDICT_SYSTEM)

func _call_api(message: String, system: String) -> void:
	if _is_requesting:
		return

	var key := GameManager.api_key
	if key.is_empty():
		_pending_callback.call(_get_fallback_reaction())
		return

	_is_requesting = true
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"x-api-key: " + key,
		"anthropic-version: 2023-06-01"
	])
	var body := JSON.stringify({
		"model": MODEL,
		"max_tokens": MAX_TOKENS,
		"system": system,
		"messages": [{"role": "user", "content": message}]
	})
	var err := _http.request(API_URL, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		_is_requesting = false
		_pending_callback.call(_get_fallback_reaction())

func _on_completed(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_is_requesting = false
	if code != 200:
		_pending_callback.call(_get_fallback_reaction())
		return
	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		_pending_callback.call(_get_fallback_reaction())
		return
	var data: Dictionary = json.get_data()
	var content: Array = data.get("content", [])
	if content.is_empty():
		_pending_callback.call(_get_fallback_reaction())
		return
	var text: String = content[0].get("text", _get_fallback_reaction())
	_pending_callback.call(text)

func _get_fallback_reaction() -> String:
	var reactions := [
		"Fo' SHIZZLE! Det er det mest vanvittige jeg har hørt siden jeg prøvede at forklare mine skattepapirer til IRS! Ya dig? ⚖️ RETTEN ER SAT, YA FEEL ME! 🌿",
		"Hold da op, tha D-O-double-G er... faktisk målløs. Og det sker aldrig. Aldrig nogensinde. Drop it like it's hot! ⚖️ RETTEN ER SAT, YA FEEL ME! 🌿",
		"Jeg har hørt mange forklaringer i dette liv, men denne her... denne her er speciel. Som gin og juice speciel. ⚖️ RETTEN ER SAT, YA FEEL ME! 🌿",
		"Objection! ...vent, det er mig der er dommeren. Carry on, ya hear? Dette er entertainment, fo' shizzle! ⚖️ RETTEN ER SAT, YA FEEL ME! 🌿",
		"Laid back, with my mind on the verdict og min verdict on the... hvad sagde du egentlig? Det var VILDT. ⚖️ RETTEN ER SAT, YA FEEL ME! 🌿",
		"Snoop Dogg har set meget i sine dage, men denne retssal? This is next level absurdity, ya dig? ⚖️ RETTEN ER SAT, YA FEEL ME! 🌿",
	]
	return reactions[randi() % reactions.size()]

func get_fallback_verdict() -> String:
	var verdicts := [
		"Ahem, tha D-O-double-G har delibereret i 4,20 sekunder. DOMMEN: SKYLDIG — men på den seje måde. STRAFFEN: 420 timers obligatorisk lytning til Doggystyle i shuffle. Et personligt råd: I er alle vanvittige, og jeg elsker det. 🔨 HAMMEREN FALDER! COURT IS IN SESSION! 🌿",
		"Efter nøje overvejelse har Dommer Snoop konkluderet: FRIFUNDET! Ikke fordi I er uskyldige, men fordi denne sag er for absurd til at eksistere i virkeligheden. Råd: Stop med at gøre tingene endnu mere komplicerede. 🔨 HAMMEREN FALDER! COURT IS IN SESSION! 🌿",
		"DOM: Alle parter er skyldige i at underholde denne retssal på finest niveau. STRAF: I skal alle købe Snoop Dogg-merchandise for 69 kroner og smile. Personligt råd: Livet er for kort til at tage det seriøst. 🔨 HAMMEREN FALDER! COURT IS IN SESSION! 🌿",
	]
	return verdicts[randi() % verdicts.size()]
