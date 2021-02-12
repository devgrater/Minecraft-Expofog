#version 120
#define PI 3.14159
#define GROUND_HEIGHT 64
#define FALLOFF_FUN 8
#define NOISE_SAMPLE_SIZE 512

uniform mat4 gbufferProjectionInverse;
uniform vec3 upPosition;
uniform sampler2D texture;
uniform sampler2D depthtex0; //This one contains the clouds
uniform float eyeAltitude;
uniform float far;
uniform float near;
uniform vec3 cameraPosition; 
uniform mat4 gbufferModelViewInverse;
uniform float viewWidth;
uniform sampler2D noisetex;
uniform float frameTimeCounter;

uniform ivec2 eyeBrightnessSmooth;
uniform float wetness;   

varying vec4 viewDir;
varying vec4 texcoord;
varying vec4 color;

const int noiseTextureResolution = 64;

void main(){
    vec4 sampledTexture = texture2D(texture, texcoord.st);
    float pitch = -upPosition.z;
    float depth0 = texture2D(depthtex0, texcoord.st).r;
    float powedDepth0 = depth0;

    for(int i = 0; i < 8; i++){
        powedDepth0 = powedDepth0 * powedDepth0;
    }
    //powedDepth0 = clrmp(powedDepth0 + sin(depth0 * 16 + 3) / 8 * depth0, 0, 1);
    //float mixVal = powedDepth0 * 1 / exp(eyeAltitude * 0.01);

    //Compute view direction:
    //gbufferProjectionInverse

    
    float time = frameTimeCounter / 4;
    vec3 screenPos = vec3(texcoord.s, texcoord.t , depth0);
    vec3 clipPos = screenPos * 2.0 - 1.0;
    vec4 tmp = gbufferProjectionInverse * vec4(clipPos, 1.0);
    vec4 viewPos = tmp;
    viewPos.xyz /= viewPos.w;
    viewPos.w = 1.0;

    vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos.xyz;
    vec3 feetPlayerPos = eyePlayerPos + gbufferModelViewInverse[3].xyz;
    vec3 worldPos = feetPlayerPos + cameraPosition;

    float rndOffset = pow(texture2D(noisetex, (worldPos.xz + time) / NOISE_SAMPLE_SIZE).r, 2);
    rndOffset = rndOffset * 2 - 1;
    float feetRndOffset = pow(texture2D(noisetex, (cameraPosition.xz + time) / NOISE_SAMPLE_SIZE).r, 2);
    feetRndOffset = feetRndOffset * 2 - 1;


    float falloff = 0.01;
    float height = eyePlayerPos.y + eyeAltitude;
    float heightFogAmount = clamp(exp(-((eyePlayerPos.y + eyeAltitude - GROUND_HEIGHT - rndOffset * 4) * FALLOFF_FUN) * falloff), 0.0, 0.8); //This determines whether the eyes is inside the fog plane
    float eyeHeightFogAmount = clamp(exp(-((eyeAltitude - GROUND_HEIGHT - feetRndOffset * 4) * FALLOFF_FUN) * falloff), 0.0, 1.0);
    
    float fogAmount = heightFogAmount * powedDepth0;
    
    fogAmount = mix(fogAmount, powedDepth0, eyeHeightFogAmount);

    float fogLerpAmount = clamp(pow(eyeAltitude / 60, 2), 0, 1);
    fogLerpAmount *= fogLerpAmount;
    fogLerpAmount *= fogLerpAmount;
    vec4 fogColor = mix(vec4(0.1, 0.1, 0.2, 1.0), vec4(gl_Fog.color.rgb, 0.01), fogLerpAmount);



    //vec4 mixFogColor = mix(fogColor * 0.2, fogColor, skyBrightness);
    gl_FragData[0] = vec4(mix(sampledTexture * color, fogColor, fogAmount));
}