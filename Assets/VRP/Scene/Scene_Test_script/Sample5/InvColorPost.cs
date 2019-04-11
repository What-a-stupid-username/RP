using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using vrp;

public class InvColorPost : VPostProcess
{
    public override void ReuildCommandBuffer()
    {
        cb.Clear();
        var camera = GetComponent<Camera>();
        var buffer_ptr = Shader.PropertyToID("ExampleInvColorBuffer");
        cb.GetTemporaryRT(buffer_ptr, camera.pixelWidth, camera.pixelHeight, 0, FilterMode.Bilinear, RenderTextureFormat.ARGBFloat);
        cb.Blit(textureIdentifiers.sceneColor, buffer_ptr, new Material(Shader.Find("VRP/Example/InvColor")), 0);
        //cb.CopyTexture(buffer_ptr, textureIdentifiers.sceneColor); //Only work with MSAA off
        cb.Blit(buffer_ptr, textureIdentifiers.sceneColor); //using Blit with MSAA on
    }

}
