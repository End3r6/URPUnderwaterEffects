using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RendererUtils;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Rendering.Universal;

[UnderwaterEffect(UnderwaterEffectOrder.WaterLine)]
public sealed class WaterLineMaskEffect
    : UnderwaterEffect
{
    [System.Serializable]
    public class Settings
    {
        [Header("Shared Resources")]
        public LayerMask waterMask = LayerMask.GetMask("Water");

        public float waterLevel = 0.0f;

        public bool debugUnderwaterMask;
    }

    private sealed class RendererListPassData
    {
        public RendererListHandle rendererList;
    }

    private sealed class WaterLineMaskPassData
    {
    }

    private readonly ShaderTagId[] shaderTags =
        {
            new ShaderTagId("UniversalForward"),
            new ShaderTagId("UniversalForwardOnly"),
            new ShaderTagId("SRPDefaultUnlit")
        };


    public Settings settings = new();

    private readonly Material waterLineMaterial;
    private readonly Material upperSideMaterial;
    private readonly Material underSideMaterial;

    private RTHandle waterLineMaskHandle;

    public WaterLineMaskEffect()
    {
        waterLineMaterial =
                CoreUtils.CreateEngineMaterial(
                    Shader.Find("Hidden/HorizonLine"));

        upperSideMaterial =
                CoreUtils.CreateEngineMaterial(
                    Shader.Find("Hidden/UpperSide"));

        underSideMaterial =
                CoreUtils.CreateEngineMaterial(
                    Shader.Find("Hidden/UnderSide"));
    }

    public override bool IsActive()
    {
        return true;
    }

    public override void RecordRenderGraph(
        RenderGraph renderGraph,
        ContextContainer frameData)
    {

        UniversalResourceData resourceData =
                frameData.Get<UniversalResourceData>();

        UniversalRenderingData renderingData =
            frameData.Get<UniversalRenderingData>();

        UniversalCameraData cameraData =
            frameData.Get<UniversalCameraData>();

        if (resourceData.isActiveTargetBackBuffer)
            return;

        TextureHandle cameraColor =
            resourceData.activeColorTexture;

        TextureHandle cameraDepth =
            resourceData.activeDepthTexture;

        RenderTextureDescriptor descriptor =
            cameraData.cameraTargetDescriptor;

        descriptor.depthBufferBits = 0;
        descriptor.msaaSamples = 1;

        RenderingUtils.ReAllocateHandleIfNeeded(
            ref waterLineMaskHandle,
            descriptor,
            FilterMode.Bilinear,
            TextureWrapMode.Clamp,
            name: "_WaterLineMask");

        TextureHandle waterLineMask =
            renderGraph.ImportTexture(
                waterLineMaskHandle);

        // RTHandles.Release(waterLineMaskHandle);
        // waterLineMaskHandle = null;

        waterLineMaterial.SetFloat(
            "_HorizonLine",
            settings.waterLevel);

        //
        // Pass 1
        // Generate water line mask.
        //
        using (IRasterRenderGraphBuilder builder =
            renderGraph.AddRasterRenderPass<WaterLineMaskPassData>(
                "Generate Water Line Mask",
                out WaterLineMaskPassData passData))
        {
            builder.SetRenderAttachment(
                waterLineMask,
                0);

            builder.SetRenderAttachmentDepth(
                cameraDepth,
                AccessFlags.Read);

            builder.AllowPassCulling(false);

            builder.SetRenderFunc(
                (WaterLineMaskPassData data,
                 RasterGraphContext context) =>
                {
                    context.cmd.ClearRenderTarget(
                        false,
                        true,
                        Color.black);

                    context.cmd.DrawProcedural(
                        Matrix4x4.identity,
                        waterLineMaterial,
                        0,
                        MeshTopology.Triangles,
                        3,
                        1);
                });
        }

        //
        // Pass 2
        // Draw upper water faces.
        //
        RendererListDesc upperDesc =
            new RendererListDesc(
                shaderTags,
                renderingData.cullResults,
                cameraData.camera)
            {
                renderQueueRange = RenderQueueRange.all,
                sortingCriteria = SortingCriteria.CommonTransparent,
                layerMask = settings.waterMask,
                overrideMaterial = upperSideMaterial,
                overrideMaterialPassIndex = 0
            };

        RendererListHandle upperList =
            renderGraph.CreateRendererList(upperDesc);

        using (IRasterRenderGraphBuilder builder =
            renderGraph.AddRasterRenderPass<RendererListPassData>(
                "Water Mask Upper Faces",
                out RendererListPassData passData))
        {
            passData.rendererList = upperList;

            builder.UseRendererList(upperList);

            builder.SetRenderAttachment(waterLineMask, 0);

            builder.SetRenderAttachmentDepth(cameraDepth, AccessFlags.Read);

            builder.AllowPassCulling(false);

            builder.SetRenderFunc(
                (RendererListPassData data, RasterGraphContext context) =>
                {
                    context.cmd.DrawRendererList(
                        data.rendererList);
                });
        }

        //
        // Pass 3
        // Draw lower water faces.
        //
        RendererListDesc underDesc =
            new RendererListDesc(
                shaderTags,
                renderingData.cullResults,
                cameraData.camera)
            {
                renderQueueRange = RenderQueueRange.all,
                sortingCriteria = SortingCriteria.CommonTransparent,
                layerMask = settings.waterMask,
                overrideMaterial = underSideMaterial,
                overrideMaterialPassIndex = 0
            };

        RendererListHandle underList =
            renderGraph.CreateRendererList(
                underDesc);

        using (IRasterRenderGraphBuilder builder =
            renderGraph.AddRasterRenderPass<RendererListPassData>(
                "Water Mask Lower Faces",
                out RendererListPassData passData))
        {
            passData.rendererList =
                underList;

            builder.UseRendererList(
                underList);

            builder.SetRenderAttachment(
                waterLineMask,
                0);

            builder.SetRenderAttachmentDepth(
                cameraDepth,
                AccessFlags.Read);

            builder.AllowPassCulling(false);

            builder.SetRenderFunc(
                (RendererListPassData data,
                 RasterGraphContext context) =>
                {
                    context.cmd.DrawRendererList(
                        data.rendererList);
                });
        }

        //
        // Publish globally.
        //
        using (IBaseRenderGraphBuilder builder =
            renderGraph.AddRasterRenderPass<object>(
                "Publish Water Line Mask",
                out _))
        {
            builder.SetGlobalTextureAfterPass(
                waterLineMask,
                Shader.PropertyToID(
                    "_WaterLineMask"));

            //
            // Legacy global binding.
            // This fixes the 4x4 placeholder issue.
            //
            Shader.SetGlobalTexture(
                "_WaterLineMask",
                waterLineMaskHandle);
        }

        //
        // Debug.
        //
        if (settings.debugUnderwaterMask)
        {
            renderGraph.AddCopyPass(
                waterLineMask,
                cameraColor,
                "Water Mask Debug");
        }
    }

    public override void Dispose()
    {
        CoreUtils.Destroy(waterLineMaterial);

        CoreUtils.Destroy(upperSideMaterial);

        CoreUtils.Destroy(underSideMaterial);

        waterLineMaskHandle?.Release();
    }
}