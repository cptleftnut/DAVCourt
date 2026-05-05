extends Node
## AudioManager - Procedural sound effects via AudioStreamGenerator

var _players: Dictionary = {}

func _ready() -> void:
	# Create audio stream players for different sfx categories
	for cat in ["gavel", "crowd", "swoosh", "judge", "bling"]:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players[cat] = p

func play_gavel() -> void:
	_play_tone("gavel", 180.0, 0.3, 0.15)
	await get_tree().create_timer(0.18).timeout
	_play_tone("gavel", 120.0, 0.25, 0.2)

func play_crowd_cheer() -> void:
	# Play a noisy "crowd" approximation
	for i in range(5):
		var freq := randf_range(200.0, 600.0)
		_play_tone("crowd", freq, 0.08, 0.4)
		await get_tree().create_timer(0.05).timeout

func play_swoosh() -> void:
	_play_tone("swoosh", 800.0, 0.2, 0.35)

func play_bling() -> void:
	var freqs := [880.0, 1100.0, 1320.0, 1760.0]
	for f in freqs:
		_play_tone("bling", f, 0.15, 0.2)
		await get_tree().create_timer(0.08).timeout

func play_dramatic_sting() -> void:
	_play_tone("judge", 220.0, 0.3, 0.6)
	await get_tree().create_timer(0.3).timeout
	_play_tone("judge", 196.0, 0.35, 0.5)

func _play_tone(category: String, frequency: float, volume: float, duration: float) -> void:
	if not category in _players:
		return
	var player: AudioStreamPlayer = _players[category]
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = duration + 0.1
	player.stream = gen
	player.volume_db = linear_to_db(clamp(volume, 0.0, 1.0))
	player.play()
	
	# Fill the buffer
	await get_tree().process_frame
	var pb := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		return
	
	var frames := int(22050.0 * duration)
	var buf := PackedVector2Array()
	buf.resize(frames)
	
	for i in range(frames):
		var t := float(i) / 22050.0
		var envelope := 1.0 - (float(i) / float(frames))  # linear fade out
		var sample := sin(TAU * frequency * t) * volume * envelope
		buf[i] = Vector2(sample, sample)
	
	pb.push_buffer(buf)
