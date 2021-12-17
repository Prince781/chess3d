#version 300 es

in vec3 position;
in vec2 texcoord;
in vec3 normal;

out vec2 TexCoord;
out vec3 Normal;
out vec3 FragPosition;

uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;

void main() {
    gl_Position = proj * view * model * vec4(position, 1.0);
    TexCoord = texcoord;
    // XXX: calculate transpose-inverse of model on the CPU side
    Normal = normalize(mat3(transpose(inverse(model))) * normal);
    FragPosition = vec3(model * vec4(position, 1.0));
}
