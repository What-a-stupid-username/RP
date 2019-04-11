Shader "VRP/default"
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
		Tags { "RenderType" = "Opaque" }
		LOD 200

		//render pass
		Pass {
			Name "VRP_BASE"
			Tags { "LightMode" = "VRP_BASE" }
				
			ZTest on
			ZWrite off

			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma target 3.0
				#pragma multi_compile __ _Enable_GI
				#pragma multi_compile __ _GI_Only

				#include "PBS.cginc"


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

				struct Result {
					float4 sceneColor: SV_TARGET0;
					float4 baseColor_Metallic: SV_TARGET1;
					float4 normal_Roughness: SV_TARGET2;
				};

				Result frag(v2f i) {

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

					Result res;
					res.sceneColor = ComplexPBS(IN, viewDir);

					res.baseColor_Metallic.rgb = _Color;
					res.baseColor_Metallic.a = _Metallic;
					res.normal_Roughness.rgb = (IN.normal + 1) / 2;
					res.normal_Roughness.a = PerceptualRoughnessToRoughness(SmoothnessToPerceptualRoughness(_Glossiness));

					return res;
				}				
			ENDCG
		}



		//Pre Z
		Pass {
			Name "VRP_PREZ"
			Tags{ "LightMode" = "VRP_PREZ" }
							
			ZWrite on
			ZTest on
			Blend off

			CGPROGRAM
			// compile directives
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#include "UnityCG.cginc"
			#include "Light.cginc"

			struct a2v {
				float4 vert : POSITION;
			};

			struct v2f {
				float4 pos : SV_POSITION;
			};

			v2f vert(a2v i) {
				v2f o;
				o.pos = UnityObjectToClipPos(i.vert);
				return o;
			}

			float4 frag(v2f i) : SV_TARGET {
				float4 color = 0;

				//x   -  depth
				color.r = i.pos.z;
				//yzw -  velocity

				//  yzw=0 is used to point out that this object is stable(no need to calculate move speed).
				//  if you want to extend this buffer to movable objects, put move speed in yzw, they will 
				//  be filled with final velocity in camera space automatically.

				return color;
			}
			ENDCG

		}
		//Directional shadow 0
		Pass {
			Name "VRP_DS_0"
			Tags{ "LightMode" = "VRP_DS_0" }

			ZWrite on
			ZTest on
			Blend off
			ColorMask R

			CGPROGRAM
				// compile directives
				#pragma vertex DS_vert
				#pragma fragment DS_frag
				#pragma target 3.0
				#include "UnityCG.cginc"
				#include "Shadow.cginc"
			ENDCG
		}
		//Directional shadow 1
		Pass {
			Name "VRP_DS_1"
			Tags{ "LightMode" = "VRP_DS_1" }

			ZWrite on
			ZTest on
			Blend off
			ColorMask G

			CGPROGRAM
				// compile directives
				#pragma vertex DS_vert
				#pragma fragment DS_frag
				#pragma target 3.0
				#include "UnityCG.cginc"
				#include "Shadow.cginc"
			ENDCG
		}
		//Directional shadow 2
		Pass {
			Name "VRP_DS_2"
			Tags{ "LightMode" = "VRP_DS_2" }

			ZWrite on
			ZTest on
			Blend off
			ColorMask B

			CGPROGRAM
				// compile directives
				#pragma vertex DS_vert
				#pragma fragment DS_frag
				#pragma target 3.0
				#include "UnityCG.cginc"
				#include "Shadow.cginc"
			ENDCG
		}
		//Directional shadow 3
		Pass {
			Name "VRP_DS_3"
			Tags{ "LightMode" = "VRP_DS_3" }

			ZWrite on
			ZTest on
			Blend off
			ColorMask A

			CGPROGRAM
				// compile directives
				#pragma vertex DS_vert
				#pragma fragment DS_frag
				#pragma target 3.0
				#include "UnityCG.cginc"
				#include "Shadow.cginc"
			ENDCG
		}
		//Point shadow 0
		Pass{
			Name "VRP_PS_0"
			Tags{ "LightMode" = "VRP_PS_0" }

			ZWrite on
			ZTest on
			Blend off
			ColorMask R

			CGPROGRAM
				#pragma vertex PS_vert
				#pragma fragment DS_frag
				#pragma target 3.0
				#include "UnityCG.cginc"
				#include "Shadow.cginc"
			ENDCG
		}
		//Point shadow 1
		Pass{
			Name "VRP_PS_1"
			Tags{ "LightMode" = "VRP_PS_1" }

			ZWrite on
			ZTest on
			Blend off
			ColorMask G

			CGPROGRAM
				#pragma vertex PS_vert
				#pragma fragment DS_frag
				#pragma target 3.0
				#include "UnityCG.cginc"
				#include "Shadow.cginc"
			ENDCG
		}
		//Point shadow tesellation 0
		Pass{
			Name "VRP_PS_0_TES"
			Tags{ "LightMode" = "VRP_PS_0_TES" }

			ZWrite on
			ZTest on
			Blend off
			ColorMask R

			CGPROGRAM
				#pragma require tessellation tessHW
				#pragma vertex PS_tessvert
				#pragma fragment DS_frag
				#pragma domain PS_ds
				#pragma hull PS_hs
				#include "UnityCG.cginc"
				#include "Shadow.cginc"
			ENDCG
		}
		//Point shadow tesellation 1
		Pass{
			Name "VRP_PS_1_TES"
			Tags{ "LightMode" = "VRP_PS_1_TES" }

			ZWrite on
			ZTest on
			Blend off
			ColorMask G

			CGPROGRAM
				#pragma require tessellation tessHW
				#pragma vertex PS_tessvert
				#pragma fragment DS_frag
				#pragma domain PS_ds
				#pragma hull PS_hs
				#include "UnityCG.cginc"
				#include "Shadow.cginc"
			ENDCG
		}
		//bake
		Pass{
			Name "VRPBAKE"
			Tags { "LightMode" = "VRP_BAKE" }

			ZTest on
			ZWrite on

			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma target 3.0
				#include "Bake.cginc"				
			ENDCG
		}
		//bake
		Pass{
			Name "VRPGI"
			Tags { "LightMode" = "VRP_GI" }

			ZTest on
			ZWrite on
			Cull front

			CGPROGRAM
				#pragma vertex vert_gi
				#pragma fragment frag
				#pragma target 3.0
				#include "Bake.cginc"				
			ENDCG
		}
	}
	FallBack "Diffuse"
}
