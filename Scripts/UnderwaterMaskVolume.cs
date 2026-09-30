using System;
using UnityEngine;

[DisallowMultipleComponent]
public class UnderwaterMaskVolume : MonoBehaviour
{
    public enum Operation
    {
        Include,
        Exclude
    }

    public enum Shape
    {
        Box,
        Sphere,
        Capsule
    }

    [Flags]
    public enum ExcludedPasses
    {
        None = 0,
        Fog = 1 << 0,
        Refraction = 1 << 1,
        Caustics = 1 << 2,
        SunShafts = 1 << 3,
        WaterLine = 1 << 4,
        All = Fog | Refraction | Caustics | SunShafts | WaterLine
    }


    public Operation operation = Operation.Exclude;
    public Shape shape = Shape.Box;
    public ExcludedPasses excludedPasses = ExcludedPasses.None;

    [SerializeField] private bool drawDebugGizmos = true;

    private void OnDrawGizmos()
    {
        DrawGizmo(false);
    }

    private void OnDrawGizmosSelected()
    {
        DrawGizmo(true);
    }

    private void DrawGizmo(bool selected)
    {
        if (!drawDebugGizmos)
            return;

        Color color =
            operation == Operation.Include
            ? new Color(0f, 0.7f, 1f, selected ? 0.35f : 0.15f)
            : new Color(1f, 0.5f, 0f, selected ? 0.35f : 0.15f);

        Gizmos.color = color;

        Matrix4x4 oldMatrix =
            Gizmos.matrix;

        Gizmos.matrix =
            transform.localToWorldMatrix;

        switch (shape)
        {
            case Shape.Box:
                {
                    Gizmos.DrawCube(
                        Vector3.zero,
                        Vector3.one);

                    Gizmos.color =
                        new Color(
                            color.r,
                            color.g,
                            color.b,
                            1f);

                    Gizmos.DrawWireCube(
                        Vector3.zero,
                        Vector3.one);

                    break;
                }

            case Shape.Sphere:
                {
                    Gizmos.DrawSphere(
                        Vector3.zero,
                        0.5f);

                    Gizmos.color =
                        new Color(
                            color.r,
                            color.g,
                            color.b,
                            1f);

                    Gizmos.DrawWireSphere(
                        Vector3.zero,
                        0.5f);

                    break;
                }

            case Shape.Capsule:
                {
                    DrawCapsuleGizmo(color);
                    break;
                }
        }

        Gizmos.matrix = oldMatrix;
    }

    private void DrawCapsuleGizmo(Color color)
    {
        //
        // Capsule is aligned to Y axis.
        //
        float radius = 0.5f;
        float halfHeight = 0.5f;

        Vector3 top =
            Vector3.up * halfHeight;

        Vector3 bottom =
            Vector3.down * halfHeight;

        Gizmos.color = color;

        Gizmos.DrawSphere(
            top,
            radius);

        Gizmos.DrawSphere(
            bottom,
            radius);

        Gizmos.color =
            new Color(
                color.r,
                color.g,
                color.b,
                1f);

        Gizmos.DrawWireSphere(
            top,
            radius);

        Gizmos.DrawWireSphere(
            bottom,
            radius);

        Vector3 right =
            Vector3.right * radius;

        Vector3 forward =
            Vector3.forward * radius;

        Gizmos.DrawLine(
            top + right,
            bottom + right);

        Gizmos.DrawLine(
            top - right,
            bottom - right);

        Gizmos.DrawLine(
            top + forward,
            bottom + forward);

        Gizmos.DrawLine(
            top - forward,
            bottom - forward);
    }
}