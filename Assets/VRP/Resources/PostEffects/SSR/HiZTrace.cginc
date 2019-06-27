
#define HIZ_START_LEVEL 2
#define HIZ_MAX_LEVEL 11

#define HIZ_STOP_LEVEL 0
#define MAX_ITERATIONS 100


float2 _HiZBufferSize;
Texture2D _HiZDepth; SamplerState _point_clamp_sampler;

inline float2 Depth(int mip, float2 uv) {
	return 1 - _HiZDepth.SampleLevel(_point_clamp_sampler, uv, mip);
}

float2 cell(float2 ray, float2 cell_count) {
	return floor(ray.xy * cell_count);
}

float2 cell_count(int level) {
	return _HiZBufferSize / (level == 0.0 ? 1.0 : exp2(level));
}

float3 intersect_cell_boundary(float3 pos, float3 dir, float2 cell_id, float2 cell_count, float2 cross_step, float2 cross_offset) {
	float2 cell_size = 1.0 / cell_count;
	float2 planes = cell_id / cell_count + cell_size * cross_step;

	float2 solutions = (planes - pos) / dir.xy;
	float3 intersection_pos = pos + dir * min(solutions.x, solutions.y);

	intersection_pos.xy += (solutions.x < solutions.y) ? float2(cross_offset.x, 0.0) : float2(0.0, cross_offset.y);

	return intersection_pos;
}

bool crossed_cell_boundary(float2 cell_id_one, float2 cell_id_two) {
	return (int)cell_id_one.x != (int)cell_id_two.x || (int)cell_id_one.y != (int)cell_id_two.y;
}

float minimum_depth_plane(float2 ray, float level, float2 cell_count) {
	return Depth(level, ray.xy).x;
}

float3 HiZTrace(float3 p, float3 v, out uint iterations) {
	float level = HIZ_START_LEVEL;
	float3 v_z = v / v.z;
	float2 hi_z_size = cell_count(level);
	float3 ray = p;

	float2 cross_step = float2(v.x >= 0.0 ? 1.0 : -1.0, v.y >= 0.0 ? 1.0 : -1.0);
	float2 cross_offset = cross_step * 0.00001;
	cross_step = saturate(cross_step);

	float2 ray_cell = cell(ray.xy, hi_z_size.xy);
	ray = intersect_cell_boundary(ray, v, ray_cell, hi_z_size, cross_step, cross_offset);

	iterations = 0;
	[LOOP]
	while (level >= HIZ_STOP_LEVEL && iterations < MAX_ITERATIONS) {
		// get the cell number of the current ray
		float2 current_cell_count = cell_count(level);
		float2 old_cell_id = cell(ray.xy, current_cell_count);

		// get the minimum depth plane in which the current ray resides
		float min_z = minimum_depth_plane(ray.xy, level, current_cell_count);

		// intersect only if ray depth is below the minimum depth plane
		float3 tmp_ray = ray;
		if (v.z > 0) {
			float min_minus_ray = min_z - ray.z;
			tmp_ray = min_minus_ray > 0 ? ray + v_z * min_minus_ray : tmp_ray;
			float2 new_cell_id = cell(tmp_ray.xy, current_cell_count);
			if (crossed_cell_boundary(old_cell_id, new_cell_id)) {
				tmp_ray = intersect_cell_boundary(ray, v, old_cell_id, current_cell_count, cross_step, cross_offset);
				level = min(HIZ_MAX_LEVEL, level + 2.0f);
			}
			else {
				if (level == 1 && abs(min_minus_ray) > 0.0001) {
					tmp_ray = intersect_cell_boundary(ray, v, old_cell_id, current_cell_count, cross_step, cross_offset);
					level = 2;
				}
			}
		}
		else if (ray.z < min_z) {
			tmp_ray = intersect_cell_boundary(ray, v, old_cell_id, current_cell_count, cross_step, cross_offset);
			level = min(HIZ_MAX_LEVEL, level + 2.0f);
		}

		ray.xyz = tmp_ray.xyz;
		--level;

		++iterations;
	}
	return ray;
}