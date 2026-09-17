Shader "Hidden/UnderwaterSunShafts"
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
            HLSLPROGRAM

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _  _MAIN_LIGHT_SHADOWS_CASCADE
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            //Boilerplate code, we aren't doind anything with our vertices or any other input info,
            // because technically we are working on a quad taking up the whole screen
            struct Attributes
            {
                uint vertexID : SV_VertexID;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings vert(Attributes input)
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

            sampler2D _MainTex;

            TEXTURE2D(_NoiseTex);
            SAMPLER(sampler_NoiseTex);

            TEXTURE2D(_WaterLineMask);
            SAMPLER(sampler_WaterLineMask);

            TEXTURE2D(_BlueNoise);
            SAMPLER(sampler_BlueNoise);

            //I set up these uniforms from the ScriptableRendererFeature
            real _Scattering;
            real3 _SunDirection;
            real _Steps;
            real _JitterVolumetric;
            real _MaxDistance;
            real _Threshold;
            real _Scale;
            real _Speed;

            real WaveAten(real3 worldPosition)
            {
                Light mainLight =
                GetMainLight();

                float3 lightDir = normalize(mainLight.direction);

                float2 uv1 = (cross(worldPosition, lightDir).xy + _Time.y * _Speed)/ _Scale;

                float2 uv2 = (cross(worldPosition, lightDir).xy - _Time.y * _Speed) / _Scale;

                real noiseA = SAMPLE_TEXTURE2D_LOD(_NoiseTex, sampler_NoiseTex, uv1, 0).r;

                real noiseB = SAMPLE_TEXTURE2D_LOD(_NoiseTex, sampler_NoiseTex, uv2, 0).r;

                return min(noiseA, noiseB);
            }

            //Unity already has a function that can reconstruct world space position from depth
            real3 GetWorldPos(real2 uv)
            {
                #if UNITY_REVERSED_Z
                    real depth = SampleSceneDepth(uv);
                #else
                    // Adjust z to match NDC for OpenGL
                    real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(uv));
                #endif
                return ComputeWorldSpacePosition(uv, depth, UNITY_MATRIX_I_VP);
            }

            // Mie scaterring approximated with Henyey-Greenstein phase function.
            real ComputeScattering(real lightDotView)
            {
                real result = 1.0f - _Scattering * _Scattering;
                result /= (4.0f * PI * pow(1.0f + _Scattering * _Scattering - (2.0f * _Scattering) * lightDotView, 1.5f));
                return result;
            }

            //standart hash
            real random( real2 p )
            {
                return frac(sin(dot(p, real2(41, 289)))*45758.5453 )-0.5; 
            }

            real random01( real2 p )
            {
                return frac(sin(dot(p, real2(41, 289)))*45758.5453 ); 
            }
            
            //from Ronja https://www.ronja-tutorials.com/post/047-invlerp_remap/
            real invLerp(real from, real to, real value)
            {
                return (value - from) / (to - from);
            }

            real remap(real origFrom, real origTo, real targetFrom, real targetTo, real value)
            {
                real rel = invLerp(origFrom, origTo, value);
                return lerp(targetFrom, targetTo, rel);
            }

            //this implementation is loosely based on http://www.alexandre-pestana.com/volumetric-lights/ and https://fr.slideshare.net/BenjaminGlatzel/volumetric-lighting-for-many-lights-in-lords-of-the-fallen

            // #define MIN_STEPS 25

            half4 frag(Varyings i) : SV_Target
            {
                real waterLineMask = SAMPLE_TEXTURE2D(_WaterLineMask, sampler_WaterLineMask, i.uv).r;
                if (waterLineMask > .99)
                {
                    return 0;
                }

                //first we get the world space position of every pixel on screen
                real3 worldPos = GetWorldPos(i.uv);

                //we find out our ray info, that depends on the distance to the camera
                real3 startPosition = _WorldSpaceCameraPos;
                real3 rayVector = worldPos - startPosition;
                real3 rayDirection =  normalize(rayVector);
                real rayLength = length(rayVector);
                if(rayLength < 0.01)
                {
                    return 0;
                }

                rayLength = min(rayLength, _MaxDistance);
                worldPos = startPosition + rayDirection * rayLength;

                if(rayLength > _MaxDistance)
                {
                    rayLength = _MaxDistance;
                }

                real stepLength = rayLength / _Steps;
                real3 stepVector = rayDirection * stepLength;
                
                float2 noiseUV = frac((i.uv * _ScreenParams.xy + float2(_Time.y, _Time.y * 1.37)) / 256.0);
                float noise = SAMPLE_TEXTURE2D(_BlueNoise, sampler_BlueNoise, noiseUV).r;

                real rayStartOffset = noise * stepLength *_JitterVolumetric / 100;
                real3 currentPosition = startPosition + rayStartOffset * rayDirection;

                Light mainLight = GetMainLight();

                float3 sunDir =
                normalize(mainLight.direction);

                real accumFog = 0;
                real kernelColor = ComputeScattering(dot(rayDirection, -sunDir));

                //we ask for the shadow map value at different depths, if the sample is in light we compute the contribution at that point and add it
                for (real j = 0; j < _Steps - 1; j++)
                {
                    real shadowMapValue = WaveAten(currentPosition);
                    
                    //if it is in light
                    accumFog += step(_Threshold, shadowMapValue) * kernelColor;

                    currentPosition += stepVector;
                }

                //we need the average value, so we divide between the amount of samples 
                accumFog /= _Steps;
                accumFog *= (1 - waterLineMask);
                
                return accumFog;
            }
            ENDHLSL
        }

        Pass
        {
            Name "Gaussian Blur x"

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


            struct Attributes
            {
                uint vertexID : SV_VertexID;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings vert(Attributes input)
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

            TEXTURE2D(_BlitTexture);
            SAMPLER(sampler_BlitTexture);   
            int _GaussSamples;
            real _GaussAmount;
            //bilateral blur from 
            static const real gauss_filter_weights[] = { 0.14446445, 0.13543542, 0.11153505, 0.08055309, 0.05087564, 0.02798160, 0.01332457, 0.00545096} ;         
            #define BLUR_DEPTH_FALLOFF 100.0

            half4 frag(Varyings i) : SV_Target
            {
                real col =0;
                real accumResult =0;
                real accumWeights=0;
                //depth at the current pixel
                real depthCenter;  
                #if UNITY_REVERSED_Z
                    depthCenter = SampleSceneDepth(i.uv);  
                #else
                    // Adjust z to match NDC for OpenGL
                    depthCenter = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(i.uv));
                #endif

                for(real index=-_GaussSamples;index<=_GaussSamples;index++){
                    //we offset our uvs by a tiny amount 
                    real2 uv= i.uv+real2(  index*_GaussAmount/1000,0);
                    //sample the color at that location
                    real kernelSample = SAMPLE_TEXTURE2D(_BlitTexture, sampler_BlitTexture, uv);

                    //depth at the sampled pixel
                    real depthKernel;
                    #if UNITY_REVERSED_Z
                        depthKernel = SampleSceneDepth(uv);
                    #else
                        // Adjust z to match NDC for OpenGL
                        depthKernel = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(uv));
                    #endif
                    //weight calculation depending on distance and depth difference
                    real depthDiff = abs(depthKernel-depthCenter);
                    real r2= depthDiff*BLUR_DEPTH_FALLOFF;
                    real g = exp(-r2*r2);
                    real weight = g * gauss_filter_weights[abs(index)];
                    //sum for every iteration of the color and weight of this sample 
                    accumResult+=weight*kernelSample;
                    accumWeights+=weight;
                }
                //final color
                col= accumResult/accumWeights;

                return col;
            }
            ENDHLSL
        }

        Pass
        {
            Name "Gaussian Blur y"

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


            struct Attributes
            {
                uint vertexID : SV_VertexID;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings vert(Attributes input)
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

            TEXTURE2D(_BlitTexture);
            SAMPLER(sampler_BlitTexture);
            int _GaussSamples;
            real _GaussAmount;
            #define BLUR_DEPTH_FALLOFF 100.0
            static const real gauss_filter_weights[] = { 0.14446445, 0.13543542, 0.11153505, 0.08055309, 0.05087564, 0.02798160, 0.01332457, 0.00545096 } ;


            half4 frag(Varyings i) : SV_Target
            {
                real col = 0;
                real accumResult = 0;
                real accumWeights = 0;
                
                if(_GaussAmount > 0){
                    for(real index = -_GaussSamples; index <= _GaussSamples; index ++){
                        real2 uv = i.uv + real2 (0, index * _GaussAmount / 1000);
                        real kernelSample = SAMPLE_TEXTURE2D(_BlitTexture, sampler_BlitTexture, uv);

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
                    
                }
                else{
                    col = SAMPLE_TEXTURE2D(_BlitTexture, sampler_BlitTexture, i.uv);
                }

                return col;
            }
            ENDHLSL
        }

        Pass
        {
            Blend One One

            Name "Compositing"

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                uint vertexID : SV_VertexID;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings vert(
            Attributes input)
            {
                Varyings output;

                output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);

                output.uv = GetFullScreenTriangleTexCoord(input.vertexID);

                return output;
            }

            TEXTURE2D(_BlitTexture);
            SAMPLER(sampler_BlitTexture);
            TEXTURE2D(_SourceTexture);
            SAMPLER(sampler_SourceTexture);

            float4 _Tint;
            float _Intensity;

            half4 frag(Varyings input) : SV_Target
            {
                float shafts = SAMPLE_TEXTURE2D(_BlitTexture, sampler_BlitTexture, input.uv).r;

                float3 shaftColor = shafts * _Tint.rgb * _Intensity;

                return float4(shaftColor, 1);
            }

            ENDHLSL
        }

        Pass
        {
            Name "SampleDepth"

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                uint vertexID : SV_VertexID;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings vert(Attributes input)
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

            real frag (Varyings i) : SV_Target
            {
                #if UNITY_REVERSED_Z
                    real depth = SampleSceneDepth(i.uv);
                #else
                    // Adjust z to match NDC for OpenGL
                    real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(i.uv));
                #endif
                return float4(depth, depth, depth, 1);

            }
            ENDHLSL
        }
    }
}
