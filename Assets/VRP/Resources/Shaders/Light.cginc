#ifndef VRP_LIGHT_CGINC
#define VRP_LIGHT_CGINC

#include "sample_disk.cginc"

struct Light
{
	float4 pos_type;  // XYZ(position)W(type)
	float4 geometry;  // XYZ(normalized direction xyz)W(radio)
	float4 color;     // XYZ(color)W(strength)
	float4 others;   // NULL
};

int _LightSum;
int _LightIndex[64];
StructuredBuffer<Light> _LightBuffer;


//Directional shadow
struct ShadowMatrix
{
	float4x4 mats[4];
};
int _MaxCascadeNum;
float4 _DirShadowResolution;
float4 _DirctionalShadowSplitDistance;
UNITY_DECLARE_TEX2DARRAY(_DirShadowArray);
StructuredBuffer<ShadowMatrix> _Shadowcascade_matrix_vp;



UNITY_DECLARE_TEX2DARRAY(_PointShadowArray);
StructuredBuffer<ShadowMatrix> _PointLightMatrixArray;

inline int GetCascadeIndex(float depth) {
	return 4 - step(_DirctionalShadowSplitDistance.x, depth)
			 - step(_DirctionalShadowSplitDistance.y, depth)
			 - step(_DirctionalShadowSplitDistance.z, depth)
			 - step(_DirctionalShadowSplitDistance.w, depth);
}

inline float4 SampleDirctionalShadow(int index, float2 uv) {
	return UNITY_SAMPLE_TEX2DARRAY(_DirShadowArray, float3(uv, index));
}

inline float4 SamplePointShadow(int index, float2 uv) {
	return UNITY_SAMPLE_TEX2DARRAY(_PointShadowArray, float3(uv, index));
}



float3 SampleLight_Dir(int cascade, Light light, float4 pos, float3 n, float3 t) {
	float3 light_contri = light.color.rgb * light.color.w;

	if (light.others.x != -1 && cascade < _MaxCascadeNum) {
		float3 biot = cross(n, t);
		float4x4 shadow_mat = _Shadowcascade_matrix_vp[light.others.x].mats[cascade];
		float visibility = 0;
		float bias = max(0.002 * (1.0 - dot(n, light.pos_type.xyz)), 0.002);
		float2 ati = 1;
		ati.x = 0.25+abs(dot(t, light.pos_type.xyz));
		ati.y = 0.25+abs(dot(biot, light.pos_type.xyz));
		ati = normalize(ati);

		float2 noise = Rand(pos.xyz);
		for (int i = 0; i < SAMPLE_DISK_SIZE; i++) {
			float2 offset = RandOffset(i, noise) * ati * 0.2;
			float4 shadow_uv = mul(shadow_mat, pos + float4(t * offset.x + biot * offset.y, 0)); shadow_uv /= shadow_uv.w;
			shadow_uv.y = -shadow_uv.y;
			float2 uv = shadow_uv.xy / 2 + 0.5;
			float z_cmp = SampleDirctionalShadow(light.others.x, uv)[cascade];
			if (shadow_uv.z > z_cmp - bias) visibility += 1;
		}
		visibility = visibility / SAMPLE_DISK_SIZE;
		light_contri *= visibility;
	}
	return light_contri;
}

float3 SampleLight_Dir_Simple(int cascade, Light light, float4 pos) {
	float3 light_contri = light.color.rgb * light.color.w;

	if (light.others.x != -1 && cascade < _MaxCascadeNum) {
		float4x4 shadow_mat = _Shadowcascade_matrix_vp[light.others.x].mats[cascade];
		float shadow = 1;
		
		float4 shadow_uv = mul(shadow_mat, pos); shadow_uv /= shadow_uv.w;
		shadow_uv.y = -shadow_uv.y;
		float2 uv = shadow_uv.xy / 2 + 0.5;
		float z_cmp = SampleDirctionalShadow(light.others.x, uv)[cascade];
		if (shadow_uv.z < z_cmp - 0.0001) shadow = 0;

		light_contri *= shadow;
	}
	return light_contri;
}



float3 SampleLight_Point(Light light, float4 pos, float3 n, float3 t) {

	float3 delta = light.pos_type - pos;
	float distance = length(delta);
	if (distance > light.geometry.w) return 0;
	float bias = max(0.004 * (1.0 - dot(n, light.pos_type.xyz)), 0.004);
	float3 l = delta / distance;
	float satu = saturate(1 - distance / light.geometry.w);
	float3 light_contri = satu * light.color.rgb * light.color.w;

	float2 noise = Rand(pos.xyz);
	if (light.others.x != -1) {
		float3 biot = cross(n, t); biot *= 0.01; t *= 0.01;
		ShadowMatrix shadow_mat = _PointLightMatrixArray[light.others.x];
		float4x4 mat0 = shadow_mat.mats[0], mat1 = shadow_mat.mats[1];
		float visibility = 0;
		for (int i = 0; i < SAMPLE_DISK_SIZE; i++) {
			float2 offset = RandOffset(i, noise)*10;
			float4 shadow_uv = mul(mat0, pos); shadow_uv.w = 1;
			int shadow_pass = step(0, shadow_uv.z);
			shadow_uv.xz *= -2 * shadow_pass + 1;
			float z = length(shadow_uv.xyz);
			shadow_uv.xyz = normalize(shadow_uv.xyz);
			shadow_uv.xy /= -shadow_uv.z + 1;

			shadow_uv.xy *= 2 * light.geometry.w;
			shadow_uv.z = -z;
			shadow_uv = mul(mat1, shadow_uv); shadow_uv /= shadow_uv.w;
			shadow_uv.y = -shadow_uv.y;
			float2 uv = shadow_uv.xy / 2 + 0.5;
			float z_cmp = SamplePointShadow(light.others.x, uv + offset/2000)[shadow_pass];
				if (shadow_uv.z > z_cmp - bias) visibility += 1;
		}
		visibility = visibility / SAMPLE_DISK_SIZE;
		light_contri *= visibility;
	}


	return light_contri;
}

float3 SampleLight_Point_Simple(Light light, float4 pos) {

	float3 delta = light.pos_type - pos;
	float distance = length(delta);
	if (distance > light.geometry.w) return 0;
	float3 l = delta / distance;
	float satu = saturate(1 - distance / light.geometry.w);
	float3 light_contri = satu * light.color.rgb * light.color.w;

	if (light.others.x != -1) {
		ShadowMatrix shadow_mat = _PointLightMatrixArray[light.others.x];
		float4x4 mat0 = shadow_mat.mats[0], mat1 = shadow_mat.mats[1];
		float shadow = 1;
		
		float4 shadow_uv = mul(mat0, pos); shadow_uv.w = 1;
		int shadow_pass = step(0, shadow_uv.z);
		shadow_uv.xz *= -2 * shadow_pass + 1;
		float z = length(shadow_uv.xyz);
		shadow_uv.xyz = normalize(shadow_uv.xyz);
		shadow_uv.xy /= -shadow_uv.z + 1;

		shadow_uv.xy *= 2 * light.geometry.w;
		shadow_uv.z = -z;
		shadow_uv = mul(mat1, shadow_uv); shadow_uv /= shadow_uv.w;
		shadow_uv.y = -shadow_uv.y;
		float2 uv = shadow_uv.xy / 2 + 0.5;
		float z_cmp = SamplePointShadow(light.others.x, uv)[shadow_pass];
		if (shadow_uv.z < z_cmp - 0.01) shadow = 0;

		light_contri *= shadow;
	}


	return light_contri;
}

float3 SampleLight_Spot(Light light, float4 pos, float3 n, float3 t) {
	float3 l = normalize(pos.xyz - light.pos_type.xyz);
	float3 dir = light.geometry.xyz;
	float satu = saturate((dot(l, dir) - light.geometry.w) / (1 - light.geometry.w));
	return satu * light.color.rgb * light.color.w;
}




#endif