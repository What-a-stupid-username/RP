Shader "VRP/Test_SH_Volume"
{
	Properties
	{
	}
	SubShader
	{
		Tags{ "RenderType" = "Opaque" }
		LOD 200

		//render pass
		Pass{
			Tags{ "LightMode" = "VRP_BASE" }

			ZTest on
			ZWrite on

			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma target 4.5


				TextureCubeArray<float4> _CubeArray;
				SamplerState sampler_CubeArray;

				struct a2v {
					float4 vert : POSITION;
					float3 normal : NORMAL;
				};

				struct v2f {
					float4 pos : SV_POSITION;
					float3 normal : NORMAL;
				};

				v2f vert(a2v i) {
					v2f o;
					o.pos = UnityObjectToClipPos(i.vert);
					o.normal = i.normal;
					return o;
				}

				float4 frag(v2f i) : SV_TARGET {
					return _CubeArray.Sample(sampler_CubeArray, float4(i.normal,0));
				}
			ENDCG
		}

	}
	FallBack "Diffuse"
}
