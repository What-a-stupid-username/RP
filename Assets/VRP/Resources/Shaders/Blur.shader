Shader "Hidden/VRP/Blur"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
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

				sampler2D _MainTex;
				float4 _MainTex_ST;

				static const float ww[4] = { 19.1,15,9.2,4.4 };
				//static const float ww[4] = { 0.6f, 0.275f, 0.1f, 0.025f };

				fixed4 frag(v2f IN) : SV_Target
				{
					float4 res = 0;
					float ws = 0;
					for (int i = -3; i <= 3; i++) {
						for (int j = -3; j <= 3; j++) {
							float2 bias = float2(i, j)*0.001;
							float4 col = max(tex2D(_MainTex, IN.uv + bias),0.001);
							col = exp(-200 * col);
							float w = ww[abs(i)] * ww[abs(j)];
							res += col * w;
							ws += w;
						}
					}
					return res / ws;
					return tex2D(_MainTex, IN.uv);
				}



				v2f vert(appdata v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv = TRANSFORM_TEX(v.uv, _MainTex);
					return o;
				}


			ENDCG
		}
	}
}
