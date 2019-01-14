using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Profiling;
using UnityEngine.Rendering;
using vrp;



public class test : MonoBehaviour
{
    public int size;
    public RenderTexture rt;
    public RenderTexture rt1;

    CommandBuffer cb;

    private void Start()
    {
        RenderTextureDescriptor renderTextureDescriptor = new RenderTextureDescriptor(size, size, RenderTextureFormat.ARGB32, 0);
        renderTextureDescriptor.sRGB = false;
        rt = new RenderTexture(renderTextureDescriptor);
        rt.anisoLevel = 0;
        rt.antiAliasing = 1;
        rt.filterMode = FilterMode.Point;
        rt.Create();

        var cbs = GetComponent<Camera>().GetCommandBuffers(CameraEvent.AfterEverything);
        if (cbs.Length == 0)
        {
            cb = new CommandBuffer();
            GetComponent<Camera>().AddCommandBuffer(CameraEvent.AfterEverything, cb);
        }
        else
        {
            cb = cbs[0];
        }
        cb.Clear();

        cb.Blit(null, rt, new Material(Shader.Find("Hiden/BB")));

        GenerateMinMaxOfTexture aaa = new GenerateMinMaxOfTexture(rt);

        aaa.Update(cb);

        rt1 = aaa.result;
    }
}




//public class test : MonoBehaviour
//{
//    public ComputeShader cs;
//    public int size = 64;
//    GetMinMaxOfTexture k;
//    Texture2D tex;

//    CommandBuffer cb;
//    void Start()
//    {
//        tex = new Texture2D(size, size, TextureFormat.RFloat, false);
//        for (int i = 0; i < size; i++)
//        {
//            for (int j = 0; j < size; j++)
//            {
//                tex.SetPixel(i, j, Color.white);
//            }
//        }
//        tex.SetPixel(0, 0, Color.black);
//        tex.SetPixel(3, 3, Color.black);
//        tex.SetPixel(300, 300, Color.black);
//        tex.Apply();
//        k = new GetMinMaxOfTexture(cs, tex);

//        var cbs = GetComponent<Camera>().GetCommandBuffers(CameraEvent.AfterEverything);
//        if (cbs.Length == 0)
//        {
//            cb = new CommandBuffer();
//            GetComponent<Camera>().AddCommandBuffer(CameraEvent.AfterEverything, cb);
//        }
//        cb = GetComponent<Camera>().GetCommandBuffers(CameraEvent.AfterEverything)[0];
//    }

//    struct aa{
//        public Vector4 a, b;
//    }

//    // Update is called once per frame
//    void Update()
//    {
//        k.Update();
//        if (Input.GetKey(KeyCode.A))
//        {
//            aa[] aaa = new aa[1];
//            k.result.GetData(aaa, 0, 0, 1);
//        }
//    }
//}

