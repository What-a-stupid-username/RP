Shader "Hidden/VRP/BlitArray"
{
	Properties
	{
		
	}
		SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#include "UnityCG.cginc"
				struct appdata
				{
					float4 vertex : POSITION;
					float2 uv : TEXCOORD0;
				};

				struct v2f
				{
					float2 uv : TEXCOORD0;
					float4 vertex : SV_POSITION;
				};

				UNITY_DECLARE_TEX2DARRAY(_TexArray);
				int _ArrayIndex;

				sampler2D _MainTex; 
				float4 _MainTex_ST;

				fixed4 frag(v2f i) : SV_Target
				{
					if (step(i.uv.x, 0)) {
						discard;
					}
					if (dot(step(1, i.uv), 1)) {
						discard;
					}
					if (dot(step(abs(i.uv - 1), 0.01), 1)) {
						return fixed4(1, 0, 1, 1);
					}
					return UNITY_SAMPLE_TEX2DARRAY(_TexArray, float3(i.uv, _ArrayIndex));
				}

				v2f vert(appdata v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv = v.uv;
					o.uv.x -= 0.2 * (_ArrayIndex+1);
					o.uv *= 5;
					return o;
				}
			ENDCG
		}
	}
}
