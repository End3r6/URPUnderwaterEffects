using System;
using UnityEngine;
using UnityEngine.Rendering;

[Serializable]
[VolumeComponentMenu("Underwater Effects/Water Line Mask (Required)")]
public sealed class WaterLineMaskVolume : VolumeComponent
{

    public BoolParameter debugView =
        new BoolParameter(false);
}