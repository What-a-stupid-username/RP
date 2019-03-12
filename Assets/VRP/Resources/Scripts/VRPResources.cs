using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace vrp
{
    [CreateAssetMenu(menuName = "VRP/Create Resources")]
    public class VRPResources : ScriptableObject
    {
        public ComputeShader cs_GetMinMaxOfTexture_32x32;
        public Shader defaultShader;
    }
}

