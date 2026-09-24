using System;
using UnityEngine;
using UnityEngine.Rendering;

[Serializable]
[VolumeComponentMenu("Underwater Effects/Underwater Caustics")]
public sealed class UnderwaterCausticsVolume
    : VolumeComponent
{

    public TextureParameter causticsTexture =
        new TextureParameter(null);

    [Header("Projection")]
    public ClampedFloatParameter range =
        new ClampedFloatParameter(
            20f,
            0.1f,
            500f);

    public ClampedFloatParameter intensity =
        new ClampedFloatParameter(
            1f,
            0f,
            25f);

    [Header("Animation")]
    public ClampedFloatParameter speed =
        new ClampedFloatParameter(
            1f,
            0f,
            100f);

    public ClampedFloatParameter tiling =
        new ClampedFloatParameter(
            8f,
            0.01f,
            500f);

    [Header("Lighting")]
    public ClampedFloatParameter coverage =
        new(
            0f,
            0f,
            1f);
    public ClampedFloatParameter lightDirectionBias =
        new(
            2f,
            0f,
            16f);

    public ClampedFloatParameter lightStretch =
        new(
            1.5f,
            0.1f,
            10f);

    [Header("Appearance")]
    public ClampedFloatParameter rgbSplit =
        new ClampedFloatParameter(
            0.01f,
            0f,
            0.1f);

    public ColorParameter color =
        new ColorParameter(
            Color.white);

    public ClampedFloatParameter depthFade =
        new ClampedFloatParameter(
            1f,
            0f,
            10f);

    public BoolParameter underwaterOnly =
        new BoolParameter(true);
}