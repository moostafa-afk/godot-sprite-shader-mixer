/*
Squish Sprite Shader by Garmelon (https://github.com/Garmelon)
Documented by Mateus-Carmo31
*/

uniform bool squash_active = true;
uniform bool uv_mode = false;
uniform float y_factor : hint_range(-1.,3.) = 2.;
uniform float squash : hint_range(-1,3) = 1;


float squash_function(float y)
{
	return sqrt(1.0 - y*y);
}

void squash_func(in vec2 uv, in sampler2D tex, in vec2 size, in vec2 pixelSize, inout vec4 color){

// This will be used to center the laser
    uv =  uv * 2.0 - 1.0;
	uv.y *= 1. / y_factor;
	float displacement = 1.0 + squash * squash_function(uv.y);
	uv.y /= displacement;
	uv = (uv + 1.0) / 2.0;


	
if (uv_mode)
{
    color = uv.y >= 0.0 && uv.y <= 1.0 ? vec4(uv, 0.0, 1.0) : vec4(vec3(0.0), 1.0);
}
else if (uv.y >= 0.0 && uv.y <= 1.0)
{
    color = texture(tex, uv);
}
else
{
    color = vec4(0.0);
}
}

