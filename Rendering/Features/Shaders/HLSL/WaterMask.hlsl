#ifndef UNDERWATER_INCLUDED
#define UNDERWATER_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Assets/URPUnderwaterEffects/Rendering/Features/Shaders/HLSL/sdf.hlsl"

TEXTURE2D(_WaterLineMask);
SAMPLER(sampler_WaterLineMask);

TEXTURE2D(_CameraDepthTexture);
SAMPLER(sampler_CameraDepthTexture);

float SampleRawDepth(float2 uv)
{
    return SAMPLE_TEXTURE2D(
        _CameraDepthTexture,
        sampler_CameraDepthTexture,
        uv).r;
}

float3 SampleWorldPosition(float2 uv)
{
    float rawDepth = SampleRawDepth(uv);

    return ComputeWorldSpacePosition(
        uv,
        rawDepth,
        UNITY_MATRIX_I_VP);
}

float3 SampleWorldNormal(float2 uv)
{
    float3 worldPos =
        SampleWorldPosition(uv);

    float3 dx =
        ddx(worldPos);

    float3 dy =
        ddy(worldPos);

    return normalize(
        cross(
            dx,
            dy));
}

float SampleWaterMask(float2 uv)
{
    return SAMPLE_TEXTURE2D(_WaterLineMask, sampler_WaterLineMask, uv).r;
}

// float GetAirMask(float2 uv)
// {
//     return saturate(SampleWaterMask(uv));
// }

float GetUnderwaterMask(float2 uv)
{
    return saturate(1 - SampleWaterMask(uv));
}

float SampleLinearDepth(float2 uv)
{
    float rawDepth =
        SampleRawDepth(uv);

    return LinearEyeDepth(
        rawDepth,
        _ZBufferParams);
}

#define UNDERWATER_PASS_FOG         1
#define UNDERWATER_PASS_REFRACTION  2
#define UNDERWATER_PASS_CAUSTICS    4
#define UNDERWATER_PASS_SUN_SHAFTS  8
#define UNDERWATER_PASS_WATER_LINE 16

float GetFinalUnderwaterMask(float2 uv, int passMask)
{
    float mask = GetUnderwaterMask(uv);
    float3 sceneWorldPos = SampleWorldPosition(uv);

    float3 rayOrigin = _WorldSpaceCameraPos;

    // Orthographic cameras need a per-pixel ray origin on the near plane.
    #if UNITY_REVERSED_Z
        const float nearRawDepth = 1.0;
    #else
        const float nearRawDepth = UNITY_NEAR_CLIP_VALUE;
    #endif

    if (unity_OrthoParams.w > 0.5)
    {
        rayOrigin = ComputeWorldSpacePosition(
            uv,
            nearRawDepth,
            UNITY_MATRIX_I_VP);
    }

    float3 rayVector = sceneWorldPos - rayOrigin;
    float rayDistance = length(rayVector);

    if (rayDistance <= 1e-6)
        return saturate(mask);

    float3 rayDirection = rayVector / rayDistance;

    bool insideInclude = false;
    bool insideExclude = false;

    for (int i = 0; i < _VolumeCount; i++)
    {
        int excludedPasses = (int)_VolumeSettings[i].z;
        if ((excludedPasses & passMask) != 0)
            continue;
            
        int operation = (int)_VolumeSettings[i].y;
        bool intersectsSurface = IsInsideVolume(sceneWorldPos, i);

        // Inclusions affect the ray through empty space as well as scene surfaces.
        bool intersects = intersectsSurface;

        if (operation == 0 && !intersects)
        {
            intersects = RayIntersectsVolume(
                rayOrigin,
                rayDirection,
                rayDistance,
                i);
        }

        if (!intersects)
            continue;

        if (operation == 0)
            insideInclude = true;
        else
            insideExclude = true;
    }

    if (insideExclude)
        mask = 0.0;

    // Preserve the existing precedence: inclusion wins if both apply.
    if (insideInclude)
        mask = 1.0;

    return saturate(mask);
}

float GetFinalUnderwaterMask(float2 uv)
{
    return GetFinalUnderwaterMask(uv, 0);
}

float GetAirMask(float2 uv)
{
    return 1.0 - GetFinalUnderwaterMask(uv);
}

#endif