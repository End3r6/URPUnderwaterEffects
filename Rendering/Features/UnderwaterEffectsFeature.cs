using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.RendererUtils;
using UnityEngine.Rendering.RenderGraphModule.Util;

public sealed class UnderwaterEffectsFeature
    : ScriptableRendererFeature
{
    private UnderwaterEffectsRenderPass pass;

    public override void Create()
    {
        pass = new UnderwaterEffectsRenderPass()
        {
            renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing
        };
    }

    public override void AddRenderPasses(
        ScriptableRenderer renderer,
        ref RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType ==
            CameraType.Preview)
        {
            return;
        }

        renderer.EnqueuePass(pass);
    }

    protected override void Dispose(
        bool disposing)
    {
        pass?.Dispose();
    }

    private sealed class UnderwaterEffectsRenderPass
        : ScriptableRenderPass
    {
        private readonly List<UnderwaterEffect> effects = new();

        public UnderwaterEffectsRenderPass()
        {
            //
            // Register effects here.
            //
            effects.Add(new WaterLineMaskEffect());
            effects.Add(new UnderwaterFogEffect());
            effects.Add(new UnderwaterRefractionEffect());
            effects.Add(new UnderwaterCausticsEffect());
            effects.Add(new UnderwaterSunShaftsEffect());
            effects.Add(new UnderwaterBlurredWaterLineEffect());
        }

        public override void RecordRenderGraph(
            RenderGraph renderGraph,
            ContextContainer frameData)
        {
            //
            // Shared resources.
            //

            GenerateTransparentDepth(
                renderGraph,
                frameData);

            //
            // Execute effects.
            //
            foreach (UnderwaterEffect effect in effects)
            {
                if (!effect.IsActive())
                {
                    continue;
                }

                effect.RecordRenderGraph(
                    renderGraph,
                    frameData);
            }
        }

        private void GenerateTransparentDepth(
            RenderGraph renderGraph,
            ContextContainer frameData)
        {
            //
            // Future transparent depth pass.
            //
        }

        public void Dispose()
        {
            foreach (var effect in effects)
            {
                effect.Dispose();
            }
        }
    }
}