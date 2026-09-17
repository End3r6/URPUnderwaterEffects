using System;
using UnityEngine;
using UnityEngine.Rendering;

[Serializable]
[VolumeComponentMenu("Underwater Effects/Underwater Refraction")]
public sealed class UnderwaterRefractionVolume
    : VolumeComponent
{
    public BoolParameter enabled =
        new BoolParameter(true);

    [Header("Large Waves")]
    public ClampedFloatParameter largeScale =
        new ClampedFloatParameter(
            50f,
            0.01f,
            500f);

    public ClampedFloatParameter largeStrength =
        new ClampedFloatParameter(
            0.02f,
            0f,
            1f);

    [Header("Small Waves")]
    public ClampedFloatParameter smallScale =
        new ClampedFloatParameter(
            200f,
            0.01f,
            1000f);

    public ClampedFloatParameter smallStrength =
        new ClampedFloatParameter(
            0.01f,
            0f,
            1f);

    [Header("Animation")]
    public ClampedFloatParameter speed =
        new ClampedFloatParameter(
            1f,
            0f,
            100f);

    public Vector2Parameter flowDirection =
        new Vector2Parameter(
            new Vector2(0.5f, 0.15f));

    [Header("Depth Refraction")]
    public ClampedFloatParameter depthDistance =
        new ClampedFloatParameter(
            25f,
            0.01f,
            500f);

    [Header("Enhancement")]
    public ClampedFloatParameter edgeStrength =
        new ClampedFloatParameter(
            2f,
            0f,
            20f);

    public ClampedFloatParameter chromaticStrength =
        new ClampedFloatParameter(
            0.0025f,
            0f,
            0.05f);
}