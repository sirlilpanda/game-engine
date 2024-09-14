#version 450 core

layout (location = 0) in vec2 tri_pos;
uniform vec4 colour;
uniform vec2 pos;
uniform vec2 scale;

out vec4 out_color;
out vec2 uv_tri_pos;

const vec2 offset = vec2(-1, 1);
void main()
{
    uv_tri_pos = tri_pos;
    out_color = vec4(1);

    vec2 updated_pos = (tri_pos+pos)*scale+offset;
	gl_Position = vec4(updated_pos.xy, 0, 1);
}