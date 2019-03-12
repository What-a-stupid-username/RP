#ifndef VRP_BLIT_CGINC
#define VRP_BLIT_CGINC

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

sampler2D _MainTex;
float4 _MainTex_ST;

fixed4 frag(v2f i) : SV_Target
{
	if (dot(step(0.2, i.uv),1)) {
		discard;
	}
	if (step(i.uv.x, 0)) {
		discard;
	}
	if (dot(step(abs(i.uv - 0.2), 0.002), 1)) {
		return fixed4(1, 0, 1, 1);
	}
	fixed4 col = tex2D(_MainTex, i.uv * 5);
	return col;
}

#endif