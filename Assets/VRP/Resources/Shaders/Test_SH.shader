Shader "VRP/Test_SH"
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
				Name "VRP_BASE"
				Tags{ "LightMode" = "VRP_BASE" }

				ZTest on
				ZWrite on

				CGPROGRAM
					#pragma vertex vert
					#pragma fragment frag
					#pragma target 3.0
					#include "PBS.cginc"
					#include "SH.cginc"

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
					StructuredBuffer<float3> SH_COEFF;

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

						//float3 dir = (float3)SH_COEFF[0] / 10000;
						//float3 color = (float3)SH_COEFF[0] / 10000;
						//return float4(color, 1);

						SH9 sh = SHCosineLobe(IN.normal);
						float3 res = 0;
						for (int i = 0; i < 9; i++)
						{
							float c = sh.c[i];
							float3 co = SH_COEFF[i];
							res += c * co;
						}
						return float4(res ,1);
					}
				ENDCG
			}

		}
			FallBack "Diffuse"
}
