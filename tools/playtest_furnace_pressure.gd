extends "res://tools/playtest_prismwing.gd"
func verify(ok: bool,label: String) -> void:
	if not ok: failures+=1; push_error("FURNACE_LIVE_FAIL "+label)
func run() -> void:
	if DisplayServer.get_name()!="headless" and "--capture" not in OS.get_cmdline_user_args():
		push_error("Native fixture requires -- --capture"); quit(1); return
	for policy in ["stand_in_rupture","gun_continuous","gun_exposure","soulfire_exposure"]:
		var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
		for i in range(4): await physics_frame
		var p=w.player; var s=p.character; var r=w.realms; var e=r.enemies[5]
		if s.persist or w.atlas.persist: push_error("Refusing persistent fixture"); quit(1); return
		p.set_process_unhandled_input(false); p.combat_rng.seed=12345
		s.set_identity("Furnace QA","frostkin","mage","balanced")
		for slot in s.equipment: s.equipment[slot]=""
		for slot in s.archetypes.mage.loadout:
			var base: String=s.archetypes.mage.loadout[slot]
			if base!="": s.equip(s.add_item(base),slot)
		var staff: String=s.add_item("horizon_staff",2,"insight")
		s.equip(staff,"main_hand"); s.train("magic",400)
		verify(s.learn_perk("kindled_mind") and s.learn_perk("clear_channel"),"eligible magic perks")
		s.story_completed.append_array(["returning_light","winter_siege","broken_seal"])
		verify(r.enter("crucible",false) and r.attune("crucible"),"normal staged entry and kit")
		if policy.begins_with("gun"):
			for uid in s.inventory:
				if s.inventory[uid].base_id=="cinder_gun": s.equip(uid,"main_hand"); break
		for actor in r.enemies:
			if actor!=e: actor.set_physics_process(false); actor.collision_layer=0
		p.position=e.global_position+Vector3(0,.1,7); p.velocity=Vector3.ZERO
		p.set_third_person(false); p.invulnerable=0; p.health=p.derived.health; p.magicka=p.derived.magicka
		var initial_hp: float=p.health; var initial_ammo: int=s.materials.hell_round
		var recorder=w.combat_metrics
		recorder.output_path="res://build/furnace-"+policy+".jsonl"
		if FileAccess.file_exists(recorder.output_path): DirAccess.remove_absolute(recorder.output_path)
		recorder.enabled=true
		var time:=0.0; var shots:=0; var eruptions:=0; var enraged_warnings:=0
		var pending:=false; var origin:=Vector3.ZERO; var origin_drift:=0.0
		var outcome:="timeout"; var dodge_direction:=1.0; var damage:=0.0
		while time<50:
			await physics_frame; time+=1.0/Engine.physics_ticks_per_second
			if not r.inside: outcome="death_or_fall"; break
			if e.vent_pending and not pending:
				origin=e.vent_origin; dodge_direction=-1 if p.position.x>e.global_position.x+1 else 1
				if e.health<=e.maximum_health*.5: enraged_warnings+=1
			if e.vent_pending: origin_drift=maxf(origin_drift,origin.distance_to(e.vent_origin))
			if pending and not e.vent_pending and e.exposed>0:
				eruptions+=1
				if policy=="stand_in_rupture": outcome="rupture_observed"; break
			pending=e.vent_pending
			if e.dead: outcome="defeated"; break
			var offset: Vector3=e.global_position+Vector3.UP*1.9-p.camera.global_position
			p.rotation.y=atan2(-offset.x,-offset.z); p.pivot.rotation.x=atan2(offset.y,Vector2(offset.x,offset.z).length())
			if policy=="stand_in_rupture": continue
			if e.vent_pending and Vector2(p.position.x-origin.x,p.position.z-origin.z).length()<3.2:
				p.velocity=Vector3.RIGHT*4*dodge_direction; p.move_and_slide(); p.velocity=Vector3.ZERO
			var fire: bool=policy=="gun_continuous" or e.exposed>0
			if fire:
				if policy.begins_with("gun"):
					if p.attack_cooldown<=0 and p.attack(): shots+=1
				elif p.spell_cooldown<=0 and p.cast_spell("soulfire"): shots+=1
		damage=initial_hp-p.health
		recorder.finish(outcome)
		verify(is_zero_approx(origin_drift),"warning stays committed: "+policy)
		verify(eruptions>0,"AI resolves a real rupture: "+policy)
		if policy=="stand_in_rupture":
			verify(outcome=="rupture_observed" and is_equal_approx(damage,34.0),"standing in first rupture takes authored damage")
		else:
			verify(outcome=="defeated" and is_zero_approx(damage),"collision-aware dodge and real fire complete fight: "+policy)
			verify(is_equal_approx(recorder.last_record.get("damage_dealt",0),340.0),"recorder sees full boss damage")
		if policy=="soulfire_exposure": verify(enraged_warnings>0,"later rupture uses enraged phase")
		rows.append({"policy":policy,"outcome":outcome,"seconds":time,"attacks":shots,"rounds_spent":initial_ammo-int(s.materials.hell_round),"eruptions":eruptions,"enraged_warnings":enraged_warnings,"warning_drift":origin_drift,"damage_taken":damage,"health_after_stop":p.health,"metrics":recorder.last_record})
		print("FURNACE_LIVE_SAMPLE %s outcome=%s attacks=%d rounds=%d ruptures=%d damage=%.1f" % [policy,outcome,shots,rows[-1].rounds_spent,eruptions,damage])
		w.queue_free(); await process_frame
	if rows.size()==4: verify(rows[2].rounds_spent<rows[1].rounds_spent,"exposure policy saves ammunition over continuous fire")
	var f=FileAccess.open("res://build/furnace-live-pressure.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"generated_utc":Time.get_datetime_string_from_system(true),"display":DisplayServer.get_name(),"failures":failures,"scenarios":rows},"\t")); f.close()
	print("FURNACE_LIVE_COMPLETE scenarios=%d failures=%d" % [rows.size(),failures]); quit(1 if failures else 0)
