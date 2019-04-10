using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;

namespace vrp
{
    public class ShadowResources
    {
        private class ShaderPropertyID
        {
            public int dirShadowArray;
            public int pointShadowArray;
            public int shadowSlipDistance;
            public int shadowcascade_matrix_vp;
            public int pointLightMatrixArray;
            public int dirShadowResolution;
            public int maxCascadeNum;
            public int dirctionalShadowSplitDistance;
            public int shadow_mat;
            public int shadow_mat2;
            public int shadow_Range;
            public ShaderPropertyID()
            {
                dirShadowArray = Shader.PropertyToID("_DirShadowArray");
                pointShadowArray = Shader.PropertyToID("_PointShadowArray"); 
                shadowSlipDistance = Shader.PropertyToID("_ShadowSlipDistance");
                shadowcascade_matrix_vp = Shader.PropertyToID("_Shadowcascade_matrix_vp");
                pointLightMatrixArray = Shader.PropertyToID("_PointLightMatrixArray");
                dirShadowResolution = Shader.PropertyToID("_DirShadowResolution");
                maxCascadeNum = Shader.PropertyToID("_MaxCascadeNum");
                dirctionalShadowSplitDistance = Shader.PropertyToID("_DirctionalShadowSplitDistance");
                shadow_mat = Shader.PropertyToID("_Shadow_mat");
                shadow_mat2 = Shader.PropertyToID("_Shadow_mat2");
                shadow_Range = Shader.PropertyToID("_Shadow_Range");
            }
        };

        private static readonly ShaderPropertyID shaderPropertyID = new ShaderPropertyID();


        VRPAsset m_asset;


        GameObject helper_;
        public Camera helper;
        
        public VRenderTextureArray m_DirShadowArray;
        public VRenderTextureArray m_PointShadowArray;


        struct ShadowCascadeMatrix
        {
            public Matrix4x4 a, b, c, d;
        }
        public VComputeBuffer m_shadowcascade_matrix_vp;

        public VComputeBuffer m_pointLightMatrix;

        class CascadeHelper
        {
            Matrix4x4 proj_mat;
            Vector4 ori;
            List<Vector4>[] cons;
            int num;
            public CascadeHelper(Matrix4x4 proj, Vector4 origin, int sliptNum)
            {
                proj_mat = proj;
                ori = origin; ori.w = 1;
                num = sliptNum < 1 ? 1 : sliptNum;
                num = num > 4 ? 4 : num;
                cons = new List<Vector4>[num];
            }

            public float[] GetCascadeVolum(Matrix4x4 w2l, int index)
            {
                Vector3 Max(Vector3 a, Vector3 b)
                {
                    Vector3 res;
                    res.x = a.x > b.x ? a.x : b.x;
                    res.y = a.y > b.y ? a.y : b.y;
                    res.z = a.z > b.z ? a.z : b.z;
                    return res;
                }
                Vector3 Min(Vector3 a, Vector3 b)
                {
                    Vector3 res;
                    res.x = a.x < b.x ? a.x : b.x;
                    res.y = a.y < b.y ? a.y : b.y;
                    res.z = a.z < b.z ? a.z : b.z;
                    return res;
                }
                Vector3 bbmin = w2l * ori;
                Vector3 bbmax = bbmin;

                for (int i = 0; i < 4; i++)
                {
                    Vector3 p = w2l * cons[index][i];
                    bbmax = Max(p, bbmax);
                    bbmin = Min(p, bbmin);
                }
                Vector4 newOri = (bbmin + bbmax) / 2;
                newOri.z = bbmin.z;newOri.w = 1;
                newOri = w2l.inverse * newOri;

                float[] ret = new float[6];
                ret[0] = newOri.x;ret[1] = newOri.y;ret[2] = newOri.z;
                ret[3] = bbmax.x - bbmin.x;ret[4] = bbmax.y - bbmin.y;ret[5] = bbmax.z - bbmin.z;

                return ret;
            }

            public Vector4 SplitVolum(float distribution, float distance)
            {
                Vector4 res = new Vector4(-1, -1, -1, -1);
                float d = 1.0f / num;

                cons[0] = new List<Vector4>();
                cons[0].Add(ori);

                Vector4 ld = proj_mat * new Vector4(-1, -1, 0, 1f); ld /= ld.w;
                Vector4 lu = proj_mat * new Vector4(-1, 1, 0, 1f); lu /= lu.w;
                Vector4 rd = proj_mat * new Vector4(1, -1, 0, 1f); rd /= rd.w;
                Vector4 ru = proj_mat * new Vector4(1, 1, 0, 1f); ru /= ru.w;
                Vector4 ldv = (ld - ori).normalized * distance;
                Vector4 luv = (lu - ori).normalized * distance;
                Vector4 rdv = (rd - ori).normalized * distance;
                Vector4 ruv = (ru - ori).normalized * distance;
                Vector4 dir = (ldv + ruv).normalized;
                float dotforward = Vector3.Dot(dir, ldv.normalized);
                ldv /= dotforward;
                luv /= dotforward;
                rdv /= dotforward;
                ruv /= dotforward;

                for (int i = 0; i < num; i++)
                {
                    float nd = Mathf.Pow((i+1) * d, distribution);
                    Vector4 pp = dir * nd * distance + ori;pp.w = 1;
                    pp = proj_mat.inverse * pp;
                    pp /= pp.w;
                    res[i] = pp.z;

                    cons[i] = new List<Vector4>(4);
                    cons[i].Add(ori + ldv * nd);
                    cons[i].Add(ori + luv * nd);
                    cons[i].Add(ori + ruv * nd);
                    cons[i].Add(ori + rdv * nd);
                }
                return res;
            }
        }

        public void UpdatePointLights(ref Dictionary<Light, int> light_table, ref ScriptableRenderContext renderContext, List<Light> plights, Camera camera, ref CommandBuffer setup_properties)
        {
            //todo: now will update every light for every camera, which is not totally necessary.
            if (helper_ == null) return;
            if (plights.Count == 0) return;
            Transform helper_trans = helper_.transform;

            m_PointShadowArray.TestNeedModify((int)m_asset.pointShadowResolution, (int)m_asset.pointShadowResolution, plights.Count);
            if (m_PointShadowArray.IsValid())
                setup_properties.SetGlobalTexture(shaderPropertyID.pointShadowArray, m_PointShadowArray.data);

            m_pointLightMatrix.TestNeedModify(plights.Count);
            if (m_pointLightMatrix.IsValid())
                setup_properties.SetGlobalBuffer(shaderPropertyID.pointLightMatrixArray, m_pointLightMatrix.data);
            

            helper_trans.up = Vector3.up;
            helper.aspect = 1f;
            var cb = CommandBufferPool.Get("Point light shadow map");
            ShadowCascadeMatrix[] light_mats = new ShadowCascadeMatrix[plights.Count];
            string tes = m_asset.enableTessellation ? "_TES" : "";
            for (int i = 0; i < plights.Count; i++)
            {
                var light = plights[i];
                light_table[light] = i;

                helper_trans.position = light.transform.position;
                helper.orthographicSize = light.range * 2;
                helper.farClipPlane = light.range;

                cb.SetRenderTarget(m_PointShadowArray.data, 0, CubemapFace.Unknown, i);
                cb.ClearRenderTarget(true, true, Color.clear);
                renderContext.ExecuteCommandBuffer(cb);
                cb.Clear();

                helper_trans.forward = Vector3.forward;

                var mats = new ShadowCascadeMatrix();
                mats.a = helper.worldToCameraMatrix;
                mats.b = GL.GetGPUProjectionMatrix(helper.projectionMatrix, true);
                cb.SetGlobalMatrix(shaderPropertyID.shadow_mat, mats.a);
                cb.SetGlobalMatrix(shaderPropertyID.shadow_mat2, mats.b);
                cb.SetGlobalVector(shaderPropertyID.shadow_Range, new Vector4(helper.farClipPlane, helper.farClipPlane));
                renderContext.ExecuteCommandBuffer(cb);
                cb.Clear();

                var cullResults = new CullResults();
                CullResults.Cull(helper, renderContext, out cullResults);

                var filterSetting = new FilterRenderersSettings(true);
                filterSetting.renderQueueRange = RenderQueueRange.opaque;
                filterSetting.layerMask = helper.cullingMask;

                var renderSetting = new DrawRendererSettings(camera, new ShaderPassName("VRP_PS_0" + tes));
                renderSetting.sorting.flags = SortFlags.None;
                renderContext.DrawRenderers(cullResults.visibleRenderers, ref renderSetting, filterSetting);

                helper_trans.forward = -Vector3.forward;

                mats.c = helper.worldToCameraMatrix;
                mats.d = mats.b;
                cb.ClearRenderTarget(true, false, Color.clear);
                cb.SetGlobalMatrix("_Shadow_mat", mats.c);
                renderContext.ExecuteCommandBuffer(cb);
                cb.Clear();

                cullResults = new CullResults();
                CullResults.Cull(helper, renderContext, out cullResults);

                renderSetting = new DrawRendererSettings(camera, new ShaderPassName("VRP_PS_1" + tes));
                renderSetting.sorting.flags = SortFlags.None;
                renderContext.DrawRenderers(cullResults.visibleRenderers, ref renderSetting, filterSetting);

                light_mats[i] = mats;
            }
            CommandBufferPool.Release(cb);
            m_pointLightMatrix.data.SetData(light_mats);
        }

        public void UpdateDirectionalLights(ref Dictionary<Light, int> light_table, ref ScriptableRenderContext renderContext, List<Light> dirlights, Camera camera, ref CommandBuffer setup_properties)
        {
            if (helper_ == null) return;
            light_table.Clear();
            //helper.name = camera.name + "_helper";
            if (dirlights.Count == 0) return;
            Transform helper_trans = helper_.transform;
            Matrix4x4 proj_mat = GL.GetGPUProjectionMatrix(camera.projectionMatrix,false) * camera.worldToCameraMatrix;
            proj_mat = proj_mat.inverse;

            //spilt the view frustrum
            CascadeHelper cascadeHelper = new CascadeHelper(proj_mat, camera.transform.position, m_asset.cascadeNum);

            //setup property
            setup_properties.SetGlobalVector(shaderPropertyID.dirctionalShadowSplitDistance, cascadeHelper.SplitVolum(m_asset.cascadeDistribution, m_asset.shadowDistance));
            setup_properties.SetGlobalInt(shaderPropertyID.maxCascadeNum, m_asset.cascadeNum);
            setup_properties.SetGlobalVector(shaderPropertyID.dirShadowResolution, new Vector4((int)m_asset.directionalShadowResolution, (int)m_asset.directionalShadowResolution,
                                                                                               1f / (float)m_asset.directionalShadowResolution, 1f / (float)m_asset.directionalShadowResolution));

            m_DirShadowArray.TestNeedModify((int)m_asset.directionalShadowResolution, (int)m_asset.directionalShadowResolution, dirlights.Count);
            if (m_DirShadowArray.IsValid())
                setup_properties.SetGlobalTexture(shaderPropertyID.dirShadowArray, m_DirShadowArray.data);
            m_shadowcascade_matrix_vp.TestNeedModify(dirlights.Count);
            if (m_shadowcascade_matrix_vp.IsValid())
                setup_properties.SetGlobalBuffer(shaderPropertyID.shadowcascade_matrix_vp, m_shadowcascade_matrix_vp.data);

            var cb = CommandBufferPool.Get("Directional light shadowmap");
            List<ShadowCascadeMatrix> mts = new List<ShadowCascadeMatrix>();
            for (int i = 0; i < dirlights.Count; i++)
            {
                var light = dirlights[i];
                light_table[light] = i;

                Matrix4x4 l2w = light.transform.localToWorldMatrix;
                Vector4 dir = new Vector4(l2w.m02, l2w.m12, l2w.m22, 0);
                
                cb.SetRenderTarget(m_DirShadowArray.data, 0, CubemapFace.Unknown, i);
                cb.ClearRenderTarget(false, true, Color.clear);
                renderContext.ExecuteCommandBuffer(cb);
                cb.Clear();
                Matrix4x4[] mats_per_light = new Matrix4x4[4];
                for (int j = 0; j < m_asset.cascadeNum; j++)
                {
                    //correct the forward of the helper camera to light dir
                    helper_trans.forward = dir;

                    float[] bias = cascadeHelper.GetCascadeVolum(helper_trans.worldToLocalMatrix, j);
                    helper_trans.position = new Vector3(bias[0], bias[1], bias[2]) - helper_trans.forward * m_asset.shadowDistance;
                    helper.orthographicSize = bias[4] / 2;
                    helper.farClipPlane = bias[5] + m_asset.shadowDistance;
                    helper.aspect = bias[3] / bias[4];

                    cb.ClearRenderTarget(true, false, Color.clear);
                    mats_per_light[j] = GL.GetGPUProjectionMatrix(helper.projectionMatrix, true) * helper.worldToCameraMatrix;                  
                    cb.SetGlobalMatrix(shaderPropertyID.shadow_mat, mats_per_light[j]);
                    renderContext.ExecuteCommandBuffer(cb);
                    cb.Clear();
                    var cullResults = new CullResults();
                    CullResults.Cull(helper, renderContext, out cullResults);

                    var filterSetting = new FilterRenderersSettings(true);
                    filterSetting.renderQueueRange = RenderQueueRange.opaque;
                    filterSetting.layerMask = helper.cullingMask;

                    var renderSetting = new DrawRendererSettings(camera, new ShaderPassName(string.Format("VRP_DS_{0:G}",j)));
                    renderSetting.sorting.flags = SortFlags.None;
                    renderContext.DrawRenderers(cullResults.visibleRenderers, ref renderSetting, filterSetting);
                }
                var mt = new ShadowCascadeMatrix();
                mt.a = mats_per_light[0]; mt.b = mats_per_light[1]; mt.c = mats_per_light[2]; mt.d = mats_per_light[3];
                mts.Add(mt);
            }
            CommandBufferPool.Release(cb);
            m_shadowcascade_matrix_vp.data.SetData(mts);
        }




        public ShadowResources(VRPAsset asset)
        {
            helper_ = new GameObject("");
            helper_.SetActive(false);
            helper_.hideFlags = HideFlags.DontSave | HideFlags.HideInHierarchy;
            helper = helper_.AddComponent<Camera>();
            helper.orthographic = true;
            helper.nearClipPlane = 0f;
            helper.enabled = false;
            m_asset = asset;
            m_DirShadowArray = new VRenderTextureArray("dir_shadow_array", RenderTextureFormat.ARGB64, true, false, true);
            m_PointShadowArray = new VRenderTextureArray("point_shadow_array", RenderTextureFormat.RG32, true, false, true);
            m_shadowcascade_matrix_vp = new VComputeBuffer(Marshal.SizeOf(typeof(ShadowCascadeMatrix)));
            m_pointLightMatrix = new VComputeBuffer(Marshal.SizeOf(typeof(ShadowCascadeMatrix)));
        }
        public void Dispose()
        {
#if UNITY_EDITOR
            UnityEditor.EditorApplication.delayCall += () =>
            {
                GameObject.DestroyImmediate(helper_);
            };
#else
             GameObject.Destroy(helper_);
#endif
            m_DirShadowArray.Dispose();
            m_PointShadowArray.Dispose();
            m_shadowcascade_matrix_vp.Dispose();
            m_pointLightMatrix.Dispose();
        }
    }


}


