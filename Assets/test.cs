using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using vrp;

public class test : MonoBehaviour
{
    public ComputeShader cs;
    GetMinMaxOfTexture k;
    void Start()
    {
        Texture2D tex = new Texture2D(64, 64, TextureFormat.RFloat, false);
        for (int i = 0; i < 64; i++)
        {
            for (int j = 0; j < 64; j++)
            {
                tex.SetPixel(i, j, Color.white);
            }
        }
        tex.SetPixel(0, 0, Color.red);
        tex.Apply();
        k = new GetMinMaxOfTexture(cs, tex);
    }

    // Update is called once per frame
    void Update()
    {
        k.Update();
    }
}

