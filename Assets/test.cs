using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class Test : MonoBehaviour
{
    public bool show;
    //[HideInInspector]
    public Mesh mesh;
    //[HideInInspector]
    public Material mat;
    [HideInInspector]
    public CommandBuffer cb;
    ComputeBuffer argsBuffer;
    public ComputeBuffer posBuffer;
    public ComputeBuffer shBuffer;

    private void Awake()
    {
        show = false;
    }

    private void OnDestroy()
    {
        if (argsBuffer != null) argsBuffer.Release();
    }


#if UNITY_EDITOR
    private void OnDrawGizmos()
    {
        if (cb == null) cb = new CommandBuffer();
        if (argsBuffer == null) argsBuffer = new ComputeBuffer(1, 5 * sizeof(uint), ComputeBufferType.IndirectArguments);
        cb.Clear();
        if (show)
        {
            argsBuffer.SetData(new uint[] { mesh.GetIndexCount(0), (uint)20, mesh.GetIndexStart(0), mesh.GetBaseVertex(0), 0 });

            cb.DrawMeshInstancedIndirect(mesh, 0, mat, 0, argsBuffer);
        }
    }
#endif
}
