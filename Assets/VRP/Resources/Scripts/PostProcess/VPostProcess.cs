using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace vrp
{
    public class TextureIdentifiers
    {
        public bool init;
        public RenderTargetIdentifier depth_Velocity;
        public RenderTargetIdentifier sceneColor;
        public RenderTargetIdentifier sceneColorPrev;
        public RenderTargetIdentifier baseColor_Metallic;
        public RenderTargetIdentifier normal_Roughness;
        public TextureIdentifiers() {
            init = false;
            depth_Velocity = BuiltinRenderTextureType.None;
            sceneColor = BuiltinRenderTextureType.None;
            sceneColorPrev = BuiltinRenderTextureType.None;
            baseColor_Metallic = BuiltinRenderTextureType.None;
            normal_Roughness = BuiltinRenderTextureType.None;
        }
    }

    public class VPostProcess : MonoBehaviour
    {
        public bool enabled = true;
        [SerializeField]
        [Range(0, 100)]
        [Tooltip("Will be execute from smaller to bigger. If the priority is same, they will be execute from top to buttom as their order on the inspector.")]
        public int priority;
        [HideInInspector]
        public CommandBuffer cb;
        [HideInInspector]
        public TextureIdentifiers textureIdentifiers;

        public virtual void Init()
        {
            if (textureIdentifiers == null) {
                textureIdentifiers = new TextureIdentifiers();
                cb = new CommandBuffer();
            }
        }

        public virtual void ReuildCommandBuffer() { }
    }
}

