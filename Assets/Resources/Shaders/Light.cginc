struct Light
{
	float4 pos_type;  // XYZ(position)W(type)
	float4 geometry;  // XYZ(normalized direction xyz)W(radio)
	float4 color;     // XYZ(color)W(strength)
	float4 others;   // NULL
};

struct ShadowCascadeMatrix
{
	float4x4 mats[4];
};


StructuredBuffer<Light> _LightBuffer;

int _MaxCascadeNum;

StructuredBuffer<ShadowCascadeMatrix> _Shadowcascade_matrix_vp;

int _LightIndex[64];

int _LightSum;

float4 _DirctionalShadowSplitDistance;

UNITY_DECLARE_TEX2DARRAY(_ShadowArray);

inline float4 SampleDirctionalShadow(int index, float2 uv) {
	return UNITY_SAMPLE_TEX2DARRAY(_ShadowArray, float3(uv, index));
}



float3 SampleLight_Dir(int cascade, Light light, float4 pos, float3 n, float3 t, float3 v) {
	float3 light_contri = saturate(dot(light.pos_type.xyz, n)) * light.color.rgb * light.color.w;
	float3 biot = cross(n, t); biot *= 0.01; t *= 0.01;

	if (light.others.x != -1 && cascade < _MaxCascadeNum) {
		float4x4 shadow_mat = _Shadowcascade_matrix_vp[light.others.x].mats[cascade];
		float shadow = 0;
		for (int i = -3; i <= 3; i++) {
			for (int j = -3; j <= 3; j++) {
				float4 shadow_uv = mul(shadow_mat, pos + float4(t * i + biot * j,0)); shadow_uv /= shadow_uv.w;
				shadow_uv.y = -shadow_uv.y;
				float2 uv = shadow_uv.xy / 2 + 0.5;
				float z_cmp = SampleDirctionalShadow(light.others.x, uv)[cascade];
				if (shadow_uv.z < z_cmp - 0.002) shadow += 1;
			}
		}
		shadow = 1 - shadow / 49;
		light_contri *= shadow;
	}
	return light_contri;
}