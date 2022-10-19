Shader "Hidden/UnderwaterCaustics"
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
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            #include "Assets/BasicUnderwaterFog/Rendering/Features/Shaders/HLSL/Caustics.hlsl"

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

            float tiling, speed, RGBSplit, intensity, range;

            sampler2D _MainTex;

            half4x4 _MainLightDirection;

            TEXTURE2D(_CameraDepthNormalsTexture);
            SAMPLER(sampler_CameraDepthNormalsTexture);

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
                half3 skyColor = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
                float2 positionNDC = i.vertex.xy / _ScaledScreenParams.xy;

                // sample scene depth using screen-space coordinates
                #if UNITY_REVERSED_Z
                real depth = SampleSceneDepth(positionNDC);
                #else
                    real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(UV));
                #endif

                float3 positionWS = ComputeWorldSpacePosition(positionNDC, depth, UNITY_MATRIX_I_VP);

                float3 positionOS = TransformWorldToObject(positionWS);

                float distance = 1 - SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv).r * 100;
                float waterLineMask = SAMPLE_TEXTURE2D(_HorizonLineTexture, sampler_HorizonLineTexture, i.uv).r;
                
                half4 caustics = 0;
                if((distance < range))
                {
                    half2 uv = mul(positionWS, _MainLightDirection).xy;

                    half2 uv1 = Panner(uv, speed, 1 / tiling);
                    half2 uv2 = Panner(uv, 1 * speed, -1 / tiling);

                    half4 tex1 = SampleCaustics(uv1, RGBSplit / 100);
                    half4 tex2 = SampleCaustics(uv2, RGBSplit / 100);

                    caustics = min(tex1, tex2) * (1 - waterLineMask) * -intensity * float4(skyColor, 1);
                }

                float4 col = tex2D(_MainTex, i.uv);

                float4 aboveWater = col * waterLineMask;

                //final combination
                return aboveWater + caustics;
            }
            ENDHLSL
        }
    }
}
