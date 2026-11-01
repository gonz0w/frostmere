extends SceneTree
## Deterministic aiming policy, real physics/AI/casts/retaliation. No human-difficulty claim.
const Projectile=preload("res://scripts/projectile.gd")
var rows: Array=[]
var failures:=0
func _initialize() -> void: call_deferred("run")
func verify(ok: bool,label: String) -> void:
	if not ok: failures+=1; push_error("PRISMWING_PLAYTEST_FAIL "+label)
func run() -> void:
	if DisplayServer.get_name()!="headless" and "--capture" not in OS.get_cmdline_user_args():
		push_error("Native playtest requires -- --capture"); quit(1); return
	for spec in [{"spell":"emberbolt","perks":false},{"spell":"emberbolt","perks":true},{"spell":"starfall","perks":true}]:
		var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
		for i in range(4): await physics_frame
		var p=w.player; var s=p.character; var r=w.realms; var e=r.enemies[2]
		if s.persist or w.atlas.persist: push_error("Refusing persistent playtest"); quit(1); return
		p.set_process_unhandled_input(false)
		s.set_identity("Prismwing QA","frostkin","mage","balanced")
		for slot in s.equipment: s.equipment[slot]=""
		for slot in s.archetypes.mage.loadout:
			var base: String=s.archetypes.mage.loadout[slot]
			if base!="": s.equip(s.add_item(base),slot)
		s.equip(s.add_item("horizon_staff",2,"insight"),"main_hand")
		if spec.perks:
			s.train("magic",400)
			verify(s.learn_perk("kindled_mind") and s.learn_perk("clear_channel"),"learn eligible perks")
		# Stage fixture only; normal attunement supplies the actual Starfall unlock.
		s.story_completed.append("threshold")
		verify(r.enter("aeralis",false) and r.attune("aeralis"),"enter and attune")
		for actor in r.enemies:
			if actor!=e: actor.set_physics_process(false); actor.collision_layer=0
		p.position=e.global_position+Vector3(0,.1,16); p.velocity=Vector3.ZERO
		p.set_third_person(false); p.invulnerable=0; p.health=p.derived.health; p.magicka=p.derived.magicka
		var initial_health: float=p.health
		var initial_enemy: Vector3=e.global_position
		var hostile: Array[int]=[0]
		w.adventure.child_entered_tree.connect(func(node):
			if node is Projectile and node.hostile: hostile[0]+=1)
		var recorder=w.combat_metrics
		recorder.output_path="res://build/prismwing-%s-%s.jsonl" % [spec.spell,spec.perks]
		if FileAccess.file_exists(recorder.output_path): DirAccess.remove_absolute(recorder.output_path)
		recorder.enabled=true
		var time:=0.0; var casts:=0; var wait:=0.0; var attack_started:=-1.0; var outcome:="timeout"
		var fractured_seen:=false
		while time<60:
			await physics_frame
			var dt: float=1.0/Engine.physics_ticks_per_second
			time+=dt
			if not r.inside: outcome="death_or_fall"; break
			fractured_seen=fractured_seen or (e.fractured and not e.dead)
			if e.dead: outcome="defeated"; break
			var offset: Vector3=e.global_position+Vector3.UP*1.7-p.camera.global_position
			p.rotation.y=atan2(-offset.x,-offset.z)
			p.pivot.rotation.x=atan2(offset.y,Vector2(offset.x,offset.z).length())
			# Wait for a genuine hit before attacking, so every case includes retaliation.
			if attack_started<0 and p.health<initial_health: attack_started=time
			if attack_started<0: continue
			if p.spell_cooldown<=0:
				if p.cast_spell(spec.spell): casts+=1
				elif p.magicka<s.spell_cost(s.spell_definition(spec.spell).cost): wait+=dt
		recorder.finish(outcome)
		var record: Dictionary=recorder.last_record
		verify(outcome=="defeated","bounded successful exchange "+str(spec))
		verify(hostile[0]>=5 and initial_health-p.health>0,"real hostile fan hits player")
		verify(initial_enemy.distance_to(e.global_position)>2,"AI closes distance")
		verify(fractured_seen,"normal second-phase transition")
		verify(record.get("damage_taken",0)>0 and is_equal_approx(record.get("damage_dealt",0),240.0),"recorder observes both directions of combat")
		rows.append({"spell":spec.spell,"perks":spec.perks,"outcome":outcome,"seconds":time,"attack_started":attack_started,"casts":casts,"mana_wait_seconds":wait,"fracture_seen_alive":fractured_seen,"hostile_projectiles":hostile[0],"health_start":initial_health,"health_end":p.health,"magicka_end":p.magicka,"enemy_movement":initial_enemy.distance_to(e.global_position),"metrics":record})
		print("PRISMWING_EXCHANGE spell=%s perks=%s outcome=%s casts=%d health=%.1f mana_wait=%.2f" % [spec.spell,spec.perks,outcome,casts,p.health,wait])
		w.queue_free(); await process_frame
	var f=FileAccess.open("res://build/prismwing-live-playtest.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"generated_utc":Time.get_datetime_string_from_system(true),"engine":Engine.get_version_info().string,"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"failures":failures,"scenarios":rows},"\t")); f.close()
	print("PRISMWING_PLAYTEST_COMPLETE scenarios=%d failures=%d" % [rows.size(),failures]); quit(1 if failures else 0)
