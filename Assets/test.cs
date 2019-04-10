using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class test : MonoBehaviour
{
    public RenderTexture rt;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        Debug.Log(transform.worldToLocalMatrix);
        Debug.Log(Matrix4x4.Translate(-transform.position) * Matrix4x4.Rotate(Quaternion.Euler(0, 90, 0)));
        Debug.Log(GetComponent<Camera>().worldToCameraMatrix);
    }
}
