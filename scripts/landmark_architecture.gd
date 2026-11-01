extends RefCounted
## Structural dressing on existing collision envelopes; arena lanes and gates stay open.
static func fortress(b: RefCounted) -> void:
	for index in range(3):
		var x: float=[-10,1,12][index]
		# Corbelled galleries and deep slit frames read at skyline distance.
		for side in [-1,1]:
			for col in range(7):
				var dx: float=-2.4+col*.8
				for tier in range(3):
					b.add("stone",Vector3(x+dx,28.4+tier*.4,-88+side*(2.55+tier*.18)),Vector3(.45,.42,.38))
			for row in range(3):
				b.add("stone",Vector3(x,29.7+row*.28,-88+side*3),Vector3(6,.26,.4))
			for dx in [-2.4,-1.2,0,1.2,2.4]: b.add("stone",Vector3(x+dx,31.1,-88+side*3),Vector3(.7,1.6,.55))
		for side in [-1,1]:
			for end in [-1,1]:
				for row in range(16): b.add("stone_dark",Vector3(x+side*2.6,5+row*1.45,-88+end*2.6),Vector3(.62,1.35,.62))
		if index==1:
			# A taller central keep replaces the repeated three-tower skyline.
			for tier in range(10): b.add("stone",Vector3(x,31+tier*.55,-88),Vector3(3.8,.52,3.8))
			for side in [-1,1]:
				b.add("coal",Vector3(x+side*1.91,33,-88),Vector3(.025,2,.55))
			for tier in range(11): b.add("roof",Vector3(x,36.3+tier*.42,-88),Vector3(5-tier*.4,.43,5-tier*.4))
		elif index==0:
			for tier in range(8): b.add("roof",Vector3(x,31+tier*.4,-88),Vector3(5.1-tier*.55,.42,5.1-tier*.55))
	# Curtain-wall buttresses support the keep rather than a blank linking rectangle.
	for x in [-6,-2,5,9]:
		for row in range(16): b.add("stone",Vector3(x,8+row*.75,-85.9),Vector3(.6,.7,.55))
		b.add("coal",Vector3(x+1.3,15,-86.45),Vector3(.35,1.6,.06))
	for col in range(28): b.add("stone",Vector3(-12+col*.95,20.4,-86.4),Vector3(.62,1,.65))
static func aeralis(b: RefCounted) -> void:
	for index in range(3):
		var z: float=[9,-12,-34][index]
		for side in [-1,1]:
			var x: float=side*8.5
			for dx in [-1.2,1.2]:
				for dz in [-1.5,1.5]:
					for tier in range(3): b.add("realm_stone",Vector3(x+dx,.54+tier*.15,z+dz),Vector3(.66-tier*.1,.14,.66-tier*.1))
					for y in [1.15,3.3,3.65]: b.add("gold",Vector3(x+dx,y,z+dz),Vector3(.4,.08,.4))
					for tooth in range(3): b.add("realm_stone",Vector3(x+dx,3.83+tooth*.11,z+dz),Vector3(.48+tooth*.17,.1,.48+tooth*.17))
			# Open pointed arches between the existing columns, above head height.
			for end in [-1,1]:
				for arm in [-1,1]:
					for step in range(8): b.add("realm_stone",Vector3(x+arm*(1.2-step*.16),2.9+step*.16,z+end*1.5),Vector3(.22,.25,.25))
				for col in range(9): b.add("gold",Vector3(x-1.5+col*.375,4.12,z+end*1.8),Vector3(.13,.13,.08))
			for tier in range(5):
				for end in [-1,1]: b.add("gold",Vector3(x,4.35+tier*.23,z+end*(2.03-tier*.23)),Vector3(3.3-tier*.4,.05,.05))
			# Distinct pavilion functions and crowns across the three terraces.
			if index==0:
				for row in range(3):
					for col in range(4): b.add("realm_stone",Vector3(x+side*1.45,1.1+row*.4,z-.6+col*.4),Vector3(.25,.30,.34))
			elif index==1:
				for i in range(16):
					var angle:=TAU*i/16
					b.add("gold",Vector3(x+cos(angle)*.65,6.2+sin(angle)*.65,z),Vector3(.12,.12,.12))
			else:
				for arm in [-1,1]:
					for step in range(6): b.add("realm_stone",Vector3(x+arm*(.2+step*.13),5.1+step*.26,z),Vector3(.2,.26,.2))
	# Deeply framed final arch, with a fretted crown and stepped bases.
	for side in [-1,1]:
		for y in range(16): b.add("realm_stone",Vector3(side*7,1+y*.22,-39),Vector3(.65,.2,.65))
		for i in range(10): b.add("realm_stone",Vector3(side*(7-i*.72),3+i*.62,-39.15),Vector3(.8,.72,.35))
static func crucible(b: RefCounted) -> void:
	for z in [13,-9,-32]:
		var width: float=25 if z==-32 else 21
		for side in [-1,1]:
			# Ribbed masonry, furnace doors and riveted cornices on the existing walls.
			var x: float=side*(width/2+.04)
			for dz in [-6,-3,0,3,6]:
				for row in range(13):
					b.add("realm_stone",Vector3(x, .3+row*.54,z+dz),Vector3(.18,.50,.65))
				for tier in range(4): b.add("iron",Vector3(x-side*tier*.14,6.65+tier*.2,z+dz),Vector3(.25,.18,.9))
			for dz in [-4.5,1.5,4.5]:
				b.add("iron",Vector3(x-side*.02,2,z+dz),Vector3(.12,2.6,1.35))
				b.add("coal",Vector3(x-side*.09,2,z+dz),Vector3(.05,2.2,1.06))
				for slat in range(6): b.add("realm_glow",Vector3(x-side*.125,1.15+slat*.31,z+dz),Vector3(.025,.09,.75))
				for edge in [-1,1]:
					for bolt in range(5): b.add("iron",Vector3(x-side*.16,1+bolt*.5,z+dz+edge*.61),Vector3(.06,.10,.10))
			# Buttressed exterior stacks vary per terrace, outside the arena collision.
			for dz in [-5,5]:
				for tier in range(6): b.add("coal",Vector3(side*(width/2+1.5+tier*.10),2+tier*.95,z+dz),Vector3(1.5-tier*.13,.98,1.3-tier*.08))
	for side in [-1,1]:
		for i in range(13):
			b.add("iron",Vector3(side*(8-i*.62),7+i*.4,-40),Vector3(.75,.58,.6))
			if i%2==0: b.add("coal",Vector3(side*(8-i*.62),8+i*.4,-40),Vector3(.25,1.5,.25))
	# Flanged conduits and hanging exhaust teeth are well above combat headroom.
	for z in [-2,-24]:
		for x in range(-12,13,2):
			b.add("coal",Vector3(x,6.5,z),Vector3(.25,.9,1.2))
			b.add("iron",Vector3(x,5.65,z),Vector3(.45,.3,.45))
static func station(station: Node3D) -> void:
	# Medical, salvage and command compartments get visibly different wall fittings.
	for section in range(3):
		var z: float=[24,-18,-65][section]
		for side in [-1,1]:
			for panel in range(5):
				var dz: float=z-8+panel*4
				station.box(Vector3(side*19.4,3.5,dz),Vector3(.22,4.9,3.5),"station_floor")
				for y in [1.1,5.9]: station.box(Vector3(side*19.25,y,dz),Vector3(.2,.15,3.6),"iron")
				if section==0:
					station.box(Vector3(side*19.20,3.5,dz),Vector3(.12,2.5,2.8),"station_plate")
					station.box(Vector3(side*19.1,3.5,dz),Vector3(.05,1.05,.22),"station_light")
					station.box(Vector3(side*19.1,3.5,dz),Vector3(.05,.22,1.05),"station_light")
				elif section==1:
					for slot in range(8): station.box(Vector3(side*19.18,1.7+slot*.49,dz),Vector3(.14,.18,2.9),"iron")
				else:
					for row in range(3):
						for col in range(3):
							station.box(Vector3(side*19.17,2.25+row*1.05,dz-.9+col*.9),Vector3(.08,.85,.72),"station_light" if (row+col)%2 else "station_plate")
	# Frame the existing bulkhead opening without shrinking its 8 m clearance.
	for z in [8,-43]:
		for side in [-1,1]:
			for tier in range(3): station.box(Vector3(side*(4.25+tier*.2),3.5,z+.42),Vector3(.19,7,.16),"iron")
			for stripe in range(12): station.box(Vector3(side*4.64,.3+stripe*.53,z+.52),Vector3(.23,.2,.06),"station_red")
		station.box(Vector3(0,7.35,z),Vector3(9.5,.45,1.05),"station_plate")
		for i in range(8): station.box(Vector3(-3.5+i,7.32,z+.56),Vector3(.45,.12,.06),"station_light")
