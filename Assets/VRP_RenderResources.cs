namespace vrp
{
    public class RenderResources
    {
        public LightResources m_lightResources;

        public RenderResources()
        {
            m_lightResources = new LightResources();
        }
        public void Dispose()
        {
            m_lightResources.Dispose();
        }
    }
}
