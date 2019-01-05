using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;
using System;

namespace vrp
{

    public class VRP : RenderPipeline
    {
        private readonly VRPAsset m_asset;
        private RenderResources m_renderResources;

        public VRP(VRPAsset asset)
        {
            m_asset = asset;
            m_renderResources = new RenderResources();
        }

        public override void Dispose()
        {
            base.Dispose();
            m_renderResources.Dispose();
        }

        public override void Render(ScriptableRenderContext renderContext, Camera[] cameras)
        {
            base.Render(renderContext, cameras);

            BeginFrameRendering(cameras);

            SortCamera(ref cameras);

            foreach (var camera in cameras)
            {
                BeginCameraRendering(camera);

                renderContext.SetupCameraProperties(camera);

                renderContext.DrawSkybox(camera);

                if (camera.cameraType == CameraType.SceneView)
                    ScriptableRenderContext.EmitWorldGeometryForSceneView(camera);

                var results = new CullResults();
                CullResults.Cull(camera, renderContext, out results);
                
                //update light buffer
                m_renderResources.m_lightResources.UpdateLightBuffer(results.visibleLights);

                var filterSetting = new FilterRenderersSettings(true);
                filterSetting.renderQueueRange = RenderQueueRange.opaque;
                filterSetting.layerMask = camera.cullingMask;
                
                {
                    var renderSetting = new DrawRendererSettings(camera, new ShaderPassName("VRP"));
                    renderSetting.sorting.flags = SortFlags.None;
                    renderContext.DrawRenderers(results.visibleRenderers, ref renderSetting, filterSetting);
                }
            }
            renderContext.Submit();

        }

        private void SortCamera(ref Camera[] cameras)
        {
            Array.Sort(cameras, (c1, c2) => { return c1.depth.CompareTo(c2.depth); });
        }


    }
}
