#ifndef VRP_PBS_CGINC
#define VRP_PBS_CGINC


#include "UnityCG.cginc"
#include "Light.cginc"
#include "PBR.cginc"

struct SurfaceInfo {
	float3 baseColor;
	float alpha;
	float metallic;
	float smoothness;
	float3 normal;
	float3 tangent;
	float4 worldPos;
	float z;
};




float4 ComplexPBS(SurfaceInfo IN, float3 viewDir) {
	float3 color = 0;

	half oneMinusReflectivity;
	half3 baseColor, specColor;
	baseColor = DiffuseAndSpecularFromMetallic(IN.baseColor, IN.metallic, /*out*/ specColor, /*out*/ oneMinusReflectivity);

	half outputAlpha;
	baseColor = PreMultiplyAlpha(baseColor, IN.alpha, oneMinusReflectivity, /*out*/ outputAlpha);

	float3 normal = IN.normal;
	float3 tangent = IN.tangent;
	float4 worldPos = IN.worldPos;
	int cascade = GetCascadeIndex(IN.z);

	for (int it = 0; it < _LightSum; it++) {
		Light light = _LightBuffer[it];
		float3 lightDir, lightSatu;
		if (light.pos_type.w == 0) {
			lightSatu = SampleLight_Dir(cascade, light, worldPos, normal, tangent);
			lightDir = light.pos_type.xyz;
		}
		else if (light.pos_type.w == 1) {
			lightSatu = SampleLight_Point(light, worldPos, normal, tangent);
			lightDir = normalize(light.pos_type.xyz - worldPos);
		}
		else if (light.pos_type.w == 2) {
			lightSatu = SampleLight_Spot(light, worldPos, normal, tangent);
			lightDir = normalize(light.pos_type.xyz - worldPos);
		}
		color += lightSatu;// BRDFLight(baseColor, specColor, IN.smoothness, normal, viewDir, lightDir, lightSatu);
	}

	//todo:
	//color += BRDFGI(baseColor, specColor, oneMinusReflectivity, IN.smoothness, normal, viewDir, 0.05, 0);

	return  float4(color, outputAlpha);
}


float4 SimplePBS(SurfaceInfo IN, float3 viewDir) {
	float3 color = 0;

	half oneMinusReflectivity;
	half3 baseColor, specColor;
	baseColor = DiffuseAndSpecularFromMetallic(IN.baseColor, IN.metallic, /*out*/ specColor, /*out*/ oneMinusReflectivity);

	half outputAlpha;
	baseColor = PreMultiplyAlpha(baseColor, IN.alpha, oneMinusReflectivity, /*out*/ outputAlpha);

	float3 normal = IN.normal;
	float3 tangent = IN.tangent;
	float4 worldPos = IN.worldPos;
	int cascade = GetCascadeIndex(IN.z);

	for (int it = 0; it < _LightSum; it++) {
		Light light = _LightBuffer[it];
		float3 lightDir, lightSatu;
		if (light.pos_type.w == 0) {
			lightSatu = SampleLight_Dir_Simple(cascade, light, worldPos);
			lightDir = light.pos_type.xyz;
		}
		else if (light.pos_type.w == 1) {
			lightSatu = SampleLight_Point_Simple(light, worldPos);
			lightDir = normalize(light.pos_type.xyz - worldPos);
		}
		else if (light.pos_type.w == 2) {
			lightSatu = SampleLight_Spot(light, worldPos, normal, tangent);
			lightDir = normalize(light.pos_type.xyz - worldPos);
		}
		color += BRDFLight_Simple(baseColor, specColor, IN.smoothness, normal, viewDir, lightDir, lightSatu);
	}

	//todo:
	//color += BRDFGI(baseColor, specColor, oneMinusReflectivity, IN.smoothness, normal, viewDir, 0.15, 0);

	return  float4(color, outputAlpha);
}

#endif