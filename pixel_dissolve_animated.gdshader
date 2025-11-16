uniform bool PIXELDISOLVEANI_active=true;
uniform float dissolve_speed :hint_range(1.,5.) = 2.;
uniform float min_value :hint_range(0,1) = .5;
uniform float max_value :hint_range(0,1) = .7;

	
uniform float PIXELDISOLVE_time:hint_range(0.0, 1.57, 0.001) = 1.0;
uniform vec2 PIXELDISOLVE_custom_resolution = vec2(100,100);


float PIXELDISOLVE_rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,96.233))) * 43758.5453);
}

float sin_range(float x) {
    return min_value + (sin(x) * 0.5 + 0.5) * (max_value - min_value);
}

void pixelDisolveAni(in vec2 uv, in sampler2D sampler, vec2 size, vec2 pixelSize, inout vec4 color){

	vec2 within_texture_pixel = vec2(floor(uv * PIXELDISOLVE_custom_resolution));
	if(sin(sin_range(TIME * dissolve_speed))  <= PIXELDISOLVE_rand(within_texture_pixel))
		color = vec4(0.0,0.0,0.0,0.0);
}
