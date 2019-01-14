using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;

namespace vrp
{
    public class VRenderResources
    {
        public VRPResources m_VRPResources;

        public VRenderTexture2D m_color;
        public VRenderTexture2D m_depth_normal;


        public LightResources m_lightResources;
        public ShadowResources m_shadowResources;

        //use this to setup per camera properties, will be excute before opaque shade.
        public CommandBuffer m_setup_per_camera_properties;

        public VMaterials m_materials;

        public VRenderResources(VRPAsset asset)
        {
            m_VRPResources = Resources.FindObjectsOfTypeAll<VRPResources>()[0];

            m_color = new VRenderTexture2D("color", RenderTextureFormat.ARGB32, true, true);
            m_depth_normal = new VRenderTexture2D("depth_normal", RenderTextureFormat.ARGB64, true, true);

            m_lightResources = new LightResources();
            m_shadowResources = new ShadowResources(asset);

            m_materials = new VMaterials();

            m_setup_per_camera_properties = CommandBufferPool.Get("setproperties_beforeOpaque");
        }
        public void Dispose()
        {
            m_color.Dispose();
            m_depth_normal.Dispose();

            m_lightResources.Dispose();
            m_shadowResources.Dispose();
            CommandBufferPool.Release(m_setup_per_camera_properties);
        }
    }
}
