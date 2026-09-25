using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;

[UnderwaterEffect(UnderwaterEffectOrder.TransparentDepthTexture)]
public sealed class TransparentDepthEffect : UnderwaterEffect<UnderwaterFogVolume>
{

    private sealed class TransparentDepthPassData
    {
        public List<Renderer> Renderers;
        public Material Material;
    }

    private readonly Material material;

    private RTHandle transparentDepthHandle;

    public TransparentDepthEffect()
    {
        material =
            CoreUtils.CreateEngineMaterial(
                Shader.Find("Hidden/TransparentDepth"));
    }

    public override void RecordRenderGraph(
        RenderGraph renderGraph,
        ContextContainer frameData)
    {
        if (!IsActive())
            return;

        UniversalResourceData resourceData =
            frameData.Get<UniversalResourceData>();

        UniversalCameraData cameraData =
            frameData.Get<UniversalCameraData>();

        if (resourceData.isActiveTargetBackBuffer)
            return;

        TextureHandle cameraDepth =
            resourceData.activeDepthTexture;

        RenderTextureDescriptor descriptor =
            cameraData.cameraTargetDescriptor;

        descriptor.depthBufferBits = 0;
        descriptor.msaaSamples = 1;

        descriptor.graphicsFormat =
            GraphicsFormat.R16G16B16A16_SFloat;

        RenderingUtils.ReAllocateHandleIfNeeded(
            ref transparentDepthHandle,
            descriptor,
            FilterMode.Point,
            TextureWrapMode.Clamp,
            name: "_TransparentDepthTexture");

        TextureHandle transparentDepthTexture =
            renderGraph.ImportTexture(
                transparentDepthHandle);

        List<Renderer> renderers = new();

        foreach (TransparentDepthSettings setting
            in TransparentDepthSettings.Instances)
        {
            if (!setting)
                continue;

            if (!setting.TryGetComponent(
                    out Renderer renderer))
            {
                continue;
            }

            if (!renderer.enabled)
                continue;

            renderers.Add(
                renderer);
        }

        using (IRasterRenderGraphBuilder builder = renderGraph.AddRasterRenderPass("Transparent Depth Texture", out TransparentDepthPassData passData))
        {
            passData.Renderers = renderers;
            passData.Material = material;

            builder.SetRenderAttachment(
                transparentDepthTexture,
                0);

            builder.SetRenderAttachmentDepth(
                cameraDepth,
                AccessFlags.Read);

            builder.AllowPassCulling(
                false);

            builder.SetRenderFunc(
                (TransparentDepthPassData data, RasterGraphContext context) =>
                {
                    context.cmd.ClearRenderTarget(
                        false,
                        true,
                        Color.clear);

                    foreach (Renderer renderer in data.Renderers)
                    {
                        if (!renderer)
                            continue;

                        context.cmd.DrawRenderer(
                            renderer,
                            data.Material,
                            0,
                            0);
                    }
                });
        }

        using (IBaseRenderGraphBuilder builder = renderGraph.AddRasterRenderPass<object>("Publish Transparent Depth Texture", out _))
        {
            builder.SetGlobalTextureAfterPass(
                transparentDepthTexture,
                Shader.PropertyToID(
                    "_TransparentDepthTexture"));

            Shader.SetGlobalTexture(
                "_TransparentDepthTexture",
                transparentDepthHandle);
        }
    }

    public override void Dispose()
    {
        CoreUtils.Destroy(
            material);

        transparentDepthHandle?.Release();
    }
}