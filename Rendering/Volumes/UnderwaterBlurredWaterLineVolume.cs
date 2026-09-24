using System;
using UnityEngine;
using UnityEngine.Rendering;

[Serializable]
[VolumeComponentMenu("Underwater Effects/Blurred Water Line")]
public sealed class UnderwaterBlurredWaterLineVolume : VolumeComponent
{
    [Header("Appearance")]
    public ColorParameter color =
        new ColorParameter(Color.white);

    public ClampedFloatParameter intensity =
        new ClampedFloatParameter(
            1f,
            0f,
            1);

    [Header("Water Line")]
    public ClampedFloatParameter thickness =
        new ClampedFloatParameter(
            4f,
            0f,
            50f);

    public ClampedFloatParameter softness =
        new ClampedFloatParameter(
            0.2f,
            0.001f,
            1f);

    public ClampedFloatParameter verticalBlur =
        new ClampedFloatParameter(
            2f,
            0f,
            20f);

    public ClampedFloatParameter highlightThickness =
        new ClampedFloatParameter(
            2f,
            0f,
            50f);

    [Header("Refraction")]
    public ClampedFloatParameter refractionStrength =
        new ClampedFloatParameter(
            15f,
            0f,
            100f);

    public ClampedFloatParameter highlightIntensity =
        new ClampedFloatParameter(
            1f,
            0f,
            10f);

    public ClampedFloatParameter highlightFineNoiseScale =
        new ClampedFloatParameter(
            30f,
            0f,
            100f);

    public ClampedFloatParameter highlightBroadNoiseScale =
        new ClampedFloatParameter(
            100f,
            0f,
            100f);
}