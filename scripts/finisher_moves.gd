extends RefCounted
# Poses are offsets from the captured equipment pose, in both camera modes.
const MOVES = {
	"dagger": {"name":"Fang Pierce", "motion":"thrust", "duration":.7, "impact":.35},
	"sword": {"name":"Sundering Sweep", "motion":"sweep", "duration":.9, "impact":.5},
	"greatsword": {"name":"Titan Cleave", "motion":"sweep", "duration":1.1, "impact":.65},
	"axe": {"name":"Rending Chop", "motion":"crush", "duration":.95, "impact":.55},
	"battleaxe": {"name":"Worldsplitter", "motion":"crush", "duration":1.2, "impact":.7},
	"mace": {"name":"Bonebreaker", "motion":"crush", "duration":1.05, "impact":.6},
}
static func pose(move: Dictionary, elapsed: float) -> Dictionary:
	# Reach the windup pose, strike at the damage frame, then recover.
	var impact: float = move.impact
	var amount: float
	if elapsed < impact*.65: amount = elapsed/(impact*.65)
	elif elapsed < impact: amount = lerpf(1.0,-.3,(elapsed-impact*.65)/(impact*.35))
	else: amount = lerpf(-.3,0.0,clampf((elapsed-impact)/(move.duration-impact),0,1))
	match move.motion:
		"thrust": return {"arm":Vector3(-1.4,0,.2)*amount,"hands":Vector3(.2,0,.12)*amount,"offset":Vector3(0,.05,.15)*amount}
		"sweep": return {"arm":Vector3(-.9,-1.2,-1.5)*amount,"hands":Vector3(.2,-.25,-.4)*amount,"offset":Vector3(.12,0,0)*amount}
		_: return {"arm":Vector3(-2.4,0,.15)*amount,"hands":Vector3(.65,0,.15)*amount,"offset":Vector3(0,.15,0)*amount}
