extends RefCounted
## Original distant ward-beast: layered silhouette, no gameplay hitboxes.
static func build(intro: Node3D) -> void:
	var c: Node3D=intro.creature
	var dark=Color("222735"); var edge=Color("535563"); var horn=Color("514650")
	for row in range(7):
		var width: float=8.8-absf(row-3)*.65
		intro.static_cube(c,Vector3(0,4.2+row*.62,0),Vector3(width,.72,4.4-absf(row-3)*.25),dark)
		for side in [-1,1]:
			intro.static_cube(c,Vector3(side*(width/2-.1),4.5+row*.62,1.8),Vector3(.58,.47,.45),edge)
	for side in [-1,1]:
		for z in [-1.5,1.5]:
			for joint in range(7):
				intro.static_cube(c,Vector3(side*(3.35+joint*.1),4.9-joint*.64,z),Vector3(1.25-joint*.07,.8,1.25),dark)
			for claw in range(3): intro.static_cube(c,Vector3(side*4+(claw-1)*.35,.5,z+.6),Vector3(.25,.26,1.1),horn)
		for plate in range(5):
			intro.static_cube(c,Vector3(side*(3.1+plate*.22),7.5+plate*.2,.5-plate*.5),Vector3(1.2-plate*.13,.42,1.2),edge)
	intro.head=Node3D.new(); intro.head.position=Vector3(0,9.1,.6); c.add_child(intro.head)
	for row in range(5):
		intro.static_cube(intro.head,Vector3(0,(row-2)*.48,0),Vector3(3.9-absf(row-2)*.48,.56,2.8-absf(row-2)*.25),dark)
	for side in [-1,1]:
		intro.static_cube(intro.head,Vector3(side*.92,.42,1.45),Vector3(.8,.18,.12),Color("f18b58"),2)
		intro.static_cube(intro.head,Vector3(side*.96,.7,1.48),Vector3(1.05,.28,.3),edge)
		for segment in range(8):
			intro.static_cube(intro.head,Vector3(side*(1.4+segment*.13),1+segment*.38,-segment*.12),Vector3(.75-segment*.073,.48,.72-segment*.07),Color("897c79") if segment>4 else horn)
	# Projecting muzzle and cheek ridges read as a beast above the distant arch.
	for step in range(4):
		intro.static_cube(intro.head,Vector3(0,-.15+step*.17,1.5-step*.1),Vector3(2.7-step*.35,.25,.8),edge)
	for side in [-1,1]:
		for plate in range(3): intro.static_cube(intro.head,Vector3(side*(1.6-plate*.12),-.15-plate*.28,1.2),Vector3(.38,.4,.6),horn)
	intro.jaw=Node3D.new(); intro.jaw.position=Vector3(0,-.7,1); intro.head.add_child(intro.jaw)
	for row in range(3): intro.static_cube(intro.jaw,Vector3(0,-row*.22,.5),Vector3(2.8-row*.35,.3,1.4-row*.15),edge)
	for tooth in range(7):
		intro.static_cube(intro.jaw,Vector3(-1.05+tooth*.35,.25,1.05),Vector3(.16,.36,.22),Color("a89a82"))
		intro.static_cube(intro.head,Vector3(-1.05+tooth*.35,-.42,1.5),Vector3(.16,.28,.22),Color("a89a82"))
