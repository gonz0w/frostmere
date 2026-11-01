extends SceneTree
const State=preload("res://scripts/character_state.gd")
const Atlas=preload("res://scripts/atlas_state.gd")
var report_path: String
var duration:=1800.0
var samples: Array=[]
var frames:=0
var stalls:=0
var maximum_ms:=0.0
var histogram: PackedInt64Array=[]
var attacks:=0
var windups:=0
var hits:=0
var crafted:=0
var travels:=0
var combat_windows: Array=[]
var window_attacks:=0
var window_hits:=0
var window_windups:=0
var previous_windup: Dictionary={}
var previous_health: Dictionary={}

func _initialize() -> void: call_deferred("run")
func write_json(path: String,value: Variant) -> void:
	var file=FileAccess.open(path,FileAccess.WRITE); assert(file!=null)
	file.store_string(JSON.stringify(value)); file.close()
func percentile(fraction: float) -> int:
	var target:=ceili(frames*fraction); var total:=0
	for i in range(histogram.size()):
		total+=histogram[i]
		if total>=target: return ceili(maximum_ms) if i==1000 else i
	return 1000
func metrics() -> Dictionary:
	return {"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"orphans":Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),"resources":Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),"static_mib":Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0}
func record_window(seconds: float) -> void:
	var window={"seconds":seconds,"attacks":attacks-window_attacks,"hits":hits-window_hits,"windups":windups-window_windups}
	assert(window.attacks>0 and window.hits>0 and window.windups>0,"Combat must remain active in every measured window")
	combat_windows.append(window)
	window_attacks=attacks; window_hits=hits; window_windups=windups
func run() -> void:
	assert(DisplayServer.get_name()!="headless")
	assert(OS.get_user_data_dir().get_file().begins_with("Frostmere-Soak-QA-"))
	var args=OS.get_cmdline_user_args()
	for arg in args:
		if arg.begins_with("--seconds="): duration=float(arg.trim_prefix("--seconds="))
		if arg.begins_with("--report="): report_path=arg.trim_prefix("--report=")
	assert(duration>=20 and duration<=3600 and not report_path.is_empty())
	if "--prepare" in args:
		assert(not FileAccess.file_exists(State.SAVE_PATH) and not FileAccess.file_exists(Atlas.SAVE_PATH))
		var seed=State.new(); seed.intro_completed=true; seed.character_name="Native soak QA"
		seed.story_completed=["stonewake","threshold","returning_light","winter_siege","broken_seal"]
		for material in seed.crafting.materials: seed.materials[material.id]=10000
		var uid=seed.add_item("iron_sword"); seed.equip(uid,"main_hand"); seed.inventory[uid].favorite=true
		assert(seed.save_to(State.SAVE_PATH)); assert(Atlas.new().save_to(Atlas.SAVE_PATH))
	root.size=Vector2i(1280,800); Engine.max_fps=60
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	for i in range(8): await physics_frame
	var p=w.player; var s=p.character
	assert(s.persist and w.atlas.persist and w.session_save.ready_to_save)
	assert(s.character_name=="Native soak QA")
	p.set_process_unhandled_input(false)
	if "--prepare" not in args:
		var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://expected.json"))
		var current: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(State.SAVE_PATH))
		assert(current==expected.character,"Primary save changed between processes")
		assert(JSON.parse_string(JSON.stringify(s.inventory))==expected.character.inventory)
		assert(s.equipment==expected.character.equipment,"Equipped identity changed")
		assert(JSON.parse_string(JSON.stringify(s.materials))==expected.character.materials,"Material amounts changed")
		assert(s.gold==expected.character.gold and s.craft_xp==expected.character.craft_xp)
		assert(s.story_completed==expected.character.story_completed and w.atlas.visits==expected.atlas.visits)
		assert(w.session_save.area()==expected.character.session.area)
		print("SOAK_RESTART_VERIFIED")
	var initial_count: int=s.inventory.size()
	var started:=Time.get_ticks_usec(); var previous:=started
	var next_attack:=0.0; var next_reposition:=0.0; var next_travel:=0.0; var next_sample:=0.0; var cycle:=0
	histogram.resize(1001); histogram.fill(0)
	while (Time.get_ticks_usec()-started)/1000000.0<duration:
		var elapsed: float=(Time.get_ticks_usec()-started)/1000000.0
		# Native focus loss may pause normal play; the unattended workload explicitly resumes.
		if p.paused: p.set_paused(false)
		p.invulnerable=10; p.stamina=p.derived.stamina
		if elapsed>=next_travel:
			if cycle>0: record_window(30.0)
			if w.realms.inside: w.realms.leave()
			if w.mountain.inside: w.mountain.leave()
			# Exercise ordinary crafting and persistence with a steadily growing inventory.
			assert(s.craft_recipe("craft_iron_dagger","forge").begins_with("Created"))
			crafted+=1
			assert(w.mountain.enter()); travels+=1; w.mountain.leave(); travels+=1
			var realm: String="aeralis" if cycle%2==0 else "crucible"
			assert(w.realms.enter(realm)); travels+=1
			p.set_third_person(cycle%2==1); p.rotation=Vector3.ZERO; p.pivot.rotation.x=0
			var group: Array=[]
			for e in w.realms.enemies:
				if e.enemy_id.begins_with(realm): group.append(e)
			var boss: CharacterBody3D=group[2]
			p.position=boss.home+Vector3(0,.2,2)
			for i in range(group.size()):
				var e: CharacterBody3D=group[i]
				e.health=10000; e.maximum_health=10000
				e.global_position=boss.home+Vector3((i-0.5)*4,0,2) if i<2 else boss.home
				e.cooldown=0; e.stagger_time=0; e.windup=0
				previous_health[e.enemy_id]=e.health; previous_windup[e.enemy_id]=false
			assert(w.session_save.save_now()); assert(w.atlas.save_to(Atlas.SAVE_PATH))
			cycle+=1; next_travel=elapsed+30
		if elapsed>=next_reposition and w.realms.inside:
			var active: Array=w.combat_enemies().filter(func(enemy): return enemy.enemy_id.begins_with(w.realms.current))
			if not active.is_empty():
				var target: CharacterBody3D=active[-1]
				p.position=target.global_position+Vector3(0,.2,2); p.rotation.y=0; p.velocity=Vector3.ZERO
			next_reposition=elapsed+5
		if elapsed>=next_attack:
			if p.attack(): attacks+=1
			next_attack=elapsed+.8
		for e in w.combat_enemies():
			if e.windup>0 and not previous_windup.get(e.enemy_id,false): windups+=1
			previous_windup[e.enemy_id]=e.windup>0
			if e.health<float(previous_health.get(e.enemy_id,e.health)): hits+=1
			previous_health[e.enemy_id]=e.health
		if elapsed>=next_sample:
			var m:=metrics(); m.seconds=elapsed; m.inventory=s.inventory.size(); samples.append(m)
			print("SOAK_PROGRESS "+JSON.stringify({"seconds":elapsed,"crafted":crafted,"attacks":attacks,"hits":hits,"windups":windups,"metrics":m}))
			next_sample=elapsed+30
		await process_frame
		var now:=Time.get_ticks_usec(); var ms: float=(now-previous)/1000.0; previous=now
		frames+=1; histogram[mini(1000,ceili(ms))]+=1; maximum_ms=maxf(maximum_ms,ms)
		if ms>250: stalls+=1
	if duration-(next_travel-30)>=10: record_window(duration-(next_travel-30))
	assert(attacks>0 and hits>0 and windups>0 and crafted>0 and travels>=3)
	assert(s.inventory.size()==initial_count+crafted)
	assert(w.session_save.save_now()); assert(w.atlas.save_to(Atlas.SAVE_PATH))
	assert(State.new().load_from(State.SAVE_PATH) and Atlas.new().load_from(Atlas.SAVE_PATH))
	write_json("user://expected.json",{"character":JSON.parse_string(FileAccess.get_file_as_string(State.SAVE_PATH)),"atlas":JSON.parse_string(FileAccess.get_file_as_string(Atlas.SAVE_PATH))})
	var report={"engine":Engine.get_version_info().string,"gpu":RenderingServer.get_video_adapter_name(),"seconds":(Time.get_ticks_usec()-started)/1000000.0,"frames":frames,"p95_ms_upper_bound":percentile(.95),"p99_ms_upper_bound":percentile(.99),"max_ms":maximum_ms,"stalls_over_250ms":stalls,"attacks":attacks,"hits":hits,"enemy_windups":windups,"crafted":crafted,"travels":travels,"samples":samples,"combat_windows":combat_windows,"final":metrics(),"inventory":s.inventory.size()}
	write_json(report_path,report)
	print("NATIVE_SOAK_COMPLETE failures=0")
	w.queue_free(); await process_frame; quit()
