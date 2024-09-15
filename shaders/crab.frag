#version 450 core

layout(location = 0) out vec4 Colour;

uniform sampler2D tSampler;

in vec2 TexCoord;
in float diffTerm;
in vec4 Ambient_colour;
in vec4 Obj_colour;

void main() 
{ 
    vec4 tColor = texture(tSampler, TexCoord);
    Colour = (tColor * Obj_colour) * (diffTerm + Ambient_colour);   //Green
}
