extends RefCounted
static var skies: Dictionary={}
static func apply(env: Environment,id: String) -> void:
	if not skies.has(id):
		var palette: Array
		match id:
			"mountain", "winter": palette=["405e7d","b6cbd7","bac7d2",.45]
			"shore": palette=["263c56","809aab","667584",.42]
			"lens": palette=["4a7899","d4ba96","dcc6aa",.62]
			"roots", "archive_chapter": palette=["3b696d","9caf9d","c2ceba",.55]
			"choir": palette=["322c3b","a27e70","665460",.38]
			_: palette=["364957","8caba7","91aaa7",.42]
		var mat=ShaderMaterial.new(); mat.shader=preload("res://shaders/regional_clouds.gdshader")
		mat.set_shader_parameter("zenith",Color(palette[0])); mat.set_shader_parameter("horizon",Color(palette[1])); mat.set_shader_parameter("clouds",Color(palette[2])); mat.set_shader_parameter("cover",palette[3])
		var sky=Sky.new(); sky.sky_material=mat; sky.radiance_size=Sky.RADIANCE_SIZE_64; sky.process_mode=Sky.PROCESS_MODE_INCREMENTAL
		skies[id]=sky
	env.background_mode=Environment.BG_SKY; env.sky=skies[id]
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
