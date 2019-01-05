using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace vrp
{
    public class ShadowResources
    {
        private class ShaderPropertyID
        {
            public int shadowArray;
            public ShaderPropertyID()
            {
                shadowArray = Shader.PropertyToID("_ShadowArray");
            }
        };
        ShaderPropertyID shaderPropertyID;


        VRPAsset m_asset;


        GameObject helperCamera;
        Camera helper;

        RenderTexture shadowArray;
        int resolution = -1, texNum = 0;


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
                VRPDebuger.DrawBB(w2l.inverse, bbmin, bbmax, Color.yellow);
                Vector4 newOri = (bbmin + bbmax) / 2;
                newOri.z = bbmin.z;newOri.w = 1;
                newOri = w2l.inverse * newOri;

                float[] ret = new float[6];
                ret[0] = newOri.x;ret[1] = newOri.y;ret[2] = newOri.z;
                ret[3] = bbmax.x - bbmin.x;ret[4] = bbmax.y - bbmin.y;ret[5] = bbmax.z - bbmin.z;
                return ret;
            }

            public void SlipVolum(float distance)
            {
                float d = 1.0f / num;

                cons[0] = new List<Vector4>();
                cons[0].Add(ori);

                for (int i = 0; i < num; i++)
                {
                    float nd = 1 - Mathf.Pow((i+1) * d, distance);
                    Vector4 ld = proj_mat * new Vector4(-1, -1, nd, 1f); ld /= ld.w;
                    Vector4 lu = proj_mat * new Vector4(-1, 1, nd, 1f); lu /= lu.w;
                    Vector4 rd = proj_mat * new Vector4(1, -1, nd, 1f); rd /= rd.w;
                    Vector4 ru = proj_mat * new Vector4(1, 1, nd, 1f); ru /= ru.w;
                    cons[i] = new List<Vector4>(4);
                    cons[i].Add(ld);
                    cons[i].Add(lu);
                    cons[i].Add(rd);
                    cons[i].Add(rd);
#if UNITY_EDITOR
                   VRPDebuger.Draw4Points(ld, lu, ru, rd, Color.red * (i+1) / num);
#endif
                }
            }
        }

        public void UpdateDirectionalLights(List<Light> dirlights, Camera camera)
        {
            if (helperCamera == null) return;
            Transform helper_trans = helperCamera.transform;
            Matrix4x4 proj_mat = GL.GetGPUProjectionMatrix(camera.projectionMatrix,false) * camera.worldToCameraMatrix;
            proj_mat = proj_mat.inverse;

            //spilt the view frustrum
            CascadeHelper cascadeHelper = new CascadeHelper(proj_mat, camera.transform.position, m_asset.cascadeNum);
            cascadeHelper.SlipVolum(m_asset.cascadeDistance);

            //correct the up of the helper camera
            helper_trans.up = camera.transform.forward;

            //
            if (m_asset.shadowResolution != resolution || dirlights.Count > texNum)
            {
                resolution = (int)m_asset.shadowResolution;
                texNum = dirlights.Count;
                shadowArray = new RenderTexture(resolution, resolution, texNum, TextureFormat.ARGB32);
                
            }

            foreach (var light in dirlights)
            {
                Matrix4x4 l2w = light.transform.localToWorldMatrix;
                Vector4 dir = new Vector4(l2w.m02, l2w.m12, l2w.m22, 0);

                //correct the forward of the helper camera to light dir
                helper_trans.forward = dir;

                for (int i = 0; i < m_asset.cascadeNum; i++)
                {
                    float[] bias = cascadeHelper.GetCascadeVolum(helper_trans.worldToLocalMatrix, i);
                    helper_trans.position = new Vector3(bias[0], bias[1], bias[2]);
                    helper.orthographicSize = bias[4] / 2;
                    helper.farClipPlane = bias[5];
                    helper.aspect = bias[3] / bias[4];
                    helper.RenderWithShader()
                }






            }
            
        }




        public ShadowResources(VRPAsset asset)
        {
            shaderPropertyID = new ShaderPropertyID();
            helperCamera = new GameObject("");
            helperCamera.SetActive(false);
            helperCamera.hideFlags = HideFlags.DontSave;//| HideFlags.HideInHierarchy;
            helper = helperCamera.AddComponent<Camera>();
            helper.orthographic = true;
            helper.nearClipPlane = 0;
            m_asset = asset;
        }
        public void Dispose()
        {
            GameObject.DestroyImmediate(helperCamera);
        }
    }


}


