using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;

namespace vrp
{
    public class VRenderResources
    {
        public int id { get; private set; }
        public VRPResources m_VRPResources;

        public bool modified = false;
        public VRenderTexture2D depth_Velocity;
        public VRenderTexture2D sceneColor;
        public VRenderTexture2D sceneColorPrev;
        public VRenderTexture2D depth;
        public VRenderTexture2D baseColor_Metallic;
        public VRenderTexture2D normal_Roughness;


        public LightResources lightResources;
        public ShadowResources shadowResources;
        public GIResources giResources;

        //use this to setup per camera properties, will be excute before opaque shade.
        public CommandBuffer setup_per_camera_properties;

        public VMaterials materials;

        public Matrix4x4 lastVP;

        public VRenderResources(VRPAsset asset, int id= 0)
        {
            this.id = id;
            if (asset.resources == null)
            {
                Debug.LogWarning("Try to load default VRPResources");
                m_VRPResources = Resources.Load<VRPResources>("VRPResources");
            }
            else
            {
                m_VRPResources = asset.resources;
            }
            if (m_VRPResources == null) Debug.LogError("Can't find VRP resources!");

            depth_Velocity = new VRenderTexture2D(id + "_velocity", RenderTextureFormat.ARGBFloat, true, asset.MSAA);
            sceneColor = new VRenderTexture2D(id + "_sceneColor", RenderTextureFormat.ARGBFloat, true, asset.MSAA);
            sceneColorPrev = new VRenderTexture2D(id + "_sceneColor", RenderTextureFormat.ARGBFloat, true);
            depth = new VRenderTexture2D(id + "_depth", RenderTextureFormat.Depth, true, asset.MSAA);
            baseColor_Metallic = new VRenderTexture2D(id + "_baseColor_Metallic", RenderTextureFormat.ARGB32, true, asset.MSAA);
            normal_Roughness = new VRenderTexture2D(id + "_normal_Roughness", RenderTextureFormat.ARGBHalf, true, asset.MSAA);

            lightResources = new LightResources();
            shadowResources = new ShadowResources(asset);
            giResources = new GIResources(asset);

            materials = new VMaterials();

            setup_per_camera_properties = CommandBufferPool.Get(id+"_setproperties_beforeOpaque");
        }

        public bool TestNeedModify(int width, int height)
        {
            modified = false;
            modified |= depth_Velocity.TestNeedModify(width, height, 0);
            modified |= sceneColor.TestNeedModify(width, height, 0);
            modified |= sceneColorPrev.TestNeedModify(width, height, 0);
            modified |= depth.TestNeedModify(width, height, 24);
            modified |= baseColor_Metallic.TestNeedModify(width, height, 0);
            modified |= normal_Roughness.TestNeedModify(width, height, 0);
            return modified;
        }

        public void Dispose()
        {
            depth_Velocity.Dispose();
            sceneColor.Dispose();
            sceneColorPrev.Dispose();
            depth.Dispose();
            baseColor_Metallic.Dispose();
            normal_Roughness.Dispose();

            lightResources.Dispose();
            shadowResources.Dispose();
            giResources.Dispose();

            CommandBufferPool.Release(setup_per_camera_properties);
        }
    }

    public class VRenderResourcesPool
    {

        private static readonly VRenderResourcesPool instance = new VRenderResourcesPool();
        private Dictionary<int, VRenderResources> m_LookupTable;
        Dictionary<int, int> m_CameraTable;

        VRenderResourcesPool()
        {
            m_LookupTable = new Dictionary<int, VRenderResources>();
            m_CameraTable = new Dictionary<int, int>();
        }

        public static VRenderResources Get(VRPAsset asset, int id)
        {
            VRenderResources res;
            instance.m_CameraTable[id] = 10;
            if (!instance.m_LookupTable.TryGetValue(id, out res))
            {
                res = new VRenderResources(asset, id);
                instance.m_LookupTable.Add(id, res);
            }
            return res;
        }

        public static void KeepAlive()
        {
            var keys = instance.m_CameraTable.Keys;
            int[] ids = new int[keys.Count];
            int i = 0;
            foreach (var id in keys)
            {
                ids[i++] = id;
            }
            foreach (var id in ids)
            {
                if (instance.m_CameraTable[id]-- <= 0)
                {
                    instance.m_CameraTable.Remove(id);
                    Release(id);
                }
            }
        }

        private static void Release(int id)
        {
            if (instance.m_LookupTable.ContainsKey(id))
            {
                instance.m_LookupTable[id].Dispose();
                instance.m_LookupTable.Remove(id);
            }
        }

        public static void Dispose()
        {
            foreach (var pair in instance.m_LookupTable)
            {
                pair.Value.Dispose();
            }
            instance.m_LookupTable.Clear();
            instance.m_CameraTable.Clear();
        }
    }
}
