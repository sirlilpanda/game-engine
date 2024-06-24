#version 450 core

layout (location = 0) in vec4 position;
layout (location = 1) in vec3 normal;
layout (location = 2) in vec2 texCoord;

uniform mat4 mMatrix;
uniform mat4 mvMatrix;
uniform mat4 mvpMatrix;
uniform mat4 norMatrix;
uniform vec4 lightPos;

out vec2 TexCoord;
out float diffTerm;

void main()
{

	// vec4 posnEye = mvMatrix * position;
	vec4 normalEye = norMatrix * vec4(normal, 0);
	vec4 fragPos = mMatrix * position;
	vec4 lgtVec = normalize(lightPos - fragPos);  
	// vec4 lgtVec = normalize(lightPos - posnEye); 

	diffTerm = max(dot(normalEye, lgtVec), 0.0);

	gl_Position = mvpMatrix * position;
	TexCoord = texCoord;
}