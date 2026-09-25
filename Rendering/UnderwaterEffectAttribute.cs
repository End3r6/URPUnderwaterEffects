using System;

/// <summary>
/// Built-in underwater effect execution stages.
///
/// Current order:
///
///     0    WaterLine
///     50   Transparent Depth Texture
///     100  Fog
///     200  Refraction
///     300  Caustics
///     400  SunShafts
///     500  BlurredWaterLine
///
/// Examples:
///
/// [UnderwaterEffect(UnderwaterEffectOrder.Fog)]
///     Runs at the fog stage.
///
/// [UnderwaterEffect(Before = UnderwaterEffectOrder.Caustics)]
///     Runs immediately before caustics.
///
/// [UnderwaterEffect(After = UnderwaterEffectOrder.Fog)]
///     Runs immediately after fog.
///
/// [UnderwaterEffect(250)]
///     Runs between refraction and caustics.
/// </summary>

public enum UnderwaterEffectOrder
{
    None = int.MinValue,

    WaterLine = 0,

    TransparentDepthTexture = 100,

    Caustics = 200,

    Fog = 300,

    Refraction = 400,

    SunShafts = 500,

    BlurredWaterLine = 600
}

[AttributeUsage(AttributeTargets.Class)]
public sealed class UnderwaterEffectAttribute : Attribute
{
    public int Order { get; }

    public UnderwaterEffectOrder Before { get; set; } = UnderwaterEffectOrder.None;

    public UnderwaterEffectOrder After { get; set; } = UnderwaterEffectOrder.None;

    public UnderwaterEffectAttribute()
    {
    }

    public UnderwaterEffectAttribute(UnderwaterEffectOrder stage)
    {
        Order = (int)stage;
    }

    public UnderwaterEffectAttribute(int order)
    {
        Order = order;
    }

    public int GetOrder()
    {
        if (Before != UnderwaterEffectOrder.None)
        {
            return (int)Before - 1;
        }

        if (After != UnderwaterEffectOrder.None)
        {
            return (int)After + 1;
        }

        return Order;
    }
}