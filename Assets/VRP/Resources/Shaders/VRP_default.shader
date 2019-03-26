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
				#pragma multi_compile __ _Enable_B_GI

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

				float4 frag(v2f i) : SV_TARGET {

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



					return ComplexPBS(IN, viewDir);
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
			#include "./Light.cginc"

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
				o.normal = UnityObjectToWorldNormal(i.normal);
				return o;
			}

			float4 frag(v2f i) : SV_TARGET {
				float4 color = 0;
				float3 normal = normalize(i.normal);
				color.x = (normal.x + 1) / 2;
				color.y = (normal.y + 1) / 2;
				color.z = (normal.z + 1) / 2;
				color.w = i.pos.z;

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
	}
	FallBack "Diffuse"
}
