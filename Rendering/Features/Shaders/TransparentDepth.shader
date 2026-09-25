Shader "Hidden/TransparentDepth"
{
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            Name "TransparentDepth"

            Cull Off

            ZWrite On
            ZTest LEqual

            Blend Off

            HLSLPROGRAM

            #pragma target 4.5

            #pragma vertex Vert
            #pragma fragment Frag

            #pragma multi_compile_instancing

            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float eyeDepth : TEXCOORD0;
            };

            // UNITY_INSTANCING_BUFFER_START(Props)

            //     UNITY_DEFINE_INSTANCED_PROP(
            //         float,
            //         _Thickness)

            //     UNITY_DEFINE_INSTANCED_PROP(
            //         float,
            //         _TransparentObjectTransmittance)

            // UNITY_INSTANCING_BUFFER_END(Props)

            float _Thickness;
            float _TransparentObjectTransmittance;

            Varyings Vert(Attributes input)
            {
                UNITY_SETUP_INSTANCE_ID(input);

                Varyings output;

                VertexPositionInputs vertex = GetVertexPositionInputs(input.positionOS.xyz);

                output.positionCS = vertex.positionCS;

                output.eyeDepth = -vertex.positionVS.z;

                return output;
            }

            float4 Frag(Varyings input) : SV_Target
            {
                float thickness =
                    UNITY_ACCESS_INSTANCED_PROP(
                        Props,
                        _Thickness);

                float opacity =
                    UNITY_ACCESS_INSTANCED_PROP(
                        Props,
                        _TransparentObjectTransmittance);

                return float4(
                    input.eyeDepth,
                    _Thickness,
                    _TransparentObjectTransmittance,
                    0);
            }

            ENDHLSL
        }
    }
}