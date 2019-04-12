using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.Linq;

namespace vrp
{
    class UpdateMaterial
    {
        [MenuItem("VRP/Tools/Update Materials #M")]
        static void UpdateMaterials()
        {
            var delfautShader = Shader.Find("VRP/default");
            var gos = GetAllSceneObjectsWithInactive();
            HashSet<Material> mats = new HashSet<Material>();
            foreach (var go in gos)
            {
                var mr = go.GetComponent<MeshRenderer>();
                if (mr)
                {
                    var mat = mr.sharedMaterials;
                    foreach (var ma in mat)
                    {
                        mats.Add(ma);
                    }
                }
            }
            foreach (var mat in mats)
            {
                if (mat!=null)
                    mat.shader = delfautShader;
            }
        }


        //用于获取所有Hierarchy中的物体，包括被禁用的物体
        static private List<GameObject> GetAllSceneObjectsWithInactive()
        {
            var allTransforms = Resources.FindObjectsOfTypeAll(typeof(Transform));
            var previousSelection = Selection.objects;
            Selection.objects = allTransforms.Cast<Transform>()
                .Where(x => x != null)
                .Select(x => x.gameObject)
                //如果你只想获取所有在Hierarchy中被禁用的物体，反注释下面代码
                //.Where(x => x != null && !x.activeInHierarchy)
                .Cast<UnityEngine.Object>().ToArray();

            var selectedTransforms = Selection.GetTransforms(SelectionMode.Editable | SelectionMode.ExcludePrefab);
            Selection.objects = previousSelection;

            return selectedTransforms.Select(tr => tr.gameObject).ToList();
        }
    }
}



