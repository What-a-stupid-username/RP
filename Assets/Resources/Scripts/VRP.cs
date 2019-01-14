using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;
using System;
using System.Collections.Generic;

namespace vrp
{

    public class VRP : RenderPipeline
    {
        private readonly VRPAsset m_asset;
        
        VRenderResources m_resources;

        PreZRenderer m_PreZRenderer;
        CommonRenderer m_commonRenderer;


        public VRP(VRPAsset asset)
        {
            m_asset = asset;

            m_resources = new VRenderResources(m_asset);

            m_PreZRenderer = new PreZRenderer(m_resources);
            m_commonRenderer = new CommonRenderer(m_resources);
        }

        public override void Dispose()
        {
            base.Dispose();

            m_resources.Dispose();

            m_PreZRenderer.Dispose();
            m_commonRenderer.Dispose();
        }

        public override void Render(ScriptableRenderContext renderContext, Camera[] cameras)
        {
            base.Render(renderContext, cameras);

            BeginFrameRendering(cameras);

            SortCamera(ref cameras);

            foreach (var camera in cameras)
            {
                //if (camera.cameraType != CameraType.SceneView) return;
                BeginCameraRendering(camera);
                
                m_resources.m_depth_normal.TestNeedModify(camera.pixelWidth, camera.pixelHeight, 24);
                m_resources.m_color.TestNeedModify(camera.pixelWidth, camera.pixelHeight, 0);

                m_PreZRenderer.Execute(ref renderContext, camera);

                m_commonRenderer.Execute(ref renderContext, camera);

                var cb_postprocess = CommandBufferPool.Get("Post");
#if UNITY_EDITOR
                VRPDebuger.ShowTexture(ref cb_postprocess, m_resources.m_depth_normal.data, camera.targetTexture, 0);
#endif
                renderContext.ExecuteCommandBuffer(cb_postprocess);
                CommandBufferPool.Release(cb_postprocess);
                renderContext.Submit();
            }
        }

        static private void SortCamera(ref Camera[] cameras)
        {
            Array.Sort(cameras, (c1, c2) => { return c1.depth.CompareTo(c2.depth); });
        }
    }
}
