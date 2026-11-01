extends RefCounted
## Asymmetric, striated mountain silhouettes. Background geometry only.
static func build(b: RefCounted,at: Vector3,width: float,depth: float,height: float,rock: String="stone_dark",snow: bool=true) -> void:
	for x in range(-12,13):
		for z in range(-10,11):
			var dx: float=x*width/25; var dz: float=z*depth/21
			var edge: float=maxf(absf(dx)/(width*.5),absf(dz)/(depth*.5))
			var spine: float=absf(dx+sin(dz*.12+at.x)*width*.13)/(width*.5)
			var h: float=height*pow(maxf(0,1-edge),.65)*(1-.4*spine)
			h+=sin(dx*.49+dz*.21+at.x)*height*.065+cos(dz*.4-dx*.18)*height*.07
			h=maxf(.3,floorf(h*2)/2)
			var p: Vector3=at+Vector3(dx,h/2-.8,dz)
			b.add(rock,p,Vector3(width/25+.025,h,depth/21+.025))
			if h>height*.45:
				b.add("stone",at+Vector3(dx,h-.76,dz),Vector3(width/25+.03,.12,depth/21+.03))
			if snow and h>height*(.53+.1*sin(dx*.37+dz*.11)):
				b.add("snow",at+Vector3(dx,h-.62,dz),Vector3(width/25+.04,.23,depth/21+.04))
