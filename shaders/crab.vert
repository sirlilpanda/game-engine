#version 450 core

layout (location = 0) in vec4 position;
layout (location = 1) in vec3 normal;
layout (location = 2) in vec2 texCoord;

uniform mat4 mMatrix;
uniform mat4 mvMatrix;
uniform mat4 mvpMatrix;
uniform mat4 norMatrix;
uniform vec4 lightPos;
uniform bool hasDiffuseLighting;
uniform vec4 ambient_colour;
uniform vec4 obj_colour;

out vec2 TexCoord;
out float diffTerm;
out vec4 Ambient_colour;
out vec4 Obj_colour;

void main()
{

	if (hasDiffuseLighting){
		vec4 posnEye = mMatrix * position;
		
		vec4 normalEye = vec4(normal, 0);
		vec4 lgtVec = normalize(lightPos - posnEye); 
		diffTerm = max(dot(lgtVec, normalEye), 0);
	} else {
		diffTerm = 1;
	};
	Ambient_colour = ambient_colour;
	Obj_colour = obj_colour;
	gl_Position = mvpMatrix * position;
	TexCoord = texCoord;
}