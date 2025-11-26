
uniform float dissolve_speed :hint_range(1.,10.) = 5.;
uniform float min_value :hint_range(0,1) = .2;
uniform float max_value :hint_range(0,1) = 1.;
uniform vec2 PIXELDISOLVE_custom_resolution = vec2(3000,100);
uniform bool  PIXEL_OUTLINE_active = true;
uniform float OUTLINE_thickness : hint_range(0, 30) = 1.4;
uniform vec4  OUTLINE_color : source_color = vec4(1,0,0,1);

float PIXELDISOLVE_rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,96.233))) * 43758.5453);
}

float sin_range(float x) {
    return min_value + (sin(x) * 0.5 + 0.5) * (max_value - min_value);
}

void pixel_outline(in vec2 uv, in sampler2D tex, in vec2 spriteSize, in vec2 pixelSize, inout vec4 color) {
    vec2 size = vec2(OUTLINE_thickness) / spriteSize;

    float alpha = color.a;
    alpha += texture(tex, uv + vec2(0.0, -size.y)).a;
    alpha += texture(tex, uv + vec2(size.x, -size.y)).a;
    alpha += texture(tex, uv + vec2(size.x, 0.0)).a;
    alpha += texture(tex, uv + vec2(size.x, size.y)).a;
    alpha += texture(tex, uv + vec2(0.0, size.y)).a;
    alpha += texture(tex, uv + vec2(-size.x, size.y)).a;
    alpha += texture(tex, uv + vec2(-size.x, 0.0)).a;
    alpha += texture(tex, uv + vec2(-size.x, -size.y)).a;

    vec3 final_color = mix(OUTLINE_color.rgb, color.rgb, color.a);
    color = vec4(final_color, clamp(alpha, 0.0, 1.0));
    if (color.a > 0. && texture(tex,uv).a == 0.){
	vec2 within_texture_pixel = vec2(floor(uv * PIXELDISOLVE_custom_resolution));
	if(sin(sin_range(TIME * dissolve_speed)) * sin_range(TIME) <= PIXELDISOLVE_rand(within_texture_pixel))
		color = vec4(0.0,0.0,0.0,0.0);
}
}
