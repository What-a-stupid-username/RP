using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;
using System;
using System.Collections.Generic;
using UnityEngine.Profiling;

namespace vrp
{

    public class VRP : RenderPipeline
    {
        private readonly VRPAsset m_asset;
        
        PreZRenderer m_PreZRenderer;
        CommonRenderer m_commonRenderer;
        BakeRenderer m_bakeRenderer;


        public VRP(VRPAsset asset)
        {
            m_asset = asset;
            
            m_PreZRenderer = new PreZRenderer();
            m_commonRenderer = new CommonRenderer();
            m_bakeRenderer = new BakeRenderer();
        }

        public override void Dispose()
        {
            base.Dispose();

            VRenderResourcesPool.Dispose();

            m_PreZRenderer.Dispose();
            m_commonRenderer.Dispose();
            m_bakeRenderer.Dispose();
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

                BeginCameraRendering(camera);

#if UNITY_EDITOR
                if (camera.cameraType == CameraType.SceneView)
                    ScriptableRenderContext.EmitWorldGeometryForSceneView(camera);
#endif

                var resources = VRenderResourcesPool.Get(m_asset, camera.GetInstanceID());

                resources.depth_normal.TestNeedModify(camera.pixelWidth, camera.pixelHeight, 24);
                resources.color.TestNeedModify(camera.pixelWidth, camera.pixelHeight, 0);

                var cullResults = new CullResults();
                CullResults.Cull(camera, renderContext, out cullResults);



#if UNITY_EDITOR
                if (camera.name == "GI Baker")
                {
                    m_bakeRenderer.AllocateResources(resources);
                    m_bakeRenderer.Execute(ref renderContext, cullResults, camera);
                }
                else
                {
#endif
                    m_PreZRenderer.AllocateResources(resources);
                    m_PreZRenderer.Execute(ref renderContext, cullResults, camera);

                    m_commonRenderer.AllocateResources(resources);
                    m_commonRenderer.Execute(ref renderContext, cullResults, camera);
#if UNITY_EDITOR
                }
#endif


                var cb_postprocess = CommandBufferPool.Get("Post");
#if UNITY_EDITOR
                if (camera.name != "GI Baker")
                {
                    VRPDebuger.ShowTexture(ref cb_postprocess, resources.depth_normal.data, camera.targetTexture, 0);
                    VRPDebuger.ShowTextureArray(ref cb_postprocess, resources.shadowResources.m_DirShadowArray.data, camera.targetTexture, 0);
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
