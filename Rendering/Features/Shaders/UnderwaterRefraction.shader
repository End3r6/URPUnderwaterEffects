Shader "Hidden/UnderwaterRefraction"
{
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
        }

        Cull Off
        ZWrite Off
        ZTest Always

        Pass
        {
            Name "UnderwaterRefraction"

            HLSLPROGRAM

            #pragma target 4.5

            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #include "./HLSL/Noise.hlsl"

            struct Attributes
            {
                uint vertexID : SV_VertexID;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            float _LargeScale;
            float _LargeStrength;

            float _SmallScale;
            float _SmallStrength;

            float _Speed;

            float _DepthDistance;

            float _EdgeStrength;

            float _ChromaticStrength;

            float2 _FlowDirection;

            TEXTURE2D(_BlitTexture);
            SAMPLER(sampler_BlitTexture);

            TEXTURE2D(_WaterLineMask);
            SAMPLER(sampler_WaterLineMask);

            TEXTURE2D(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);

            float3 NormalFromHeight(
                float value,
                float bumpScale)
            {
                float3 normal;

                normal.x = ddx(value);
                normal.y = ddy(value);

                normal.z =
                    sqrt(
                        saturate(
                            1 -
                            normal.x * normal.x -
                            normal.y * normal.y));

                return normal *
                    float3(
                        bumpScale,
                        bumpScale,
                        1);
            }

            Varyings Vert(
                Attributes input)
            {
                Varyings output;

                output.positionCS =
                    GetFullScreenTriangleVertexPosition(
                        input.vertexID);

                output.uv =
                    GetFullScreenTriangleTexCoord(
                        input.vertexID);

                return output;
            }

            half4 Frag(
                Varyings input)
                : SV_Target
            {
                float2 uv = input.uv;

                float waterMask =
                    SAMPLE_TEXTURE2D(
                        _WaterLineMask,
                        sampler_WaterLineMask,
                        uv).r;

                float underwaterMask =
                    1.0 - waterMask;

                float rawDepth =
                    SAMPLE_TEXTURE2D(
                        _CameraDepthTexture,
                        sampler_CameraDepthTexture,
                        uv).r;

                float linearDepth =
                    LinearEyeDepth(
                        rawDepth,
                        _ZBufferParams);

                //
                // Distance-based distortion.
                //
                float depthFactor =
                    saturate(
                        linearDepth /
                        max(
                            0.001,
                            _DepthDistance));

                //
                // Edge awareness.
                //
                float edge =
                    abs(ddx(linearDepth)) +
                    abs(ddy(linearDepth));

                edge =
                    saturate(
                        edge *
                        _EdgeStrength);

                //
                // Multi-layer flow.
                //
                float2 flowUV =
                    uv +
                    (_FlowDirection *
                     _Time.y *
                     (_Speed * 0.01));

                float2 largeNoise =
                    NormalFromHeight(
                        GradientNoise(
                            flowUV,
                            _LargeScale),
                        _LargeStrength).xy;

                float2 smallNoise =
                    NormalFromHeight(
                        GradientNoise(
                            flowUV * 2.7,
                            _SmallScale),
                        _SmallStrength).xy;

                float2 distortion =
                    largeNoise +
                    smallNoise;

                //
                // Stronger effect
                // farther away.
                //
                distortion *=
                    depthFactor;

                //
                // Stronger around
                // edges/silhouettes.
                //
                distortion *=
                    1.0 +
                    edge;

                //
                // Chromatic offsets.
                //
                float2 redUV =
                    uv +
                    distortion *
                    (1.0 + _ChromaticStrength);

                float2 greenUV =
                    uv +
                    distortion;

                float2 blueUV =
                    uv +
                    distortion *
                    (1.0 - _ChromaticStrength);

                float red =
                    SAMPLE_TEXTURE2D(
                        _BlitTexture,
                        sampler_BlitTexture,
                        redUV).r;

                float green =
                    SAMPLE_TEXTURE2D(
                        _BlitTexture,
                        sampler_BlitTexture,
                        greenUV).g;

                float blue =
                    SAMPLE_TEXTURE2D(
                        _BlitTexture,
                        sampler_BlitTexture,
                        blueUV).b;

                float3 refracted =
                    float3(
                        red,
                        green,
                        blue);

                float3 original =
                    SAMPLE_TEXTURE2D(
                        _BlitTexture,
                        sampler_BlitTexture,
                        uv).rgb;

                float3 underwater =
                    refracted *
                    underwaterMask;

                float3 aboveWater =
                    original *
                    waterMask;

                return float4(
                    underwater +
                    aboveWater,
                    1);
            }

            ENDHLSL
        }
    }
}