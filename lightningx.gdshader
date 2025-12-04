uniform bool LIGHTNINGX_active=true;
uniform float min_offset :hint_range(-1.,1.) = -1.;
uniform float max_offset :hint_range(-1.,1.) = 1.;
uniform int count : hint_range(1, 15) = 1;
uniform vec4 LIGHTNING_lightningColor: source_color=vec4(1,1,1,1);
uniform float LIGHTNING_size: hint_range (0.,.4)=0.01;
uniform float LIGHTNING_width: hint_range (0.,.9)=.05;
uniform float LIGHTNING_speed:hint_range(0.0, 15.0, 0.1)=4;
uniform float LIGHTNING_frequency:hint_range(0.0, 100.0, 0.1)=20.;
uniform float LIGHTNING_flash:hint_range(0.0, 15.0, 0.1)=15.0;
uniform float LIGHTNING_time_shift:hint_range(0.0, 15.0, 0.1)=15;

float LIGHTNING_rand(float x){
	return fract(sin(x)*100000.0);
}

float min_max_sin(float x){
    return float (min_offset +(sin(x) + 1.0) * 0.5 * (max_offset - min_offset));
}

void lightningx(in vec2 uv, in sampler2D sampler,in vec2 texSize, vec2 pixelSize, inout vec4 color){
    const int max_const = 11;
    float bolt[max_const];
    float wave[max_const];
    float blink;
    vec4 display[max_const];
    
        for (int i = 0; i < count; i++ ){
    	    bolt[i] = abs(mod(uv.x * LIGHTNING_frequency + (LIGHTNING_rand(TIME) + LIGHTNING_time_shift) * LIGHTNING_speed * -1., 0.5)-0.25)-0.125;
            bolt[i] *= 4. * LIGHTNING_width;
 	        wave[i] = abs(uv.y - float(i) * .1  + bolt[i] + (min_max_sin(TIME + float(i)) *.9) )  ;     
            wave[i] = 1. - step(LIGHTNING_size * .2, wave[i]);
           	blink = step(LIGHTNING_rand (TIME) * LIGHTNING_flash  , float(i) );
	        wave[i] *= blink;
            
	        display[i] = LIGHTNING_lightningColor * vec4(wave[i]);
	        color =vec4(color.rgb + display[i].rgb , color.a);
        }
        
    }
  
