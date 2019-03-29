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
        rt_ = rt;
        self_camera = GetComponent<Camera>();
        self_camera.enabled = false;
        self_camera.targetTexture = rt_;
        self_camera.name = name;
        self_camera.allowHDR = true;
    }

    public void Draw()
    {
        self_camera.RenderToCubemap(rt_);
        //rt_.GenerateMips();
    }






    void Start() //this object should not live in game mode
    {
        Destroy(gameObject);
    }
}
