using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

namespace vrp
{

#if UNITY_EDITOR
    public class VRPDebuger
    {
        [MenuItem("VRP/SwitchRP %&s")]
        static void CreateAsset()
        {
            if (GraphicsSettings.renderPipelineAsset == null)
            {
                var ins = Resources.Load<VRPAsset>("NewVRPAsset");
                if (ins == null)
                {
                    Debug.LogError("Can't find defalut asset.");
                    ins = VRPAsset.CreateAsset();
                }
                GraphicsSettings.renderPipelineAsset = ins;
            }
            else
            {
                GraphicsSettings.renderPipelineAsset = null;
            }
        }

    }
#endif


    public class VRPAsset : RenderPipelineAsset
    {
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
