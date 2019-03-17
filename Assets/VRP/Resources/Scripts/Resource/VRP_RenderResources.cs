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

        public VRenderTexture2D color;
        public VRenderTexture2D depth_normal;


        public LightResources lightResources;
        public ShadowResources shadowResources;

        //use this to setup per camera properties, will be excute before opaque shade.
        public CommandBuffer setup_per_camera_properties;

        public VMaterials materials;

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

            color = new VRenderTexture2D(id+"_color", RenderTextureFormat.ARGB32, true, asset.MASS);
            depth_normal = new VRenderTexture2D(id+"_depth_normal", RenderTextureFormat.ARGB64, true, asset.MASS);

            lightResources = new LightResources();
            shadowResources = new ShadowResources(asset);

            materials = new VMaterials();

            setup_per_camera_properties = CommandBufferPool.Get(id+"_setproperties_beforeOpaque");
        }

        public void Dispose()
        {
            color.Dispose();
            depth_normal.Dispose();

            lightResources.Dispose();
            shadowResources.Dispose();

            CommandBufferPool.Release(setup_per_camera_properties);
        }
    }

    public class LightRecord
    {
        float UpdateTime;
        int id;
        int index;
    }

    public class VRenderResourcesPool
    {

        private static readonly VRenderResourcesPool instance = new VRenderResourcesPool();
        private Dictionary<int, VRenderResources> m_LookupTable;
        Dictionary<int, int> m_CameraTable;
        Dictionary<int, LightRecord> m_lightTable;

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

        public static void RecordLight(int id, int index)
        {
            Debug.Log(Time.time);
        }
        public static void SearchLight(int id, int index)
        {
            Debug.Log(Time.time);
        }
    }
}
