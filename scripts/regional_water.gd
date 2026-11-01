extends RefCounted
static func material(marsh: bool=false) -> ShaderMaterial:
	var mat=ShaderMaterial.new(); mat.shader=preload("res://shaders/regional_water.gdshader")
	mat.set_shader_parameter("deep_color",Color("354e49") if marsh else Color("345b68"))
	mat.set_shader_parameter("crest_color",Color("688075") if marsh else Color("9dbdc1"))
	mat.set_shader_parameter("speed",.18 if marsh else .55)
	return mat
