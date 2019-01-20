using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

namespace vrp
{
    public class VRPAsset : RenderPipelineAsset
    {
        [Header("Directional Light")]
        [Header("Shadow")]
        [Range(1, 4)]
        public int cascadeNum = 4;
        [Range(1f, 10f)]
        public float cascadeDistribution = 1.2f;
        [Min(256)]
        public uint directionalShadowResolution = 4096;
        [Min(20)]
        public float shadowDistance = 50;
        [Header("Point Light")]
        [Min(128)]
        public float pointShadowResolution = 1024;
        public bool enableTessellation = true;

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


#if UNITY_EDITOR
        [MenuItem("VRP/new asset")]
        public static VRPAsset CreateAsset()
        {
            var instance = CreateInstance<VRPAsset>();
            AssetDatabase.CreateAsset(instance, "Assets/Resources/NewVRPAsset.asset");
            return instance;
        }
#endif

        protected override IRenderPipeline InternalCreatePipeline()
        {
            return new VRP(this);
        }
    }
}
