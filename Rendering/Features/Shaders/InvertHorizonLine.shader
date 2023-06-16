Shader "Hidden/InvertWaterLine"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            Name "Invert"

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;

                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;

                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_HorizonLineTexture);
            SAMPLER(sampler_HorizonLineTexture);

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformWorldToHClip(v.vertex.xyz);
                o.uv = v.uv;

                return o;
            }

            float3 frag (v2f i) : SV_Target
            {
                float waterLineMask = SAMPLE_TEXTURE2D(_HorizonLineTexture, sampler_HorizonLineTexture, i.uv).r;
                float3 col = 1 - waterLineMask;

                return col.rrr;
            }
            ENDHLSL
        }
    }
}
