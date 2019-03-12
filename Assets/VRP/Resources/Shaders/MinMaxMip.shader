Shader "Hiden/MinMaxMip"
{
    Properties
	{ _MainTex("Texture", 2D) = "white" {} }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
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
                float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
            };

			sampler2D _MainTex;
			float4 _MinMax_Parameters;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

			float2 frag (v2f i) : SV_Target
            {
				float4 jwj = float4(_MinMax_Parameters.xy, -_MinMax_Parameters.xy);
                // sample the texture
				float2 col0 = tex2Dlod(_MainTex, float4(i.uv + jwj.xy, 0, _MinMax_Parameters.z));
				float2 col1 = tex2Dlod(_MainTex, float4(i.uv + jwj.xw, 0, _MinMax_Parameters.z));
				float2 col2 = tex2Dlod(_MainTex, float4(i.uv + jwj.zw, 0, _MinMax_Parameters.z));
				float2 col3 = tex2Dlod(_MainTex, float4(i.uv + jwj.zy, 0, _MinMax_Parameters.z));

				float max_ = max(max(col0, col1), max(col2, col3)).x;
				float min_ = min(min(col0, col1), min(col2, col3)).y;
				
				return float2(max_, min_);
            }
            ENDCG
        }
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
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			sampler2D _MainTex;
			float4 _MinMax_Parameters;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			float2 frag(v2f i) : SV_Target
			{
				float col = tex2D(_MainTex, i.uv).r;

				return col;
			}
			ENDCG
		}
    }
}
