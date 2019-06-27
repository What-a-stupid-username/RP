using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

namespace vrp
{
    [CreateAssetMenu(menuName = "VRP/Create new asset")]
    public class VRPAsset : RenderPipelineAsset
    {
        public VRPResources resources;
        public bool MSAA = true;

        [Header("Shadow")]
        [Min(20)]
        [Tooltip("influnce all types of shadow")]//Todo: now only work with directional light
        public float shadowDistance = 50;
        [Header("Directional Light")]
        [Range(1, 4)]
        public int cascadeNum = 4;
        [Range(1f, 10f)]
        public float cascadeDistribution = 1.2f;
        [Min(256)] 
        public uint directionalShadowResolution = 4096;

        [Header("Point Light")]
        [Min(128)]
        public float pointShadowResolution = 1024;
        public bool enableTessellation = true;
        

        [Header("GI")]
        [Tooltip("This mode Only work with editor.")]
        public bool OnlyShowGI = false;
        [Tooltip("influnce all types of GI")]
        public float maxDistanceOfIndirectLight = 10;
        [Header("Realtime GI")]
        public bool enableRealtimeGI = true;
        [Tooltip("probs density(resolution of gi volume)")]
        [Range(8, 128)]
        public int realtimeGIDensity = 32;
        [Tooltip("Importance sampling of camera frustum.(Now must set to 1 because of unfixed bug.)")]
        [Range(1f, 1f)]
        public float frustumImportance = 0.6f;
        [Range(0.1f, 100f)]
        public float distributionDistanceFromCamera = 10;
        [Tooltip("Update GI probe Num in one frame.")]
        [Range(4, 300)]
        public int updateNumPerFrame = 20;
        [Header("Baked GI")]
        public bool enableBakedGI = true;
        [Tooltip("update baked GI")]
        public bool updatGIInRealtime = false;


        [HideInInspector]
        private Material defaultMaterial;

        public override Material GetDefaultMaterial()
        {
            if (defaultMaterial == null)
            {
                defaultMaterial = new Material(Shader.Find("VRP/default"));
            }
            return defaultMaterial;
        }

        protected override IRenderPipeline InternalCreatePipeline()
        {
            return new VRP(this);
        }
    }
}
