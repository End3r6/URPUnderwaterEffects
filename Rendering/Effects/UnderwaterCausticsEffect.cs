using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Rendering.Universal;

public sealed class UnderwaterCausticsEffect
    : UnderwaterEffect<UnderwaterCausticsVolume>
{
    private readonly Material material;

    public UnderwaterCausticsEffect()
    {
        material =
            CoreUtils.CreateEngineMaterial(
                Shader.Find(
                    "Hidden/UnderwaterCaustics"));
    }

    public override bool IsActive()
    {
        return Volume != null &&
               Volume.enabled.value &&
               Volume.causticsTexture.value != null;
    }

    public override void RecordRenderGraph(
        RenderGraph renderGraph,
        ContextContainer frameData)
    {
        if (!IsActive())
            return;

        UniversalResourceData resourceData =
            frameData.Get<UniversalResourceData>();

        UniversalLightData lightData =
            frameData.Get<UniversalLightData>();

        if (resourceData.isActiveTargetBackBuffer)
            return;

        TextureHandle cameraColor =
            resourceData.activeColorTexture;

        TextureDesc descriptor =
            cameraColor.GetDescriptor(
                renderGraph);

        descriptor.name =
            "Underwater Caustics";

        TextureHandle destination =
            renderGraph.CreateTexture(
                descriptor);

        material.SetTexture(
            "_Caustics",
            Volume.causticsTexture.value);

        material.SetFloat(
            "_Speed",
            Volume.speed.value);

        material.SetFloat(
            "_Tiling",
            Volume.tiling.value);

        material.SetFloat(
            "_RGBSplit",
            Volume.rgbSplit.value);

        material.SetFloat(
            "_Intensity",
            Volume.intensity.value);

        material.SetFloat(
            "_Range",
            Volume.range.value);

        material.SetColor(
            "_CausticColor",
            Volume.color.value);

        material.SetFloat(
            "_DepthFade",
            Volume.depthFade.value);

        material.SetFloat(
            "_UnderwaterOnly",
            Volume.underwaterOnly.value
                ? 1f
                : 0f);

        material.SetFloat(
            "_Coverage",
            Volume.coverage.value);

        material.SetFloat(
            "_LightDirectionBias",
            Volume.lightDirectionBias.value);

        material.SetFloat(
            "_LightStretch",
            Volume.lightStretch.value);

        renderGraph.AddBlitPass(
            new RenderGraphUtils
                .BlitMaterialParameters(
                    cameraColor,
                    destination,
                    material,
                    0),
            "Underwater Caustics");

        renderGraph.AddCopyPass(
            destination,
            cameraColor,
            "Underwater Caustics Copy");
    }

    public override void Dispose()
    {
        CoreUtils.Destroy(
            material);
    }
}