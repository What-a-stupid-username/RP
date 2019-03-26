#ifndef VRP_GI_CGINC
#define VRP_GI_CGINC

#include "SH.cginc"

float4 _GI_Volume_Params;

#ifdef _Enable_B_GI

Texture3D<float4> _GIVolume_0;
SamplerState sampler_GIVolume_0;

Texture3D<float4> _GIVolume_1;
SamplerState sampler_GIVolume_1;

Texture3D<float4> _GIVolume_2;
SamplerState sampler_GIVolume_2;

Texture3D<float4> _GIVolume_3;
SamplerState sampler_GIVolume_3;

Texture3D<float4> _GIVolume_4;
SamplerState sampler_GIVolume_4;

Texture3D<float4> _GIVolume_5;
SamplerState sampler_GIVolume_5;

Texture3D<float4> _GIVolume_6;
SamplerState sampler_GIVolume_6;


float3 GI_Diffuse(float3 worldPos, float3 normal) {
	float3 gi_position = worldPos -_WorldSpaceCameraPos;
	gi_position /= _GI_Volume_Params.x; gi_position += 0.5;
	gi_position = saturate(gi_position);

	float3 res = 0;

	SH9 sh9 = SHCosineLobe(normal);

	float4 encode_sh0 = _GIVolume_0.SampleLevel(sampler_GIVolume_0, gi_position, 0);
	float4 encode_sh1 = _GIVolume_1.SampleLevel(sampler_GIVolume_1, gi_position, 0);

	res += sh9.c[0] * encode_sh0.xyz;
	res += sh9.c[1] * float3(encode_sh0.w, encode_sh1.xy);

	encode_sh0 = _GIVolume_2.SampleLevel(sampler_GIVolume_2, gi_position, 0);

	res += sh9.c[2] * float3(encode_sh1.zw, encode_sh0.x);

	encode_sh1 = _GIVolume_3.SampleLevel(sampler_GIVolume_3, gi_position, 0);

	res += sh9.c[3] * encode_sh0.yzw;

	res += sh9.c[4] * encode_sh1.xyz;

	encode_sh0 = _GIVolume_4.SampleLevel(sampler_GIVolume_4, gi_position, 0);

	res += sh9.c[5] * float3(encode_sh1.w, encode_sh0.xy);

	encode_sh1 = _GIVolume_5.SampleLevel(sampler_GIVolume_5, gi_position, 0);

	res += sh9.c[6] * float3(encode_sh0.zw, encode_sh1.x);

	encode_sh0 = _GIVolume_6.SampleLevel(sampler_GIVolume_6, gi_position, 0);

	res += sh9.c[7] * encode_sh1.yzw;

	res += sh9.c[8] * encode_sh0.xyz;

	return res;
}
#endif



//this function should never be used!!! Just for test using.
/*
StructuredBuffer<float4> posBuffer;
StructuredBuffer<float4> shBuffer;
float3 GI_Diffuse_(float3 worldPos, float3 normal) {
	float3 gi_position = worldPos;// -_WorldSpaceCameraPos;

	float3 res = 0;

	SH9 sh9 = SHCosineLobe(normal);

	float3 k[9]; float ws = 0;
	for (int i = 0; i < 9; i++)
	{
		k[i] = 0;
	}
	for (int i = 0; i < 201; i++)
	{
		float dis = distance(posBuffer[i].xyz, gi_position);

		float weight = 1 / pow(10, dis);

		for (int j = 0; j < 9; j++)
		{
			k[j] += shBuffer[i * 9 + j].xyz * weight;
		}
		ws += weight;
	}

	for (int i = 0; i < 9; i++)
	{
		res += sh9.c[i] * k[i];
	}

	return res / ws;
}
*/



#endif