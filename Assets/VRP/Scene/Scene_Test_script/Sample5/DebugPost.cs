using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using vrp;

public class DebugPost : VPostProcess 
{
    public override void Init()
    {
        base.Init();//don't delete this
    }


    public override void ReuildCommandBuffer()
    {
        Debug.Log("Rebuild cb");

        cb.Clear();

        //these functions only work in ediotr and will throw out compile error if been used in release game
        VRPDebuger.ShowTexture(cb, textureIdentifiers.sceneColorPrev, textureIdentifiers.sceneColor, 0);
        VRPDebuger.ShowTexture(cb, textureIdentifiers.depth_Velocity, textureIdentifiers.sceneColor, 1);
        VRPDebuger.ShowTexture(cb, textureIdentifiers.baseColor_Metallic, textureIdentifiers.sceneColor, 2);
        VRPDebuger.ShowTexture(cb, textureIdentifiers.normal_Roughness, textureIdentifiers.sceneColor, 3);
    }
}
