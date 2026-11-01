extends RefCounted
static var catalog: Dictionary={}
static func data() -> Dictionary:
	if catalog.is_empty(): catalog=JSON.parse_string(FileAccess.get_file_as_string("res://data/road_quests.json"))
	return catalog
static func complete(records: Dictionary,id: String) -> bool:
	return records.get(id,{}).get("answers",[]).size()==data().quests[id].steps.size()
static func ending(records: Dictionary,id: String) -> String:
	return str(records[id].answers.back()) if complete(records,id) else ""
static func valid(value: Dictionary) -> bool:
	var records: Variant=value.get("hunt",{}).get("roads",{})
	if not records is Dictionary: return false
	var quests: Dictionary=data().quests
	for id in records:
		if not quests.has(id) or not records[id] is Dictionary: return false
		var answers: Variant=records[id].get("answers")
		if not answers is Array or answers.is_empty() or answers.size()>quests[id].steps.size(): return false
		var q: Dictionary=quests[id]
		if q.gate!="" and q.gate not in value.get("story_completed",[]): return false
		if q.requires!="":
			if not records.get(q.requires) is Dictionary or not records[q.requires].get("answers") is Array: return false
			if not complete(records,q.requires): return false
		for i in range(answers.size()):
			var found:=false
			for o: Dictionary in q.steps[i].options:
				if answers[i]!=o.id: continue
				found=true
				if o.has("when") and answers[o.when[0]]!=o.when[1]: return false
				if o.has("guard") and o.guard[1] not in value.get(o.guard[0],{}).get("defeated",[]): return false
			if not found: return false
	if complete(records,"sable_concord_3") and value.get("shore",{}).get("passage_choice","")=="outlaw": return false
	if ending(records,"sable_concord_3")=="war" and value.get("shore",{}).get("passage_choice","")!="": return false
	return true
