shader_type spatial;
render_mode unshaded;
uniform vec4 ember : source_color = vec4(1.0,0.13,0.006,1.0);
void fragment(){
 float waves=sin(UV.x*85.0+TIME*.8)+sin(UV.y*44.0-TIME*.7)+sin((UV.x+UV.y)*116.0+TIME*.25);
 float fissure=smoothstep(.0,.5,waves);
 ALBEDO=mix(vec3(.07,.022,.011),ember.rgb,fissure);
 EMISSION=ember.rgb*fissure*2.2;
}
