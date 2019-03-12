Shader "Unlit/MinMax_Debuger"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
			
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

			struct MinMax {
				float4 min, max;
			};
			StructuredBuffer<MinMax> _MinMax;

			float4 GetValue(float2 uv) {
				uint2 xy = uv * 32;
				MinMax k = _MinMax[xy.x * 32 + xy.y];
				float4 value1 = k.min;
				float4 value2 = k.max;
				return float4(value1.x, value2.x, 0, 1);
			}

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = GetValue(i.uv);
                return col;
            }
            ENDCG
        }
    }
}
