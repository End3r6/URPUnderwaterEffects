using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

using System.Collections;
using System.Collections.Generic;

public class BlurredWaterLinePass : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        public Color waterLineColor;

        public float width = 4;
        public float height = 4;
        // public int steps = 10;
        public float threshold = 0.78f;

        public float intensity = 2;

        [Range(0, 1)]
        public float min = 0;
        [Range(0, 1)]
        public float max = 1;

        //future settings
        public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
    }

    public Settings settings = new Settings();

    class Pass : ScriptableRenderPass
    {
        public Settings settings;
        private RenderTargetIdentifier source;

        RenderTargetHandle tempTexture;
        RenderTargetHandle invertLine;
        RenderTargetHandle tempWaterLineMask;

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

            tempTexture.id = 5;
            invertLine.id = 6;
            tempWaterLineMask.id = 7;

            cmd.GetTemporaryRT(tempTexture.id, cameraTextureDescriptor);
            ConfigureTarget(tempTexture.Identifier());

            cmd.GetTemporaryRT(invertLine.id, cameraTextureDescriptor);
            ConfigureTarget(invertLine.Identifier());

            cmd.GetTemporaryRT(tempWaterLineMask.id, cameraTextureDescriptor);
            ConfigureTarget(tempWaterLineMask.Identifier());

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
                Material material = new Material(Shader.Find("Hidden/BluredWaterline"));
                Material invert = new Material(Shader.Find("Hidden/InvertWaterLine"));
                
                material.SetFloat("width", settings.width);
                material.SetFloat("height", settings.height);

                material.SetFloat("threshold", settings.threshold);

                material.SetFloat("intensity", settings.intensity);
                material.SetFloat("minBlur", settings.min);
                material.SetFloat("maxBlur", settings.max);

                material.SetColor("waterLineTint", settings.waterLineColor);
                
                // cmd.Blit(source, tempTexture.Identifier(), invert);
                // cmd.SetGlobalTexture("_InvHorizonLineTexture", tempTexture.id);

                cmd.Blit(source, tempTexture.Identifier(), material, 0);
                cmd.SetGlobalTexture("_BlurredWaterLine", tempWaterLineMask.id);

                cmd.Clear();

                cmd.Blit(source, tempWaterLineMask.Identifier(), material, 1);
                cmd.Blit(tempWaterLineMask.Identifier(), source);

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
        pass = new Pass("Blured Waterline Texture");
        name = "Blured Waterline Texture";
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


