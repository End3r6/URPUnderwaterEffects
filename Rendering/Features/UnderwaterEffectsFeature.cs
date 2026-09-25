using System;
using System.Linq;
using System.Reflection;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;

public sealed class UnderwaterEffectsFeature : ScriptableRendererFeature
{
    private UnderwaterEffectsRenderPass pass;

    public override void Create()
    {
        pass = new UnderwaterEffectsRenderPass()
        {
            renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing
        };
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType ==
            CameraType.Preview)
        {
            return;
        }

        renderer.EnqueuePass(pass);
    }

    protected override void Dispose(bool disposing)
    {
        pass?.Dispose();
    }

    private sealed class UnderwaterEffectsRenderPass : ScriptableRenderPass
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
                    .Select(type => new
                    {
                        Type = type,
                        Attribute = type?.GetCustomAttribute<UnderwaterEffectAttribute>()
                    })
                    .Where(x =>
                           x != null &&
                           !x.Type.IsAbstract &&
                           typeof(UnderwaterEffect).IsAssignableFrom(x.Type) &&
                           x.Attribute != null)
                    .OrderBy(x => x.Attribute.Order);

            foreach (var x in effectTypes)
            {
                try
                {
                    if (Activator.CreateInstance(x.Type) is UnderwaterEffect effect)
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
            // Execute effects.
            //
            foreach (UnderwaterEffect effect in effects)
            {
                effect.RecordRenderGraph(
                    renderGraph,
                    frameData);
            }
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