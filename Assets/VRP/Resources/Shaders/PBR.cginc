#ifndef VRP_PBR_CGINC
#define VRP_PBR_CGINC


//-------------------------------------------------------------------------------

inline half Pow4(half x)
{
	return x * x*x*x;
}

inline float2 Pow4(float2 x)
{
	return x * x*x*x;
}

inline half3 Pow4(half3 x)
{
	return x * x*x*x;
}

inline half4 Pow4(half4 x)
{
	return x * x*x*x;
}

inline half Pow5(half x)
{
	return x * x * x*x * x;
}

inline half2 Pow5(half2 x)
{
	return x * x * x*x * x;
}

inline half3 Pow5(half3 x)
{
	return x * x * x*x * x;
}

inline half4 Pow5(half4 x)
{
	return x * x * x*x * x;
}


//-------------------------------------------------------------------------------

inline half OneMinusReflectivityFromMetallic(half metallic)
{
    // We'll need oneMinusReflectivity, so
    //   1-reflectivity = 1-lerp(dielectricSpec, 1, metallic) = lerp(1-dielectricSpec, 0, metallic)
    // store (1-dielectricSpec) in unity_ColorSpaceDielectricSpec.a, then
    //   1-reflectivity = lerp(alpha, 0, metallic) = alpha + metallic*(0 - alpha) =
    //                  = alpha - metallic * alpha
    half oneMinusDielectricSpec = unity_ColorSpaceDielectricSpec.a;
    return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
}

inline half3 DiffuseAndSpecularFromMetallic (half3 albedo, half metallic, out half3 specColor, out half oneMinusReflectivity)
{
    specColor = lerp (unity_ColorSpaceDielectricSpec.rgb, albedo, metallic);
    oneMinusReflectivity = OneMinusReflectivityFromMetallic(metallic);
    return albedo * oneMinusReflectivity;
}


inline half3 PreMultiplyAlpha (half3 diffColor, half alpha, half oneMinusReflectivity, out half outModifiedAlpha)
{
    diffColor *= alpha;
    outModifiedAlpha = 1-oneMinusReflectivity + alpha*oneMinusReflectivity;
    return diffColor;
}

inline float SmoothnessToPerceptualRoughness(float smoothness)
{
	return (1 - smoothness);
}

inline float3 Unity_SafeNormalize(float3 inVec)
{
	float dp3 = max(0.001f, dot(inVec, inVec));
	return inVec * rsqrt(dp3);
}

//-------------------------------------------------------------------------------

half DisneyDiffuse(half NdotV, half NdotL, half LdotH, half perceptualRoughness)
{
	half fd90 = 0.5 + 2 * LdotH * LdotH * perceptualRoughness;
	// Two schlick fresnel term
	half lightScatter = (1 + (fd90 - 1) * Pow5(1 - NdotL));
	half viewScatter = (1 + (fd90 - 1) * Pow5(1 - NdotV));

	return lightScatter * viewScatter;
}

inline float PerceptualRoughnessToRoughness(float perceptualRoughness)
{
	return perceptualRoughness * perceptualRoughness;
}

inline half PerceptualRoughnessToSpecPower(half perceptualRoughness)
{
	half m = PerceptualRoughnessToRoughness(perceptualRoughness);   // m is the true academic roughness.
	half sq = max(1e-4f, m*m);
	half n = (2.0 / sq) - 2.0;                          // https://dl.dropboxusercontent.com/u/55891920/papers/mm_brdf.pdf
	n = max(n, 1e-4f);                                  // prevent possible cases of pow(0,0), which could happen when roughness is 1.0 and NdotH is zero
	return n;
}

inline half3 FresnelTerm(half3 F0, half cosA)
{
	half t = Pow5(1 - cosA);   // ala Schlick interpoliation
	return F0 + (1 - F0) * t;
}

inline float SmithJointGGXVisibilityTerm(float NdotL, float NdotV, float roughness)
{
#if 0
	// Original formulation:
	//  lambda_v    = (-1 + sqrt(a2 * (1 - NdotL2) / NdotL2 + 1)) * 0.5f;
	//  lambda_l    = (-1 + sqrt(a2 * (1 - NdotV2) / NdotV2 + 1)) * 0.5f;
	//  G           = 1 / (1 + lambda_v + lambda_l);

	// Reorder code to be more optimal
	half a = roughness;
	half a2 = a * a;

	half lambdaV = NdotL * sqrt((-NdotV * a2 + NdotV) * NdotV + a2);
	half lambdaL = NdotV * sqrt((-NdotL * a2 + NdotL) * NdotL + a2);

	// Simplify visibility term: (2.0f * NdotL * NdotV) /  ((4.0f * NdotL * NdotV) * (lambda_v + lambda_l + 1e-5f));
	return 0.5f / (lambdaV + lambdaL + 1e-5f);  // This function is not intended to be running on Mobile,
												// therefore epsilon is smaller than can be represented by half
#else
	// Approximation of the above formulation (simplify the sqrt, not mathematically correct but close enough)
	float a = roughness;
	float lambdaV = NdotL * (NdotV * (1 - a) + a);
	float lambdaL = NdotV * (NdotL * (1 - a) + a);

#if defined(SHADER_API_SWITCH)
	return 0.5f / (lambdaV + lambdaL + 1e-4f); // work-around against hlslcc rounding error
#else
	return 0.5f / (lambdaV + lambdaL + 1e-5f);
#endif

#endif
}

inline float GGXTerm(float NdotH, float roughness)
{
	float a2 = roughness * roughness;
	float d = (NdotH * a2 - NdotH) * NdotH + 1.0f; // 2 mad
	return UNITY_INV_PI * a2 / (d * d + 1e-7f); // This function is not intended to be running on Mobile,
											// therefore epsilon is smaller than what can be represented by half
}

inline half3 FresnelLerp(half3 F0, half3 F90, half cosA)
{
	half t = Pow5(1 - cosA);   // ala Schlick interpoliation
	return lerp(F0, F90, t);
}

//-------------------------------------------------------------------------------



float3 BRDFLight(half3 diffColor, half3 specColor, half smoothness,
    float3 normal, float3 viewDir, float3 lightDir,
    float3 lightSatu) {
	float perceptualRoughness = SmoothnessToPerceptualRoughness(smoothness);
	float3 halfDir = Unity_SafeNormalize(lightDir + viewDir);

	half shiftAmount = dot(normal, viewDir);
	normal = shiftAmount < 0.0f ? normal + viewDir * (-shiftAmount + 1e-5f) : normal;

	float nv = saturate(dot(normal, viewDir));

	float nl = saturate(dot(normal, lightDir));
	float nh = saturate(dot(normal, halfDir));

	half lv = saturate(dot(lightDir, viewDir));
	half lh = saturate(dot(lightDir, halfDir));

	half diffuseTerm = DisneyDiffuse(nv, nl, lh, perceptualRoughness) * nl;

	float roughness = PerceptualRoughnessToRoughness(perceptualRoughness);

	roughness = max(roughness, 0.002);
	float V = SmithJointGGXVisibilityTerm(nl, nv, roughness);
	float D = GGXTerm(nh, roughness);

	float specularTerm = V * D * UNITY_PI;

	specularTerm = max(0, specularTerm * nl);

	half surfaceReduction;
	surfaceReduction = 1.0 / (roughness*roughness + 1.0);

	specularTerm *= any(specColor) ? 1.0 : 0.0;

	half3 color = diffColor * lightSatu * diffuseTerm
		+ specularTerm * lightSatu * FresnelTerm(specColor, lh);

	return half4(color, 1);
}





float3 BRDFGI(half3 diffColor, half3 specColor, half oneMinusReflectivity, half smoothness,
    float3 normal, float3 viewDir, float3 giDiffuse,
    float3 giSpecular) {

    half shiftAmount = dot(normal, viewDir);
    normal = shiftAmount < 0.0f ? normal + viewDir * (-shiftAmount + 1e-5f) : normal;

    float nv = saturate(dot(normal, viewDir));


	float perceptualRoughness = SmoothnessToPerceptualRoughness (smoothness);
    float roughness = PerceptualRoughnessToRoughness(perceptualRoughness);
	roughness = max(roughness, 0.002);

    half surfaceReduction;

	surfaceReduction = 1.0 / (roughness*roughness + 1.0);

    half grazingTerm = saturate(smoothness + (1-oneMinusReflectivity));
	return  diffColor *  giDiffuse
            + surfaceReduction * giSpecular * FresnelLerp (specColor, grazingTerm, nv);
}





float3 BRDFLight_Simple(half3 diffColor, half3 specColor, half smoothness,
	float3 normal, float3 viewDir, float3 lightDir,
	float3 lightSatu) {
	smoothness = min(smoothness, 0.9);
	float perceptualRoughness = SmoothnessToPerceptualRoughness(smoothness);
	float3 halfDir = Unity_SafeNormalize(lightDir + viewDir);

	half nv = dot(normal, viewDir);

	float nl = saturate(dot(normal, lightDir));
	float nh = saturate(dot(normal, halfDir));

	half lv = saturate(dot(lightDir, viewDir));
	half lh = saturate(dot(lightDir, halfDir));

	half diffuseTerm = nl;

	half V = nl * nv * perceptualRoughness;
	half D = GGXTerm(nh, perceptualRoughness);

	float specularTerm = V * D * UNITY_PI;

	specularTerm = max(0, specularTerm * nl);

	return  diffColor * lightSatu * diffuseTerm
			+ specularTerm * lightSatu * FresnelTerm(specColor, lh);
}

#endif