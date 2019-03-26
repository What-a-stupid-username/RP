Shader "VRP/Test_SH_Volume"
{
	Properties
	{
		_Tex("Tex N", Range(0,6)) = 0
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


					Texture3D<float4> _GIVolume_0;
					SamplerState sampler_GIVolume_0;
					Texture3D<float4> _GIVolume_1;
					SamplerState sampler_GIVolume_1;
					Texture3D<float4> _GIVolume_2;
					SamplerState sampler_GIVolume_2;
					Texture3D<float4> _GIVolume_3;
					SamplerState sampler_GIVolume_3;
					Texture3D<float4> _GIVolume_4;
					SamplerState sampler_GIVolume_4;
					Texture3D<float4> _GIVolume_5;
					SamplerState sampler_GIVolume_5;
					Texture3D<float4> _GIVolume_6;
					SamplerState sampler_GIVolume_6;

					struct a2v {
						float4 vert : POSITION;
						float3 normal : NORMAL;
					};

					struct v2f {
						float4 pos : SV_POSITION;
						float4 objPos : TEXCOORD0;
						float4 worldPos : TEXCOORD1;
					};

					v2f vert(a2v i) {
						v2f o;
						o.pos = UnityObjectToClipPos(i.vert);
						o.objPos = i.vert;
						o.worldPos = mul(unity_ObjectToWorld, i.vert);
						return o;
					}

					int _Tex;

					float4 frag(v2f i) : SV_TARGET{

						float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
						float3 match_dir = -viewDir;
						float3 ori = i.objPos;

						float3 point_ = ori;
						float3 res;
						while (true) {
							float3 t = abs(point_);
							if (t.x > 0.5 || t.y > 0.5 || t.z > 0.5) break;
							point_ += match_dir * 0.01;

							switch (_Tex) {
							case 0:
								res += _GIVolume_0.SampleLevel(sampler_GIVolume_0, point_ + 0.5, 0);
								break;
							case 1:
								res += _GIVolume_1.SampleLevel(sampler_GIVolume_1, point_ + 0.5, 0);
								break;
							case 2:
								res += _GIVolume_2.SampleLevel(sampler_GIVolume_2, point_ + 0.5, 0);
								break;
							case 3:
								res += _GIVolume_3.SampleLevel(sampler_GIVolume_3, point_ + 0.5, 0);
								break;
							case 4:
								res += _GIVolume_4.SampleLevel(sampler_GIVolume_4, point_ + 0.5, 0);
								break;
							case 5:
								res += _GIVolume_5.SampleLevel(sampler_GIVolume_5, point_ + 0.5, 0);
								break;
							case 6:
								res += _GIVolume_6.SampleLevel(sampler_GIVolume_6, point_ + 0.5, 0);
								break;
							}

						}
						return float4(res / 100,1);
					}
				ENDCG
			}

		}
			FallBack "Diffuse"
}
