using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Rendering.Universal;

[UnderwaterEffect(UnderwaterEffectOrder.BlurredWaterLine)]
public sealed class UnderwaterBlurredWaterLineEffect : UnderwaterEffect<UnderwaterBlurredWaterLineVolume>
{
    private readonly Material material;

    public UnderwaterBlurredWaterLineEffect()
    {
        material =
            CoreUtils.CreateEngineMaterial(
                Shader.Find(
                    "Hidden/UnderwaterBlurredWaterLine"));
    }


    public override void RecordRenderGraph(
        RenderGraph renderGraph,
        ContextContainer frameData)
    {
        if (!IsActive())
            return;

        UniversalResourceData resourceData =
            frameData.Get<UniversalResourceData>();

        if (resourceData.isActiveTargetBackBuffer)
            return;

        TextureHandle cameraColor =
            resourceData.activeColorTexture;

        TextureDesc descriptor =
            cameraColor.GetDescriptor(
                renderGraph);

        descriptor.name =
            "Blurred Water Line";

        TextureHandle destination =
            renderGraph.CreateTexture(
                descriptor);

        material.SetColor(
            "_WaterLineColor",
            Volume.color.value);

        material.SetFloat(
            "_Intensity",
            Volume.intensity.value);

        material.SetFloat(
            "_Thickness",
            Volume.thickness.value);

        material.SetFloat(
            "_Softness",
            Volume.softness.value);

        material.SetFloat(
            "_VerticalBlur",
            Volume.verticalBlur.value);

        material.SetFloat(
            "_HighlightThickness",
            Volume.highlightThickness.value);

        material.SetFloat(
            "_RefractionStrength",
            Volume.refractionStrength.value);

        material.SetFloat(
            "_HighlightIntensity",
            Volume.highlightIntensity.value);

        material.SetFloat(
            "_HighlightFineNoiseScale",
            Volume.highlightFineNoiseScale.value);

        material.SetFloat(
            "_HighlightBroadNoiseScale",
            Volume.highlightBroadNoiseScale.value);

        renderGraph.AddBlitPass(
            new RenderGraphUtils
                .BlitMaterialParameters(
                    cameraColor,
                    destination,
                    material,
                    0),
            "Blurred Water Line");

        renderGraph.AddCopyPass(
            destination,
            cameraColor,
            "Blurred Water Line Copy");
    }

    public override void Dispose()
    {
        CoreUtils.Destroy(
            material);
    }
}