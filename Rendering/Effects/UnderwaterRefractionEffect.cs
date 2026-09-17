using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Rendering.Universal;

public sealed class UnderwaterRefractionEffect
    : UnderwaterEffect<UnderwaterRefractionVolume>
{
    private readonly Material material;

    public UnderwaterRefractionEffect()
    {
        material =
            CoreUtils.CreateEngineMaterial(
                Shader.Find(
                    "Hidden/UnderwaterRefraction"));
    }

    public override bool IsActive()
    {
        return Volume != null &&
               Volume.enabled.value;
    }

    public override void RecordRenderGraph(
        RenderGraph renderGraph,
        ContextContainer frameData)
    {
        if (Volume == null)
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
            "Underwater Refraction";

        TextureHandle destination =
            renderGraph.CreateTexture(
                descriptor);

        material.SetFloat(
            "_LargeScale",
            Volume.largeScale.value);

        material.SetFloat(
            "_LargeStrength",
            Volume.largeStrength.value);

        material.SetFloat(
            "_SmallScale",
            Volume.smallScale.value);

        material.SetFloat(
            "_SmallStrength",
            Volume.smallStrength.value);

        material.SetFloat(
            "_Speed",
            Volume.speed.value);

        material.SetVector(
            "_FlowDirection",
            Volume.flowDirection.value);

        material.SetFloat(
            "_DepthDistance",
            Volume.depthDistance.value);

        material.SetFloat(
            "_EdgeStrength",
            Volume.edgeStrength.value);

        material.SetFloat(
            "_ChromaticStrength",
            Volume.chromaticStrength.value);

        renderGraph.AddBlitPass(
            new RenderGraphUtils
                .BlitMaterialParameters(
                    cameraColor,
                    destination,
                    material,
                    0),
            "Underwater Refraction");

        renderGraph.AddCopyPass(
            destination,
            cameraColor,
            "Underwater Refraction Copy");
    }

    public override void Dispose()
    {
        CoreUtils.Destroy(
            material);
    }
}