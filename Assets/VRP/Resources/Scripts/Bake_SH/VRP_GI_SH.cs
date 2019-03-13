using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Camera))]
public class VRP_GI_SH : MonoBehaviour
{
    Camera self_camera;
    RenderTexture rt_;
    public void Init(RenderTexture rt)
    {
        if (rt == null) rt = new RenderTexture(256, 256, 24);
        rt_ = rt;
        self_camera = GetComponent<Camera>();
        self_camera.enabled = false;
        self_camera.targetTexture = rt_;
        Shader shader = Shader.Find("VRP/bake");
        self_camera.SetReplacementShader(shader, "RenderType");
        self_camera.name = "GI Baker";
    }

    public void Draw()
    {
        self_camera.Render();
    }






    void Start() //this object should not live in game mode
    {
        Destroy(gameObject);
    }
}
