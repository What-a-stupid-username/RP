using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

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
        public static void DrawBB(Matrix4x4 mat, Vector3 bbmin, Vector3 bbmax, Color color)
        {
            Vector4 a = bbmin, b = new Vector4(bbmin.x, bbmin.y, bbmax.z),
                    c = new Vector4(bbmin.x, bbmax.y, bbmax.z), d = new Vector4(bbmin.x, bbmax.y, bbmin.z);
            Vector4 e = new Vector4(bbmax.x, bbmin.y, bbmin.z), f = new Vector4(bbmax.x, bbmin.y, bbmax.z),
                    g = bbmax, h = new Vector4(bbmax.x, bbmax.y, bbmin.z);
            a.w = 1; b.w = 1; c.w = 1; d.w = 1; e.w = 1; f.w = 1; g.w = 1; h.w = 1;
            Draw8Points(mat * a, mat * b, mat * c, mat * d, mat * e, mat * f, mat * g, mat * h, color);
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

        public static void ShowTexture(ref CommandBuffer cb, Texture texture, RenderTargetIdentifier target, int pos = 0)
        {
            var blitSmall = new Material(Shader.Find("Hidden/VRP/BlitSmall"));
            cb.Blit(texture, target, blitSmall, pos > 4 ? 4 : pos);
        }
        public static void ShowTextureArray(ref CommandBuffer cb, Texture texture, RenderTargetIdentifier target, int index = 0)
        {
            var blitSmall = new Material(Shader.Find("Hidden/VRP/BlitArray"));
            cb.SetGlobalInt("_ArrayIndex", index);
            cb.SetGlobalTexture("_TexArray", texture);
            index++;
            cb.Blit(texture, target, blitSmall);
        }


        public static void SetTextureToDebuger(RenderTexture texture)
        {
            GameObject.Find("Debug").GetComponent<VRP_Debug>().rt = texture;
        }
    }
#endif


    public class GenerateMinMaxOfTexture
    {
        public RenderTexture result;
        RenderTexture helper;
        Material m_mat;
        Texture m_tex;
        int parameters_id, result_id;
        public GenerateMinMaxOfTexture(Texture tex, string name = "")
        {
            m_mat = new Material(Shader.Find("Hiden/MinMaxMip"));
            m_tex = tex;
            result = new RenderTexture(tex.width, tex.height, 0, RenderTextureFormat.RG32, RenderTextureReadWrite.Linear);
            result.useMipMap = true;
            result.autoGenerateMips = false;
            result.anisoLevel = 0;
            result.antiAliasing = 1;
            result.filterMode = FilterMode.Point;
            result.Create();
            helper = new RenderTexture(result);
            helper.useMipMap = true;
            helper.autoGenerateMips = false;
            helper.anisoLevel = 0;
            helper.antiAliasing = 1;
            helper.filterMode = FilterMode.Point;
            helper.Create();
            parameters_id = Shader.PropertyToID("_MinMax_Parameters");
            result_id = Shader.PropertyToID(name + "_MinMax");
        }
        public void Update(CommandBuffer cb)
        {
            cb.Blit(m_tex, result, m_mat, 1);
            for (int i = 0; i < Mathf.Log(Mathf.Max(result.width, result.height), 2); i++)
            {
                cb.SetRenderTarget(i % 2 == 0 ? helper : result, i + 1);
                float scale = 1.0f / Mathf.Pow(2, i);
                cb.SetGlobalVector(parameters_id, new Vector4(0.5f / result.width * scale, 0.5f / result.height * scale, i, 0));
                cb.Blit(i % 2 == 0 ? result : helper, new RenderTargetIdentifier(BuiltinRenderTextureType.CurrentActive), m_mat, 0);
            }
            for (int i = 0; i < Mathf.Log(Mathf.Max(result.width, result.height), 2); i += 2)
            {
                cb.SetRenderTarget(result, i + 1);
                float scale = 1.0f / Mathf.Pow(2, i);
                cb.SetGlobalVector(parameters_id, new Vector4(0.5f / result.width * scale, 0.5f / result.height * scale, i, 0));
                cb.Blit(helper, new RenderTargetIdentifier(BuiltinRenderTextureType.CurrentActive));
            }
            cb.SetGlobalTexture(result_id, result);
        }

        public void Dispose()
        {
            helper.Release();
            result.Release();
        }
    }
}