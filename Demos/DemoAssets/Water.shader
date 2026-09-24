Shader "Custom/Water/BasicProceduralWater"
{
    Properties
    {
        [Header(Colors)]
        _ShallowColor("Shallow Color", Color) = (0.25,0.8,1,1)
        _DeepColor("Deep Color", Color) = (0,0.15,0.35,1)
        _FoamColor("Foam Color", Color) = (1,1,1,1)

        [Header(Waves)]
        _WaveScale("Wave Scale", Float) = 2
        _WaveSpeed("Wave Speed", Float) = 1
        _WaveHeight("Wave Height", Float) = 0.25

        [Header(Foam)]
        _FoamScale("Foam Scale", Float) = 8
        _FoamSpeed("Foam Speed", Float) = 0.5
        _FoamThreshold("Foam Threshold", Range(0,1)) = 0.7

        [Header(Transparency)]
        _Alpha("Alpha", Range(0,1)) = 0.8
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }

        Pass
        {
            Name "Forward"
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Back

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #include "Assets/URPUnderwaterEffects/Rendering/Features/Shaders/HLSL/Noise.hlsl"

            CBUFFER_START(UnityPerMaterial)

            float4 _ShallowColor;
            float4 _DeepColor;
            float4 _FoamColor;

            float _WaveScale;
            float _WaveSpeed;
            float _WaveHeight;

            float _FoamScale;
            float _FoamSpeed;
            float _FoamThreshold;

            float _Alpha;

            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float waveNoise : TEXCOORD1;
            };

            Varyings Vert(Attributes IN)
            {
                Varyings OUT;

                float3 pos = IN.positionOS.xyz;

                float2 waveUV =
                    pos.xz +
                    _Time.y * _WaveSpeed;

                float wave =
                    GradientNoise(
                        waveUV,
                        _WaveScale);

                wave = wave * 2.0 - 1.0;

                pos.y += wave * _WaveHeight;

                VertexPositionInputs v =
                    GetVertexPositionInputs(pos);

                OUT.positionCS = v.positionCS;
                OUT.worldPos = v.positionWS;
                OUT.waveNoise = wave * 0.5 + 0.5;

                return OUT;
            }

            half4 Frag(Varyings IN) : SV_Target
            {
                float waterDepth =
                    saturate(IN.waveNoise);

                float3 color =
                    lerp(
                        _DeepColor.rgb,
                        _ShallowColor.rgb,
                        waterDepth);

                float2 foamUV =
                    IN.worldPos.xz +
                    (_Time.y * _FoamSpeed);

                float2 voronoi =
                    VoronoiNoise(
                        foamUV,
                        3.14159,
                        _FoamScale);

                float foam =
                    1.0 -
                    smoothstep(
                        _FoamThreshold,
                        _FoamThreshold + 0.15,
                        voronoi.x);

                color =
                    lerp(
                        color,
                        _FoamColor.rgb,
                        foam);

                return float4(
                    color,
                    _Alpha);
            }

            ENDHLSL
        }
    }
}