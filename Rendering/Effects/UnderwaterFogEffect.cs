using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Rendering.Universal;

[UnderwaterEffect(UnderwaterEffectOrder.Fog)]
public sealed class UnderwaterFogEffect : UnderwaterEffect<UnderwaterFogVolume>
{
    private readonly Material material;

    public UnderwaterFogEffect()
    {
        material =
            CoreUtils.CreateEngineMaterial(
                Shader.Find("Hidden/UnderwaterFog"));
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
            cameraColor.GetDescriptor(renderGraph);

        descriptor.name =
            "Underwater Fog";

        TextureHandle destination =
            renderGraph.CreateTexture(
                descriptor);

        material.SetColor(
            "_FogColor",
            Volume.fogColor.value);

        material.SetFloat(
            "_Vision",
            Volume.vision.value);

        material.SetFloat(
            "_Absorption",
            Volume.absorption.value);

        material.SetFloat(
            "_Desaturation",
            Volume.desaturation.value);

        material.SetFloat(
            "_RedAbsorption",
            Volume.redAbsorption.value);

        material.SetFloat(
            "_GreenAbsorption",
            Volume.greenAbsorption.value);

        material.SetFloat(
            "_DebugView",
            Volume.debugView.value
                ? 1f
                : 0f);

        renderGraph.AddBlitPass(
            new RenderGraphUtils
                .BlitMaterialParameters(
                    cameraColor,
                    destination,
                    material,
                    0),
            "Underwater Fog");

        renderGraph.AddCopyPass(
            destination,
            cameraColor,
            "Underwater Fog Copy");
    }

    public override void Dispose()
    {
        CoreUtils.Destroy(material);
    }
}