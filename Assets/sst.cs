using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

public class sst : MonoBehaviour
{
    List<Vector3> vs;
    // Start is called before the first frame update
    void Start()
    {
        WriteTXT();
    }

    Vector3 UniformSampleHemisphere(Vector2 E)
    {
        float Phi = 2 * Mathf.PI * E.x;
        float CosTheta = Mathf.Sqrt(E.y);
        float SinTheta = Mathf.Sqrt(1 - CosTheta * CosTheta);

        Vector3 H;
        H.x = SinTheta * Mathf.Cos(Phi);
        H.y = CosTheta;
        H.z = SinTheta* Mathf.Sin(Phi);

        return H - Vector3.up;
    }


    void WriteTXT()
    {
        StreamWriter sw;
        FileInfo fi = new FileInfo(Application.streamingAssetsPath + "/" + "aaa.txt");
        Debug.Log(fi);
        if (!fi.Exists)
        {
            Debug.Log("写入 不存在");
            sw = fi.CreateText();
            for (int i = 0; i < 128; i++)
            {
                Vector2 a;
                a.x = Random.Range(0f, 1f);
                a.y = Random.Range(0f, 1f);
                var v = UniformSampleHemisphere(a);
                string str = "float3(" + v.x.ToString() + "f," + v.y.ToString() + "f," + v.z.ToString() + "f),";
                sw.WriteLine(str);
            }
            sw.Close();
        }
        else
        {
            Debug.Log("写入 存在");
            sw = fi.CreateText();
            //	sw = fi.AppendText ();
            //	sw.WriteLine ("this is a line.");
        }
    }

    private void Update()
    {

    }
}
