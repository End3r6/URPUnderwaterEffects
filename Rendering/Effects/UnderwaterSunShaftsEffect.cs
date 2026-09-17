using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Rendering.Universal;

public sealed class UnderwaterSunShaftsEffect : UnderwaterEffect<UnderwaterSunShaftsVolume>
{

    private static Texture2D fallbackBlueNoise;

    private static Texture2D FallbackBlueNoise
    {
        get
        {
            if (fallbackBlueNoise == null)
            {
                fallbackBlueNoise =
                    Resources.Load<Texture2D>(
                        "BlueNoise");
            }

            return fallbackBlueNoise;
        }
    }


    private readonly Material material;

    public UnderwaterSunShaftsEffect()
    {
        material =
            CoreUtils.CreateEngineMaterial(
                Shader.Find(
                    "Hidden/UnderwaterSunShafts"));
    }

    public override bool IsActive()
    {
        return Volume != null &&
               Volume.enabled.value;
    }

    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
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
            "Sun Shafts Source";

        //
        // Shared params
        //
        UnderwaterCausticsVolume caustics =
            VolumeManager.instance.stack
                .GetComponent<UnderwaterCausticsVolume>();

        bool usingCaustics =
            Volume.inheritCaustics.value &&
            caustics != null &&
            caustics.enabled.value &&
            caustics.causticsTexture.value != null;

        if (usingCaustics)
        {
            material.SetTexture(
                "_NoiseTex",
                caustics.causticsTexture.value);

            material.SetFloat(
                "_Scale",
                caustics.tiling.value);

            material.SetFloat(
                "_Speed",
                caustics.speed.value);
        }
        else
        {
            material.SetTexture(
                "_NoiseTex",
                Volume.rayMap.value);

            material.SetFloat(
                "_Scale",
                Volume.scale.value);

            material.SetFloat(
                "_Speed",
                Volume.speed.value);
        }

        Texture blueNoise =
            Volume.blueNoise.value != null
                ? Volume.blueNoise.value
                : FallbackBlueNoise;

        material.SetTexture(
            "_BlueNoise",
            blueNoise);

        material.SetColor(
            "_Tint",
            Volume.tint.value);

        material.SetFloat(
            "_Intensity",
            Volume.intensity.value);

        material.SetFloat(
            "_Scattering",
            Volume.scattering.value);

        material.SetFloat(
            "_Threshold",
            Volume.threshold.value);

        float effectiveSteps =
            Volume.steps.value;

        if (Volume.downsample.value > 1)
        {
            effectiveSteps *= 0.75f;
        }

        material.SetFloat(
            "_Steps",
            effectiveSteps);

        material.SetFloat(
            "_MaxDistance",
            Volume.maxDistance.value);

        material.SetFloat(
            "_JitterVolumetric",
            Volume.jitter.value);

        material.SetFloat(
            "_GaussSamples",
            Volume.blurSamples.value);

        material.SetFloat(
            "_GaussAmount",
            Volume.blurAmount.value);

        TextureDesc lowResDescriptor =
            descriptor;

        int divisor =
            Mathf.Max(
                1,
                Volume.downsample.value);

        lowResDescriptor.width /=
            divisor;

        lowResDescriptor.height /=
            divisor;

        //
        // Raymarch
        //
        lowResDescriptor.name =
            "Sun Shafts Raymarch";

        TextureHandle raymarch =
            renderGraph.CreateTexture(
                lowResDescriptor);

        //
        // Blur X
        //
        lowResDescriptor.name =
            "Sun Shafts Blur X";

        TextureHandle blurX =
            renderGraph.CreateTexture(
                lowResDescriptor);

        //
        // Blur Y
        //
        lowResDescriptor.name =
            "Sun Shafts Blur Y";

        TextureHandle blurY =
            renderGraph.CreateTexture(
                lowResDescriptor);

        //
        // PASS 0
        //
        renderGraph.AddBlitPass(
            new RenderGraphUtils
                .BlitMaterialParameters(
                    cameraColor,
                    raymarch,
                    material,
                    0),
            "Sun Shafts Raymarch");

        //
        // PASS 1
        //
        renderGraph.AddBlitPass(
            new RenderGraphUtils
                .BlitMaterialParameters(
                    raymarch,
                    blurX,
                    material,
                    1),
            "Sun Shafts Blur X");

        //
        // PASS 2
        //
        renderGraph.AddBlitPass(
            new RenderGraphUtils
                .BlitMaterialParameters(
                    blurX,
                    blurY,
                    material,
                    2),
            "Sun Shafts Blur Y");

        //
        // PASS 3
        //
        renderGraph.AddBlitPass(
            new RenderGraphUtils
                .BlitMaterialParameters(
                    blurY,
                    cameraColor,
                    material,
                    3),
            "Sun Shafts Composite");

        //
        // Final Output
        //
        // renderGraph.AddCopyPass(
        //     composite,
        //     cameraColor,
        //     "Sun Shafts Final");
    }

    public override void Dispose()
    {
        CoreUtils.Destroy(
            material);
    }
}