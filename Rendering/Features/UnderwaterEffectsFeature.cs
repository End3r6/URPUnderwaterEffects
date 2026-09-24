using System;
using System.Linq;
using System.Reflection;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;

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
            DiscoverEffects();
        }

        private void DiscoverEffects()
        {
            effects.Clear();

            var effectTypes =
                UnityEngine.Assemblies.CurrentAssemblies.GetLoadedAssemblies()
                    .SelectMany(assembly =>
                    {
                        try
                        {
                            return assembly.GetTypes();
                        }
                        catch (ReflectionTypeLoadException e)
                        {
                            return e.Types.Where(t => t != null);
                        }
                    })
                    .Where(type =>
                           type != null &&
                           !type.IsAbstract &&
                           typeof(UnderwaterEffect).IsAssignableFrom(type) &&
                           type.GetCustomAttribute<UnderwaterEffectAttribute>() != null)
                    .OrderBy(type =>
                        type.GetCustomAttribute<UnderwaterEffectAttribute>().Order);

            foreach (Type type in effectTypes)
            {
                try
                {
                    if (Activator.CreateInstance(type) is UnderwaterEffect effect)
                    {
                        effects.Add(effect);
                    }
                }
                catch (Exception e)
                {
                    Debug.LogException(e);
                }
            }
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
                // if (!effect.IsActive())
                // {
                //     continue;
                // }

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