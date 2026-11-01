shader_type sky;
render_mode disable_fog;
uniform vec3 zenith: source_color=vec3(.20,.32,.44);
uniform vec3 horizon: source_color=vec3(.62,.71,.76);
uniform vec3 clouds: source_color=vec3(.65,.68,.71);
uniform float cover=.52;
float hash(vec2 p) {return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p) {vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void sky(){
 vec3 d=normalize(EYEDIR); float h=max(d.y,0.0);
 vec2 p=d.xz/(.24+h)*2.3;
 float n=noise(p)*.55+noise(p*2.4)*.28+noise(p*5.9)*.17;
 vec3 col=mix(horizon,zenith,pow(h,.6));
 float cloud=smoothstep(cover-.15,cover+.17,n)*smoothstep(-.08,.14,d.y);
 col=mix(col,clouds*(.72+n*.36),cloud*.83);
 COLOR=col;
}
