using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;
using System;
using System.Collections.Generic;
using UnityEngine.Profiling;
using System.Linq;

namespace vrp
{

    public class VRP : RenderPipeline
    {
        private readonly VRPAsset m_asset;
        
        PreZRenderer m_preZRenderer;
        LightRenderer m_lightRenderer;
        CommonRenderer m_commonRenderer;
        BakeRenderer m_bakeRenderer;
        GIRenderer m_giRenderer;


        public VRP(VRPAsset asset)
        {
            m_asset = asset;
            
            m_preZRenderer = new PreZRenderer();
            m_lightRenderer = new LightRenderer();
            m_commonRenderer = new CommonRenderer();
            m_bakeRenderer = new BakeRenderer();
            m_giRenderer = new GIRenderer();
        }

        public override void Dispose()
        {
            base.Dispose();

            VRenderResourcesPool.Dispose();

            m_preZRenderer.Dispose();
            m_lightRenderer.Dispose();
            m_commonRenderer.Dispose();
            m_bakeRenderer.Dispose();
            m_giRenderer.Dispose();
        }

        public override void Render(ScriptableRenderContext renderContext, Camera[] cameras)
        {
            base.Render(renderContext, cameras);

            BeginFrameRendering(cameras);

            SortCamera(ref cameras);

            foreach (var camera in cameras)
            {
                if (camera.orthographic == true)
                {
                    Debug.LogError("Orthographic camera is not yet supported!");
                    return;
                }
                //if (camera.cameraType != CameraType.Game) return;
                //Debug.Log(camera.name);

                BeginCameraRendering(camera);

#if UNITY_EDITOR
                if (camera.cameraType == CameraType.SceneView)
                    ScriptableRenderContext.EmitWorldGeometryForSceneView(camera);
#endif

                var resources = VRenderResourcesPool.Get(m_asset, camera.GetInstanceID());

                resources.depth_normal.TestNeedModify(camera.pixelWidth, camera.pixelHeight, 0);
                resources.color.TestNeedModify(camera.pixelWidth, camera.pixelHeight, 24);





#if UNITY_EDITOR
                if (camera.name == "GI Baker")
                {
                    var cullResults = new CullResults();
                    CullResults.Cull(camera, renderContext, out cullResults);

                    m_bakeRenderer.AllocateResources(resources);
                    m_bakeRenderer.Execute(ref renderContext, cullResults, camera);
                }
                else
                {
#endif
                    {
                        var giCullResult = new CullResults();
                        var helper = resources.shadowResources.helper;
                        helper.aspect = 1;
                        helper.transform.up = Vector3.up;
                        helper.transform.forward = Vector3.forward;
                        helper.transform.position = camera.transform.position + Vector3.back * m_asset.distributionDistanceFromCamera / 2;
                        helper.orthographicSize = m_asset.distributionDistanceFromCamera * 2;
                        helper.farClipPlane = m_asset.distributionDistanceFromCamera;
                        CullResults.Cull(helper, renderContext, out giCullResult);
                        
                        var commonCullResults = new CullResults();
                        CullResults.Cull(camera, renderContext, out commonCullResults);

                        List<Light> totalight = new List<Light>();
                        {
                            foreach (var light in commonCullResults.visibleLights)
                                totalight.Add(light.light);
                            foreach (var light in giCullResult.visibleLights)
                                totalight.Add(light.light);
                            totalight = totalight.Distinct().ToList();
                        }

                        m_lightRenderer.AllocateResources(resources);
                        m_lightRenderer.PrepareShadow(ref renderContext, totalight, camera);


                        m_lightRenderer.PrepareLightBuffer(giCullResult.visibleLights, true);
                        m_giRenderer.AllocateResources(resources);
                        m_giRenderer.Execute(ref renderContext, giCullResult, camera);

                        m_preZRenderer.AllocateResources(resources);
                        m_preZRenderer.Execute(ref renderContext, commonCullResults, camera);

                        m_lightRenderer.PrepareLightBuffer(commonCullResults.visibleLights);
                        m_commonRenderer.AllocateResources(resources);
                        m_commonRenderer.Execute(ref renderContext, commonCullResults, camera);
                    }
#if UNITY_EDITOR
                }
#endif


                var cb_postprocess = CommandBufferPool.Get("Post");
#if UNITY_EDITOR
                if (camera.name != "GI Baker")
                {
                    VRPDebuger.ShowTexture(ref cb_postprocess, resources.depth_normal.data, resources.color.data, 0);
                    VRPDebuger.ShowTextureArray(ref cb_postprocess, resources.shadowResources.m_DirShadowArray.data, resources.color.data, 0);
                }
                try
                {
                    renderContext.ExecuteCommandBuffer(GameObject.Find("GI SH").GetComponent<Scene_SH>().cb);
                }
                catch (Exception) {}
#endif

#if UNITY_EDITOR
                if (camera.name != "GI Baker")
                {
#endif
                    cb_postprocess.Blit(resources.color.data, camera.targetTexture);
#if UNITY_EDITOR
                }
#endif

                renderContext.ExecuteCommandBuffer(cb_postprocess);
                CommandBufferPool.Release(cb_postprocess);

                renderContext.Submit();
            }
            VRenderResourcesPool.KeepAlive();
        }

        static private void SortCamera(ref Camera[] cameras)
        {
            Array.Sort(cameras, (c1, c2) => { return c1.depth.CompareTo(c2.depth); });
        }
    }
}
