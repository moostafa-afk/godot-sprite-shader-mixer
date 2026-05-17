// given the filename is blur2.gdshader ....
//BLUR2_ <-- note that you have to prefix all variables with an uppercased shader file name of the shader
uniform bool  BLUR2_active  = true;
// Note that all shaders MUST have a _active boolean variable to work
uniform float BLUR2_radius : hint_range(1, 15.0) = 15.0;
uniform float BLUR2_mix : hint_range(0,1.0)=0;
// blur2 <-- note that you have to name the function variable with lowercased filename of the shader
void blur2(in vec2 uv, in sampler2D tex, in vec2 size, in vec2 pixelSize, inout vec4 color) {
	vec4 final_color = vec4(0.0);
    float total_weight = 0.0;

    for (float x = -BLUR2_radius; x <= BLUR2_radius; x += 1.0) {
        for (float y = -BLUR2_radius; y <= BLUR2_radius; y += 1.0) {
            vec2 offset = vec2(x, y);
            vec4 sample = texture(tex, uv + offset / size);

            float distance = length(offset);
            float weight = smoothstep(BLUR2_radius, BLUR2_radius - 1.0, distance);

            final_color += mix(sample * weight, color,BLUR2_mix);
            total_weight += weight;
        }
    }
    color= final_color / total_weight;
}