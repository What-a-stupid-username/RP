using UnityEngine;
using UnityEngine.Rendering;

namespace vrp
{

    public class GetMinMaxOfTexture
    {
        public ComputeShader minMax;
        int main;
        Texture tex;
        ComputeBuffer tmpBuffer;

        public GetMinMaxOfTexture(ComputeShader minMax_in, Texture tex_in, string name = "")
        {
            minMax = minMax_in;
            tex = tex_in;
            main = minMax.FindKernel("Main");
            tmpBuffer = new ComputeBuffer(1024, 32);

            minMax.SetTexture(main, "_Texture", tex);
            minMax.SetBuffer(main, "_Result", tmpBuffer);
            minMax.SetInt("_Width", tex.width / 32);
            minMax.SetInt("_Height", tex.height / 32);
            name += "_MinMax";
            Shader.SetGlobalBuffer(name, tmpBuffer);
        }
        public void Update()
        {
            minMax.Dispatch(main, 1, 1, 1);
        }
        public void Update(CommandBuffer cb)
        {
            cb.DispatchCompute(minMax, main, 1, 1, 1);
        }

        public void Dispose()
        {
            tmpBuffer.Dispose();
        }
    }

}