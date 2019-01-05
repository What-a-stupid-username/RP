struct LightStruct
{
	float4 pos_type;  // XYZ(position)W(type)
	float4 geometry;  // XYZ(normalized direction xyz)W(radio)
	float4 color;     // XYZ(color)W(strength)
	float4 reserve;   // NULL
};

StructuredBuffer<LightStruct> _LightBuffer;

int _LightIndex[64];

int _LightSum;