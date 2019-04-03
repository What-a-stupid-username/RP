using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class test : MonoBehaviour
{
    public RenderTexture rt;

    // Start is called before the first frame update
    void Start()
    {
        GetComponent<Camera>().RenderToCubemap(rt);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
