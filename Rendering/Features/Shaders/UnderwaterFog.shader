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
            #include "./HLSL/WaterMask.hlsl"

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
            float _Absorption;
            float _Desaturation;
            float _RedAbsorption;
            float _GreenAbsorption;

            TEXTURE2D(_BlitTexture);
            SAMPLER(sampler_BlitTexture);

            TEXTURE2D(_TransparentDepthTexture);
            SAMPLER(sampler_TransparentDepthTexture);

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
                float3 sceneColor = SAMPLE_TEXTURE2D(_BlitTexture, sampler_BlitTexture, input.uv).rgb;

                float underwaterMask = GetFinalUnderwaterMask(input.uv, UNDERWATER_PASS_FOG);
                float airMask = GetAirMask(input.uv);
                
                float4 transparentData = SAMPLE_TEXTURE2D(_TransparentDepthTexture, sampler_TransparentDepthTexture, input.uv);
                float transparentDepth = transparentData.r;

                float thickness = transparentData.g;
                float transmittance = transparentData.b;

                float rawDepth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, input.uv).r;
                float opaqueDepth = LinearEyeDepth(rawDepth, _ZBufferParams);

                float linearDepth = opaqueDepth;
                float fogAmount = 1.0 - exp(-linearDepth / max(0.001, _Vision));

                bool hasTransparent = transparentDepth > 0.001;

                float transparentContribution = 0;
                if (hasTransparent)
                {
                    float opticalDepth = transparentDepth + thickness;

                    transparentContribution = (exp(-opticalDepth / max(0.001, _Vision)));
                    fogAmount = lerp(fogAmount, fogAmount - transparentContribution, transmittance);
                }
                
                fogAmount *= underwaterMask;

                //
                // Water absorbs red frequencies first.
                //
                float3 absorbedColor = sceneColor;

                absorbedColor.r *= lerp(1.0, 1 - _RedAbsorption, fogAmount * _Absorption);
                absorbedColor.g *= lerp(1.0, 1 - _GreenAbsorption, fogAmount * _Absorption);

                //
                // Underwater visibility loses saturation.
                //
                float luminance = dot(absorbedColor, float3(0.299, 0.587, 0.114));

                float3 desaturated = lerp(absorbedColor, luminance.xxx, fogAmount * _Desaturation);

                //
                // Blend into water color.
                //
                float3 underwaterColor = lerp(desaturated, _FogColor.rgb, fogAmount);

                //
                // Preserve visible world above water.
                //
                float3 finalColor = lerp(underwaterColor, sceneColor, airMask);

                if (_DebugView > 0.5)
                {
                    return float4(GetFinalUnderwaterMask(input.uv).xxx, 1);
                }

                return float4(finalColor, 1);
            }

            ENDHLSL
        }
    }
}