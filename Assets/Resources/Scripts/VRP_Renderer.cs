using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;

namespace vrp
{
    public abstract class Renderer
    {
        protected CullResults m_cullResults;
        virtual public void Execute(ref ScriptableRenderContext renderContext, Camera camera)
        {
            if (camera.orthographic == true)
            {
                Debug.LogError("Orthographic camera is not yet supported.");
            }

            renderContext.SetupCameraProperties(camera);

            if (camera.cameraType == CameraType.SceneView)
                ScriptableRenderContext.EmitWorldGeometryForSceneView(camera);

            m_cullResults = new CullResults();
            CullResults.Cull(camera, renderContext, out m_cullResults);
        }

        public abstract void Dispose();

    }

    class PreZRenderer : Renderer
    {
        public VRenderResources m_resources;

        public override void Execute(ref ScriptableRenderContext renderContext, Camera camera)
        {
            base.Execute(ref renderContext, camera);
            
            CommandBuffer cb = CommandBufferPool.Get("PreZRenderer");

            var filterSetting = new FilterRenderersSettings(true);
            filterSetting.renderQueueRange = RenderQueueRange.opaque;
            filterSetting.layerMask = camera.cullingMask;

            cb.SetRenderTarget(m_resources.m_depth_normal.data);
            cb.ClearRenderTarget(true, true, Color.clear);
            renderContext.ExecuteCommandBuffer(cb);

            var renderSetting = new DrawRendererSettings(camera, new ShaderPassName("VRP_PREZ"));
            renderSetting.sorting.flags = SortFlags.None;
            renderContext.DrawRenderers(m_cullResults.visibleRenderers, ref renderSetting, filterSetting);

            CommandBufferPool.Release(cb);
        }

        //bool NeedInvV(Camera camera)
        //{
        //    if (SystemInfo.graphicsDeviceType == GraphicsDeviceType.Direct3D11 || SystemInfo.graphicsDeviceType == GraphicsDeviceType.Direct3D12)
        //    {
        //        if (camera.cameraType == CameraType.Game)
        //        {
        //            return true;
        //        }
        //    }
        //    return false;
        //}

        public PreZRenderer(VRenderResources resources)
        {
            m_resources = resources;
        }

        public override void Dispose() { }
    }


    class CommonRenderer : Renderer
    {
        private VRenderResources m_renderResources;

        public override void Execute(ref ScriptableRenderContext renderContext, Camera camera)
        {
            base.Execute(ref renderContext, camera);

            PrepareLights(ref renderContext, m_cullResults.visibleLights, camera);

            renderContext.SetupCameraProperties(camera);

            CommandBuffer cb = CommandBufferPool.Get("CommonRenderer_setbuffer");
            
            RenderTexture cmrt = m_renderResources.m_color.data;
            cb.SetRenderTarget(cmrt, m_renderResources.m_depth_normal.data);
            cb.ClearRenderTarget(false, true, Color.black);
            renderContext.ExecuteCommandBuffer(cb);

            var filterSetting = new FilterRenderersSettings(true);
            filterSetting.renderQueueRange = RenderQueueRange.opaque;
            filterSetting.layerMask = camera.cullingMask;

            {
                renderContext.ExecuteCommandBuffer(m_renderResources.m_setup_per_camera_properties);
                m_renderResources.m_setup_per_camera_properties.Clear();
                var renderSetting = new DrawRendererSettings(camera, new ShaderPassName("VRP_BASE"));
                renderSetting.sorting.flags = SortFlags.None;
                renderContext.DrawRenderers(m_cullResults.visibleRenderers, ref renderSetting, filterSetting);
            }

            renderContext.DrawSkybox(camera);

            cb.Clear();
            cb.Blit(cmrt, camera.targetTexture);
            renderContext.ExecuteCommandBuffer(cb);

            CommandBufferPool.Release(cb);
        }


        private void PrepareLights(ref ScriptableRenderContext renderContext, List<VisibleLight> lights, Camera camera)
        {
            //update light buffer
            m_renderResources.m_lightResources.UpdateLightBuffer(lights, ref m_renderResources.m_setup_per_camera_properties);

            //calcu directional light shadow
            {
                List<Light> shadow_directional_lights = new List<Light>();

                foreach (var light in lights)
                {
                    if (light.light.shadows != LightShadows.None && light.lightType == LightType.Directional)
                    {
                        shadow_directional_lights.Add(light.light);
                    }
                }
                m_renderResources.m_shadowResources.UpdateDirectionalLights(ref renderContext, shadow_directional_lights, camera, ref m_renderResources.m_setup_per_camera_properties);
            }


        }

        public CommonRenderer(VRenderResources resources)
        {
            m_renderResources = resources;
        }

        public override void Dispose() {}
    }



}
