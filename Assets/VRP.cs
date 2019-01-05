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
        private RenderResources m_renderResources;

        public VRP(VRPAsset asset)
        {
            m_asset = asset;
            m_renderResources = new RenderResources(asset);
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

                if (camera.cameraType != CameraType.SceneView && camera.orthographic == false)
                    PrepareLights(results.visibleLights, camera);
                

                var filterSetting = new FilterRenderersSettings(true);
                filterSetting.renderQueueRange = RenderQueueRange.opaque;
                filterSetting.layerMask = camera.cullingMask;

                {
                    var renderSetting = new DrawRendererSettings(camera, new ShaderPassName("VRP_PREZ"));
                    renderSetting.sorting.flags = SortFlags.None;
                    renderContext.DrawRenderers(results.visibleRenderers, ref renderSetting, filterSetting);
                }





                {
                    var renderSetting = new DrawRendererSettings(camera, new ShaderPassName("VRP_BASE"));
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

        private void PrepareLights(List<VisibleLight> lights, Camera camera)
        {
            //update light buffer
            m_renderResources.m_lightResources.UpdateLightBuffer(lights);

            List<Light> shadow_directional_lights = new List<Light>();

            foreach (var light in lights)
            {
                if (light.light.shadows != LightShadows.None && light.lightType == LightType.Directional)
                {
                    shadow_directional_lights.Add(light.light);
                }
            }
            m_renderResources.m_shadowResources.UpdateDirectionalLights(shadow_directional_lights, camera);

        }




    }
}
