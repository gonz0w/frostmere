extends "res://tools/playtest_prismwing.gd"
## Adversarial arrangements, not the normal realm approach or human play.
func verify(ok: bool,label: String) -> void:
	if not ok: failures+=1; push_error("AERALIS_PRESSURE_FAIL "+label)
func run() -> void:
	if DisplayServer.get_name()!="headless" and "--capture" not in OS.get_cmdline_user_args():
		push_error("Native pressure fixture requires -- --capture"); quit(1); return
	for scenario in ["bite_stay","bite_sidestep","overlapping_enemies"]:
		var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
		for i in range(4): await physics_frame
		var p=w.player; var s=p.character; var r=w.realms; var boss=r.enemies[2]
		if s.persist or w.atlas.persist: push_error("Refusing persistent fixture"); quit(1); return
		p.set_process_unhandled_input(false)
		s.set_identity("Pressure QA","frostkin","mage","balanced")
		for slot in s.equipment: s.equipment[slot]=""
		for slot in s.archetypes.mage.loadout:
			var base: String=s.archetypes.mage.loadout[slot]
			if base!="": s.equip(s.add_item(base),slot)
		s.equip(s.add_item("horizon_staff",2,"insight"),"main_hand")
		s.train("magic",400); verify(s.learn_perk("kindled_mind") and s.learn_perk("clear_channel"),"eligible magic perks")
		s.story_completed.append("threshold")
		verify(r.enter("aeralis",false) and r.attune("aeralis"),"normal staged entry and attunement")
		var group: bool=scenario=="overlapping_enemies"
		for actor in r.enemies:
			if actor!=boss and not (group and actor in [r.enemies[0],r.enemies[1]]):
				actor.set_physics_process(false); actor.collision_layer=0
		p.position=boss.global_position+Vector3(0,.1,8 if group else 3)
		if group:
			r.enemies[0].global_position=boss.global_position+Vector3(-3,0,4)
			r.enemies[1].global_position=boss.global_position+Vector3(3,0,4)
		p.velocity=Vector3.ZERO; p.set_third_person(false); p.invulnerable=0
		p.health=p.derived.health; p.magicka=p.derived.magicka
		var recorder=w.combat_metrics
		recorder.output_path="res://build/aeralis-pressure-"+scenario+".jsonl"
		if FileAccess.file_exists(recorder.output_path): DirAccess.remove_absolute(recorder.output_path)
		recorder.enabled=true
		var time:=0.0; var casts:=0; var outcome:="timeout"; var peak_windups:=0
		var bite_started:=false; var bite_resolved:=false; var bite_health:=0.0; var bite_damage:=0.0
		var phase_seen:=false; var actors_attacking: Array=[]
		var sidestep_distance:=0.0
		var previous_windup: Dictionary={}
		var resolved_attacks: Array=[]
		while time<45:
			await physics_frame; time+=1.0/Engine.physics_ticks_per_second
			if not r.inside: outcome="death_or_fall"; break
			var living: Array=[]; var winding:=0
			for actor in [r.enemies[0],r.enemies[1],boss] if group else [boss]:
				if not actor.dead: living.append(actor)
				if previous_windup.get(actor.enemy_id,0.0)>0 and actor.windup<=0 and actor.cooldown>1 and not actor.dead:
					if actor.enemy_id not in resolved_attacks: resolved_attacks.append(actor.enemy_id)
				previous_windup[actor.enemy_id]=actor.windup
				if actor.windup>0 and not actor.dead:
					winding+=1
					if actor.enemy_id not in actors_attacking: actors_attacking.append(actor.enemy_id)
			peak_windups=maxi(peak_windups,winding)
			if living.is_empty(): outcome="defeated"; break
			phase_seen=phase_seen or (boss.fractured and not boss.dead)
			var target=living[0]
			for actor in living:
				if actor.global_position.distance_to(p.global_position)<target.global_position.distance_to(p.global_position): target=actor
			var offset: Vector3=target.global_position+Vector3.UP*(1.7 if target==boss else 1)-p.camera.global_position
			p.rotation.y=atan2(-offset.x,-offset.z); p.pivot.rotation.x=atan2(offset.y,Vector2(offset.x,offset.z).length())
			if not group and phase_seen and not bite_resolved:
				if not bite_started and boss.attack_kind=="bite" and boss.windup>0:
					bite_started=true; bite_health=p.health
				if bite_started and (boss.attack_kind!="bite" or boss.windup<=0):
					bite_resolved=true; bite_damage=bite_health-p.health
				elif bite_started and scenario=="bite_sidestep":
					# Collision-aware scripted steering, not a teleport or input-accuracy test.
					var before: Vector3=p.position
					p.velocity=Vector3.RIGHT*4; p.move_and_slide(); p.velocity=Vector3.ZERO
					sidestep_distance+=p.position.distance_to(before)
				continue
			# Let each enemy resolve its first attack before this stress-policy retaliates.
			if group and resolved_attacks.size()<3: continue
			if p.spell_cooldown<=0 and p.cast_spell("starfall"): casts+=1
		recorder.finish(outcome)
		var record: Dictionary=recorder.last_record
		verify(outcome in ["defeated","death_or_fall"],"exchange terminates: "+scenario)
		if not group:
			verify(phase_seen and bite_started and bite_resolved,"real casts earn fracture and provoke a resolved bite: "+scenario)
			verify(is_equal_approx(bite_damage,32.0) if scenario=="bite_stay" else is_zero_approx(bite_damage),"committed bite hit/avoid behavior: "+scenario)
			verify(outcome=="defeated","close-range encounter can finish: "+scenario)
		else:
			verify(actors_attacking.size()==3 and resolved_attacks.size()==3 and peak_windups>=2,"all enemies attack with overlapping warnings")
			verify(record.get("damage_taken",0)>0 and record.get("targets",[]).size()>=2,"real incoming pressure and multiple damaged targets")
		rows.append({"scenario":scenario,"outcome":outcome,"seconds":time,"casts":casts,"phase_seen_alive":phase_seen,"bite_started":bite_started,"bite_resolved":bite_resolved,"bite_damage":bite_damage,"sidestep_distance":sidestep_distance,"peak_windups":peak_windups,"resolved_attacks":resolved_attacks,"actors_attacking":actors_attacking,"health_end":p.health,"metrics":record})
		print("AERALIS_PRESSURE_SAMPLE %s outcome=%s casts=%d bite_damage=%.1f overlaps=%d" % [scenario,outcome,casts,bite_damage,peak_windups])
		w.queue_free(); await process_frame
	var f=FileAccess.open("res://build/aeralis-pressure.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"generated_utc":Time.get_datetime_string_from_system(true),"display":DisplayServer.get_name(),"failures":failures,"scenarios":rows},"\t")); f.close()
	print("AERALIS_PRESSURE_COMPLETE scenarios=%d failures=%d" % [rows.size(),failures]); quit(1 if failures else 0)
