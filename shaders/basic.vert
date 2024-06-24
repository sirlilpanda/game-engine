#version 450

layout (location = 0) in vec3 position;
layout (location = 1) in vec3 normal;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

uniform mat4 normMatrix;
uniform vec4 lightPos;



out vec4 oColor;

void main() {
	vec4 white = vec4(1.0);
	vec4 grey = vec4(0.2);
	vec4 material = vec4(1.0, 0.64, 0.45, 1.0);
	float shininess = 10.0;

	vec4 posnEye = model*view * position;
	vec4 normalEye = norMatrix * vec4(normal, 0);
	vec4 lgtVec = normalize(lightPos - posnEye); 
	vec4 viewVec = normalize(vec4(-posnEye.xyz, 0)); 
	vec4 halfVec = normalize(lgtVec + viewVec); 

	vec4 ambient = grey * material;
	float diffTerm = max(dot(lgtVec, normalEye), 0);
	vec4 diffuse = material * diffTerm;

    gl_Position = projection * view * model * vec4(position, 1.0);
}