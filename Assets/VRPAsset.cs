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
        static void SwitchRP()
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
        public static void DrawBB(Matrix4x4 mat,Vector3 bbmin, Vector3 bbmax, Color color)
        {
            Vector4 a = bbmin, b = new Vector4(bbmin.x, bbmin.y, bbmax.z),
                    c = new Vector4(bbmin.x, bbmax.y, bbmax.z), d = new Vector4(bbmin.x, bbmax.y, bbmin.z);
            Vector4 e = new Vector4(bbmax.x,bbmin.y,bbmin.z), f = new Vector4(bbmax.x, bbmin.y, bbmax.z),
                    g = bbmax, h = new Vector4(bbmax.x, bbmax.y, bbmin.z);
            a.w = 1;b.w = 1;c.w = 1;d.w = 1;e.w = 1;f.w = 1;g.w = 1;h.w = 1;
            Draw8Points(mat * a,mat * b, mat * c, mat * d, mat * e, mat * f, mat * g, mat * h, color);
        }
        public static void Draw8Points(Vector4 a, Vector4 b, Vector4 c, Vector4 d,
                                Vector4 e, Vector4 f, Vector4 g, Vector4 h,
                                Color color)
        {
            Draw4Points(a, b, c, d, color);
            Draw4Points(e, f, g, h, color);
            Draw4Points(a, b, f, e, color);
            Draw4Points(b, c, g, f, color);
            Draw4Points(c, d, h, g, color);
            Draw4Points(d, a, e, h, color);
        }
        public static void Draw4Points(Vector4 a, Vector4 b, Vector4 c, Vector4 d, Color color)
        {
            Debug.DrawLine(a, b, color);
            Debug.DrawLine(b, c, color);
            Debug.DrawLine(c, d, color);
            Debug.DrawLine(d, a, color);
        }
    }
#endif


    public class VRPAsset : RenderPipelineAsset
    {
        [Header("Shadow")]
        public int cascadeNum = 3;
        [Range(0.04f,0.1f)]
        public float cascadeDistance = 0.1f;
        public uint shadowResolution = 512;



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
