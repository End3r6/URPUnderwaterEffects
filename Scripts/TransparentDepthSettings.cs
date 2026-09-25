using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
[DisallowMultipleComponent]
[RequireComponent(typeof(Renderer))]
public sealed class TransparentDepthSettings
    : MonoBehaviour
{
    public static readonly HashSet<TransparentDepthSettings>
        Instances = new();

    private static readonly int ThicknessId =
        Shader.PropertyToID(
            "_Thickness");

    private static readonly int OpacityId =
        Shader.PropertyToID(
            "_TransparentObjectTransmittance");

    [Min(0)]
    public float Thickness = 5.0f;

    [Range(0, 1)]
    public float Transmittance = 0.0f;

    private Renderer cachedRenderer;

    private void OnEnable()
    {
        cachedRenderer =
            GetComponent<Renderer>();

        Instances.Add(this);

        Apply();
    }

    private void OnDisable()
    {
        Instances.Remove(this);
    }

    private void OnValidate()
    {
        if (!cachedRenderer)
        {
            cachedRenderer =
                GetComponent<Renderer>();
        }

        Apply();
    }

    private void Apply()
    {
        if (!cachedRenderer)
            return;

        MaterialPropertyBlock block =
            new();

        cachedRenderer.GetPropertyBlock(
            block);

        block.SetFloat(
            ThicknessId,
            Thickness);

        block.SetFloat(
            OpacityId,
            Transmittance);

        cachedRenderer.SetPropertyBlock(
            block);
    }
}