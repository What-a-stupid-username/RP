using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace vrp
{

    public class Bake_GI_Window : EditorWindow
    {
        static float axle_l = 0.2f;
        VRP_Bake_GI_E instance = VRP_Bake_GI_E.instance;
        static void DrawAxle(Vector3 pos)
        {
            Debug.DrawLine(pos, pos + Vector3.right * axle_l, Color.red);
            Debug.DrawLine(pos, pos + Vector3.up * axle_l, Color.green);
            Debug.DrawLine(pos, pos + Vector3.forward * axle_l, Color.blue);
        }

        private static Rect middleCenterRect = new Rect(200, 100, 400, 400);
        private void OnGUI()
        {
            EditorGUILayout.BeginVertical();
            int probe_amount = EditorGUILayout.IntField("GI probe Amount", instance.probe_amount);
            probe_amount = probe_amount < 10 ? 10 : probe_amount;
            instance.probe_amount = probe_amount;
            if (instance.rt == null)
                instance.rt = new RenderTexture(256, 256, 24);
            if (GUILayout.Button("Bake"))
            {
                instance.shg.Init(instance.rt);
                instance.shg.Draw();
            }
            EditorGUI.DrawPreviewTexture(new Rect(18, 240, 256, 256), instance.rt);
            EditorGUILayout.EndVertical();
        }
    }

    public class VRP_Bake_GI_E
    {
        GameObject go;
        public RenderTexture rt;
        public VRP_GI_SH shg
        {
            get
            {
                VRP_GI_SH shg_;
                if (go == null)
                {
                    go = new GameObject();
                    go.name = "GI Baker";
                    go.AddComponent<VRP_GI_SH>();
                    go.hideFlags = HideFlags.DontSave;
                }
                shg_ = go.GetComponent<VRP_GI_SH>();
                return shg_;
            }
        }
        public bool able_to_bake
        {
            get
            {
                return GraphicsSettings.renderPipelineAsset.GetType() == typeof(VRPAsset);
            }
        }
        [Min(10)]
        public int probe_amount = 2;

        public static readonly VRP_Bake_GI_E instance = new VRP_Bake_GI_E();
        [MenuItem("VRP/Tools/Bake GI")]
        static void BakeGI()
        {
            var window = EditorWindow.GetWindow<Bake_GI_Window>(true, "Bake GI", true);
            window.Show();
        }
        VRP_Bake_GI_E()
        {

        }

    }
}


