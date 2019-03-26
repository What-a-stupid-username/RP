Shader "VRP/Test_SH_One"
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
				Tags {"LightMode" = "VRP_BASE"}

				ZTest on
				ZWrite on

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

					StructuredBuffer<float3> SH_COEFF;

					v2f vert(a2v i) {
						v2f o;
						o.pos = UnityObjectToClipPos(i.vert);

						float3 normal = i.normal;

						SH9 sh = SHCosineLobe(normal);
						float3 res = 0;
						for (int i = 0; i < 9; i++)
						{
							float c = sh.c[i];
							float3 co = SH_COEFF[i];
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
