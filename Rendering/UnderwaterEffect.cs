using System.Linq;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;

public abstract class UnderwaterEffect
{
    public abstract bool IsActive();

    public abstract void RecordRenderGraph(
        RenderGraph renderGraph,
        ContextContainer frameData);

    public virtual void Dispose() { }
}

public abstract class UnderwaterEffect<TVolume> : UnderwaterEffect where TVolume : VolumeComponent
{
    protected TVolume Volume => VolumeManager.instance.stack.GetComponent<TVolume>();

    public override bool IsActive()
    {
        if (Volume == null)
            return false;

        return Volume.parameters.Any(p => p.overrideState);
    }
}