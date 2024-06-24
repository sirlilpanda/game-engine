#version 450 core

// layout (location = 0) in vec4 position;
// layout (location = 1) in vec3 normal;
// uniform mat4 mvMatrix;
// uniform mat4 mvpMatrix;
// uniform mat4 norMatrix;
// uniform vec4 lightPos;

// out vec4 oColor;
// out float diffTerm;

// void main()
// {
// 	vec4 posnEye = mvMatrix * position;
// 	vec4 normalEye = norMatrix * vec4(normal, 0);
// 	vec4 lgtVec = normalize(lightPos - posnEye); 

// 	diffTerm = max(dot(lgtVec, normalEye), 0);
// 	gl_Position = mvpMatrix * position;
// 	oColor = vec4(1.0, 0.64, 0.45, 1.0);
// }

layout (location = 0) in vec3 aPos;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main()
{
    gl_Position = projection * view * model * vec4(aPos, 1.0);
} 