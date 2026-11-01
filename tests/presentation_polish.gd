extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS "+label)
	else: failures+=1; push_error("FAIL "+label)
func run() -> void:
	assert(DisplayServer.get_name()=="headless")
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(6): await physics_frame
	assert(not w.player.character.persist and not w.atlas.persist)
	w.player.set_physics_process(false); w.audio.set_process(false)
	var a=w.audio; a.enabled=true
	# Keep all 12 mixer voices occupied long enough to test saturation deterministically.
	for i in range(a.voices.size()):
		var v=a.voices[i]; v.stream=a.streams.wander; v.set_meta("priority",0); v.set_meta("order",i); v.play()
	a.cooldowns.clear(); a.sfx("ward_approach")
	check(a.voices[0].stream==a.streams.ward_approach,"Critical reveal replaces oldest footstep-priority voice in saturated pool")
	for v in a.voices: v.stream=a.streams.wander; v.set_meta("priority",3); v.play()
	a.cooldowns.clear(); a.sfx("step_snow")
	var protected:=true
	for v in a.voices: protected=protected and v.stream==a.streams.wander
	check(protected,"Footsteps cannot evict critical cues")
	a.voices[4].stop(); a.cooldowns.clear(); a.sfx("hit")
	check(a.voices[4].stream==a.streams.hit and a.voices.size()==12,"Free slot reused without expanding the effects pool")
	for v in a.voices: v.stop()
	a.enabled=false
	check(w.intro.start(),"Presentation intro starts in isolated profile")
	w.intro.set_process(false); w.hud._process(0)
	check(not w.hud.combat_panel.visible,"Noncombat opening hides combat HUD panel")
	check(w.intro.scene.find_children("*","MultiMeshInstance3D",true,false).size()>0,"Intro scenery uses material batches")
	check(w.intro.static_batches.is_empty(),"Temporary intro batch buffers released after construction")
	check(w.intro.ash[0].material_override==w.intro.ash[1].material_override,"Animated ash shares a material")
	for size in [Vector2i(800,600),Vector2i(1280,800)]:
		root.size=size
		for i in range(3): await process_frame
		check(w.intro.subtitle.size.x>size.x*.65 and w.intro.subtitle.position.x>=0,"Subtitle has useful width at "+str(size))
	w.intro.finish(); w.hud._process(0)
	check(w.hud.combat_panel.visible and w.intro.material_cache.is_empty(),"Village handoff restores combat HUD and clears intro material ownership")
	var actor=w.wilderness.enemies[11]
	var first=preload("res://scripts/ground_slam_effect.gd").spawn(actor,actor.home)
	var second=preload("res://scripts/ground_slam_effect.gd").spawn(actor,actor.home)
	check(first.chips.size()==24 and second.chips.size()==24,"Shared debris retains full fragment count")
	check(first.chips[1].mesh==second.chips[1].mesh and first.chips[0].mesh==second.chips[0].mesh,"Repeated slams share immutable meshes")
	var at: Vector3=second.chips[1].position; first._process(.2)
	check(second.chips[1].position==at,"Shared meshes do not share fragment transforms")
	first.queue_free(); second.queue_free(); await process_frame
	print("PRESENTATION_POLISH_COMPLETE checks=%d failures=%d"%[checks,failures]); quit(1 if failures else 0)
