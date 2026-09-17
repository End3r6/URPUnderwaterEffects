Shader "Hidden/HorizonLine"
{
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" }

        Cull Off
        ZWrite Off
        ZTest Always

        Pass
        {
            Name "Horizon"

            HLSLPROGRAM

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

            float _HorizonLine;

            TEXTURE2D(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);

            float3 GetWorldPos(float2 uv)
            {
            #if UNITY_REVERSED_Z
                float depth =
                    SAMPLE_TEXTURE2D(
                        _CameraDepthTexture,
                        sampler_CameraDepthTexture,
                        uv).r;
            #else
                float depth =
                    lerp(
                        UNITY_NEAR_CLIP_VALUE,
                        1,
                        SAMPLE_TEXTURE2D(
                            _CameraDepthTexture,
                            sampler_CameraDepthTexture,
                            uv).r);
            #endif

                return ComputeWorldSpacePosition(
                    uv,
                    depth,
                    UNITY_MATRIX_I_VP);
            }

            Varyings Vert(Attributes input)
            {
                Varyings o;

                o.positionCS =
                    GetFullScreenTriangleVertexPosition(
                        input.vertexID);

                o.uv =
                    GetFullScreenTriangleTexCoord(
                        input.vertexID);

                return o;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                float3 worldPos =
                    GetWorldPos(input.uv);

                return
                    worldPos.y <= _HorizonLine
                    ? half4(0,0,0,1)
                    : half4(1,1,1,1);
            }

            ENDHLSL
        }
    }
}