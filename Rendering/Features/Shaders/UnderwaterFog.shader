Shader "Hidden/UnderwaterFog"
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
            Name "UnderwaterFog"

            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM

            #pragma target 4.5

            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                uint vertexID : SV_VertexID;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            float _Vision;
            float _DebugView;

            half4 _FogColor;

            TEXTURE2D(_BlitTexture);
            SAMPLER(sampler_BlitTexture);

            TEXTURE2D(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);

            TEXTURE2D(_WaterLineMask);
            SAMPLER(sampler_WaterLineMask);

            Varyings Vert(Attributes input)
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

            half4 Frag(Varyings input) : SV_Target
            {
                float3 sceneColor =
                    SAMPLE_TEXTURE2D(
                        _BlitTexture,
                        sampler_BlitTexture,
                        input.uv).rgb;

                float horizonMask =
                    SAMPLE_TEXTURE2D(
                        _WaterLineMask,
                        sampler_WaterLineMask,
                        input.uv).r;

                float underwaterMask =
                    saturate(1.0 - horizonMask);

                float rawDepth =
                    SAMPLE_TEXTURE2D(
                        _CameraDepthTexture,
                        sampler_CameraDepthTexture,
                        input.uv).r;

                float linearDepth =
                    LinearEyeDepth(
                        rawDepth,
                        _ZBufferParams);

                float fogAmount =
                    1.0 - exp(-linearDepth / max(0.001, _Vision));

                fogAmount *= underwaterMask;

                //
                // Water absorbs red frequencies first.
                //
                float3 absorbedColor = sceneColor;

                absorbedColor.r *= lerp(1.0, 0.05, fogAmount);
                absorbedColor.g *= lerp(1.0, 0.45, fogAmount);

                //
                // Underwater visibility loses saturation.
                //
                float luminance =
                    dot(
                        absorbedColor,
                        float3(
                            0.299,
                            0.587,
                            0.114));

                float3 desaturated =
                    lerp(
                        absorbedColor,
                        luminance.xxx,
                        fogAmount * 0.65);

                //
                // Blend into water color.
                //
                float3 underwaterColor =
                    lerp(
                        desaturated,
                        _FogColor.rgb,
                        fogAmount);

                //
                // Preserve visible world above water.
                //
                float3 finalColor =
                    lerp(
                        underwaterColor,
                        sceneColor,
                        horizonMask);

                if (_DebugView > 0.5)
                {
                    return float4(
                        underwaterMask.xxx,
                        1);
                }

                return float4(
                    finalColor,
                    1);
            }

            ENDHLSL
        }
    }
}