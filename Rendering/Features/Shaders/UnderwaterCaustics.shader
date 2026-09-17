Shader "Hidden/UnderwaterCaustics"
{
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
        }

        Cull Off
        ZWrite Off
        ZTest Always

        Pass
        {
            Name "UnderwaterCaustics"

            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM

            #pragma target 4.5

            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #include "./HLSL/Caustics.hlsl"

            struct Attributes
            {
                uint vertexID : SV_VertexID;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            float _Speed;
            float _Tiling;
            float _RGBSplit;

            float _Intensity;
            float _Range;

            float _DepthFade;

            float _Coverage;

            float _LightDirectionBias;
            float _LightStretch;

            float _UnderwaterOnly;

            float4 _CausticColor;

            TEXTURE2D(_BlitTexture);
            SAMPLER(sampler_BlitTexture);

            TEXTURE2D(_WaterLineMask);
            SAMPLER(sampler_WaterLineMask);

            TEXTURE2D(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);

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

                float3 source =
                    SAMPLE_TEXTURE2D(
                        _BlitTexture,
                        sampler_BlitTexture,
                        uv).rgb;

                float waterMask =
                    SAMPLE_TEXTURE2D(
                        _WaterLineMask,
                        sampler_WaterLineMask,
                        uv).r;

                float underwaterMask =
                    _UnderwaterOnly > 0.5
                    ? 1.0 - waterMask
                    : 1.0;

                float rawDepth =
                    SAMPLE_TEXTURE2D(
                        _CameraDepthTexture,
                        sampler_CameraDepthTexture,
                        uv).r;

                float linearDepth =
                    LinearEyeDepth(
                        rawDepth,
                        _ZBufferParams);

                float fade =
                    saturate(
                        1.0 -
                        linearDepth /
                        max(
                            0.001,
                            _Range));

                fade =
                    pow(
                        fade,
                        max(
                            0.001,
                            _DepthFade));

                float3 worldPos =
                    ComputeWorldSpacePosition(
                        uv,
                        rawDepth,
                        UNITY_MATRIX_I_VP);

                //
                // Reconstruct world normal
                //
                float3 dx =
                    ddx(worldPos);

                float3 dy =
                    ddy(worldPos);

                float3 worldNormal =
                    normalize(
                        cross(
                            dx,
                            dy));

                //
                // Stable blending
                //
                float3 blend =
                    abs(worldNormal);

                //
                // Favor floors
                //
                blend.y *= 2.0;

                float triplanarSharpness =
                    4.0;

                blend =
                    pow(
                        blend,
                        triplanarSharpness);

                blend /=
                    max(
                        0.0001,
                        blend.x +
                        blend.y +
                        blend.z);

                //
                // Main directional light
                //
                Light mainLight =
                    GetMainLight();

                float3 lightDir =
                    normalize(
                        mainLight.direction);

                float lightFacing =
                    saturate(
                        dot(
                            worldNormal,
                            -lightDir));

                lightFacing =
                    pow(
                        lightFacing,
                        max(
                            0.001,
                            _LightDirectionBias));

                //
                // Upward bias
                //
                float upness =
                    saturate(
                        dot(
                            worldNormal,
                            float3(
                                0,
                                1,
                                0)));

                upness =
                    lerp(
                        0.25,
                        1.0,
                        upness);

                //
                // Build light-space basis
                //
                float3 tangent =
                    normalize(
                        cross(
                            float3(0,1,0),
                            lightDir));

                if(length(tangent) < 0.001)
                {
                    tangent =
                        float3(
                            1,
                            0,
                            0);
                }

                float3 bitangent =
                    normalize(
                        cross(
                            lightDir,
                            tangent));

                float3 lightSpacePos =
                    float3(
                        dot(
                            worldPos,
                            tangent),

                        dot(
                            worldPos,
                            bitangent),

                        dot(
                            worldPos,
                            lightDir));

                //
                // Triplanar UVs
                //
                float2 uvX =
                    lightSpacePos.zy;

                float2 uvY =
                    lightSpacePos.xz;

                float2 uvZ =
                    float2(
                        lightSpacePos.x *
                        _LightStretch,

                        lightSpacePos.y);

                //
                // X Projection
                //
                float3 causticsX =
                    min(
                        SampleCaustics(
                            Panner(
                                uvX,
                                _Speed / 100.0,
                                1.0 / _Tiling),
                            _RGBSplit).rgb,

                        SampleCaustics(
                            Panner(
                                uvX,
                                _Speed / 100.0,
                                -1.0 / _Tiling),
                            _RGBSplit).rgb);

                //
                // Y Projection
                //
                float3 causticsY =
                    min(
                        SampleCaustics(
                            Panner(
                                uvY,
                                _Speed / 100.0,
                                1.0 / _Tiling),
                            _RGBSplit).rgb,

                        SampleCaustics(
                            Panner(
                                uvY,
                                _Speed / 100.0,
                                -1.0 / _Tiling),
                            _RGBSplit).rgb);

                //
                // Z Projection
                //
                float3 causticsZ =
                    min(
                        SampleCaustics(
                            Panner(
                                uvZ,
                                _Speed / 100.0,
                                1.0 / _Tiling),
                            _RGBSplit).rgb,

                        SampleCaustics(
                            Panner(
                                uvZ,
                                _Speed / 100.0,
                                -1.0 / _Tiling),
                            _RGBSplit).rgb);

                //
                // Triplanar Blend
                //
                float3 caustics =
                    causticsX * blend.x +
                    causticsY * blend.y +
                    causticsZ * blend.z;

                //
                // Coverage control
                //
                caustics =
                    saturate(
                        caustics -
                        _Coverage);

                //
                // Contrast
                //
                caustics =
                    pow(
                        saturate(
                            caustics),
                        2.0);

                caustics *=
                    _Intensity;

                caustics *=
                    fade;

                caustics *=
                    underwaterMask;

                caustics *=
                    _CausticColor.rgb;

                caustics *=
                    upness;

                caustics *=
                    lightFacing;

                float3 finalColor =
                    source +
                    caustics;

                return float4(
                    finalColor,
                    1.0);
            }

            ENDHLSL
        }
    }
}