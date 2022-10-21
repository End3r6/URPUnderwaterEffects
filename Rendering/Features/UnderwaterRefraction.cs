using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class UnderwaterRefraction : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        [System.Serializable]
        public class Noise
        {
            public float scale;
        }

        public Noise noise = new Noise();

        public float intensity;
        public float speed;

        //future settings
        public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
    }

    public Settings settings = new Settings();

    class Pass : ScriptableRenderPass
    {
        public Settings settings;
        private RenderTargetIdentifier source;

        RenderTargetHandle tempTexture;

        private string profilerTag;

        public void Setup(RenderTargetIdentifier source)
        {
            this.source = source;
        }

        public Pass(string profilerTag)
        {
            this.profilerTag = profilerTag;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            //R8 has noticeable banding
            cameraTextureDescriptor.colorFormat = RenderTextureFormat.ARGB32;
            
            //we dont need to resolve AA in every single Blit
            cameraTextureDescriptor.msaaSamples = 1;

            // tempTexture.id = 1;

            cmd.GetTemporaryRT(tempTexture.id, cameraTextureDescriptor);
            ConfigureTarget(tempTexture.Identifier());

            ConfigureClear(ClearFlag.All, Color.black);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(profilerTag);
            cmd.Clear();

            //it is very important that if something fails our code still calls 
            //CommandBufferPool.Release(cmd) or we will have a HUGE memory leak
            try
            {
                Material material = new Material(Shader.Find("Hidden/UnderwaterRefraction"));
                
                material.SetFloat("scale", settings.noise.scale);
                material.SetFloat("speed", settings.speed);
                material.SetFloat("intensity", settings.intensity);
                
                cmd.Blit(source, tempTexture.Identifier());
                cmd.Blit(tempTexture.Identifier(), source, material, 0);

                context.ExecuteCommandBuffer(cmd);
            }
            catch
            {
                Debug.LogError($"An error has occured in {profilerTag}");
            }

            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }
    }

    Pass pass;
    RenderTargetHandle renderTextureHandle;
    public override void Create()
    {
        pass = new Pass("Underwater Refraction");
        name = "Underwater Refraction";
        pass.settings = settings;
        pass.renderPassEvent = settings.renderPassEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        var cameraColorTargetIdent = renderer.cameraColorTarget;
        pass.Setup(cameraColorTargetIdent);
        renderer.EnqueuePass(pass);
    }
}


