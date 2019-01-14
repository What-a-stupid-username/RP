Shader "Custom/NewSurfaceShader"
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

			Pass {
				Name "VRP_BASE"
				Tags { "LightMode" = "VRP_BASE" }
				
				ZTest on
				ZWrite on

				CGPROGRAM
				// compile directives
				#pragma vertex vert
				#pragma fragment frag
				#pragma target 3.0
				#include "UnityCG.cginc"
				#include "Light.cginc"

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

				float4 frag(v2f i) : SV_TARGET {
					float3 color = 0;
					float3 normal = normalize(i.normal);
					float3 tanget = normalize(cross(i.normal,float3(0,1,1)));
					float4 worldPos = i.worldPos;
					float3 viewDir = _WorldSpaceCameraPos - i.worldPos;


					int cascade = 4 - step(_DirctionalShadowSplitDistance.x, i.pos.z) -
						step(_DirctionalShadowSplitDistance.y, i.pos.z) -
						step(_DirctionalShadowSplitDistance.z, i.pos.z) -
						step(_DirctionalShadowSplitDistance.w, i.pos.z);

					for (int it = 0; it < _LightSum; it++) {
						Light light = _LightBuffer[it];
						if (light.pos_type.w == 0) {
							color += SampleLight_Dir(cascade, light, worldPos, normal, tanget, viewDir);
						}
						else if (light.pos_type.w == 1) {
							float3 delta = light.pos_type - worldPos;
							float distance = length(delta);
							float3 l = delta / distance;
							float nl = saturate(dot(l, normal));
							float satu = saturate(1 - distance / light.geometry.w);
							color += nl * satu * light.color.rgb * light.color.w;
						}
						else if (light.pos_type.w == 2) {
							float3 l = normalize(worldPos.xyz - light.pos_type.xyz);
							float3 dir = light.geometry.xyz;
							float satu = saturate((dot(l, dir) - light.geometry.w) / (1 - light.geometry.w));
							color += satu * light.color.rgb * light.color.w;
						}
					}
					return float4(color, 1); SampleDirctionalShadow(0, i.pos);
				}










				ENDCG
			}








			// ------------------------------------------------------------
			// Surface shader code generated out of a CGPROGRAM block:


			// ---- forward rendering base pass:
			Pass {
				Name "FORWARD"
				Tags { "LightMode" = "ForwardBase" }

		CGPROGRAM
			// compile directives
			#pragma vertex vert_surf
			#pragma fragment frag_surf
			#pragma target 3.0
			#pragma multi_compile_instancing
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase
			#include "HLSLSupport.cginc"
			#define UNITY_INSTANCED_LOD_FADE
			#define UNITY_INSTANCED_SH
			#define UNITY_INSTANCED_LIGHTMAPSTS
			#include "UnityShaderVariables.cginc"
			#include "UnityShaderUtilities.cginc"
			// -------- variant for: <when no other keywords are defined>
			#if !defined(INSTANCING_ON)
			// Surface shader code generated based on:
			// writes to per-pixel normal: no
			// writes to emission: no
			// writes to occlusion: no
			// needs world space reflection vector: no
			// needs world space normal vector: no
			// needs screen space position: no
			// needs world space position: no
			// needs view direction: no
			// needs world space view direction: no
			// needs world space position for lighting: YES
			// needs world space view direction for lighting: YES
			// needs world space view direction for lightmaps: no
			// needs vertex color: no
			// needs VFACE: no
			// passes tangent-to-world matrix to pixel shader: no
			// reads from normal: no
			// 1 texcoords actually used
			//   float2 _MainTex
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			#include "AutoLight.cginc"

			#define INTERNAL_DATA
			#define WorldReflectionVector(data,normal) data.worldRefl
			#define WorldNormalVector(data,normal) normal

			// Original surface shader snippet:
			#line 13 ""
			#ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
			#endif
			/* UNITY: Original start of shader */
					// Physically based Standard lighting model, and enable shadows on all light types
					//#pragma surface surf Standard fullforwardshadows

					// Use shader model 3.0 target, to get nicer looking lighting
					//#pragma target 3.0

					sampler2D _MainTex;

					struct Input
					{
						float2 uv_MainTex;
					};

					half _Glossiness;
					half _Metallic;
					fixed4 _Color;

					// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
					// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
					// //#pragma instancing_options assumeuniformscaling
					UNITY_INSTANCING_BUFFER_START(Props)
						// put more per-instance properties here
					UNITY_INSTANCING_BUFFER_END(Props)

					void surf(Input IN, inout SurfaceOutputStandard o)
					{
						// Albedo comes from a texture tinted by color
						fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
						o.Albedo = c.rgb;
						// Metallic and smoothness come from slider variables
						o.Metallic = _Metallic;
						o.Smoothness = _Glossiness;
						o.Alpha = c.a;
					}


					// vertex-to-fragment interpolation data
					// no lightmaps:
					#ifndef LIGHTMAP_ON
					// half-precision fragment shader registers:
					#ifdef UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS
					#define FOG_COMBINED_WITH_WORLD_POS
					struct v2f_surf {
					  UNITY_POSITION(pos);
					  float2 pack0 : TEXCOORD0; // _MainTex
					  float3 worldNormal : TEXCOORD1;
					  float4 worldPos : TEXCOORD2;
					  #if UNITY_SHOULD_SAMPLE_SH
					  half3 sh : TEXCOORD3; // SH
					  #endif
					  UNITY_LIGHTING_COORDS(4,5)
					  #if SHADER_TARGET >= 30
					  float4 lmap : TEXCOORD6;
					  #endif
					  UNITY_VERTEX_INPUT_INSTANCE_ID
					  UNITY_VERTEX_OUTPUT_STEREO
					};
					#endif
					// high-precision fragment shader registers:
					#ifndef UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS
					struct v2f_surf {
					  UNITY_POSITION(pos);
					  float2 pack0 : TEXCOORD0; // _MainTex
					  float3 worldNormal : TEXCOORD1;
					  float3 worldPos : TEXCOORD2;
					  #if UNITY_SHOULD_SAMPLE_SH
					  half3 sh : TEXCOORD3; // SH
					  #endif
					  UNITY_FOG_COORDS(4)
					  UNITY_SHADOW_COORDS(5)
					  #if SHADER_TARGET >= 30
					  float4 lmap : TEXCOORD6;
					  #endif
					  UNITY_VERTEX_INPUT_INSTANCE_ID
					  UNITY_VERTEX_OUTPUT_STEREO
					};
					#endif
					#endif
					// with lightmaps:
					#ifdef LIGHTMAP_ON
					// half-precision fragment shader registers:
					#ifdef UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS
					#define FOG_COMBINED_WITH_WORLD_POS
					struct v2f_surf {
					  UNITY_POSITION(pos);
					  float2 pack0 : TEXCOORD0; // _MainTex
					  float3 worldNormal : TEXCOORD1;
					  float4 worldPos : TEXCOORD2;
					  float4 lmap : TEXCOORD3;
					  UNITY_LIGHTING_COORDS(4,5)
					  UNITY_VERTEX_INPUT_INSTANCE_ID
					  UNITY_VERTEX_OUTPUT_STEREO
					};
					#endif
					// high-precision fragment shader registers:
					#ifndef UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS
					struct v2f_surf {
					  UNITY_POSITION(pos);
					  float2 pack0 : TEXCOORD0; // _MainTex
					  float3 worldNormal : TEXCOORD1;
					  float3 worldPos : TEXCOORD2;
					  float4 lmap : TEXCOORD3;
					  UNITY_FOG_COORDS(4)
					  UNITY_SHADOW_COORDS(5)
					  #ifdef DIRLIGHTMAP_COMBINED
					  float3 tSpace0 : TEXCOORD6;
					  float3 tSpace1 : TEXCOORD7;
					  float3 tSpace2 : TEXCOORD8;
					  #endif
					  UNITY_VERTEX_INPUT_INSTANCE_ID
					  UNITY_VERTEX_OUTPUT_STEREO
					};
					#endif
					#endif
					float4 _MainTex_ST;

					// vertex shader
					v2f_surf vert_surf(appdata_full v) {
					  UNITY_SETUP_INSTANCE_ID(v);
					  v2f_surf o;
					  UNITY_INITIALIZE_OUTPUT(v2f_surf,o);
					  UNITY_TRANSFER_INSTANCE_ID(v,o);
					  UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
					  o.pos = UnityObjectToClipPos(v.vertex);
					  o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
					  float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
					  float3 worldNormal = UnityObjectToWorldNormal(v.normal);
					  #if defined(LIGHTMAP_ON) && defined(DIRLIGHTMAP_COMBINED)
					  fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
					  fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
					  fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
					  #endif
					  #if defined(LIGHTMAP_ON) && defined(DIRLIGHTMAP_COMBINED) && !defined(UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS)
					  o.tSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
					  o.tSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
					  o.tSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
					  #endif
					  o.worldPos.xyz = worldPos;
					  o.worldNormal = worldNormal;
					  #ifdef DYNAMICLIGHTMAP_ON
					  o.lmap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
					  #endif
					  #ifdef LIGHTMAP_ON
					  o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
					  #endif

					  // SH/ambient and vertex lights
					  #ifndef LIGHTMAP_ON
						#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
						  o.sh = 0;
						  // Approximated illumination from non-important point lights
						  #ifdef VERTEXLIGHT_ON
							o.sh += Shade4PointLights(
							  unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
							  unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
							  unity_4LightAtten0, worldPos, worldNormal);
						  #endif
						  o.sh = ShadeSHPerVertex(worldNormal, o.sh);
						#endif
					  #endif // !LIGHTMAP_ON

					  UNITY_TRANSFER_LIGHTING(o,v.texcoord1.xy); // pass shadow and, possibly, light cookie coordinates to pixel shader
					  #ifdef FOG_COMBINED_WITH_TSPACE
						UNITY_TRANSFER_FOG_COMBINED_WITH_TSPACE(o,o.pos); // pass fog coordinates to pixel shader
					  #elif defined (FOG_COMBINED_WITH_WORLD_POS)
						UNITY_TRANSFER_FOG_COMBINED_WITH_WORLD_POS(o,o.pos); // pass fog coordinates to pixel shader
					  #else
						UNITY_TRANSFER_FOG(o,o.pos); // pass fog coordinates to pixel shader
					  #endif
					  return o;
					}

					// fragment shader
					fixed4 frag_surf(v2f_surf IN) : SV_Target {
					  UNITY_SETUP_INSTANCE_ID(IN);
					// prepare and unpack data
					Input surfIN;
					#ifdef FOG_COMBINED_WITH_TSPACE
					  UNITY_EXTRACT_FOG_FROM_TSPACE(IN);
					#elif defined (FOG_COMBINED_WITH_WORLD_POS)
					  UNITY_EXTRACT_FOG_FROM_WORLD_POS(IN);
					#else
					  UNITY_EXTRACT_FOG(IN);
					#endif
					UNITY_INITIALIZE_OUTPUT(Input,surfIN);
					surfIN.uv_MainTex.x = 1.0;
					surfIN.uv_MainTex = IN.pack0.xy;
					float3 worldPos = IN.worldPos.xyz;
					#ifndef USING_DIRECTIONAL_LIGHT
					  fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
					#else
					  fixed3 lightDir = _WorldSpaceLightPos0.xyz;
					#endif
					float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
					#ifdef UNITY_COMPILER_HLSL
					SurfaceOutputStandard o = (SurfaceOutputStandard)0;
					#else
					SurfaceOutputStandard o;
					#endif
					o.Albedo = 0.0;
					o.Emission = 0.0;
					o.Alpha = 0.0;
					o.Occlusion = 1.0;
					fixed3 normalWorldVertex = fixed3(0,0,1);
					o.Normal = IN.worldNormal;
					normalWorldVertex = IN.worldNormal;

					// call surface function
					surf(surfIN, o);

					// compute lighting & shadowing factor
					UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
					fixed4 c = 0;

					// Setup lighting environment
					UnityGI gi;
					UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
					gi.indirect.diffuse = 0;
					gi.indirect.specular = 0;
					gi.light.color = _LightColor0.rgb;
					gi.light.dir = lightDir;
					// Call GI (lightmaps/SH/reflections) lighting function
					UnityGIInput giInput;
					UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
					giInput.light = gi.light;
					giInput.worldPos = worldPos;
					giInput.worldViewDir = worldViewDir;
					giInput.atten = atten;
					#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
					  giInput.lightmapUV = IN.lmap;
					#else
					  giInput.lightmapUV = 0.0;
					#endif
					#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
					  giInput.ambient = IN.sh;
					#else
					  giInput.ambient.rgb = 0.0;
					#endif
					giInput.probeHDR[0] = unity_SpecCube0_HDR;
					giInput.probeHDR[1] = unity_SpecCube1_HDR;
					#if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
					  giInput.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
					#endif
					#ifdef UNITY_SPECCUBE_BOX_PROJECTION
					  giInput.boxMax[0] = unity_SpecCube0_BoxMax;
					  giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
					  giInput.boxMax[1] = unity_SpecCube1_BoxMax;
					  giInput.boxMin[1] = unity_SpecCube1_BoxMin;
					  giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
					#endif
					LightingStandard_GI(o, giInput, gi);

					// realtime lighting: call lighting function
					c += LightingStandard(o, worldViewDir, gi);
					UNITY_APPLY_FOG(_unity_fogCoord, c); // apply fog
					UNITY_OPAQUE_ALPHA(c.a);
					return c;
				  }


				  #endif

						// -------- variant for: INSTANCING_ON 
						#if defined(INSTANCING_ON)
						// Surface shader code generated based on:
						// writes to per-pixel normal: no
						// writes to emission: no
						// writes to occlusion: no
						// needs world space reflection vector: no
						// needs world space normal vector: no
						// needs screen space position: no
						// needs world space position: no
						// needs view direction: no
						// needs world space view direction: no
						// needs world space position for lighting: YES
						// needs world space view direction for lighting: YES
						// needs world space view direction for lightmaps: no
						// needs vertex color: no
						// needs VFACE: no
						// passes tangent-to-world matrix to pixel shader: no
						// reads from normal: no
						// 1 texcoords actually used
						//   float2 _MainTex
						#include "UnityCG.cginc"
						#include "Lighting.cginc"
						#include "UnityPBSLighting.cginc"
						#include "AutoLight.cginc"

						#define INTERNAL_DATA
						#define WorldReflectionVector(data,normal) data.worldRefl
						#define WorldNormalVector(data,normal) normal

						// Original surface shader snippet:
						#line 13 ""
						#ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
						#endif
						/* UNITY: Original start of shader */
								// Physically based Standard lighting model, and enable shadows on all light types
								//#pragma surface surf Standard fullforwardshadows

								// Use shader model 3.0 target, to get nicer looking lighting
								//#pragma target 3.0

								sampler2D _MainTex;

								struct Input
								{
									float2 uv_MainTex;
								};

								half _Glossiness;
								half _Metallic;
								fixed4 _Color;

								// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
								// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
								// //#pragma instancing_options assumeuniformscaling
								UNITY_INSTANCING_BUFFER_START(Props)
									// put more per-instance properties here
								UNITY_INSTANCING_BUFFER_END(Props)

								void surf(Input IN, inout SurfaceOutputStandard o)
								{
									// Albedo comes from a texture tinted by color
									fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
									o.Albedo = c.rgb;
									// Metallic and smoothness come from slider variables
									o.Metallic = _Metallic;
									o.Smoothness = _Glossiness;
									o.Alpha = c.a;
								}


								// vertex-to-fragment interpolation data
								// no lightmaps:
								#ifndef LIGHTMAP_ON
								// half-precision fragment shader registers:
								#ifdef UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS
								#define FOG_COMBINED_WITH_WORLD_POS
								struct v2f_surf {
								  UNITY_POSITION(pos);
								  float2 pack0 : TEXCOORD0; // _MainTex
								  float3 worldNormal : TEXCOORD1;
								  float4 worldPos : TEXCOORD2;
								  #if UNITY_SHOULD_SAMPLE_SH
								  half3 sh : TEXCOORD3; // SH
								  #endif
								  UNITY_LIGHTING_COORDS(4,5)
								  #if SHADER_TARGET >= 30
								  float4 lmap : TEXCOORD6;
								  #endif
								  UNITY_VERTEX_INPUT_INSTANCE_ID
								  UNITY_VERTEX_OUTPUT_STEREO
								};
								#endif
								// high-precision fragment shader registers:
								#ifndef UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS
								struct v2f_surf {
								  UNITY_POSITION(pos);
								  float2 pack0 : TEXCOORD0; // _MainTex
								  float3 worldNormal : TEXCOORD1;
								  float3 worldPos : TEXCOORD2;
								  #if UNITY_SHOULD_SAMPLE_SH
								  half3 sh : TEXCOORD3; // SH
								  #endif
								  UNITY_FOG_COORDS(4)
								  UNITY_SHADOW_COORDS(5)
								  #if SHADER_TARGET >= 30
								  float4 lmap : TEXCOORD6;
								  #endif
								  UNITY_VERTEX_INPUT_INSTANCE_ID
								  UNITY_VERTEX_OUTPUT_STEREO
								};
								#endif
								#endif
								// with lightmaps:
								#ifdef LIGHTMAP_ON
								// half-precision fragment shader registers:
								#ifdef UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS
								#define FOG_COMBINED_WITH_WORLD_POS
								struct v2f_surf {
								  UNITY_POSITION(pos);
								  float2 pack0 : TEXCOORD0; // _MainTex
								  float3 worldNormal : TEXCOORD1;
								  float4 worldPos : TEXCOORD2;
								  float4 lmap : TEXCOORD3;
								  UNITY_LIGHTING_COORDS(4,5)
								  UNITY_VERTEX_INPUT_INSTANCE_ID
								  UNITY_VERTEX_OUTPUT_STEREO
								};
								#endif
								// high-precision fragment shader registers:
								#ifndef UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS
								struct v2f_surf {
								  UNITY_POSITION(pos);
								  float2 pack0 : TEXCOORD0; // _MainTex
								  float3 worldNormal : TEXCOORD1;
								  float3 worldPos : TEXCOORD2;
								  float4 lmap : TEXCOORD3;
								  UNITY_FOG_COORDS(4)
								  UNITY_SHADOW_COORDS(5)
								  #ifdef DIRLIGHTMAP_COMBINED
								  float3 tSpace0 : TEXCOORD6;
								  float3 tSpace1 : TEXCOORD7;
								  float3 tSpace2 : TEXCOORD8;
								  #endif
								  UNITY_VERTEX_INPUT_INSTANCE_ID
								  UNITY_VERTEX_OUTPUT_STEREO
								};
								#endif
								#endif
								float4 _MainTex_ST;

								// vertex shader
								v2f_surf vert_surf(appdata_full v) {
								  UNITY_SETUP_INSTANCE_ID(v);
								  v2f_surf o;
								  UNITY_INITIALIZE_OUTPUT(v2f_surf,o);
								  UNITY_TRANSFER_INSTANCE_ID(v,o);
								  UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
								  o.pos = UnityObjectToClipPos(v.vertex);
								  o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
								  float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
								  float3 worldNormal = UnityObjectToWorldNormal(v.normal);
								  #if defined(LIGHTMAP_ON) && defined(DIRLIGHTMAP_COMBINED)
								  fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
								  fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
								  fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
								  #endif
								  #if defined(LIGHTMAP_ON) && defined(DIRLIGHTMAP_COMBINED) && !defined(UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS)
								  o.tSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
								  o.tSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
								  o.tSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
								  #endif
								  o.worldPos.xyz = worldPos;
								  o.worldNormal = worldNormal;
								  #ifdef DYNAMICLIGHTMAP_ON
								  o.lmap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
								  #endif
								  #ifdef LIGHTMAP_ON
								  o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
								  #endif

								  // SH/ambient and vertex lights
								  #ifndef LIGHTMAP_ON
									#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
									  o.sh = 0;
									  // Approximated illumination from non-important point lights
									  #ifdef VERTEXLIGHT_ON
										o.sh += Shade4PointLights(
										  unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
										  unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
										  unity_4LightAtten0, worldPos, worldNormal);
									  #endif
									  o.sh = ShadeSHPerVertex(worldNormal, o.sh);
									#endif
								  #endif // !LIGHTMAP_ON

								  UNITY_TRANSFER_LIGHTING(o,v.texcoord1.xy); // pass shadow and, possibly, light cookie coordinates to pixel shader
								  #ifdef FOG_COMBINED_WITH_TSPACE
									UNITY_TRANSFER_FOG_COMBINED_WITH_TSPACE(o,o.pos); // pass fog coordinates to pixel shader
								  #elif defined (FOG_COMBINED_WITH_WORLD_POS)
									UNITY_TRANSFER_FOG_COMBINED_WITH_WORLD_POS(o,o.pos); // pass fog coordinates to pixel shader
								  #else
									UNITY_TRANSFER_FOG(o,o.pos); // pass fog coordinates to pixel shader
								  #endif
								  return o;
								}

								// fragment shader
								fixed4 frag_surf(v2f_surf IN) : SV_Target {
								  UNITY_SETUP_INSTANCE_ID(IN);
								// prepare and unpack data
								Input surfIN;
								#ifdef FOG_COMBINED_WITH_TSPACE
								  UNITY_EXTRACT_FOG_FROM_TSPACE(IN);
								#elif defined (FOG_COMBINED_WITH_WORLD_POS)
								  UNITY_EXTRACT_FOG_FROM_WORLD_POS(IN);
								#else
								  UNITY_EXTRACT_FOG(IN);
								#endif
								UNITY_INITIALIZE_OUTPUT(Input,surfIN);
								surfIN.uv_MainTex.x = 1.0;
								surfIN.uv_MainTex = IN.pack0.xy;
								float3 worldPos = IN.worldPos.xyz;
								#ifndef USING_DIRECTIONAL_LIGHT
								  fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
								#else
								  fixed3 lightDir = _WorldSpaceLightPos0.xyz;
								#endif
								float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
								#ifdef UNITY_COMPILER_HLSL
								SurfaceOutputStandard o = (SurfaceOutputStandard)0;
								#else
								SurfaceOutputStandard o;
								#endif
								o.Albedo = 0.0;
								o.Emission = 0.0;
								o.Alpha = 0.0;
								o.Occlusion = 1.0;
								fixed3 normalWorldVertex = fixed3(0,0,1);
								o.Normal = IN.worldNormal;
								normalWorldVertex = IN.worldNormal;

								// call surface function
								surf(surfIN, o);

								// compute lighting & shadowing factor
								UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
								fixed4 c = 0;

								// Setup lighting environment
								UnityGI gi;
								UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
								gi.indirect.diffuse = 0;
								gi.indirect.specular = 0;
								gi.light.color = _LightColor0.rgb;
								gi.light.dir = lightDir;
								// Call GI (lightmaps/SH/reflections) lighting function
								UnityGIInput giInput;
								UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
								giInput.light = gi.light;
								giInput.worldPos = worldPos;
								giInput.worldViewDir = worldViewDir;
								giInput.atten = atten;
								#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
								  giInput.lightmapUV = IN.lmap;
								#else
								  giInput.lightmapUV = 0.0;
								#endif
								#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
								  giInput.ambient = IN.sh;
								#else
								  giInput.ambient.rgb = 0.0;
								#endif
								giInput.probeHDR[0] = unity_SpecCube0_HDR;
								giInput.probeHDR[1] = unity_SpecCube1_HDR;
								#if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
								  giInput.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
								#endif
								#ifdef UNITY_SPECCUBE_BOX_PROJECTION
								  giInput.boxMax[0] = unity_SpecCube0_BoxMax;
								  giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
								  giInput.boxMax[1] = unity_SpecCube1_BoxMax;
								  giInput.boxMin[1] = unity_SpecCube1_BoxMin;
								  giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
								#endif
								LightingStandard_GI(o, giInput, gi);

								// realtime lighting: call lighting function
								c += LightingStandard(o, worldViewDir, gi);
								UNITY_APPLY_FOG(_unity_fogCoord, c); // apply fog
								UNITY_OPAQUE_ALPHA(c.a);
								return c;
							  }


							  #endif


							  ENDCG

							  }

			// ---- forward rendering additive lights pass:
			Pass {
				Name "FORWARD"
				Tags { "LightMode" = "ForwardAdd" }
				ZWrite Off Blend One One

		CGPROGRAM
								  // compile directives
								  #pragma vertex vert_surf
								  #pragma fragment frag_surf
								  #pragma target 3.0
								  #pragma multi_compile_instancing
								  #pragma multi_compile_fog
								  #pragma skip_variants INSTANCING_ON
								  #pragma multi_compile_fwdadd_fullshadows
								  #include "HLSLSupport.cginc"
								  #define UNITY_INSTANCED_LOD_FADE
								  #define UNITY_INSTANCED_SH
								  #define UNITY_INSTANCED_LIGHTMAPSTS
								  #include "UnityShaderVariables.cginc"
								  #include "UnityShaderUtilities.cginc"
								  // -------- variant for: <when no other keywords are defined>
								  #if !defined(INSTANCING_ON)
								  // Surface shader code generated based on:
								  // writes to per-pixel normal: no
								  // writes to emission: no
								  // writes to occlusion: no
								  // needs world space reflection vector: no
								  // needs world space normal vector: no
								  // needs screen space position: no
								  // needs world space position: no
								  // needs view direction: no
								  // needs world space view direction: no
								  // needs world space position for lighting: YES
								  // needs world space view direction for lighting: YES
								  // needs world space view direction for lightmaps: no
								  // needs vertex color: no
								  // needs VFACE: no
								  // passes tangent-to-world matrix to pixel shader: no
								  // reads from normal: no
								  // 1 texcoords actually used
								  //   float2 _MainTex
								  #include "UnityCG.cginc"
								  #include "Lighting.cginc"
								  #include "UnityPBSLighting.cginc"
								  #include "AutoLight.cginc"

								  #define INTERNAL_DATA
								  #define WorldReflectionVector(data,normal) data.worldRefl
								  #define WorldNormalVector(data,normal) normal

								  // Original surface shader snippet:
								  #line 13 ""
								  #ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
								  #endif
								  /* UNITY: Original start of shader */
										  // Physically based Standard lighting model, and enable shadows on all light types
										  //#pragma surface surf Standard fullforwardshadows

										  // Use shader model 3.0 target, to get nicer looking lighting
										  //#pragma target 3.0

										  sampler2D _MainTex;

										  struct Input
										  {
											  float2 uv_MainTex;
										  };

										  half _Glossiness;
										  half _Metallic;
										  fixed4 _Color;

										  // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
										  // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
										  // //#pragma instancing_options assumeuniformscaling
										  UNITY_INSTANCING_BUFFER_START(Props)
											  // put more per-instance properties here
										  UNITY_INSTANCING_BUFFER_END(Props)

										  void surf(Input IN, inout SurfaceOutputStandard o)
										  {
											  // Albedo comes from a texture tinted by color
											  fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
											  o.Albedo = c.rgb;
											  // Metallic and smoothness come from slider variables
											  o.Metallic = _Metallic;
											  o.Smoothness = _Glossiness;
											  o.Alpha = c.a;
										  }


										  // vertex-to-fragment interpolation data
										  struct v2f_surf {
											UNITY_POSITION(pos);
											float2 pack0 : TEXCOORD0; // _MainTex
											float3 worldNormal : TEXCOORD1;
											float3 worldPos : TEXCOORD2;
											UNITY_LIGHTING_COORDS(3,4)
											UNITY_FOG_COORDS(5)
											UNITY_VERTEX_INPUT_INSTANCE_ID
											UNITY_VERTEX_OUTPUT_STEREO
										  };
										  float4 _MainTex_ST;

										  // vertex shader
										  v2f_surf vert_surf(appdata_full v) {
											UNITY_SETUP_INSTANCE_ID(v);
											v2f_surf o;
											UNITY_INITIALIZE_OUTPUT(v2f_surf,o);
											UNITY_TRANSFER_INSTANCE_ID(v,o);
											UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
											o.pos = UnityObjectToClipPos(v.vertex);
											o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
											float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
											float3 worldNormal = UnityObjectToWorldNormal(v.normal);
											o.worldPos.xyz = worldPos;
											o.worldNormal = worldNormal;

											UNITY_TRANSFER_LIGHTING(o,v.texcoord1.xy); // pass shadow and, possibly, light cookie coordinates to pixel shader
											UNITY_TRANSFER_FOG(o,o.pos); // pass fog coordinates to pixel shader
											return o;
										  }

										  // fragment shader
										  fixed4 frag_surf(v2f_surf IN) : SV_Target {
											UNITY_SETUP_INSTANCE_ID(IN);
										  // prepare and unpack data
										  Input surfIN;
										  #ifdef FOG_COMBINED_WITH_TSPACE
											UNITY_EXTRACT_FOG_FROM_TSPACE(IN);
										  #elif defined (FOG_COMBINED_WITH_WORLD_POS)
											UNITY_EXTRACT_FOG_FROM_WORLD_POS(IN);
										  #else
											UNITY_EXTRACT_FOG(IN);
										  #endif
										  UNITY_INITIALIZE_OUTPUT(Input,surfIN);
										  surfIN.uv_MainTex.x = 1.0;
										  surfIN.uv_MainTex = IN.pack0.xy;
										  float3 worldPos = IN.worldPos.xyz;
										  #ifndef USING_DIRECTIONAL_LIGHT
											fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
										  #else
											fixed3 lightDir = _WorldSpaceLightPos0.xyz;
										  #endif
										  float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
										  #ifdef UNITY_COMPILER_HLSL
										  SurfaceOutputStandard o = (SurfaceOutputStandard)0;
										  #else
										  SurfaceOutputStandard o;
										  #endif
										  o.Albedo = 0.0;
										  o.Emission = 0.0;
										  o.Alpha = 0.0;
										  o.Occlusion = 1.0;
										  fixed3 normalWorldVertex = fixed3(0,0,1);
										  o.Normal = IN.worldNormal;
										  normalWorldVertex = IN.worldNormal;

										  // call surface function
										  surf(surfIN, o);
										  UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
										  fixed4 c = 0;

										  // Setup lighting environment
										  UnityGI gi;
										  UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
										  gi.indirect.diffuse = 0;
										  gi.indirect.specular = 0;
										  gi.light.color = _LightColor0.rgb;
										  gi.light.dir = lightDir;
										  gi.light.color *= atten;
										  c += LightingStandard(o, worldViewDir, gi);
										  c.a = 0.0;
										  UNITY_APPLY_FOG(_unity_fogCoord, c); // apply fog
										  UNITY_OPAQUE_ALPHA(c.a);
										  return c;
										}


										#endif


										ENDCG

										}

								  // ---- deferred shading pass:
								  Pass {
									  Name "DEFERRED"
									  Tags { "LightMode" = "Deferred" }

							  CGPROGRAM
											// compile directives
											#pragma vertex vert_surf
											#pragma fragment frag_surf
											#pragma target 3.0
											#pragma multi_compile_instancing
											#pragma exclude_renderers nomrt
											#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
											#pragma multi_compile_prepassfinal
											#include "HLSLSupport.cginc"
											#define UNITY_INSTANCED_LOD_FADE
											#define UNITY_INSTANCED_SH
											#define UNITY_INSTANCED_LIGHTMAPSTS
											#include "UnityShaderVariables.cginc"
											#include "UnityShaderUtilities.cginc"
											// -------- variant for: <when no other keywords are defined>
											#if !defined(INSTANCING_ON)
											// Surface shader code generated based on:
											// writes to per-pixel normal: no
											// writes to emission: no
											// writes to occlusion: no
											// needs world space reflection vector: no
											// needs world space normal vector: no
											// needs screen space position: no
											// needs world space position: no
											// needs view direction: no
											// needs world space view direction: no
											// needs world space position for lighting: YES
											// needs world space view direction for lighting: YES
											// needs world space view direction for lightmaps: no
											// needs vertex color: no
											// needs VFACE: no
											// passes tangent-to-world matrix to pixel shader: no
											// reads from normal: YES
											// 1 texcoords actually used
											//   float2 _MainTex
											#include "UnityCG.cginc"
											#include "Lighting.cginc"
											#include "UnityPBSLighting.cginc"

											#define INTERNAL_DATA
											#define WorldReflectionVector(data,normal) data.worldRefl
											#define WorldNormalVector(data,normal) normal

											// Original surface shader snippet:
											#line 13 ""
											#ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
											#endif
											/* UNITY: Original start of shader */
													// Physically based Standard lighting model, and enable shadows on all light types
													//#pragma surface surf Standard fullforwardshadows

													// Use shader model 3.0 target, to get nicer looking lighting
													//#pragma target 3.0

													sampler2D _MainTex;

													struct Input
													{
														float2 uv_MainTex;
													};

													half _Glossiness;
													half _Metallic;
													fixed4 _Color;

													// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
													// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
													// //#pragma instancing_options assumeuniformscaling
													UNITY_INSTANCING_BUFFER_START(Props)
														// put more per-instance properties here
													UNITY_INSTANCING_BUFFER_END(Props)

													void surf(Input IN, inout SurfaceOutputStandard o)
													{
														// Albedo comes from a texture tinted by color
														fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
														o.Albedo = c.rgb;
														// Metallic and smoothness come from slider variables
														o.Metallic = _Metallic;
														o.Smoothness = _Glossiness;
														o.Alpha = c.a;
													}


													// vertex-to-fragment interpolation data
													struct v2f_surf {
													  UNITY_POSITION(pos);
													  float2 pack0 : TEXCOORD0; // _MainTex
													  float3 worldNormal : TEXCOORD1;
													  float3 worldPos : TEXCOORD2;
													#ifndef DIRLIGHTMAP_OFF
													  half3 viewDir : TEXCOORD3;
													#endif
													  float4 lmap : TEXCOORD4;
													#ifndef LIGHTMAP_ON
													  #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
														half3 sh : TEXCOORD5; // SH
													  #endif
													#else
													  #ifdef DIRLIGHTMAP_OFF
														float4 lmapFadePos : TEXCOORD5;
													  #endif
													#endif
													  UNITY_VERTEX_INPUT_INSTANCE_ID
													  UNITY_VERTEX_OUTPUT_STEREO
													};
													float4 _MainTex_ST;

													// vertex shader
													v2f_surf vert_surf(appdata_full v) {
													  UNITY_SETUP_INSTANCE_ID(v);
													  v2f_surf o;
													  UNITY_INITIALIZE_OUTPUT(v2f_surf,o);
													  UNITY_TRANSFER_INSTANCE_ID(v,o);
													  UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
													  o.pos = UnityObjectToClipPos(v.vertex);
													  o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
													  float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
													  float3 worldNormal = UnityObjectToWorldNormal(v.normal);
													  o.worldPos.xyz = worldPos;
													  o.worldNormal = worldNormal;
													  float3 viewDirForLight = UnityWorldSpaceViewDir(worldPos);
													  #ifndef DIRLIGHTMAP_OFF
													  o.viewDir = viewDirForLight;
													  #endif
													#ifdef DYNAMICLIGHTMAP_ON
													  o.lmap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
													#else
													  o.lmap.zw = 0;
													#endif
													#ifdef LIGHTMAP_ON
													  o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
													  #ifdef DIRLIGHTMAP_OFF
														o.lmapFadePos.xyz = (mul(unity_ObjectToWorld, v.vertex).xyz - unity_ShadowFadeCenterAndType.xyz) * unity_ShadowFadeCenterAndType.w;
														o.lmapFadePos.w = (-UnityObjectToViewPos(v.vertex).z) * (1.0 - unity_ShadowFadeCenterAndType.w);
													  #endif
													#else
													  o.lmap.xy = 0;
														#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
														  o.sh = 0;
														  o.sh = ShadeSHPerVertex(worldNormal, o.sh);
														#endif
													#endif
													  return o;
													}
													#ifdef LIGHTMAP_ON
													float4 unity_LightmapFade;
													#endif
													fixed4 unity_Ambient;

													// fragment shader
													void frag_surf(v2f_surf IN,
														out half4 outGBuffer0 : SV_Target0,
														out half4 outGBuffer1 : SV_Target1,
														out half4 outGBuffer2 : SV_Target2,
														out half4 outEmission : SV_Target3
													#if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
														, out half4 outShadowMask : SV_Target4
													#endif
													) {
													  UNITY_SETUP_INSTANCE_ID(IN);
													  // prepare and unpack data
													  Input surfIN;
													  #ifdef FOG_COMBINED_WITH_TSPACE
														UNITY_EXTRACT_FOG_FROM_TSPACE(IN);
													  #elif defined (FOG_COMBINED_WITH_WORLD_POS)
														UNITY_EXTRACT_FOG_FROM_WORLD_POS(IN);
													  #else
														UNITY_EXTRACT_FOG(IN);
													  #endif
													  UNITY_INITIALIZE_OUTPUT(Input,surfIN);
													  surfIN.uv_MainTex.x = 1.0;
													  surfIN.uv_MainTex = IN.pack0.xy;
													  float3 worldPos = IN.worldPos.xyz;
													  #ifndef USING_DIRECTIONAL_LIGHT
														fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
													  #else
														fixed3 lightDir = _WorldSpaceLightPos0.xyz;
													  #endif
													  float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
													  #ifdef UNITY_COMPILER_HLSL
													  SurfaceOutputStandard o = (SurfaceOutputStandard)0;
													  #else
													  SurfaceOutputStandard o;
													  #endif
													  o.Albedo = 0.0;
													  o.Emission = 0.0;
													  o.Alpha = 0.0;
													  o.Occlusion = 1.0;
													  fixed3 normalWorldVertex = fixed3(0,0,1);
													  o.Normal = IN.worldNormal;
													  normalWorldVertex = IN.worldNormal;

													  // call surface function
													  surf(surfIN, o);
													fixed3 originalNormal = o.Normal;
													  half atten = 1;

													  // Setup lighting environment
													  UnityGI gi;
													  UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
													  gi.indirect.diffuse = 0;
													  gi.indirect.specular = 0;
													  gi.light.color = 0;
													  gi.light.dir = half3(0,1,0);
													  // Call GI (lightmaps/SH/reflections) lighting function
													  UnityGIInput giInput;
													  UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
													  giInput.light = gi.light;
													  giInput.worldPos = worldPos;
													  giInput.worldViewDir = worldViewDir;
													  giInput.atten = atten;
													  #if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
														giInput.lightmapUV = IN.lmap;
													  #else
														giInput.lightmapUV = 0.0;
													  #endif
													  #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
														giInput.ambient = IN.sh;
													  #else
														giInput.ambient.rgb = 0.0;
													  #endif
													  giInput.probeHDR[0] = unity_SpecCube0_HDR;
													  giInput.probeHDR[1] = unity_SpecCube1_HDR;
													  #if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
														giInput.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
													  #endif
													  #ifdef UNITY_SPECCUBE_BOX_PROJECTION
														giInput.boxMax[0] = unity_SpecCube0_BoxMax;
														giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
														giInput.boxMax[1] = unity_SpecCube1_BoxMax;
														giInput.boxMin[1] = unity_SpecCube1_BoxMin;
														giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
													  #endif
													  LightingStandard_GI(o, giInput, gi);

													  // call lighting function to output g-buffer
													  outEmission = LightingStandard_Deferred(o, worldViewDir, gi, outGBuffer0, outGBuffer1, outGBuffer2);
													  #if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
														outShadowMask = UnityGetRawBakedOcclusions(IN.lmap.xy, worldPos);
													  #endif
													  #ifndef UNITY_HDR_ON
													  outEmission.rgb = exp2(-outEmission.rgb);
													  #endif
													}


													#endif

													// -------- variant for: INSTANCING_ON 
													#if defined(INSTANCING_ON)
													// Surface shader code generated based on:
													// writes to per-pixel normal: no
													// writes to emission: no
													// writes to occlusion: no
													// needs world space reflection vector: no
													// needs world space normal vector: no
													// needs screen space position: no
													// needs world space position: no
													// needs view direction: no
													// needs world space view direction: no
													// needs world space position for lighting: YES
													// needs world space view direction for lighting: YES
													// needs world space view direction for lightmaps: no
													// needs vertex color: no
													// needs VFACE: no
													// passes tangent-to-world matrix to pixel shader: no
													// reads from normal: YES
													// 1 texcoords actually used
													//   float2 _MainTex
													#include "UnityCG.cginc"
													#include "Lighting.cginc"
													#include "UnityPBSLighting.cginc"

													#define INTERNAL_DATA
													#define WorldReflectionVector(data,normal) data.worldRefl
													#define WorldNormalVector(data,normal) normal

													// Original surface shader snippet:
													#line 13 ""
													#ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
													#endif
													/* UNITY: Original start of shader */
															// Physically based Standard lighting model, and enable shadows on all light types
															//#pragma surface surf Standard fullforwardshadows

															// Use shader model 3.0 target, to get nicer looking lighting
															//#pragma target 3.0

															sampler2D _MainTex;

															struct Input
															{
																float2 uv_MainTex;
															};

															half _Glossiness;
															half _Metallic;
															fixed4 _Color;

															// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
															// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
															// //#pragma instancing_options assumeuniformscaling
															UNITY_INSTANCING_BUFFER_START(Props)
																// put more per-instance properties here
															UNITY_INSTANCING_BUFFER_END(Props)

															void surf(Input IN, inout SurfaceOutputStandard o)
															{
																// Albedo comes from a texture tinted by color
																fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
																o.Albedo = c.rgb;
																// Metallic and smoothness come from slider variables
																o.Metallic = _Metallic;
																o.Smoothness = _Glossiness;
																o.Alpha = c.a;
															}


															// vertex-to-fragment interpolation data
															struct v2f_surf {
															  UNITY_POSITION(pos);
															  float2 pack0 : TEXCOORD0; // _MainTex
															  float3 worldNormal : TEXCOORD1;
															  float3 worldPos : TEXCOORD2;
															#ifndef DIRLIGHTMAP_OFF
															  half3 viewDir : TEXCOORD3;
															#endif
															  float4 lmap : TEXCOORD4;
															#ifndef LIGHTMAP_ON
															  #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
																half3 sh : TEXCOORD5; // SH
															  #endif
															#else
															  #ifdef DIRLIGHTMAP_OFF
																float4 lmapFadePos : TEXCOORD5;
															  #endif
															#endif
															  UNITY_VERTEX_INPUT_INSTANCE_ID
															  UNITY_VERTEX_OUTPUT_STEREO
															};
															float4 _MainTex_ST;

															// vertex shader
															v2f_surf vert_surf(appdata_full v) {
															  UNITY_SETUP_INSTANCE_ID(v);
															  v2f_surf o;
															  UNITY_INITIALIZE_OUTPUT(v2f_surf,o);
															  UNITY_TRANSFER_INSTANCE_ID(v,o);
															  UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
															  o.pos = UnityObjectToClipPos(v.vertex);
															  o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
															  float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
															  float3 worldNormal = UnityObjectToWorldNormal(v.normal);
															  o.worldPos.xyz = worldPos;
															  o.worldNormal = worldNormal;
															  float3 viewDirForLight = UnityWorldSpaceViewDir(worldPos);
															  #ifndef DIRLIGHTMAP_OFF
															  o.viewDir = viewDirForLight;
															  #endif
															#ifdef DYNAMICLIGHTMAP_ON
															  o.lmap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
															#else
															  o.lmap.zw = 0;
															#endif
															#ifdef LIGHTMAP_ON
															  o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
															  #ifdef DIRLIGHTMAP_OFF
																o.lmapFadePos.xyz = (mul(unity_ObjectToWorld, v.vertex).xyz - unity_ShadowFadeCenterAndType.xyz) * unity_ShadowFadeCenterAndType.w;
																o.lmapFadePos.w = (-UnityObjectToViewPos(v.vertex).z) * (1.0 - unity_ShadowFadeCenterAndType.w);
															  #endif
															#else
															  o.lmap.xy = 0;
																#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
																  o.sh = 0;
																  o.sh = ShadeSHPerVertex(worldNormal, o.sh);
																#endif
															#endif
															  return o;
															}
															#ifdef LIGHTMAP_ON
															float4 unity_LightmapFade;
															#endif
															fixed4 unity_Ambient;

															// fragment shader
															void frag_surf(v2f_surf IN,
																out half4 outGBuffer0 : SV_Target0,
																out half4 outGBuffer1 : SV_Target1,
																out half4 outGBuffer2 : SV_Target2,
																out half4 outEmission : SV_Target3
															#if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
																, out half4 outShadowMask : SV_Target4
															#endif
															) {
															  UNITY_SETUP_INSTANCE_ID(IN);
															  // prepare and unpack data
															  Input surfIN;
															  #ifdef FOG_COMBINED_WITH_TSPACE
																UNITY_EXTRACT_FOG_FROM_TSPACE(IN);
															  #elif defined (FOG_COMBINED_WITH_WORLD_POS)
																UNITY_EXTRACT_FOG_FROM_WORLD_POS(IN);
															  #else
																UNITY_EXTRACT_FOG(IN);
															  #endif
															  UNITY_INITIALIZE_OUTPUT(Input,surfIN);
															  surfIN.uv_MainTex.x = 1.0;
															  surfIN.uv_MainTex = IN.pack0.xy;
															  float3 worldPos = IN.worldPos.xyz;
															  #ifndef USING_DIRECTIONAL_LIGHT
																fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
															  #else
																fixed3 lightDir = _WorldSpaceLightPos0.xyz;
															  #endif
															  float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
															  #ifdef UNITY_COMPILER_HLSL
															  SurfaceOutputStandard o = (SurfaceOutputStandard)0;
															  #else
															  SurfaceOutputStandard o;
															  #endif
															  o.Albedo = 0.0;
															  o.Emission = 0.0;
															  o.Alpha = 0.0;
															  o.Occlusion = 1.0;
															  fixed3 normalWorldVertex = fixed3(0,0,1);
															  o.Normal = IN.worldNormal;
															  normalWorldVertex = IN.worldNormal;

															  // call surface function
															  surf(surfIN, o);
															fixed3 originalNormal = o.Normal;
															  half atten = 1;

															  // Setup lighting environment
															  UnityGI gi;
															  UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
															  gi.indirect.diffuse = 0;
															  gi.indirect.specular = 0;
															  gi.light.color = 0;
															  gi.light.dir = half3(0,1,0);
															  // Call GI (lightmaps/SH/reflections) lighting function
															  UnityGIInput giInput;
															  UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
															  giInput.light = gi.light;
															  giInput.worldPos = worldPos;
															  giInput.worldViewDir = worldViewDir;
															  giInput.atten = atten;
															  #if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
																giInput.lightmapUV = IN.lmap;
															  #else
																giInput.lightmapUV = 0.0;
															  #endif
															  #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
																giInput.ambient = IN.sh;
															  #else
																giInput.ambient.rgb = 0.0;
															  #endif
															  giInput.probeHDR[0] = unity_SpecCube0_HDR;
															  giInput.probeHDR[1] = unity_SpecCube1_HDR;
															  #if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
																giInput.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
															  #endif
															  #ifdef UNITY_SPECCUBE_BOX_PROJECTION
																giInput.boxMax[0] = unity_SpecCube0_BoxMax;
																giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
																giInput.boxMax[1] = unity_SpecCube1_BoxMax;
																giInput.boxMin[1] = unity_SpecCube1_BoxMin;
																giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
															  #endif
															  LightingStandard_GI(o, giInput, gi);

															  // call lighting function to output g-buffer
															  outEmission = LightingStandard_Deferred(o, worldViewDir, gi, outGBuffer0, outGBuffer1, outGBuffer2);
															  #if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
																outShadowMask = UnityGetRawBakedOcclusions(IN.lmap.xy, worldPos);
															  #endif
															  #ifndef UNITY_HDR_ON
															  outEmission.rgb = exp2(-outEmission.rgb);
															  #endif
															}


															#endif


															ENDCG

															}

											// ---- meta information extraction pass:
											Pass {
												Name "Meta"
												Tags { "LightMode" = "Meta" }
												Cull Off

										CGPROGRAM
																// compile directives
																#pragma vertex vert_surf
																#pragma fragment frag_surf
																#pragma target 3.0
																#pragma multi_compile_instancing
																#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
																#pragma shader_feature EDITOR_VISUALIZATION

																#include "HLSLSupport.cginc"
																#define UNITY_INSTANCED_LOD_FADE
																#define UNITY_INSTANCED_SH
																#define UNITY_INSTANCED_LIGHTMAPSTS
																#include "UnityShaderVariables.cginc"
																#include "UnityShaderUtilities.cginc"
																// -------- variant for: <when no other keywords are defined>
																#if !defined(INSTANCING_ON)
																// Surface shader code generated based on:
																// writes to per-pixel normal: no
																// writes to emission: no
																// writes to occlusion: no
																// needs world space reflection vector: no
																// needs world space normal vector: no
																// needs screen space position: no
																// needs world space position: no
																// needs view direction: no
																// needs world space view direction: no
																// needs world space position for lighting: YES
																// needs world space view direction for lighting: YES
																// needs world space view direction for lightmaps: no
																// needs vertex color: no
																// needs VFACE: no
																// passes tangent-to-world matrix to pixel shader: no
																// reads from normal: no
																// 1 texcoords actually used
																//   float2 _MainTex
																#include "UnityCG.cginc"
																#include "Lighting.cginc"
																#include "UnityPBSLighting.cginc"

																#define INTERNAL_DATA
																#define WorldReflectionVector(data,normal) data.worldRefl
																#define WorldNormalVector(data,normal) normal

																// Original surface shader snippet:
																#line 13 ""
																#ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
																#endif
																/* UNITY: Original start of shader */
																		// Physically based Standard lighting model, and enable shadows on all light types
																		//#pragma surface surf Standard fullforwardshadows

																		// Use shader model 3.0 target, to get nicer looking lighting
																		//#pragma target 3.0

																		sampler2D _MainTex;

																		struct Input
																		{
																			float2 uv_MainTex;
																		};

																		half _Glossiness;
																		half _Metallic;
																		fixed4 _Color;

																		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
																		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
																		// //#pragma instancing_options assumeuniformscaling
																		UNITY_INSTANCING_BUFFER_START(Props)
																			// put more per-instance properties here
																		UNITY_INSTANCING_BUFFER_END(Props)

																		void surf(Input IN, inout SurfaceOutputStandard o)
																		{
																			// Albedo comes from a texture tinted by color
																			fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
																			o.Albedo = c.rgb;
																			// Metallic and smoothness come from slider variables
																			o.Metallic = _Metallic;
																			o.Smoothness = _Glossiness;
																			o.Alpha = c.a;
																		}

																#include "UnityMetaPass.cginc"

																		// vertex-to-fragment interpolation data
																		struct v2f_surf {
																		  UNITY_POSITION(pos);
																		  float2 pack0 : TEXCOORD0; // _MainTex
																		  float3 worldPos : TEXCOORD1;
																		#ifdef EDITOR_VISUALIZATION
																		  float2 vizUV : TEXCOORD2;
																		  float4 lightCoord : TEXCOORD3;
																		#endif
																		  UNITY_VERTEX_INPUT_INSTANCE_ID
																		  UNITY_VERTEX_OUTPUT_STEREO
																		};
																		float4 _MainTex_ST;

																		// vertex shader
																		v2f_surf vert_surf(appdata_full v) {
																		  UNITY_SETUP_INSTANCE_ID(v);
																		  v2f_surf o;
																		  UNITY_INITIALIZE_OUTPUT(v2f_surf,o);
																		  UNITY_TRANSFER_INSTANCE_ID(v,o);
																		  UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
																		  o.pos = UnityMetaVertexPosition(v.vertex, v.texcoord1.xy, v.texcoord2.xy, unity_LightmapST, unity_DynamicLightmapST);
																		#ifdef EDITOR_VISUALIZATION
																		  o.vizUV = 0;
																		  o.lightCoord = 0;
																		  if (unity_VisualizationMode == EDITORVIZ_TEXTURE)
																			o.vizUV = UnityMetaVizUV(unity_EditorViz_UVIndex, v.texcoord.xy, v.texcoord1.xy, v.texcoord2.xy, unity_EditorViz_Texture_ST);
																		  else if (unity_VisualizationMode == EDITORVIZ_SHOWLIGHTMASK)
																		  {
																			o.vizUV = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
																			o.lightCoord = mul(unity_EditorViz_WorldToLight, mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1)));
																		  }
																		#endif
																		  o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
																		  float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
																		  float3 worldNormal = UnityObjectToWorldNormal(v.normal);
																		  o.worldPos.xyz = worldPos;
																		  return o;
																		}

																		// fragment shader
																		fixed4 frag_surf(v2f_surf IN) : SV_Target {
																		  UNITY_SETUP_INSTANCE_ID(IN);
																		// prepare and unpack data
																		Input surfIN;
																		#ifdef FOG_COMBINED_WITH_TSPACE
																		  UNITY_EXTRACT_FOG_FROM_TSPACE(IN);
																		#elif defined (FOG_COMBINED_WITH_WORLD_POS)
																		  UNITY_EXTRACT_FOG_FROM_WORLD_POS(IN);
																		#else
																		  UNITY_EXTRACT_FOG(IN);
																		#endif
																		UNITY_INITIALIZE_OUTPUT(Input,surfIN);
																		surfIN.uv_MainTex.x = 1.0;
																		surfIN.uv_MainTex = IN.pack0.xy;
																		float3 worldPos = IN.worldPos.xyz;
																		#ifndef USING_DIRECTIONAL_LIGHT
																		  fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
																		#else
																		  fixed3 lightDir = _WorldSpaceLightPos0.xyz;
																		#endif
																		#ifdef UNITY_COMPILER_HLSL
																		SurfaceOutputStandard o = (SurfaceOutputStandard)0;
																		#else
																		SurfaceOutputStandard o;
																		#endif
																		o.Albedo = 0.0;
																		o.Emission = 0.0;
																		o.Alpha = 0.0;
																		o.Occlusion = 1.0;
																		fixed3 normalWorldVertex = fixed3(0,0,1);

																		// call surface function
																		surf(surfIN, o);
																		UnityMetaInput metaIN;
																		UNITY_INITIALIZE_OUTPUT(UnityMetaInput, metaIN);
																		metaIN.Albedo = o.Albedo;
																		metaIN.Emission = o.Emission;
																	  #ifdef EDITOR_VISUALIZATION
																		metaIN.VizUV = IN.vizUV;
																		metaIN.LightCoord = IN.lightCoord;
																	  #endif
																		return UnityMetaFragment(metaIN);
																	  }


																	  #endif

																			// -------- variant for: INSTANCING_ON 
																			#if defined(INSTANCING_ON)
																			// Surface shader code generated based on:
																			// writes to per-pixel normal: no
																			// writes to emission: no
																			// writes to occlusion: no
																			// needs world space reflection vector: no
																			// needs world space normal vector: no
																			// needs screen space position: no
																			// needs world space position: no
																			// needs view direction: no
																			// needs world space view direction: no
																			// needs world space position for lighting: YES
																			// needs world space view direction for lighting: YES
																			// needs world space view direction for lightmaps: no
																			// needs vertex color: no
																			// needs VFACE: no
																			// passes tangent-to-world matrix to pixel shader: no
																			// reads from normal: no
																			// 1 texcoords actually used
																			//   float2 _MainTex
																			#include "UnityCG.cginc"
																			#include "Lighting.cginc"
																			#include "UnityPBSLighting.cginc"

																			#define INTERNAL_DATA
																			#define WorldReflectionVector(data,normal) data.worldRefl
																			#define WorldNormalVector(data,normal) normal

																			// Original surface shader snippet:
																			#line 13 ""
																			#ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
																			#endif
																			/* UNITY: Original start of shader */
																					// Physically based Standard lighting model, and enable shadows on all light types
																					//#pragma surface surf Standard fullforwardshadows

																					// Use shader model 3.0 target, to get nicer looking lighting
																					//#pragma target 3.0

																					sampler2D _MainTex;

																					struct Input
																					{
																						float2 uv_MainTex;
																					};

																					half _Glossiness;
																					half _Metallic;
																					fixed4 _Color;

																					// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
																					// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
																					// //#pragma instancing_options assumeuniformscaling
																					UNITY_INSTANCING_BUFFER_START(Props)
																						// put more per-instance properties here
																					UNITY_INSTANCING_BUFFER_END(Props)

																					void surf(Input IN, inout SurfaceOutputStandard o)
																					{
																						// Albedo comes from a texture tinted by color
																						fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
																						o.Albedo = c.rgb;
																						// Metallic and smoothness come from slider variables
																						o.Metallic = _Metallic;
																						o.Smoothness = _Glossiness;
																						o.Alpha = c.a;
																					}

																			#include "UnityMetaPass.cginc"

																					// vertex-to-fragment interpolation data
																					struct v2f_surf {
																					  UNITY_POSITION(pos);
																					  float2 pack0 : TEXCOORD0; // _MainTex
																					  float3 worldPos : TEXCOORD1;
																					#ifdef EDITOR_VISUALIZATION
																					  float2 vizUV : TEXCOORD2;
																					  float4 lightCoord : TEXCOORD3;
																					#endif
																					  UNITY_VERTEX_INPUT_INSTANCE_ID
																					  UNITY_VERTEX_OUTPUT_STEREO
																					};
																					float4 _MainTex_ST;

																					// vertex shader
																					v2f_surf vert_surf(appdata_full v) {
																					  UNITY_SETUP_INSTANCE_ID(v);
																					  v2f_surf o;
																					  UNITY_INITIALIZE_OUTPUT(v2f_surf,o);
																					  UNITY_TRANSFER_INSTANCE_ID(v,o);
																					  UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
																					  o.pos = UnityMetaVertexPosition(v.vertex, v.texcoord1.xy, v.texcoord2.xy, unity_LightmapST, unity_DynamicLightmapST);
																					#ifdef EDITOR_VISUALIZATION
																					  o.vizUV = 0;
																					  o.lightCoord = 0;
																					  if (unity_VisualizationMode == EDITORVIZ_TEXTURE)
																						o.vizUV = UnityMetaVizUV(unity_EditorViz_UVIndex, v.texcoord.xy, v.texcoord1.xy, v.texcoord2.xy, unity_EditorViz_Texture_ST);
																					  else if (unity_VisualizationMode == EDITORVIZ_SHOWLIGHTMASK)
																					  {
																						o.vizUV = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
																						o.lightCoord = mul(unity_EditorViz_WorldToLight, mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1)));
																					  }
																					#endif
																					  o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
																					  float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
																					  float3 worldNormal = UnityObjectToWorldNormal(v.normal);
																					  o.worldPos.xyz = worldPos;
																					  return o;
																					}

																					// fragment shader
																					fixed4 frag_surf(v2f_surf IN) : SV_Target {
																					  UNITY_SETUP_INSTANCE_ID(IN);
																					// prepare and unpack data
																					Input surfIN;
																					#ifdef FOG_COMBINED_WITH_TSPACE
																					  UNITY_EXTRACT_FOG_FROM_TSPACE(IN);
																					#elif defined (FOG_COMBINED_WITH_WORLD_POS)
																					  UNITY_EXTRACT_FOG_FROM_WORLD_POS(IN);
																					#else
																					  UNITY_EXTRACT_FOG(IN);
																					#endif
																					UNITY_INITIALIZE_OUTPUT(Input,surfIN);
																					surfIN.uv_MainTex.x = 1.0;
																					surfIN.uv_MainTex = IN.pack0.xy;
																					float3 worldPos = IN.worldPos.xyz;
																					#ifndef USING_DIRECTIONAL_LIGHT
																					  fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
																					#else
																					  fixed3 lightDir = _WorldSpaceLightPos0.xyz;
																					#endif
																					#ifdef UNITY_COMPILER_HLSL
																					SurfaceOutputStandard o = (SurfaceOutputStandard)0;
																					#else
																					SurfaceOutputStandard o;
																					#endif
																					o.Albedo = 0.0;
																					o.Emission = 0.0;
																					o.Alpha = 0.0;
																					o.Occlusion = 1.0;
																					fixed3 normalWorldVertex = fixed3(0,0,1);

																					// call surface function
																					surf(surfIN, o);
																					UnityMetaInput metaIN;
																					UNITY_INITIALIZE_OUTPUT(UnityMetaInput, metaIN);
																					metaIN.Albedo = o.Albedo;
																					metaIN.Emission = o.Emission;
																				  #ifdef EDITOR_VISUALIZATION
																					metaIN.VizUV = IN.vizUV;
																					metaIN.LightCoord = IN.lightCoord;
																				  #endif
																					return UnityMetaFragment(metaIN);
																				  }


																				  #endif


																				  ENDCG

																				  }

																// ---- end of surface shader generated code

															#LINE 50

		}
			FallBack "Diffuse"
}
