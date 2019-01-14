using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

namespace vrp
{
    public class VRPAsset : RenderPipelineAsset
    {
        [Header("Shadow")]
        [Range(1, 4)]
        public int cascadeNum = 4;
        [Range(1f, 10f)]
        public float cascadeDistribution = 1.2f;
        public uint shadowResolution = 4096;
        public float shadowDistance = 50;



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
