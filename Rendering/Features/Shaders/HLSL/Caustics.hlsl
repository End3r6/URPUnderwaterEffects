#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

TEXTURE2D(_Caustics);
SAMPLER(sampler_Caustics);

half2 Panner(half2 uv, half speed, half tiling)
{
    return (half2(1, 0) * _Time.y * speed) + (uv * tiling);
}

half4 SampleCaustics(half2 uv, half split)
{
    half2 uv1 = uv + half2(split, split);
    half2 uv2 = uv + half2(split, -split);
    half2 uv3 = uv + half2(-split, -split);

    half r = SAMPLE_TEXTURE2D(_Caustics, sampler_Caustics, uv1).r;
    half g = SAMPLE_TEXTURE2D(_Caustics, sampler_Caustics, uv2).r;
    half b = SAMPLE_TEXTURE2D(_Caustics, sampler_Caustics, uv3).r;

    return half4(r, g, b, r);
}