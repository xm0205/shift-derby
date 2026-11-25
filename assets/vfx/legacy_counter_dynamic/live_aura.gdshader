shader_type canvas_item;
render_mode unshaded;
uniform vec4 aura_color : source_color = vec4(1.0,0.6,0.1,1.0);
uniform float strength = 1.0;
void fragment() {
 vec2 pixel = TEXTURE_PIXEL_SIZE * 5.0;
 float body = texture(TEXTURE,UV).a;
 float halo = 0.0;
 for (int i=0;i<12;i++) {
  float angle=float(i)*0.523599;
  halo=max(halo,texture(TEXTURE,UV+vec2(cos(angle),sin(angle))*pixel).a);
 }
 float ripple=0.62+0.38*sin(UV.x*42.0-UV.y*19.0-TIME*18.0);
 COLOR=vec4(aura_color.rgb*1.2,halo*(1.0-body)*ripple*strength);
}
