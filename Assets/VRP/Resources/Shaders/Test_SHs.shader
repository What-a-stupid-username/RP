Shader "VRP/Test_SHs"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
	_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0
	}
		SubShader
	{
		Tags{ "RenderType" = "Opaque" }
		LOD 200

		//render pass
		Pass{
		ZTest on
		ZWrite on
		Blend SrcAlpha OneMinusSrcAlpha

		CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma target 4.5
#include "PBS.cginc"
#include "SH.cginc"

		struct a2v {
		float4 vert : POSITION;
		float3 normal : NORMAL;
	};

	struct v2f {
		float4 pos : SV_POSITION;
		float3 shColor : TEXCOOD1;
	};
	StructuredBuffer<int3> _SamplePos;
	StructuredBuffer<int3> _OutputSH;
	v2f vert(a2v i, uint instanceID : SV_InstanceID) {
		v2f o;
		float4 vert = i.vert / 4 + float4(_SamplePos[instanceID],0) / 16 * 10 - 5;
		vert.w = 1;
		o.pos = mul(UNITY_MATRIX_VP, vert);
		float3 normal = i.normal;

		SH9 sh = SHCosineLobe(normal);
		float3 res = 0;
		for (int j = 0; j < 9; j++)
		{
			float c = sh.c[j];
			float3 co = _OutputSH[instanceID * 9 + j] * 4.908734375e-6f;
			res += c * co;
		}
		o.shColor = res;

		return o;
	}

	float4 _Color;
	float _Metallic;
	float _Glossiness;

	float4 frag(v2f i) : SV_TARGET{
		return float4(i.shColor, 1);
	}
		ENDCG
	}

	}
		FallBack "Diffuse"
}
