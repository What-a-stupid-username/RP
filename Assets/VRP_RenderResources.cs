namespace vrp
{
    public class RenderResources
    {
        public LightResources m_lightResources;
        public ShadowResources m_shadowResources;

        public RenderResources(VRPAsset asset)
        {
            m_lightResources = new LightResources();
            m_shadowResources = new ShadowResources(asset);
        }
        public void Dispose()
        {
            m_lightResources.Dispose();
            m_shadowResources.Dispose();
        }
    }
}
