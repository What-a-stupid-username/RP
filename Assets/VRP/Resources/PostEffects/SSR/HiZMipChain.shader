Shader "VRP/Post/HiZMipChain"
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

			Texture2D _MainTex; SamplerState _point_clamp_sampler;
			float _HiZGenerationParemeters;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

			float2 frag (v2f i) : SV_Target
            {
				uint w, h, l;
				_MainTex.GetDimensions(_HiZGenerationParemeters, w, h, l);
				float2 lastTexSize = 1.0f / float2(w, h);
				_MainTex.GetDimensions(_HiZGenerationParemeters + 1, w, h, l);
				float2 currentTexSize = 1.0f / float2(w, h);

				float2 lastUV = (floor(i.uv / currentTexSize) * 2 + 1) * lastTexSize;

				float4 jwj = float4(lastTexSize.xy, -lastTexSize.xy) / 2;
                // sample the texture
				float2 col0 = _MainTex.SampleLevel(_point_clamp_sampler, lastUV + jwj.xy, _HiZGenerationParemeters);
				float2 col1 = _MainTex.SampleLevel(_point_clamp_sampler, lastUV + jwj.xw, _HiZGenerationParemeters);
				float2 col2 = _MainTex.SampleLevel(_point_clamp_sampler, lastUV + jwj.zw, _HiZGenerationParemeters);
				float2 col3 = _MainTex.SampleLevel(_point_clamp_sampler, lastUV + jwj.zy, _HiZGenerationParemeters);

				float maxZ = max(max(col0, col1), max(col2, col3)).x;
				float minZ = min(min(col0, col1), min(col2, col3)).y;

				//float k = 0;
				//if (int((i.uv.x / currentTexSize.x) % 2 + int(i.uv.y / currentTexSize.y) % 2) % 2 == 0) {
				//	k = 1;
				//}

				return float2(maxZ, minZ);
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

			Texture2D _MainTex; SamplerState _point_clamp_sampler;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			float2 frag(v2f i) : SV_Target
			{
				float col = _MainTex.SampleLevel(_point_clamp_sampler, i.uv, 0);
				
				return float2(col, col);
			}
			ENDCG
		}Pass
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

			Texture2D _MainTex; SamplerState _point_clamp_sampler;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			float2 frag(v2f i) : SV_Target
			{
				float col = _MainTex.SampleLevel(_point_clamp_sampler, i.uv, 0);
				
				return float2(col, col);
			}
			ENDCG
		}
    }
}
