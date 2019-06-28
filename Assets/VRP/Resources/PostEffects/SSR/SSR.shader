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
			sampler2D _NormalSmoothness;
			float4x4 _ProjMat;

			float4 frag(v2f i) : SV_Target
			{
				float d = Depth(0, i.uv).x;
				float4 ns = tex2D(_NormalSmoothness, i.uv);
				
				if (d <= 0.00001) return float4(1, 0, 1, 0);

				float z = D2Z(_ProjMat, d);
				float2 xy = (i.uv * 2 - 1) * z / float2(_ProjMat._11, _ProjMat._22);
				float3 pos_v = float3(xy, z);
				float3 viewDir_v = pos_v;
				float3 normal_v = ns.xyz;
				pos_v += normal_v * 0.0001;
				float3 reflect_v = reflect(viewDir_v, normal_v);

				int iterNum; float2 hitUV;
				if (HiZTrace(_ProjMat, pos_v, reflect_v, hitUV, iterNum)) {
					return float4(V2S(_ProjMat, pos_v) - i.uv,0,0);

					//return tex2D(_SceneColor, hitUV);
					return float4(hitUV, 0, 0);
				}
				//return (float)iterNum / 64;
				return 1;// float4(hitUV, 0, 0);

				//float3 pos = HiZTrace(p, float3(0, -1, 0), iterNum);
				//return tex2D(_SceneColor, pos.xy);
				//return lerp(float4(0, 0, 1, 0), float4(1, 0, 0, 0), (float)iterNum / 64);
				//return float4(pos.xy, 0, 0);
				//return float4(i.uv, 0, 0);
				//return float4(pos.xy - i.uv, 0, 0);
			}
		ENDCG
		}
	}
}
