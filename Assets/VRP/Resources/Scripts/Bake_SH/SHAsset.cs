using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SHAsset : ScriptableObject
{
    [SerializeField]
    public List<Vector3> poss;
    [SerializeField]

    [System.Serializable]
    public class SH_Coef
    {
        public List<Vector3> c;
    }

    [SerializeField]
    public List<SH_Coef> SHs;
}

