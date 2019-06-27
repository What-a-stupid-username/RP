using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using vrp;

public class SSRPost : VPostProcess
{
    public RenderTexture HiZDepth;
    public RenderTexture Helper;

    Material HiZMipChainMaterial;
    Material SSRMaterial;

    VRenderTexture2D VHiZDepth;
    VRenderTexture2D VHelper;
    VRenderTexture2D VColorBuffer;

    struct ShaderProperties
    {
        public static int _HiZGenerationParemeters = Shader.PropertyToID("_HiZGenerationParemeters");
        public static int _HiZDepth = Shader.PropertyToID("_HiZDepth");
        public static int _HiZBufferSize = Shader.PropertyToID("_HiZBufferSize");
        public static int _SceneColor = Shader.PropertyToID("_SceneColor");
    }


    public override void Init()
    {
        base.Init();
        VHiZDepth = new VRenderTexture2D("HiZDepth", RenderTextureFormat.RGFloat, true, false, true, false);
        VHelper = new VRenderTexture2D("Helper", RenderTextureFormat.RGFloat, true, false, true, false);
        VColorBuffer = new VRenderTexture2D("SceneColor", RenderTextureFormat.ARGBFloat);
        HiZMipChainMaterial = new Material(Shader.Find("VRP/Post/HiZMipChain"));
        SSRMaterial = new Material(Shader.Find("VRP/Post/SSR"));
    }

    public override void ReuildCommandBuffer()
    {
        Debug.Log("rebuild SSR");

        #region Check properties
        Camera camera = GetComponent<Camera>();
        int w = Mathf.ClosestPowerOfTwo(camera.pixelWidth), h = Mathf.ClosestPowerOfTwo(camera.pixelHeight);
        if (VHiZDepth.TestNeedModify(w, h, 0))
        {
            cb.SetGlobalVector(ShaderProperties._HiZBufferSize, new Vector4(w, h, 0, 0));
            HiZDepth = VHiZDepth.data;
        }
        if (VHelper.TestNeedModify(w, h, 0))
            Helper = VHelper.data;
        VColorBuffer.TestNeedModify(w, h, 0);
        #endregion

        GenerateMipMaps();

        cb.Blit(textureIdentifiers.sceneColor, VColorBuffer.data);
        cb.SetGlobalTexture(ShaderProperties._SceneColor, VColorBuffer.data);

        cb.Blit(null, textureIdentifiers.sceneColor, SSRMaterial, 0);
    }

    void GenerateMipMaps()
    {
        cb.Blit(textureIdentifiers.depth_Velocity, new RenderTargetIdentifier(HiZDepth, 0), HiZMipChainMaterial, 1);

        int mip_level_num = (int)Mathf.Log(Mathf.Max(HiZDepth.width, HiZDepth.height), 2);

        for (int i = 1; i <= mip_level_num; ++i)
        {
            cb.SetGlobalFloat(ShaderProperties._HiZGenerationParemeters, i - 1);
            cb.SetRenderTarget(Helper, i);
            cb.Blit(HiZDepth, new RenderTargetIdentifier(BuiltinRenderTextureType.CurrentActive), HiZMipChainMaterial, 0);
            cb.CopyTexture(Helper, 0, i, HiZDepth, 0, i);
        }

        cb.SetGlobalTexture(ShaderProperties._HiZDepth, HiZDepth);
    }
}
