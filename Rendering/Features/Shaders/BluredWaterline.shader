Shader "Hidden/BluredWaterline"
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
            // Blend SrcAlpha OneMinusSrcAlpha

            // Tags
            // {
            //     "Queue" = "Transparent" 
            //     "RenderType" = "Transparent" 
            //     "RenderPipeline" = "UniversalRenderPipeline"
            // }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #include "./Hlsl/Blur.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;

                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;

                float2 uv : TEXCOORD0;
                // float2 uv2 : TEXCOORD1;
            };
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformWorldToHClip(v.vertex.xyz);
                o.uv = v.uv;
                
                // o.uv = v.u;
                // o.uv = 1 - v.v;

                return o;
            }

            sampler2D _HorizonLineTexture;
            // sampler2D _InvHorizonLineTexture;

            float4 _HorizonLineTexture_ST;
            // float4 _InvHorizonLineTexture_ST;

            float4 _HorizonLineTexture_TexelSize;
            // float4 _InvHorizonLineTexture_TexelSize;

            real width;
            real height;
            real threshold;

            real3 frag (v2f i) : SV_Target
            {
                float4 col = kawaseBlur(_HorizonLineTexture, i.uv, 5, height, _HorizonLineTexture_TexelSize.xy);
                // float4 col2 = kawaseBlur(_InvHorizonLineTexture, i.uv, 5, height, _InvHorizonLineTexture_TexelSize.xy);

                // if(col.r > threshold)
                // {
                //     col.rgb = float3(0, 0, 0);
                // }

                // if(col2.r > threshold)
                // {
                //     col2.rgb = float3(0, 0, 0);
                // }

                return col /* + col2 */;
            }
            ENDHLSL
        }

        Pass
        {
            // Blend SrcAlpha OneMinusSrcAlpha

            // Tags
            // {
            //     "Queue" = "Transparent" 
            //     "RenderType" = "Transparent" 
            //     "RenderPipeline" = "UniversalRenderPipeline"
            // }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #include "./Hlsl/Blur.hlsl"

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

            sampler2D _MainTex;

            TEXTURE2D(_BlurredWaterLine);
            SAMPLER(sampler_BlurredWaterLine);

            float4 waterLineTint;
            float minBlur, maxBlur, intensity;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformWorldToHClip(v.vertex.xyz);
                o.uv = v.uv;

                return o;
            }

            float3 frag (v2f i) : SV_Target
            {
                half3 skyColor = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);

                float3 col = tex2D(_MainTex, i.uv);

                float waterLineMask = SAMPLE_TEXTURE2D(_BlurredWaterLine, sampler_BlurredWaterLine, i.uv).r;

                float invertedMask = 0;
                if(waterLineMask > 0.3)
                {
                    invertedMask = 1 - waterLineMask;
                }
                else
                {
                    invertedMask = waterLineMask;
                }

                float3 waterLine = smoothstep(minBlur, maxBlur, invertedMask);

                float3 finalColor = lerp(col, waterLineTint * skyColor, waterLine * intensity);

                return waterLineMask;
            }
            ENDHLSL
        }
    }
}
