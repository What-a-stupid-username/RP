#ifndef VRP_DEFAULT_CGINC
#define VRP_DEFAULT_CGINC

#include "PBS.cginc"



//------------------------------
struct a2v {
	float4 vert		: POSITION;
	float3 normal	: NORMAL;
	float3 tangent	: TANGENT;
	float2 uv0		: TEXCOORD0;
};

struct v2f {
	float4 pos		: SV_POSITION;
	float3 normal	: NORMAL;
	float3 tangent	: TANGENT;
	float4 worldPos : TEXCOOD0;
	float2 uv		: TEXCOOD1;
};

struct Result {
	float4 sceneColor: SV_TARGET0;
	float4 baseColor_Metallic: SV_TARGET1;
	float4 normal_Roughness: SV_TARGET2;
};


//------------------------------
half4       _Color;
sampler2D   _MainTex;
float4      _MainTex_ST;

#if _NORMALMAP

sampler2D   _BumpMap;
half        _BumpScale;

#endif // _NORMALMAP

#if _METALLICGLOSSMAP

sampler2D   _MetallicGlossMap;
float       _GlossMapScale;

#else

half        _Metallic;
float       _Smoothness;

#endif // _METALLICGLOSSMAP

#if _EMISSION

half4       _EmissionColor;
sampler2D   _EmissionMap;

#endif // _EMISSION



//------------------------------
half3 UnpackScaleNormalRGorAG(half4 packednormal, half bumpScale)
{
    #if defined(UNITY_NO_DXT5nm)
        half3 normal = packednormal.xyz * 2 - 1;
        #if (SHADER_TARGET >= 30)
            // SM2.0: instruction count limitation
            // SM2.0: normal scaler is not supported
            normal.xy *= bumpScale;
        #endif
        return normal;
    #else
        // This do the trick
        packednormal.x *= packednormal.w;

        half3 normal;
        normal.xy = (packednormal.xy * 2 - 1);
        #if (SHADER_TARGET >= 30)
            // SM2.0: instruction count limitation
            // SM2.0: normal scaler is not supported
            normal.xy *= bumpScale;
        #endif
        normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
        return normal;
    #endif
}

half3 UnpackScaleNormal(half4 packednormal, half bumpScale)
{
	return UnpackScaleNormalRGorAG(packednormal, bumpScale);
}



//------------------------------
v2f vert(a2v i) {
	v2f o;
	o.pos = UnityObjectToClipPos(i.vert);
#if _NORMALMAP
	o.normal = i.normal;
	o.tangent = i.tangent;
#else
	o.normal = UnityObjectToWorldNormal(i.normal);
	o.tangent = UnityObjectToWorldDir(i.tangent);
#endif // _NORMALMAP

	o.worldPos = mul(unity_ObjectToWorld, i.vert);
	o.uv.xy = TRANSFORM_TEX(i.uv0, _MainTex);
	return o;
}



SurfaceInfo GetSurfaceInfo(v2f i) {
	SurfaceInfo IN;
	float4 baseColor = _Color * tex2D(_MainTex, i.uv);
	IN.baseColor = baseColor.rgb;
	IN.alpha = baseColor.a;

#if _METALLICGLOSSMAP
	float4 m_s = tex2D(_MetallicGlossMap, i.uv);
	IN.metallic = m_s.r;
	IN.smoothness = m_s.a * _GlossMapScale;
#else
	IN.metallic = _Metallic;
	IN.smoothness = _Smoothness;
#endif

#if _NORMALMAP
	half3 normal = UnpackScaleNormal(tex2D(_BumpMap, i.uv), _BumpScale);
	float3x3 t2w = float3x3(-i.tangent, -cross(i.normal, i.tangent), i.normal);
	IN.normal = normalize(UnityObjectToWorldNormal(mul(normal, t2w)));
	IN.tangent = UnityObjectToWorldDir(i.tangent);
#else
	IN.normal = normalize(i.normal);
	IN.tangent = normalize(i.tangent);
#endif // _NORMALMAP

	IN.worldPos = i.worldPos;

	IN.z = i.pos.z;

	return IN;
}

void PrepareGBuffer(out Result res, const SurfaceInfo IN) {
	res.sceneColor = 0;

	res.baseColor_Metallic.rgb = IN.baseColor;
	res.baseColor_Metallic.a = IN.metallic;
	res.normal_Roughness.rgb = (IN.normal + 1) / 2;
	res.normal_Roughness.a = PerceptualRoughnessToRoughness(SmoothnessToPerceptualRoughness(IN.smoothness));
}

inline float3 Emmition(float2 uv) {
#if _EMISSION
	return _EmissionColor * tex2D(_EmissionMap, uv);
#else
	return 0;
#endif // _EMISSION
}

#endif