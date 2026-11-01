shader_type sky;
render_mode disable_fog;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void sky() {
 vec3 d=normalize(EYEDIR);
 float h=max(d.y,0.0);
 vec2 p=d.xz/(0.45+abs(d.y));
 float cloud=noise(p*3.0+vec2(TIME*.003,0));
 cloud=cloud*.65+noise(p*8.0)*.25+noise(p*21.0)*.1;
 vec3 col=mix(vec3(.24,.34,.48),vec3(.025,.035,.13),smoothstep(-.08,.75,d.y));
 col+=vec3(.19,.10,.29)*smoothstep(.38,.76,cloud)*smoothstep(-.1,.3,d.y);
 float wave=p.y+.36*sin(p.x*1.7+TIME*.016)+.12*sin(p.x*4.0);
 float ribbon=exp(-abs(wave-.35)*8.0)+.55*exp(-abs(wave+.24)*13.0);
 float folds=.55+.45*noise(vec2(p.x*37.0,TIME*.015));
 col+=mix(vec3(.08,.45,.40),vec3(.30,.12,.50),cloud)*ribbon*folds*smoothstep(.03,.25,h);
 vec2 stars=vec2(atan(d.z,d.x),asin(d.y))*220.0;
 float star=step(.994,hash(floor(stars)))*(1.0-smoothstep(.03,.21,length(fract(stars)-.5)));
 col+=vec3(.65,.8,1.0)*star*smoothstep(.06,.3,h);
 vec3 moon=normalize(vec3(-.48,.46,-.8));
 float dist=length(d-moon);
 col+=vec3(.15,.27,.43)*exp(-dist*16.0);
 float disc=1.0-smoothstep(.081,.084,dist);
 float shadow=smoothstep(.070,.075,length(d-normalize(moon+vec3(.038,.014,0))));
 col+=vec3(.7,.82,.91)*disc*(.12+.88*shadow);
 COLOR=col;
}
