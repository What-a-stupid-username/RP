struct DS_a2v {
	float4 vert : POSITION;
};

struct DS_v2f {
	float4 pos : SV_POSITION;
};

float4x4 _Shadow_mat;

DS_v2f DS_vert(DS_a2v i) {
	DS_v2f o;
	o.pos = mul(_Shadow_mat, mul(unity_ObjectToWorld, i.vert));
	return o;
}

float4 DS_frag(DS_v2f i) : SV_TARGET {
	return i.pos.z;
}