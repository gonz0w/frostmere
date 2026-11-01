extends Node
## Two persistent music voices crossfade; effects use a bounded pool.
const TRACKS = ["wander", "battle", "aeralis", "aeralis_battle", "crucible", "crucible_battle", "station", "station_battle", "intro"]
const EFFECTS = ["finish_shell", "finish_crystal", "finish_furnace", "step_wood", "step_metal", "step_grass", "step_snow", "step_stone", "root_warning", "brine_warning", "ash_warning", "solar_warning", "power_impact", "interact", "loot", "quest", "enchant", "heal", "portal", "error", "swing", "hit", "block", "gun", "bow", "spell", "step", "forge", "gather", "death", "ward_approach", "ward_holds"]
const SETTINGS = "user://audio.cfg"
var world: Node3D
var music: Array[AudioStreamPlayer] = []
var voices: Array[AudioStreamPlayer] = []
var spatial_voices: Array[AudioStreamPlayer3D] = []
var spatial_sources: Dictionary = {}
var spatial_cursor := 0
var streams: Dictionary = {}
var cooldowns: Dictionary = {}
var current_track := ""
var active := 0
var fade := 1.0
var combat_hold := 0.0
var scan_time := 0.0
var step_time := 0.0
var previous_zone := ""
var quest_count := 0
var music_volume := 0.65
var effects_volume := 0.8
var master_volume := 0.85
var enabled := true
var last_effect := ""
var effect_count := 0

func _ready() -> void:
	# Tests and automated captures stay silent; playback remains testable explicitly.
	enabled = DisplayServer.get_name() != "headless" and not world.player._automated_render()
	for bus in ["Music", "Effects"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus(); AudioServer.set_bus_name(AudioServer.bus_count-1,bus)
	for id in TRACKS + EFFECTS:
		var path: String = "res://assets/audio/" + ("music/" if id in TRACKS else "sfx/") + id + ".wav"
		# Exported builds contain imported streams, not the original WAV files.
		var stream := load(path) as AudioStreamWAV if ResourceLoader.exists(path) else AudioStreamWAV.load_from_file(path)
		if stream == null: push_error("Missing audio: " + id); continue
		if id in TRACKS:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
		streams[id] = stream
	for i in range(2):
		var voice := AudioStreamPlayer.new(); voice.bus="Music"; add_child(voice); music.append(voice)
	for i in range(12):
		var voice := AudioStreamPlayer.new(); voice.bus="Effects"; add_child(voice); voices.append(voice)
	for i in range(6):
		var voice:=AudioStreamPlayer3D.new(); voice.bus="Effects"; voice.unit_size=6; voice.max_distance=32
		voice.volume_db=-5; voice.panning_strength=1; add_child(voice); spatial_voices.append(voice)
	var config := ConfigFile.new()
	if config.load(SETTINGS) == OK:
		master_volume = clampf(float(config.get_value("audio","master",0.85)),0,1)
		music_volume = clampf(float(config.get_value("audio","music",0.65)),0,1)
		effects_volume = clampf(float(config.get_value("audio","effects",0.8)),0,1)
	apply_volumes()
	quest_count = world.player.character.story_completed.size()

func apply_volumes() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),linear_to_db(maxf(0.00001,music_volume*master_volume)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Effects"),linear_to_db(maxf(0.00001,effects_volume*master_volume)))
func set_volume(kind: String, value: float) -> void:
	match kind:
		"master": master_volume=clampf(value,0,1)
		"music": music_volume=clampf(value,0,1)
		"effects": effects_volume=clampf(value,0,1)
	apply_volumes()
	if world.player.character.persist:
		var config:=ConfigFile.new()
		config.set_value("audio","master",master_volume); config.set_value("audio","music",music_volume); config.set_value("audio","effects",effects_volume)
		if config.save(SETTINGS) != OK: push_warning("Audio settings could not be saved.")

func zone() -> String:
	if is_instance_valid(world.intro) and world.intro.active: return "intro"
	if is_instance_valid(world.threshold) and world.threshold.inside: return "station"
	if is_instance_valid(world.realms) and world.realms.inside: return world.realms.current
	return "north"
func choose_track(place: String, combat: bool) -> String:
	if place == "intro": return "intro"
	if place in ["aeralis", "crucible", "station"]: return place + ("_battle" if combat else "")
	return "battle" if combat else "wander"
func transition(id: String) -> void:
	if id == current_track or not streams.has(id): return
	# Complete a pending fade before reusing its outgoing voice.
	music[1-active].stop()
	active = 1-active
	music[active].stream=streams[id]; music[active].volume_db=-80
	if enabled: music[active].play()
	current_track=id; fade=0
func engage() -> void:
	combat_hold=6.0
func sfx(id: String) -> void:
	if not streams.has(id) or float(cooldowns.get(id,0)) > 0: return
	cooldowns[id]=0.06 if id=="gun" else 0.12
	last_effect=id; effect_count+=1
	if not enabled: return
	var voice: AudioStreamPlayer=effect_voice(effect_priority(id))
	if voice==null: return
	voice.stop(); voice.stream_paused=false
	voice.set_meta("priority",effect_priority(id)); voice.set_meta("order",effect_count)
	voice.stream=streams[id]; voice.volume_db=-12 if id.begins_with("step") else -5
	voice.pitch_scale=randf_range(0.96,1.04) if id.begins_with("step") or id in ["hit","swing","gun"] else 1.0
	voice.play()

func effect_priority(id: String) -> int:
	if id in ["ward_approach","ward_holds","death"]: return 3
	if id in ["quest","portal","heal"] or id.begins_with("finish_"): return 2
	return 0 if id.begins_with("step") else 1
func effect_voice(priority: int) -> AudioStreamPlayer:
	var candidate: AudioStreamPlayer
	for voice in voices:
		if not voice.playing: return voice
		var rank: int=voice.get_meta("priority",0)
		if rank>=priority: continue
		if candidate==null or rank<int(candidate.get_meta("priority",0)) or (rank==int(candidate.get_meta("priority",0)) and int(voice.get_meta("order",0))<int(candidate.get_meta("order",0))):
			candidate=voice
	return candidate

func sync_intro_cues(paused: bool, stop: bool = false) -> void:
	for voice in voices:
		if voice.stream in [streams.get("ward_approach"), streams.get("ward_holds")]:
			if stop: voice.stop()
			voice.stream_paused=paused and not stop

func warning_at(id: String, source: Node3D) -> void:
	if not is_instance_valid(source) or not streams.has(id) or float(cooldowns.get(id,0))>0: return
	if world.player.paused or source.dead or not source.adventure.inside: return
	if source.global_position.distance_to(world.player.global_position)>32: return
	cooldowns[id]=.12; last_effect=id; effect_count+=1
	var slot:=spatial_cursor
	for i in range(spatial_voices.size()):
		if not spatial_voices[i].playing: slot=i; break
	spatial_cursor=(slot+1)%spatial_voices.size()
	var voice:=spatial_voices[slot]; voice.stop()
	voice.stream=streams[id]; voice.global_position=source.global_position+Vector3.UP*1.5
	spatial_sources[slot]=weakref(source)
	if enabled: voice.play()

func update_spatial() -> void:
	for slot in spatial_sources.keys():
		var source=spatial_sources[slot].get_ref()
		var voice: AudioStreamPlayer3D=spatial_voices[slot]
		if not is_instance_valid(source) or world.player.paused or source.dead or not source.adventure.inside or source.execution_locked or source.stagger_time>0:
			voice.stop(); spatial_sources.erase(slot); continue
		voice.global_position=source.global_position+Vector3.UP*1.5
		if enabled and not voice.playing: spatial_sources.erase(slot)

func _process(delta: float) -> void:
	update_spatial()
	for id in cooldowns: cooldowns[id]=maxf(0,float(cooldowns[id])-delta)
	if not is_instance_valid(world.archive_chapter): return
	var place:=zone()
	if place!=previous_zone:
		if previous_zone!="": sfx("portal")
		previous_zone=place; combat_hold=0
	if not world.player.paused:
		combat_hold=maxf(0,combat_hold-delta)
		scan_time-=delta
		if scan_time<=0:
			scan_time=0.25
			for enemy in world.combat_enemies():
				if enemy.has_method("threatens_player") and not enemy.threatens_player(): continue
				if enemy.adventure.inside and not enemy.dead and enemy.global_position.distance_to(world.player.global_position)<21 and enemy.adventure.line_clear(enemy.global_position+Vector3.UP,world.player.global_position+Vector3.UP,enemy,world.player): engage(); break
		step_time-=delta
		if world.player.is_on_floor() and Vector2(world.player.velocity.x,world.player.velocity.z).length()>1 and step_time<=0:
			sfx(world.footstep_at(world.player.global_position)); step_time=0.32 if world.player.velocity.length()>5 else 0.48
	var count: int=world.player.character.story_completed.size()
	if count>quest_count: sfx("quest")
	quest_count=count
	transition(choose_track(place,combat_hold>0))
	fade=minf(1,fade+delta/2.0)
	var duck: float=0.45 if world.player.paused else 1.0
	music[active].volume_db=linear_to_db(maxf(.0001,sin(fade*PI/2)*duck))
	music[1-active].volume_db=linear_to_db(maxf(.0001,cos(fade*PI/2)*duck))
	if fade>=1 and music[1-active].playing: music[1-active].stop()
