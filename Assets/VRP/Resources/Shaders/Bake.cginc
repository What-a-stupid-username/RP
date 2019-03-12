#ifndef VRP_BAKE_CGINC
#define VRP_BAKE_CGINC

#include "PBS.cginc"

struct a2v {
	float4 vert : POSITION;
	float3 normal : NORMAL;
};

struct v2f {
	float4 pos : SV_POSITION;
	float3 normal : NORMAL;
	float4 worldPos : TEXCOOD0;
};

v2f vert(a2v i) {
	v2f o;
	o.pos = UnityObjectToClipPos(i.vert);
	o.normal = UnityObjectToWorldNormal(i.normal);
	o.worldPos = mul(unity_ObjectToWorld, i.vert);
	return o;
}

float4 _Color;
float _Metallic;
float _Glossiness;

float4 frag(v2f i) : SV_TARGET{

	SurfaceInfo IN;
	IN.baseColor = _Color;
	IN.alpha = _Color.a;
	IN.metallic = _Metallic;
	IN.smoothness = _Glossiness;
	IN.normal = normalize(i.normal);
	IN.tangent = normalize(cross(i.normal,float3(0,1,1)));
	IN.worldPos = i.worldPos;
	IN.z = i.pos.z;

	float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

	return SimplePBS(IN, viewDir);
}

#endif