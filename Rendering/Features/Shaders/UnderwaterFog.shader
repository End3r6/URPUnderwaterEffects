Shader "Hidden/UnderwaterFog"
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
            Blend SrcAlpha OneMinusSrcAlpha

            Tags
            {
                "Queue" = "Transparent" 
                "RenderType" = "Transparent" 
                "RenderPipeline" = "UniversalRenderPipeline"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
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

            float _Vision;

            half4 _FogColor;

            sampler2D _MainTex;

            TEXTURE2D(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);

            TEXTURE2D(_HorizonLineTexture);
            SAMPLER(sampler_HorizonLineTexture);

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformWorldToHClip(v.vertex.xyz);
                o.uv = v.uv;

                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float3 col = tex2D(_MainTex, i.uv);

                float waterLineMask = SAMPLE_TEXTURE2D(_HorizonLineTexture, sampler_HorizonLineTexture, i.uv).r;

                float waterMask = waterLineMask;
                
                float depthMask = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv).r;

                float depth = saturate(LinearEyeDepth(depthMask, _ZBufferParams.y) * _Vision / 10);

                float3 aboveWater = col * waterMask;

                float3 color = _FogColor.rgb * (1 - waterMask);

                float3 finalColor = lerp(color, _FogColor * 0.3, 1 - depth) + aboveWater;

                return float4(finalColor, depth);

                // return waterLineMask;
            }
            ENDHLSL
        }
    }
}
