using System;
using UnityEngine;
using UnityEngine.Rendering;

[Serializable]
[VolumeComponentMenu("Underwater Effects/Underwater Sun Shafts")]
public sealed class UnderwaterSunShaftsVolume
    : VolumeComponent
{
    public BoolParameter enabled =
        new BoolParameter(true);

    [Header("Caustics Integration")]
    public BoolParameter inheritCaustics =
        new BoolParameter(true);

    [Header("Noise")]
    public TextureParameter blueNoise =
        new TextureParameter(null);

    [Header("Appearance")]

    public TextureParameter rayMap =
        new TextureParameter(null);

    public ColorParameter tint =
        new ColorParameter(Color.white);

    public ClampedFloatParameter intensity =
        new ClampedFloatParameter(
            1f,
            0f,
            50f);

    public ClampedFloatParameter scattering =
        new ClampedFloatParameter(
            0.5f,
            0f,
            0.999f);

    public ClampedFloatParameter threshold =
        new ClampedFloatParameter(
            0.5f,
            0f,
            1f);

    public ClampedFloatParameter scale =
        new ClampedFloatParameter(
            50f,
            0.01f,
            1000f);

    public ClampedFloatParameter speed =
        new ClampedFloatParameter(
            1f,
            0f,
            100f);

    [Header("Raymarching")]

    public ClampedFloatParameter steps =
        new ClampedFloatParameter(
            24f,
            1f,
            256f);

    public ClampedFloatParameter maxDistance =
        new ClampedFloatParameter(
            75f,
            0.1f,
            1000f);

    public ClampedFloatParameter jitter =
        new ClampedFloatParameter(
            250f,
            0f,
            1000f);

    [Header("Blur")]

    public ClampedFloatParameter blurSamples =
        new ClampedFloatParameter(
            6,
            0,
            16);

    public ClampedFloatParameter blurAmount =
        new ClampedFloatParameter(
            1f,
            0f,
            10f);

    [Header("Performance")]

    public ClampedIntParameter downsample =
        new ClampedIntParameter(
            2,
            1,
            4);
}