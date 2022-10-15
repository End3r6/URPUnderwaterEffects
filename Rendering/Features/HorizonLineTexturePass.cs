using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

using System.Collections;
using System.Collections.Generic;

public class HorizonLineTexturePass : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        public float horizonLine;

        //future settings
        public Shader shader;
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
    }

    public Settings settings = new Settings();

    class Pass : ScriptableRenderPass
    {
        public Settings settings;
        private RenderTargetIdentifier source;

        RenderTargetHandle horizonTexture;
        RenderTargetHandle tempTexture;

        private readonly List<ShaderTagId> shaderTagIdList = new List<ShaderTagId>();

        private FilteringSettings filteringSettings = new FilteringSettings(RenderQueueRange.transparent);

        private string profilerTag;

        public void Setup(RenderTargetIdentifier source)
        {
            this.source = source;
        }

        public Pass(string profilerTag)
        {
            this.profilerTag = profilerTag;

            horizonTexture.Init("_HorizonLineTexture");

            shaderTagIdList.Add(new ShaderTagId("UniversalForward"));
            shaderTagIdList.Add(new ShaderTagId("UniversalForwardOnly"));
            shaderTagIdList.Add(new ShaderTagId("SRPDefaultUnlit"));
            // shaderTagIdList.Add(new ShaderTagId("Always"));
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            //R8 has noticeable banding
            cameraTextureDescriptor.colorFormat = RenderTextureFormat.R16;
            
            //we dont need to resolve AA in every single Blit
            cameraTextureDescriptor.msaaSamples = 1;

            horizonTexture.id = 1;
            tempTexture.id = 2;

            cmd.GetTemporaryRT(horizonTexture.id, cameraTextureDescriptor, FilterMode.Bilinear);
            ConfigureTarget(horizonTexture.Identifier());

            cmd.GetTemporaryRT(tempTexture.id, cameraTextureDescriptor, FilterMode.Bilinear);
            ConfigureTarget(tempTexture.Identifier());

            ConfigureClear(ClearFlag.All, Color.black);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(profilerTag);
            cmd.ClearRenderTarget(true, false, Color.black);

            Material material = new Material(settings.shader);

            Material waterPlaneMat = new Material(Shader.Find("Hidden/White"));
            Material backFaceMat = new Material(Shader.Find("Hidden/BlackUnder"));

            //it is very important that if something fails our code still calls 
            //CommandBufferPool.Release(cmd) or we will have a HUGE memory leak
            try
            {
                material.SetFloat("_HorizonLine", settings.horizonLine);

                cmd.Blit(tempTexture.Identifier(), horizonTexture.Identifier(), material, 0);

                cmd.SetGlobalTexture("_HorizonLineTexture", horizonTexture.Identifier());

                context.ExecuteCommandBuffer(cmd);

                DrawingSettings drawSettings = CreateDrawingSettings(shaderTagIdList, ref renderingData, SortingCriteria.CommonOpaque);
                DrawingSettings drawSettingsUnder = CreateDrawingSettings(shaderTagIdList, ref renderingData, SortingCriteria.CommonOpaque);

                drawSettings.overrideMaterial = waterPlaneMat;
                drawSettingsUnder.overrideMaterial = backFaceMat;

                context.DrawRenderers(renderingData.cullResults, ref drawSettings, ref filteringSettings);
                context.DrawRenderers(renderingData.cullResults, ref drawSettingsUnder, ref filteringSettings);
            }
            catch
            {
                Debug.LogError($"An error has occured in {profilerTag}");
            }

            // context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }

    Pass pass;
    RenderTargetHandle renderTextureHandle;
    public override void Create()
    {
        pass = new Pass("Horizon Line Texture");
        name = "Horizon Line Texture";
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


