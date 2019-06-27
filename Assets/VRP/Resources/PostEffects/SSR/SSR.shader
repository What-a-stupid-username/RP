Shader "VRP/Post/SSR"
{
	Properties
	{ _MainTex("Texture", 2D) = "white" {} }
	SubShader
	{
		Tags{ "RenderType" = "Opaque" }
		LOD 100

		CGINCLUDE

		#include "UnityCG.cginc"
		#include "HiZTrace.cginc"

		struct appdata
		{
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
		};

		struct v2f
		{
			float4 vertex : SV_POSITION;
			float2 uv : TEXCOORD0;
		};

		v2f vert(appdata v)
		{
			v2f o;
			o.vertex = UnityObjectToClipPos(v.vertex);
			o.uv = v.uv;
			return o;
		}

		ENDCG

			Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			sampler2D _SceneColor;

			float4 frag(v2f i) : SV_Target
			{
				float3 p = float3(i.uv, Depth(0, i.uv).x) + float3(0, 0.001,0);

				int iterNum;
				float3 pos = HiZTrace(p, float3(0, 1, 0.001), iterNum);
				return tex2D(_SceneColor, pos.xy);
				return iterNum / 100;
				//return float4(pos.xy, 0, 0);
				//return float4(i.uv, 0, 0);
				//return float4(pos.xy - i.uv, 0, 0);
			}
		ENDCG
		}
	}
}
