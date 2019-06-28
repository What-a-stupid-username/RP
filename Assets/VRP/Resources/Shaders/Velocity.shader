Shader "Hidden/VRP/Velocity"
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

				sampler2D _MainTex;
				float4 _MainTex_ST;

				float4x4 _Last_VP;
				float4x4 _VP;

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

				v2f vert(appdata v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv = TRANSFORM_TEX(v.uv, _MainTex);
					return o;
				}

				float4 frag(v2f i) : SV_Target
				{
					float4 col = tex2D(_MainTex, i.uv);
					float depth = col.x;
					float3 speed = col.yzw;

					float4 vpoint = float4(i.uv * 2 - 1, depth, 1);


					float4 wpoint;
					wpoint = mul(_VP, vpoint); wpoint /= wpoint.w;
					wpoint.xyz -= speed;

					float4 lvpoint = mul(_Last_VP, wpoint);

					lvpoint /= lvpoint.w;
					lvpoint = (lvpoint + 1) * 0.5;

					return float4(depth, i.uv - lvpoint.xy, 0);
				}

			ENDCG
		}
	}
}
