uniform bool Electric_active = true;	
group_uniforms noise_uniforms;
uniform sampler2D lightning_noise : repeat_enable;
uniform sampler2D background_noise : repeat_enable;
group_uniforms;
group_uniforms color_uniforms;
// use this gradient if you want to set a custom gradient instead of the base texture colors
// By making the color transparent in the gradient you can smooth out the end.
uniform sampler2D color_gradient; 
uniform bool use_color_gradient = false;
uniform float color_effect_mod : hint_range(0.0, 3.0, 0.05) = 0.5; // How weak the color effect should be
group_uniforms;
uniform float intensive : hint_range(.0, 5.0, 0.05) = 0.8; // How much the lightning oscillates 
uniform float lightning_thin = 2.; // How thin the lightning i
uniform float frequency:hint_range (1.,50.) = 5.;
uniform int number_lightning = 8;
uniform float speed = 1.;
uniform float position : hint_range(0.0, 1.0, 0.05) = 0.5;

float random (vec2 uv) {
    return fract(sin(dot(uv.xy,
        vec2(12.9898,78.233))) * 43758.5453123);
}

void electric_line(in vec2 uv, in sampler2D tex, in vec2 size, in vec2 pixelSize, inout vec4 color) {
    vec4 old_color = color;
	if (use_color_gradient) {
		old_color = texture(color_gradient, vec2(uv.y, uv.x));
	}
	color = vec4(0.);
	float time = TIME * speed;
    
    vec4 final_color = vec4(0.0);
    float total_weight = 0.0;


    for (int i = 0; i < number_lightning; i++){
		float offset_x = random(vec2(time));
		vec2 noise_coords = vec2(time * .4 * (.5 + fract(sin(float(i) * 50.))), abs(uv.x - 0.5) *frequency);
		vec2 offset = (texture(lightning_noise, noise_coords).rg - vec2(0.5)) * intensive; 
		vec2 uv_off = uv + offset;
		float dist_x = abs(uv_off.y - position) * lightning_thin;
		
		float color_lower_bound = .1 + 0.5 * (float(i) - .5);
		float color_mod = smoothstep(color_lower_bound, 1., texture(background_noise, uv * sin(offset_x)).x);
		
		vec4 new_color = old_color * color_mod / dist_x;
		
		new_color *= 0.1 * texture(background_noise, uv_off + vec2((time))).r;
		color += new_color;
        color.a -= min(color_effect_mod, new_color.a);
        color -= vec4(.8,.8,0.,0.);
}



}
