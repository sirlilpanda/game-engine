#version 450 core

layout (location = 0) in vec4 position;
layout (location = 1) in vec3 normal;

uniform mat4 mvpMatrix;
//so you can change the colour
uniform vec4 colour;

out vec4 oColor;

void main()
{
	gl_Position = mvpMatrix * position;
    oColor = colour; // dont know if this should go here yet
}