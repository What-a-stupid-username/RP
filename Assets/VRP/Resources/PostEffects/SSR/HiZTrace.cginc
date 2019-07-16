#define HIZ_START_LEVEL 4
#define HIZ_MAX_LEVEL 4

#define MAX_ITERATIONS 64

float2 _HiZBufferSize;
Texture2D _HiZDepth; SamplerState _point_clamp_sampler;

float4x4 _ProjMat;

inline float2 Depth(int mip, float2 uv) {
	return _HiZDepth.SampleLevel(_point_clamp_sampler, uv, mip);
}

inline float D2Z(float4x4 proj, float d) {
	if (d <= 0.00001) return 999999999;
	return proj._34 / (d - proj._33);
}

inline float2 D2Z(float4x4 proj, float2 d) {
	float2 res = proj._34 / (d - proj._33);
	res += (d <= 0.00001) * 999999999;
	return res;
}

inline float2 V2S(float4x4 proj, float3 viewPos) {
	float4 vp_1 = float4(viewPos, 1);
	float4 sp = mul(proj, viewPos);
	sp /= sp.w;
	return 1 - (sp * 0.5 + 0.5).xy;
}

inline float2 V2S(float4x4 proj, float3 pos_v, float3 dir_v) {
	float2 s_s = V2S(proj, pos_v);
	float2 e_s = V2S(proj, pos_v + 10 * dir_v);
	return normalize(e_s - s_s);
}

inline float2 cell(float2 ray, float2 cell_count) {
	return floor(ray.xy * cell_count);
}

inline float2 CellCount(int level) {
	return _HiZBufferSize / (level == 0.0 ? 1.0 : exp2(level));
}


bool crossed_cell_boundary(float2 cell_id_one, float2 cell_id_two) {
	return (int)cell_id_one.x != (int)cell_id_two.x || (int)cell_id_one.y != (int)cell_id_two.y;
}

float minimum_depth_plane(float2 ray, float level) {
	return Depth(level, ray.xy).x;
}



bool MoveToNext(in out float2 pos_s, const float2 dir_s, in out float3 pos_v, const float3 dir_v,
				const float2 m11m22, const float2 cell_count,
				const float2 cross_step, const float2 cross_offset) {

	float2 cell_size = 1.0 / cell_count;
	float2 cell_id = floor(pos_s / cell_size);
	float2 planes = cell_id / cell_count + cell_size * cross_step;
	float2 solutions = (planes - pos_s) / dir_s;
	float2 intersection_s = pos_s + dir_s * min(solutions.x, solutions.y);

	pos_s = intersection_s + ((solutions.x < solutions.y) ? float2(cross_offset.x, 0.0) : float2(0.0, cross_offset.y));

	float2 inersection_v = (pos_s * 2 - 1) / m11m22;

	float inter_y_div_x = inersection_v.y / inersection_v.x;

	float k = (pos_v.y - inter_y_div_x * pos_v.x) / (inter_y_div_x * dir_v.x - dir_v.y);

	pos_v += dir_v * k;

	return !(any(pos_s > 1) || any(pos_s < 0));
}

bool HiZTrace(const float4x4 projMat, in out float3 pos_v, const float3 dir_v, out float2 hitUV, out uint iterations) {
	int level = HIZ_START_LEVEL;
	
	hitUV = V2S(projMat, pos_v);
	float3 iterPosition_v = pos_v;
	float2 m11m22 = float2(projMat._11, projMat._22);

	float2 dir_s = V2S(projMat, pos_v, dir_v);

	float2 cross_step = float2(dir_s.x >= 0.0 ? 1.0 : -1.0, dir_s.y >= 0.0 ? 1.0 : -1.0);
	float2 cross_offset = cross_step * 0.00001;
	cross_step = saturate(cross_step);

	iterations = 0;
	int2 flags[HIZ_MAX_LEVEL+2];
	[UNROLL]
	for (int i = 0; i < HIZ_MAX_LEVEL+2; i++)
	{
		flags[i] = -1;
	}

	[BRANCH]
	if (dir_v.z > 0) {
		[LOOP]
		while (iterations < MAX_ITERATIONS) {
			bool hit = false;
			float3 tmp_pos_v = pos_v;
			float2 tmp_pos_s = hitUV;

			bool has_hit_on_parent_level = false;
			while (level < HIZ_MAX_LEVEL)
			{
				float2 cell_count_ = CellCount(level + 1);
				float2 cell_id_ = cell(tmp_pos_s, cell_count_);
				if (all(cell_id_ == flags[level + 1].xy))
					break;
				else {
					level += 1;
				}
			}

			float2 cell_count = CellCount(level);
			float2 cell_id = cell(tmp_pos_s, cell_count);


			float2 max_min_depth_of_cell = Depth(level, hitUV);
			float2 min_max_z_of_cell = D2Z(projMat, max_min_depth_of_cell);

			bool has_next = MoveToNext(tmp_pos_s, dir_s, tmp_pos_v, dir_v,
				m11m22, cell_count,
				cross_step, cross_offset);
			
			if (level >= 1) {
				if (tmp_pos_v.z > min_max_z_of_cell.x && pos_v.z < min_max_z_of_cell.y) hit = true;
			}
			else {
				if (tmp_pos_v.z > min_max_z_of_cell.x - 0.1 && pos_v.z < min_max_z_of_cell.x + 0.1) {
					return true;
				}
			}

			if (!hit) {
				if (!has_next) return false;
				hitUV = tmp_pos_s;
				pos_v = tmp_pos_v;
			}
			else {
				flags[level] = cell_id;
				level -= 1;
			}

			++iterations;
		}
	}
	else {
		return false;
		//[LOOP]
		//while (iterations < MAX_ITERATIONS) {
		//	bool hit = false;
		//	float3 tmp_pos_v = pos_v;
		//	float2 tmp_pos_s = hitUV;

		//	bool has_hit_on_parent_level = false;
		//	while (level < HIZ_MAX_LEVEL)
		//	{
		//		float2 cell_count_ = CellCount(level + 1);
		//		float2 cell_id_ = cell(tmp_pos_s, cell_count_);
		//		if (all(cell_id_ == flags[level + 1].xy))
		//			break;
		//		else {
		//			level += 1;
		//		}
		//	}

		//	float2 cell_count = CellCount(level);
		//	float2 cell_id = cell(tmp_pos_s, cell_count);


		//	float2 max_min_depth_of_cell = Depth(level, hitUV);
		//	float2 min_max_z_of_cell = D2Z(projMat, max_min_depth_of_cell);

		//	bool has_next = MoveToNext(tmp_pos_s, dir_s, tmp_pos_v, dir_v,
		//		m11m22, cell_count,
		//		cross_step, cross_offset);

		//	if (level >= 1) {
		//		if (tmp_pos_v.z < min_max_z_of_cell.x && pos_v.z > min_max_z_of_cell.y) hit = true;
		//	}
		//	else {
		//		if (tmp_pos_v.z < min_max_z_of_cell.x - 0.1 && pos_v.z > min_max_z_of_cell.x + 0.1) {
		//			return true;
		//		}
		//	}

		//	if (!hit) {
		//		if (!has_next) return false;
		//		hitUV = tmp_pos_s;
		//		pos_v = tmp_pos_v;
		//	}
		//	else {
		//		flags[level] = cell_id;
		//		level -= 1;
		//	}
		//	++iterations;
		//}
	}

	return false;
}

inline half distanceSquared(half2 A, half2 B)
{
	A -= B;
	return dot(A, A);
}
bool intersectsDepthBuffer(half rayZMin, half rayZMax, half sceneZ, half layerThickness)
{
	return (rayZMax >= sceneZ - layerThickness) && (rayZMin <= sceneZ);
}
void swap(inout half v0, inout half v1)
{
	half temp = v0;
	v0 = v1;
	v1 = temp;
}

void rayIterations(sampler2D forntDepth, in bool traceBehind_Old, in bool traceBehind, inout half2 P, inout half stepDirection, inout half end, inout int stepCount, inout int maxSteps, inout bool intersecting,
	inout half sceneZ, inout half2 dP, inout half3 Q, inout half3 dQ, inout half k, inout half dk,
	inout half rayZMin, inout half rayZMax, inout half prevZMaxEstimate, inout bool permute, inout half2 hitPixel,
	half2 invSize, inout half layerThickness)
{
	bool stop = intersecting;

	for (; (P.x * stepDirection) <= end && stepCount < maxSteps && !stop; P += dP, Q.z += dQ.z, k += dk, stepCount += 1)
	{
		rayZMin = prevZMaxEstimate;
		rayZMax = (dQ.z * 0.5 + Q.z) / (dk * 0.5 + k);
		prevZMaxEstimate = rayZMax;

		if (rayZMin > rayZMax) {
			swap(rayZMin, rayZMax);
		}

		hitPixel = permute ? P.yx : P;
		sceneZ = tex2Dlod(forntDepth, half4(hitPixel * invSize, 0, 0)).r;
		sceneZ = -LinearEyeDepth(sceneZ);
		bool isBehind = (rayZMin <= sceneZ);

		if (traceBehind_Old == 1) {
			intersecting = isBehind && (rayZMax >= sceneZ - layerThickness);
		}
		else {
			intersecting = (rayZMax >= sceneZ - layerThickness);
		}

		stop = traceBehind ? intersecting : isBehind;
	}
	P -= dP, Q.z -= dQ.z, k -= dk;
}

bool Linear2D_Trace(sampler2D forntDepth, half3 csOrigin, half3 csDirection, half4x4 projectMatrix, half2 csZBufferSize, half jitter, int maxSteps, half layerThickness, 
	half traceDistance, in out half2 hitPixel,int stepSize, bool traceBehind, in out half3 csHitPoint, in out half stepCount)
{

	half2 invSize = half2(1 / csZBufferSize.x, 1 / csZBufferSize.y);
	hitPixel = half2(-1, -1);

	half nearPlaneZ = -0.01;
	half rayLength = ((csOrigin.z + csDirection.z * traceDistance) > nearPlaneZ) ? ((nearPlaneZ - csOrigin.z) / csDirection.z) : traceDistance;
	half3 csEndPoint = csDirection * rayLength + csOrigin;
	half4 H0 = mul(projectMatrix, half4(csOrigin, 1));
	half4 H1 = mul(projectMatrix, half4(csEndPoint, 1));
	half k0 = 1 / H0.w;
	half k1 = 1 / H1.w;
	half2 P0 = H0.xy * k0;
	half2 P1 = H1.xy * k1;
	half3 Q0 = csOrigin * k0;
	half3 Q1 = csEndPoint * k1;

#if 1
	half yMax = csZBufferSize.y - 0.5;
	half yMin = 0.5;
	half xMax = csZBufferSize.x - 0.5;
	half xMin = 0.5;
	half alpha = 0;

	if (P1.y > yMax || P1.y < yMin)
	{
		half yClip = (P1.y > yMax) ? yMax : yMin;
		half yAlpha = (P1.y - yClip) / (P1.y - P0.y);
		alpha = yAlpha;
	}
	if (P1.x > xMax || P1.x < xMin)
	{
		half xClip = (P1.x > xMax) ? xMax : xMin;
		half xAlpha = (P1.x - xClip) / (P1.x - P0.x);
		alpha = max(alpha, xAlpha);
	}

	P1 = lerp(P1, P0, alpha);
	k1 = lerp(k1, k0, alpha);
	Q1 = lerp(Q1, Q0, alpha);
#endif

	P1 = (distanceSquared(P0, P1) < 0.0001) ? P0 + half2(0.01, 0.01) : P1;
	half2 delta = P1 - P0;
	bool permute = false;

	if (abs(delta.x) < abs(delta.y))
	{
		permute = true;
		delta = delta.yx;
		P1 = P1.yx;
		P0 = P0.yx;
	}

	half stepDirection = sign(delta.x);
	half invdx = stepDirection / delta.x;
	half2 dP = half2(stepDirection, invdx * delta.y);
	half3 dQ = (Q1 - Q0) * invdx;
	half dk = (k1 - k0) * invdx;

	dP *= stepSize;
	dQ *= stepSize;
	dk *= stepSize;
	P0 += dP * jitter;
	Q0 += dQ * jitter;
	k0 += dk * jitter;

	half3 Q = Q0;
	half k = k0;
	half prevZMaxEstimate = csOrigin.z;
	stepCount = 0;
	half rayZMax = prevZMaxEstimate, rayZMin = prevZMaxEstimate;
	half sceneZ = 100000;
	half end = P1.x * stepDirection;
	bool intersecting = intersectsDepthBuffer(rayZMin, rayZMax, sceneZ, layerThickness);
	half2 P = P0;
	int originalStepCount = 0;

	bool traceBehind_Old = true;
	rayIterations(forntDepth, traceBehind_Old, traceBehind, P, stepDirection, end, originalStepCount, maxSteps, intersecting, sceneZ, dP, Q, dQ, k, dk, rayZMin, rayZMax, prevZMaxEstimate, permute, hitPixel, invSize, layerThickness);

	stepCount = originalStepCount;
	Q.xy += dQ.xy * stepCount;
	csHitPoint = Q * (1 / k);
	return intersecting;
}