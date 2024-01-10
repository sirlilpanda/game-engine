#version 450 core

layout (location = 0) in vec4 position;
layout (location = 1) in vec3 normal;
uniform mat4 mvMatrix;
uniform mat4 mvpMatrix;
uniform mat4 norMatrix;
uniform vec4 lightPos;

out vec4 oColor;
out float diffTerm;

void main()
{
	vec4 posnEye = mvMatrix * position;
	vec4 normalEye = norMatrix * vec4(normal, 0);
	vec4 lgtVec = normalize(lightPos - posnEye); 

	diffTerm = max(dot(lgtVec, normalEye), 0);
	gl_Position = mvpMatrix * position;
	oColor = vec4(1.0, 0.64, 0.45, 1.0);
}