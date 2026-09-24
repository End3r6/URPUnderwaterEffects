using System;
using UnityEngine;
using UnityEngine.Rendering;

[Serializable]
[VolumeComponentMenu("Underwater Effects/Underwater Fog")]
public sealed class UnderwaterFogVolume : VolumeComponent
{

    public ColorParameter fogColor =
        new ColorParameter(
            new Color(0.0f, 0.6f, 0.8f));

    public ClampedFloatParameter vision =
        new ClampedFloatParameter(
            10f,
            0.01f,
            500f);

    public ClampedFloatParameter absorption =
        new ClampedFloatParameter(
            1f,
            0f,
            10f);

    public ClampedFloatParameter desaturation =
        new ClampedFloatParameter(
            0.65f,
            0f,
            1f);

    public ClampedFloatParameter redAbsorption =
        new ClampedFloatParameter(
            0.95f,
            0f,
            1f);

    public ClampedFloatParameter greenAbsorption =
        new ClampedFloatParameter(
            0.55f,
            0f,
            1f);

    public BoolParameter debugView =
        new BoolParameter(false);
}