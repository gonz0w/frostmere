shader_type spatial;
uniform vec3 deep_color: source_color=vec3(.15,.29,.34);
uniform vec3 crest_color: source_color=vec3(.36,.48,.49);
uniform float speed=.55;
varying vec3 world_position;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 p=world_position.xz;
 float wave=sin(p.x*2.4+p.y*.35+TIME*speed)+.45*sin(p.y*4.7-p.x*.64-TIME*speed*.8);
 float broken=smoothstep(.1,.85,sin(p.y*.7+p.x*2.7));
 float crest=smoothstep(.88,1.35,wave)*broken;
 ALBEDO=mix(deep_color,crest_color,crest*.5)+sin(p.x*.31+p.y*.26)*.012;
 ROUGHNESS=.3+crest*.12;
 METALLIC=.13;
}
