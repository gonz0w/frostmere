extends SceneTree
var w: Node3D
var entries: Array=[]
func _initialize() -> void: call_deferred("run")
func capture(id: String,title: String,group: String) -> void:
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_jpg("res://build/presentation-review/"+id+".jpg",.92)
	entries.append({"id":id,"title":title,"group":group,"file":id+".jpg"})
func run() -> void:
	assert(DisplayServer.get_name()!="headless" and "--capture" in OS.get_cmdline_user_args())
	root.size=Vector2i(1280,800)
	w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	for i in range(6): await physics_frame
	assert(not w.player.character.persist and not w.atlas.persist)
	var p=w.player; p.set_physics_process(false); p.set_process_unhandled_input(false)
	w.intro.start(); w.intro.set_process(false); p.set_third_person(false)
	await capture("intro-arrival","Ash through the snow · arrival","Opening")
	p.position=w.intro.ORIGIN+Vector3(0,.1,-1.5); p.pivot.rotation.x=.12
	assert(w.intro.interact()); w.intro.advance(3.5)
	await capture("intro-reveal-first","The ward beast · first person","Opening")
	p.set_third_person(true)
	await capture("intro-reveal-third","The ward beast · third person","Opening")
	root.size=Vector2i(800,600); p.set_third_person(false)
	await capture("intro-compact","Opening subtitles · 800 × 600","Opening")
	root.size=Vector2i(1280,800); w.intro.advance(5)
	await capture("intro-resolution","The ward holds","Opening")
	w.intro.finish(); w.intro.advance(1)
	await capture("intro-home","Arrival in Frostmere","Opening")
	for id in ["aeralis","crucible"]:
		assert(w.realms.enter(id,true)); w.realms.preview_kit(id)
		var e=w.realms.enemies[2 if id=="aeralis" else 5]
		for enemy in w.realms.enemies: enemy.set_physics_process(false)
		p.position=e.global_position+Vector3(0,0,8); p.rotation=Vector3.ZERO; p.pivot.rotation.x=.03
		w.hud.notice_time=0; e.rotation.y=PI
		for third in [false,true]:
			p.set_third_person(third)
			await capture(id+("-third" if third else "-first"),id.capitalize()+" · "+("third person" if third else "first person"),"Combat readability")
	w.realms.leave()
	w.adventure.open_dialog(); await capture("edda","Edda · gallows humor and the first quest","Dialogue"); w.adventure.close_dialog()
	w.threshold.open_dialog("keeper"); await capture("rook","Rook · station welcome","Dialogue"); w.threshold.close_dialog()
	w.archive_chapter.open_dialog("lantern"); await capture("mereth","Mereth · the screaming safety manual","Dialogue"); w.archive_chapter.close_dialog()
	var f=FileAccess.open("res://build/presentation-review/manifest.json",FileAccess.WRITE); f.store_string(JSON.stringify(entries,"\t")); f.close()
	print("PRESENTATION_REVIEW_COMPLETE captures=%d"%entries.size()); quit()
