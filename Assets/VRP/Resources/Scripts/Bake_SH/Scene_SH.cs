using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class Scene_SH : MonoBehaviour
{
    public SHAsset asset;
    public bool show;
    [HideInInspector]
    public Mesh mesh;
    [HideInInspector]
    public Material mat;
    [HideInInspector]
    public CommandBuffer cb;
    ComputeBuffer argsBuffer;
    public ComputeBuffer posBuffer;
    public ComputeBuffer shBuffer;

    private void Awake()
    {
        PrepareBuffer();
        show = false;
    }

    public void PrepareBuffer()
    {
        if (asset == null) return;

        if (posBuffer == null) posBuffer = new ComputeBuffer(asset.poss.Count, 16);
        if (shBuffer == null) shBuffer = new ComputeBuffer(asset.poss.Count * 9, 16);

        Vector4[] poss = new Vector4[asset.poss.Count];
        Vector4[] shs = new Vector4[asset.poss.Count * 9];
        for (int i = 0; i < asset.poss.Count; i++)
        {
            Vector3 col = asset.SHs[i].c[0];
            poss[i] = asset.poss[i];
            for (int j = 0; j < 9; j++)
            {
                shs[i * 9 + j] = asset.SHs[i].c[j];
            }
        }
        posBuffer.SetData(poss);
        shBuffer.SetData(shs);

    }

    private void OnDestroy()
    {
        if (posBuffer != null) posBuffer.Release();
        if (shBuffer != null) shBuffer.Release();
        if (argsBuffer != null) argsBuffer.Release();
    }


#if UNITY_EDITOR
    private void OnDrawGizmos()
    {
        if (asset == null) return;
        if (cb == null) cb = new CommandBuffer();
        if (argsBuffer == null) argsBuffer = new ComputeBuffer(1, 5 * sizeof(uint), ComputeBufferType.IndirectArguments);
        cb.Clear();
        if (show)
        {
            PrepareBuffer();

            argsBuffer.SetData(new uint[] { mesh.GetIndexCount(0), (uint)asset.poss.Count, mesh.GetIndexStart(0), mesh.GetBaseVertex(0), 0 });

            mat.SetBuffer("posBuffer", posBuffer);
            mat.SetBuffer("shBuffer", shBuffer);
            cb.DrawMeshInstancedIndirect(mesh, 0, mat, 0, argsBuffer);
        }
    }
#endif
}
