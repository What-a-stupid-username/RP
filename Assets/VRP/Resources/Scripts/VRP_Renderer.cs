using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;

namespace vrp
{
    public abstract class Renderer
    {
        protected VRenderResources m_renderResources;
        virtual public void Execute(ref ScriptableRenderContext renderContext, CullResults cullResults, Camera camera)
        { }

        public abstract void Dispose();
        public void AllocateResources(VRenderResources resources)
        {
            m_renderResources = resources;
        }
    }

    class PreZRenderer : Renderer
    {
        int _Last_VP = Shader.PropertyToID("_Last_VP");
        int _VP = Shader.PropertyToID("_VP");

        public override void Execute(ref ScriptableRenderContext renderContext, CullResults cullResults, Camera camera)
        {
            Matrix4x4 vp = GL.GetGPUProjectionMatrix(camera.projectionMatrix,false) * camera.worldToCameraMatrix;
            
            CommandBuffer cb = CommandBufferPool.Get("PreZRenderer");

            var filterSetting = new FilterRenderersSettings(true);
            filterSetting.renderQueueRange = RenderQueueRange.opaque;
            filterSetting.layerMask = camera.cullingMask;

            renderContext.SetupCameraProperties(camera);

            cb.SetRenderTarget(m_renderResources.depth_Velocity.data, m_renderResources.depth.data);
            cb.ClearRenderTarget(true, true, Color.clear);
            renderContext.ExecuteCommandBuffer(cb);

            var renderSetting = new DrawRendererSettings(camera, new ShaderPassName("VRP_PREZ"));
            renderSetting.sorting.flags = SortFlags.None;
            renderContext.DrawRenderers(cullResults.visibleRenderers, ref renderSetting, filterSetting);
            cb.Clear();

            cb.SetGlobalMatrix(_Last_VP, m_renderResources.lastVP);
            cb.SetGlobalMatrix(_VP, vp.inverse);
            cb.Blit(m_renderResources.depth_Velocity.data, m_renderResources.sceneColor.data, m_renderResources.materials.velocity, 0);
            cb.Blit(m_renderResources.sceneColor.data, m_renderResources.depth_Velocity.data);
            renderContext.ExecuteCommandBuffer(cb);

            CommandBufferPool.Release(cb);
            m_renderResources.lastVP = vp;
        }

        public override void Dispose() { }
    }

    class LightRenderer : Renderer
    {
        Dictionary<Light, int> m_lights_table;

        public override void Execute(ref ScriptableRenderContext renderContext, CullResults cullResults, Camera camera) { throw new NotImplementedException(); }

        public void PrepareShadow(ref ScriptableRenderContext renderContext, List<Light> lights, Camera camera)
        {
            //calcu directional light shadow map
            {
                List<Light> shadow_directional_lights = new List<Light>();

                foreach (var light in lights)
                {
                    if (light.shadows != LightShadows.None && light.type == LightType.Directional)
                    {
                        shadow_directional_lights.Add(light);
                    }
                }
                m_renderResources.shadowResources.UpdateDirectionalLights(ref m_lights_table, ref renderContext, shadow_directional_lights, camera, ref m_renderResources.setup_per_camera_properties);
            }

            //calcu point light shadow map
            {
                List<Light> shadow_point_lights = new List<Light>();

                foreach (var light in lights)
                {
                    if (light.shadows != LightShadows.None && light.type == LightType.Point)
                    {
                        shadow_point_lights.Add(light);
                    }
                }
                m_renderResources.shadowResources.UpdatePointLights(ref m_lights_table, ref renderContext, shadow_point_lights, camera, ref m_renderResources.setup_per_camera_properties);
            }
        }

        public void PrepareLightBuffer(List<VisibleLight> lights, bool isGI = false)
        {
            //update light buffer
            m_renderResources.lightResources.UpdateLightBuffer(ref m_lights_table, lights, ref m_renderResources.setup_per_camera_properties, isGI);
        }

        public LightRenderer()
        {
            m_lights_table = new Dictionary<Light, int>();
        }

        public override void Dispose() { }
    }

    class CommonRenderer : Renderer
    {
        public override void Execute(ref ScriptableRenderContext renderContext, CullResults cullResults, Camera camera)
        {
            renderContext.SetupCameraProperties(camera);

            CommandBuffer cb = CommandBufferPool.Get("CommonRenderer_setbuffer");
            
            RenderTargetIdentifier[] mrt = new RenderTargetIdentifier[] { m_renderResources.sceneColor.data, m_renderResources.baseColor_Metallic.data, m_renderResources.normal_Roughness.data };
            cb.SetRenderTarget(mrt, m_renderResources.depth.data);
            cb.ClearRenderTarget(false, true, Color.clear);
            renderContext.ExecuteCommandBuffer(cb);

            var filterSetting = new FilterRenderersSettings(true);
            filterSetting.renderQueueRange = RenderQueueRange.opaque;
            filterSetting.layerMask = camera.cullingMask;

            {
                renderContext.ExecuteCommandBuffer(m_renderResources.setup_per_camera_properties);
                m_renderResources.setup_per_camera_properties.Clear();
                var renderSetting = new DrawRendererSettings(camera, new ShaderPassName("VRP_BASE"));
                renderSetting.sorting.flags = SortFlags.None;
                renderContext.DrawRenderers(cullResults.visibleRenderers, ref renderSetting, filterSetting);
            }

            renderContext.DrawSkybox(camera);

            cb.Clear();
            renderContext.ExecuteCommandBuffer(cb);

            CommandBufferPool.Release(cb);
        }
        public override void Dispose() {}
    }

    class BakeRenderer : LightRenderer
    {
        public override void Execute(ref ScriptableRenderContext renderContext, CullResults cullResults, Camera camera)
        {
            List<Light> lights = new List<Light>();
            foreach (var light in cullResults.visibleLights)
            {
                lights.Add(light.light);
            }
            PrepareShadow(ref renderContext, lights, camera);

            PrepareLightBuffer(cullResults.visibleLights);

            renderContext.SetupCameraProperties(camera);

            CommandBuffer cb = CommandBufferPool.Get("CommonRenderer_setbuffer");
            
            cb.ClearRenderTarget(true, true, Color.clear);
            renderContext.ExecuteCommandBuffer(cb);

            var filterSetting = new FilterRenderersSettings(true);
            filterSetting.renderQueueRange = RenderQueueRange.opaque;
            filterSetting.layerMask = camera.cullingMask;

            var renderSetting = new DrawRendererSettings(camera, new ShaderPassName("VRP_BAKE"));
            renderSetting.sorting.flags = SortFlags.None;

            {
                renderContext.ExecuteCommandBuffer(m_renderResources.setup_per_camera_properties);
                m_renderResources.setup_per_camera_properties.Clear();
 
                renderContext.DrawRenderers(cullResults.visibleRenderers, ref renderSetting, filterSetting);
            }

            renderContext.DrawSkybox(camera);

            CommandBufferPool.Release(cb);
        }
    }

    class GIRenderer : Renderer
    {
        public override void Execute(ref ScriptableRenderContext renderContext, CullResults cullResults, Camera camera)
        {
            renderContext.ExecuteCommandBuffer(m_renderResources.setup_per_camera_properties);
            m_renderResources.giResources.Update(ref renderContext, ref cullResults, camera, ref m_renderResources.setup_per_camera_properties);
        }

        public override void Dispose() { }
    }

    class PostRenderer : Renderer
    {
        void SetupIdentifier(VPostProcess post)
        {
            post.Init();
            if (m_renderResources.modified == true || post.textureIdentifiers.init == false)
            {
                post.textureIdentifiers.init = true;
                post.textureIdentifiers.sceneColor = m_renderResources.sceneColor.data;
                post.textureIdentifiers.sceneColorPrev = m_renderResources.sceneColorPrev.data;
                post.textureIdentifiers.normal_Roughness = m_renderResources.normal_Roughness.data;
                post.textureIdentifiers.depth_Velocity = m_renderResources.depth_Velocity.data;
                post.textureIdentifiers.baseColor_Metallic = m_renderResources.baseColor_Metallic.data;
                post.ReuildCommandBuffer();
            }
        }

        public void Execute(ref ScriptableRenderContext renderContext, VPostProcess post)
        {
            SetupIdentifier(post);
            renderContext.ExecuteCommandBuffer(post.cb);
        }
        public override void Execute(ref ScriptableRenderContext renderContext, CullResults cullResults, Camera camera) { throw new NotImplementedException(); }
        public override void Dispose() { }
    }
}
