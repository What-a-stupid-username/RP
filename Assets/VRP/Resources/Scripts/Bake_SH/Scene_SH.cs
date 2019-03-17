using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Scene_SH : MonoBehaviour
{
    public SHAsset asset;

#if UNITY_EDITOR
    private void OnDrawGizmos()
    {
        if (asset == null) return;
        Color c = Gizmos.color;
        for (int i = 0; i < asset.poss.Count; i++)
        {
            Vector3 col = asset.SHs[i].c[0];
            Gizmos.color = new Color(col.x, col.y, col.z);
            Gizmos.DrawSphere(asset.poss[i], 0.1f);
        }
        Gizmos.color = c;
    }
#endif
}
