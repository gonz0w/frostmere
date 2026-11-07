extends "res://scripts/monster_effect.gd"
# Strike-local, cosmetic breakup; inherited lifetime/pause/travel handling.
var spins: Array[Vector3]=[]
func _process(delta: float) -> void:
	super._process(delta)
	if is_queued_for_deletion() or not visible: return
	for i in range(chips.size()):
		chips[i].position=destinations[i]*(age/.35)+Vector3.DOWN*2.0*age*age
		chips[i].rotation=spins[i]*age*world.accessibility.motion_factor()
static func spawn(actor: Node3D, motion: String, direction: Vector3) -> Node3D:
	if not actor.adventure.world.accessibility.show_fragments: return null
	var surface: String=actor.finisher_surface()
	var colors={"shell":["637a79","c9bca2"],"bark":["79644a","69734c"],"flesh":["8c233a","a72b35"],"stone":["788474","526c40"],"alien":["637c84","80f2a8"],"crystal":["a8e6f4","d7b5f1"],"furnace":["583b3c","ff793e"]}
	var palette: Array=colors.get(surface,colors.flesh)
	var stone: bool = surface != "flesh"
	var burst = load("res://scripts/finisher_effect.gd").new(); burst.name = "FinisherFragments"; burst.set_meta("finisher_surface",actor.finisher_surface()); actor.adventure.add_child(burst); burst.global_position = actor.global_position + Vector3.UP * (2.5 if stone else 1.0)
	burst.world=actor.adventure.world; burst.controller=actor.adventure
	if actor.adventure==burst.world.realms: burst.realm=actor.adventure.current
	var flat:=Vector3(direction.x,0,direction.z)
	if flat.length_squared()>.001: burst.global_rotation.y=atan2(-flat.x,-flat.z)
	var material := StandardMaterial3D.new(); material.albedo_color = Color(palette[0]); material.emission_enabled = true; material.emission = Color(palette[1]); material.emission_energy_multiplier = 0.5
	if burst.world.accessibility.reduced_flashes: material.emission_enabled=false
	for i in range(18):
		var chip := MeshInstance3D.new(); var mesh := BoxMesh.new(); mesh.size = Vector3(.12,.35,.12) if surface=="crystal" else Vector3.ONE * (0.18 if stone else 0.10); mesh.material = material; chip.mesh = mesh; burst.add_child(chip)
		var angle := TAU * i / 18.0
		var spread := Vector3(cos(angle) * 0.9, 0.2 + (i % 4) * 0.15, sin(angle) * 0.9)
		if motion == "sweep": spread = Vector3(cos(angle)*1.4,.15+(i%3)*.1,sin(angle)*.35)
		elif motion == "thrust": spread = Vector3(cos(angle)*.3,(i%4)*.12,sin(angle)*.3-.7)
		if surface=="crystal": spread*=1.3
		elif surface=="furnace" and i%2==1: spread.y+=.7
		burst.chips.append(chip); burst.destinations.append(spread)
		burst.spins.append(Vector3((i%3)-1, 1 if i%2==0 else -1, .5)* (5.0 if surface=="crystal" else 3.0))
	return burst
