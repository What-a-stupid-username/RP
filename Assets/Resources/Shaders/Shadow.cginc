#include "Lighting.cginc"

struct S_a2v {
	float4 vert : POSITION;
};

struct S_v2f {
	float4 pos : SV_POSITION;
};

float4x4 _Shadow_mat;
float4x4 _Shadow_mat2;
float2 _Shadow_Range;

S_v2f DS_vert(S_a2v i) {
	S_v2f o;
	o.pos = mul(_Shadow_mat, mul(unity_ObjectToWorld, i.vert));
	return o;
}


S_v2f PS_vert(S_a2v i)
{
	S_v2f o;

	o.pos = mul(_Shadow_mat, mul(unity_ObjectToWorld, i.vert));

	float z = length(o.pos.xyz);
	o.pos.xyz = normalize(o.pos.xyz);
	o.pos.xy /= -o.pos.z + 1;

	o.pos.xy *= 2 * _Shadow_Range;
	o.pos.z = -z;
	o.pos = mul(_Shadow_mat2, o.pos);

	return o;
}

//x2 + z2 = 1
//y = x / z
//y = x / sqrt(1-x2)
// x = sin(x)


float4 DS_frag(S_v2f i) : SV_TARGET {
	return i.pos.z;
}




struct PS_a2t {
	float4 vertex : INTERNALTESSPOS;
	float z : TEXCOORD0;
};


PS_a2t PS_tessvert(S_a2v i) {
	PS_a2t o;
	o.vertex = i.vert;
	float3 pos = mul(_Shadow_mat, mul(unity_ObjectToWorld, i.vert));
	float z = max(length(pos),0.01);
	z = 1 - z / _Shadow_Range;
	o.z = lerp(0, 32, z);
	return o;
}

UnityTessellationFactors PS_hsconst(InputPatch<PS_a2t, 3> v) {
	UnityTessellationFactors o;
	float4 tf;
	tf = max(max(v[0].z, v[1].z), v[2].z);
	o.edge[0] = tf.x;
	o.edge[1] = tf.y;
	o.edge[2] = tf.z;
	o.inside = tf.w;
	return o;
}

[UNITY_domain("tri")]
[UNITY_partitioning("fractional_odd")] //截断在[1,max]范围内，然后取整到下一个奇数整数值
[UNITY_outputtopology("triangle_cw")] //cw顺时针，ccw逆时针
[UNITY_patchconstantfunc("PS_hsconst")]
[UNITY_outputcontrolpoints(3)]
PS_a2t PS_hs(InputPatch<PS_a2t, 3> v, uint id : SV_OutputControlPointID) {
	return v[id];
}

[UNITY_domain("tri")]
S_a2v PS_ds(UnityTessellationFactors tessFactors, const OutputPatch<PS_a2t, 3> vi, float3 bary : SV_DomainLocation) {
	S_a2v v;

	v.vert = vi[0].vertex*bary.x + vi[1].vertex*bary.y + vi[2].vertex*bary.z;

	S_v2f o = PS_vert(v);
	return o;
}