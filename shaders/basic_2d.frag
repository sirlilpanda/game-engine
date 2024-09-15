#version 450 core

in vec4 out_color;
in vec2 uv_tri_pos;
uniform vec2 uv_pos;
uniform vec2 uv_cell_size;

uniform sampler2D tSampler;

void main()
{
    vec4 texture_colour = texture(tSampler, uv_tri_pos*uv_cell_size+vec2(uv_pos.x, 1-uv_pos.y)); 
    
    if((texture_colour.r*texture_colour.r + texture_colour.g*texture_colour.g + texture_colour.b*texture_colour.b) > 1 ){
        gl_FragColor = texture_colour*out_color;   
    } else {
        discard;
    }
    
}