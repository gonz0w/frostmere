extends RefCounted
## Read-only travel guidance. Recommendations never accept quests or open gates.
const ROUTES = [
	["council","mountain","Wyrmkeep","The Divided Council","North pass beyond Ember Hall",["stonewake"],"PASS"],
	["archive","archive_chapter","Pinehall","The Missing Atlas","West trail from Frostmere",["stonewake"],"TRAIL"],
	["roots","roots","Stag Shrine","Pacts Beneath the Roots","Amberweald trail west of Frostmere",["stonewake"],"TRAIL"],
	["tides","shore","Saltbreak","The Wreck on the Black Shore","Coastal road southwest of Frostmere",["archive"],"TRAIL"],
	["lens","lens","Sunken Lens","The Sky Below the Sand","Eastern expedition road",["archive"],"TRAIL"],
	["choir","choir","Ember Caldera","A Song Through the Stone","Volcanic road southeast of Frostmere",["council"],"TRAIL"],
	["convergence","convergence","Mirewatch","The Roads Converge","Southeastern marsh expedition road",["roots","tides","lens","choir"],"TRAIL"],
	["threshold","threshold","Sunken Lens vault","Beyond the First Threshold","Eastern road to Sunken Lens; then northern vault",["convergence"],"TRAIL"],
	["winter_siege","winter","Winter garrison","The Winter Siege","Southern supply road",["returning_light"],"TRAIL"],
	["broken_seal","seal","Wardworks","The Broken Seal","Service lift southeast of Frostmere",["winter_siege"],"TRAIL"]
]

static func routes(world: Node) -> Array[Dictionary]:
	# The map builds before destination controllers during world startup.
	if not is_instance_valid(world.realms): return []
	var state: RefCounted=world.player.character
	var result: Array[Dictionary]=[]
	for entry in ROUTES:
		if entry[0] in state.story_completed: continue
		var ready:=true
		for requirement in entry[5]:
			if requirement not in state.story_completed: ready=false
		if not ready: continue
		var chapter: Node=world.get(entry[1])
		var progress: Dictionary=state.get("archive" if entry[1]=="archive_chapter" else entry[1])
		# The station is accessed from another chapter, never by a 1,200 m home waypoint.
		var at: Vector3=world.lens.TRAIL if entry[0]=="threshold" else chapter.get(entry[6])
		result.append({"id":entry[0],"place":entry[2],"title":entry[3],"directions":entry[4],"target":at,"accepted":progress.accepted})
	for id in ["aeralis","crucible"]:
		var definition: Dictionary=world.realms.definitions[id]
		if definition.quest in state.story_completed or not world.realms.can_enter(id): continue
		result.append({"id":definition.quest,"place":"Aeralis" if id=="aeralis" else "The Crucible","title":"The Returning Light" if id=="aeralis" else "The Last Furnace","directions":"Watchstone gate northeast of the village","target":world.realms.vector(definition.portal),"accepted":false})
	# Resume accepted work first; preserve authored order among equally ready branches.
	var ordered: Array[Dictionary]=[]
	for accepted in [true,false]:
		for route in result:
			if route.accepted==accepted: ordered.append(route)
	return ordered

static func text_for(world: Node) -> String:
	if is_instance_valid(world.intro) and world.intro.active: return ""
	if world.lens.inside and "convergence" in world.player.character.story_completed and "threshold" not in world.player.character.story_completed:
		return "BEYOND THE FIRST THRESHOLD\nReach the northern transit vault\n%.0f m · E at the crossing" % world.player.position.distance_to(world.threshold.TRAIL)
	if world.session_save.area()!="home" or world.atlas.waypoint!="": return ""
	if "stonewake" not in world.player.character.story_completed: return ""
	var choices:=routes(world)
	if choices.is_empty(): return ""
	var next: Dictionary=choices[0]
	var text: String=next.title.to_upper()+"\n"+next.directions+"\n%.0f m · M Journal" % world.player.position.distance_to(next.target)
	if choices.size()>1:
		var names: PackedStringArray=[]
		for i in range(1,mini(choices.size(),3)): names.append(choices[i].place)
		text+="\nAlso open: "+" / ".join(names)
		if choices.size()>3: text+=" (+%d)" % (choices.size()-3)
	return text
