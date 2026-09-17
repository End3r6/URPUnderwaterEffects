Shader "Hidden/UnderwaterBlurredWaterLine"
{
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" }

        Cull Off
        ZWrite Off
        ZTest Always

        Pass
        {            
            Name "BlurredWaterLine"

            HLSLPROGRAM

            #pragma target 4.5

            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                uint vertexID : SV_VertexID;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;

                output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
                output.uv = GetFullScreenTriangleTexCoord(input.vertexID);

                return output;
            }

            TEXTURE2D(_BlitTexture);
            SAMPLER(sampler_BlitTexture);

            TEXTURE2D(_WaterLineMask);
            SAMPLER(sampler_WaterLineMask);

            float4 _WaterLineColor;

            float _Intensity;
            float _Thickness;
            float _Softness;
            float _VerticalBlur;
            float _HighlightThickness;

            float _RefractionStrength;
            float _HighlightIntensity;

            float SampleWaterMask(float2 uv)
            {
                return SAMPLE_TEXTURE2D(_WaterLineMask, sampler_WaterLineMask, uv).r;
            }

            float3 SampleSceneBlur(float2 uv, float blurRadius)
            {
                float3 blurred = 0.0;

                blurred += SAMPLE_TEXTURE2D(_BlitTexture, sampler_BlitTexture, uv).rgb * 0.227027;
                blurred += SAMPLE_TEXTURE2D(_BlitTexture, sampler_BlitTexture, uv + float2(0, blurRadius * 1.384615)).rgb * 0.316216;
                blurred += SAMPLE_TEXTURE2D(_BlitTexture, sampler_BlitTexture, uv - float2(0, blurRadius * 1.384615)).rgb * 0.316216;
                blurred += SAMPLE_TEXTURE2D(_BlitTexture, sampler_BlitTexture, uv + float2(0, blurRadius * 3.230769)).rgb * 0.070270;
                blurred += SAMPLE_TEXTURE2D(_BlitTexture, sampler_BlitTexture, uv - float2(0, blurRadius * 3.230769)).rgb * 0.070270;

                return blurred;
            }

            float Noise(float2 value)
            {
                value = frac(value * float2(123.34, 456.21));
                value += dot(value, value + 45.32);

                return frac(value.x * value.y);
            }

            half4 Frag(Varyings input) : SV_Target
            {
                float2 uv = input.uv;

                float pixelUV = 1.0 / max(1.0, _ScreenParams.y);
                float maskDistance = max(1.0, _Thickness) * pixelUV;
                float maskAtSurface = SampleWaterMask(uv);
                float maskAbove = SampleWaterMask(uv + float2(0, maskDistance));
                float signedEdge = maskAbove - maskAtSurface;
                float edgeMask = smoothstep(0.001, max(0.01, _Softness), abs(signedEdge));

                float highlightDistance = max(1.0, _HighlightThickness) * pixelUV;
                float highlightAtSurface = SampleWaterMask(uv);
                float highlightAbove = SampleWaterMask(uv + float2(0, highlightDistance));
                float topEdgeDifference = highlightAbove - highlightAtSurface;
                float topEdgeMask = smoothstep(0.001, max(0.01, _Softness), abs(topEdgeDifference));

                float3 originalScene = SAMPLE_TEXTURE2D(_BlitTexture, sampler_BlitTexture, uv).rgb;
                float blurRadius = max(0.0, _VerticalBlur) * pixelUV;
                float3 blurredScene = SampleSceneBlur(uv, blurRadius);

                float waveNoise = Noise(floor(uv * float2(18.0, 5.0)));
                waveNoise = lerp(0.75, 1.25, smoothstep(0.2, 0.8, waveNoise));
                float refractionOffset = signedEdge * _RefractionStrength * pixelUV * waveNoise;
                float2 refractedUV = saturate(uv + float2(0.0, refractionOffset));
                float3 refractedBlurredScene = SampleSceneBlur(refractedUV, blurRadius);

                float blend = saturate(edgeMask * _Intensity);
                float3 blurredRefraction = lerp(blurredScene, refractedBlurredScene, edgeMask);
                blurredRefraction *= _WaterLineColor.rgb;
                float3 finalColor = lerp(originalScene, blurredRefraction, blend);

                float sourceLuminance = dot(originalScene, float3(0.2126, 0.7152, 0.0722));
                float fineNoise = Noise(floor(uv * float2(48.0, 9.0)));
                float broadNoise = Noise(floor(uv * float2(12.0, 3.0)));
                float choppyNoise = smoothstep(0.35, 0.7, fineNoise * 0.65 + broadNoise * 0.35);
                float highlight = topEdgeMask * choppyNoise * _HighlightIntensity * lerp(0.35, 1.0, saturate(sourceLuminance));
                finalColor += highlight.xxx;

                return float4(finalColor, 1);
            }

            ENDHLSL
        }
    }
}