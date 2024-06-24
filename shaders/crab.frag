#version 450 core

uniform sampler2D tSampler;

in vec2 TexCoord;
in float diffTerm;
out vec4 outputColor;

void main() 
{ 
    vec4 tColor = texture(tSampler, TexCoord);
    outputColor = tColor*diffTerm;   //Green
}
