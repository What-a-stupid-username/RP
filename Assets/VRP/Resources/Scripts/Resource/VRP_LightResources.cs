using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace vrp
{
    public struct LightStruct
    {
        public Vector4 pos_type;  // XYZ(position)W(type)
        public Vector4 geometry;  // XYZ(normalized direction xyz)W(radio)
        public Vector4 color;     // XYZ(color)W(strength)
        public Vector4 others;   // NULL
    }

    public class LightResources
    {
        private VComputeBuffer lightBuffer;
        private class ShaderPropertyID
        {
            public int lightBuffer;
            public int lightSum;
            public ShaderPropertyID()
            {
                lightBuffer = Shader.PropertyToID("_LightBuffer");
                lightSum = Shader.PropertyToID("_LightSum");
            }
        };
        private static readonly ShaderPropertyID shaderPropertyID = new ShaderPropertyID();

        public void UpdateLightBuffer(ref Dictionary<Light, int> lights_table, List<VisibleLight> lights, ref CommandBuffer setup_properties)
        {
            lightBuffer.TestNeedModify(lights.Count);
            BindProperties(lights.Count, ref setup_properties);
            if (lights.Count == 0) return;

            List<LightStruct> lights_ = new List<LightStruct>();
            try
            {
                foreach (var light in lights)
                {
                    LightStruct lightStruct = new LightStruct();
                    Matrix4x4 l2w = light.localToWorld;
                    lightStruct.others = new Vector4(-1, -1, -1, -1);
                    switch (light.lightType)
                    {
                        case LightType.Directional:
                            {
                                lightStruct.geometry = new Vector3(l2w.m02, l2w.m12, l2w.m22).normalized;
                                lightStruct.pos_type = -lightStruct.geometry;
                                lightStruct.geometry.w = float.MaxValue;
                                lightStruct.pos_type.w = 0;
                                if (light.light.shadows != LightShadows.None)
                                    lightStruct.others.x = lights_table[light.light];
                            }
                            break;
                        case LightType.Point:
                            {
                                lightStruct.pos_type = new Vector4(l2w.m03, l2w.m13, l2w.m23, 1);
                                lightStruct.geometry = new Vector3(l2w.m02, l2w.m12, l2w.m22).normalized;
                                lightStruct.geometry.w = light.range;
                                if (light.light.shadows != LightShadows.None)
                                    lightStruct.others.x = lights_table[light.light];
                            }
                            break;
                        case LightType.Spot:
                            {
                                lightStruct.pos_type = new Vector4(l2w.m03, l2w.m13, l2w.m23, 2);
                                lightStruct.geometry = new Vector3(l2w.m02, l2w.m12, l2w.m22).normalized;
                                lightStruct.geometry.w = Mathf.Cos(light.spotAngle / 360 * Mathf.PI);
                            }
                            break;
                    }
                    lightStruct.color = light.finalColor;
                    lightStruct.color.w = 1;
                    lights_.Add(lightStruct);
                }
            }
            catch (Exception)
            {
                Debug.Log(lights.Count);
                Debug.Log(lights_table.Count);
            }
            lightBuffer.data.SetData(lights_);
        }

        public void BindProperties(int lightNum, ref CommandBuffer cb)
        {
            cb.SetGlobalInt(shaderPropertyID.lightSum, lightNum);
            if (lightBuffer.IsValid())
            {
                cb.SetGlobalBuffer(shaderPropertyID.lightBuffer, lightBuffer.data);
            }
        }

        public LightResources()
        {
            lightBuffer = new VComputeBuffer(64);
        }
        public void Dispose()
        {
            if (lightBuffer != null)
                lightBuffer.Dispose();
        }
    }
}
