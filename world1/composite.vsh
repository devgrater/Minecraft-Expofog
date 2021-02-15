#version 120

varying vec4 viewDir;
varying vec4 texcoord;
varying vec4 color;

void main(){
    viewDir = gl_ModelViewMatrix * gl_Vertex;
    gl_Position = gl_ProjectionMatrix * viewDir;
    texcoord = gl_TextureMatrix[0] * gl_MultiTexCoord0;
    color = gl_Color;
}