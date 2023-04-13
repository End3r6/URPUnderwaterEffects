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

            sampler2D _MainTex;

            int steps;
            real width;
            real threshold;

            #define BLUR_DEPTH_FALLOFF 100.0
            static const real gauss_filter_weights[] = { 0.14446445, 0.13543542, 0.11153505, 0.08055309, 0.05087564, 0.02798160, 0.01332457, 0.00545096 } ;


            real3 frag (v2f i) : SV_Target
            {
                real col = 0;
                real accumResult = 0;
                real accumWeights = 0;
                
                if(width > 0)
                {
                    for(real index = -steps; index <= steps; index ++)
                    {
                        real2 uv = i.uv + real2 (0, index * width / 1000);
                        real kernelSample = SAMPLE_TEXTURE2D(_HorizonLineTexture, sampler_HorizonLineTexture, uv).r;
                        real depthKernel;
                        real depthCenter;

                        #if UNITY_REVERSED_Z
                            depthCenter = SampleSceneDepth(i.uv);
                            depthKernel = SampleSceneDepth(uv);
                        #else
                            // Adjust z to match NDC for OpenGL
                            depthCenter = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(i.uv));
                            depthKernel = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(uv));
                        #endif
                        
                        real depthDiff = abs(depthKernel - depthCenter);
                        real r2 = depthDiff*BLUR_DEPTH_FALLOFF;
                        real g = exp(-r2 * r2);
                        real weight = g * gauss_filter_weights[abs(index)];

                        accumResult += weight * kernelSample;
                        accumWeights += weight;
                    }

                    col = accumResult / accumWeights;

                    if(col > threshold)
                    {
                        col = 0;
                    }
                }
                else
                {
                    col = SAMPLE_TEXTURE2D(_HorizonLineTexture, sampler_HorizonLineTexture, i.uv).r;
                }

                return col;
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

            TEXTURE2D(_HardWaterLineMask);
            SAMPLER(sampler_HardWaterLineMask);
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformWorldToHClip(v.vertex.xyz);
                o.uv = v.uv;

                return o;
            }

            sampler2D _MainTex;

            int steps;
            real width;
            real threshold;

            #define BLUR_DEPTH_FALLOFF 100.0
            static const real gauss_filter_weights[] = { 0.14446445, 0.13543542, 0.11153505, 0.08055309, 0.05087564, 0.02798160, 0.01332457, 0.00545096 } ;


            real3 frag (v2f i) : SV_Target
            {
                real col = 0;
                real accumResult = 0;
                real accumWeights = 0;
                
                if(width > 0)
                {
                    for(real index = -steps; index <= steps; index ++)
                    {
                        real2 uv = i.uv + real2 (0, index * width / 1000);
                        real kernelSample = SAMPLE_TEXTURE2D(_HardWaterLineMask, sampler_HardWaterLineMask, uv).r;
                        real depthKernel;
                        real depthCenter;

                        #if UNITY_REVERSED_Z
                            depthCenter = SampleSceneDepth(i.uv);
                            depthKernel = SampleSceneDepth(uv);
                        #else
                            // Adjust z to match NDC for OpenGL
                            depthCenter = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(i.uv));
                            depthKernel = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(uv));
                        #endif
                        
                        real depthDiff = abs(depthKernel - depthCenter);
                        real r2 = depthDiff*BLUR_DEPTH_FALLOFF;
                        real g = exp(-r2 * r2);
                        real weight = g * gauss_filter_weights[abs(index)];

                        accumResult += weight * kernelSample;
                        accumWeights += weight;
                    }

                    col = accumResult / accumWeights;

                    if(col > threshold)
                    {
                        col = 0;
                    }
                }
                else
                {
                    col = SAMPLE_TEXTURE2D(_HardWaterLineMask, sampler_HardWaterLineMask, i.uv).r;
                }

                return col;
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

            TEXTURE2D(_SoftWaterLineMask);
            SAMPLER(sampler_SoftWaterLineMask);

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

                float waterLineMask = SAMPLE_TEXTURE2D(_SoftWaterLineMask, sampler_SoftWaterLineMask, i.uv).r;

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

                float3 finalColor =  lerp(col, waterLineTint * skyColor, waterLine * intensity);

                return finalColor;
            }
            ENDHLSL
        }
    }
}
