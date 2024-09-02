#version 450 core

uniform sampler2D tSampler;

in vec2 TexCoord;
in float diffTerm;
in vec4 Ambient_colour;
in vec4 Obj_colour;

out vec4 outputColor;

void main() 
{ 
    vec4 tColor = texture(tSampler, TexCoord);
    outputColor = (tColor * Obj_colour) * (diffTerm + Ambient_colour);   //Green
}
