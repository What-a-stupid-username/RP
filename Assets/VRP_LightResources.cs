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
        public Vector4 reserve;   // NULL
    }

    public class LightResources
    {
        private int lightNum = 0;
        private ComputeBuffer lightBuffer;
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
        private ShaderPropertyID shaderPropertyID;

        public void UpdateLightBuffer(List<VisibleLight> lights)
        {
            if (lights.Count != lightNum)
            {
                lightNum = lights.Count;
                if (lightNum == 0)
                {
                    Shader.SetGlobalInt(shaderPropertyID.lightSum, lightNum);
                    return;
                }
                if (lightBuffer != null)
                {
                    lightBuffer.Release();
                    lightBuffer = null;
                }
                lightBuffer = new ComputeBuffer(lights.Count, 64);
                BindLightBuffer();
            }
            if (lightNum == 0) return;
            List<LightStruct> lights_ = new List<LightStruct>();
            foreach(var light in lights)
            {
                LightStruct lightStruct = new LightStruct();
                Matrix4x4 l2w = light.localToWorld;
                switch (light.lightType)
                {
                    case LightType.Directional:
                        {
                            lightStruct.geometry = new Vector3(l2w.m02, l2w.m12, l2w.m22).normalized;
                            lightStruct.pos_type = -lightStruct.geometry;
                            lightStruct.geometry.w = float.MaxValue;
                            lightStruct.pos_type.w = 0;
                        }
                        break;
                    case LightType.Point:
                        {
                            lightStruct.pos_type = new Vector4(l2w.m03, l2w.m13, l2w.m23, 1);
                            lightStruct.geometry = new Vector3(l2w.m02, l2w.m12, l2w.m22).normalized;
                            lightStruct.geometry.w = light.range;
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
            lightBuffer.SetData(lights_);
        }

        public void BindLightBuffer()
        {
            if (lightBuffer != null && lightBuffer.IsValid())
            {
                Shader.SetGlobalBuffer(shaderPropertyID.lightBuffer, lightBuffer);
                Shader.SetGlobalInt(shaderPropertyID.lightSum, lightNum);
            }
            else
            {
                Debug.LogError("Light buffer is not valid");
            }
        }

        public LightResources()
        {
            shaderPropertyID = new ShaderPropertyID();
        }
        public void Dispose()
        {
            if (lightBuffer != null)
                lightBuffer.Dispose();
        }
    }
}
