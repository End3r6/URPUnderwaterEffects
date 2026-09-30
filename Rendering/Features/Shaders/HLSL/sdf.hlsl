#ifndef UNDERWATER_VOLUMES_INCLUDED
#define UNDERWATER_VOLUMES_INCLUDED

#define MAX_VOLUMES 64

int _VolumeCount;

float4x4 _VolumeWorldToLocal[MAX_VOLUMES];

float4 _VolumeShapeData[MAX_VOLUMES];

float4 _VolumeSettings[MAX_VOLUMES];

float BoxSDF(float3 p, float3 size)
{
    float3 q = abs(p) - size;

    return
        length(max(q,0))
        + min(
            max(q.x,
            max(q.y,q.z)),
            0);
}

float SphereSDF(float3 p, float radius)
{
    return length(p) - radius;
}

float CapsuleSDF(float3 p, float height, float radius)
{
    p.y -= clamp(p.y, -height * 0.5, height * 0.5);

    return length(p) - radius;
}

float GetVolumeSDF(float3 localPos, int index)
{
    int shape = (int)_VolumeSettings[index].x;

    if (shape == 0)
    {
        return BoxSDF(localPos, _VolumeShapeData[index].xyz);
    }
    else if (shape == 1)
    {
        return SphereSDF(localPos, _VolumeShapeData[index].x);
    }
    else if (shape == 2)
    {
        return CapsuleSDF(
            localPos,
            _VolumeShapeData[index].x,
            _VolumeShapeData[index].y);
    }

    return 99999.0;
}

bool IsInsideVolume(float3 worldPos, int index)
{
    float3 localPos = mul(
        _VolumeWorldToLocal[index],
        float4(worldPos, 1.0)).xyz;

    return GetVolumeSDF(localPos, index) < 0.0;
}

// Tests the camera ray only up to the visible scene depth, so volumes
// affect pixels in front of scene geometry but don't show through it.
bool RayIntersectsVolume(float3 rayOrigin, float3 rayDirection, float maxWorldDistance, int index)
{
    float4x4 worldToLocal = _VolumeWorldToLocal[index];

    float3 localOrigin = mul(
        worldToLocal,
        float4(rayOrigin, 1.0)).xyz;

    float3 localRay = mul((float3x3)worldToLocal, rayDirection);
    float localUnitsPerWorldUnit = length(localRay);

    if (localUnitsPerWorldUnit <= 1e-6)
        return false;

    float3 localDirection = localRay / localUnitsPerWorldUnit;
    float maxLocalDistance = maxWorldDistance * localUnitsPerWorldUnit;
    float distanceAlongRay = 0.0;

    [loop]
    for (int step = 0; step < 96; step++)
    {
        float3 localPos =
            localOrigin + localDirection * distanceAlongRay;

        float sdfDistance = GetVolumeSDF(localPos, index);

        if (sdfDistance <= 0.001)
            return true;

        distanceAlongRay += max(sdfDistance, 0.001);

        if (distanceAlongRay > maxLocalDistance)
            return false;
    }

    return false;
}


#endif