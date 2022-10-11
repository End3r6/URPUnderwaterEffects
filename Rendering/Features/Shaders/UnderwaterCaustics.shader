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
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

            #include "./HLSL/Noise.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;

                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;

                float2 uv : TEXCOORD0;

                float4 screenPos : TEXCOORD1;
            };

            float4x4 _CamToWorld;
            float angleOffset, cellDensity, width, speed, RGBSplit, intensity;

            sampler2D _MainTex;

            TEXTURE2D(_CameraDepthNormalsTexture);
            SAMPLER(sampler_CameraDepthNormalsTexture);

            TEXTURE2D(_HorizonLineTexture);
            SAMPLER(sampler_HorizonLineTexture);

            TEXTURE2D(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);

            inline float DecodeFloatRG( float2 enc )
            {
                float2 kDecodeDot = float2(1.0, 1/255.0);
                return dot( enc, kDecodeDot );
            }

            inline float3 DecodeViewNormalStereo( float4 enc4 )
            {
                float kScale = 1.7777;
                float3 nn = enc4.xyz*float3(2*kScale,2*kScale,0) + float3(-kScale,-kScale,1);
                float g = 2.0 / dot(nn.xyz,nn.xyz);
                float3 n;
                n.xy = g*nn.xy;
                n.z = g-1;
                return n;
            }

            inline void DecodeDepthNormal( float4 enc, out float depth, out float3 normal )
            {
                depth = DecodeFloatRG (enc.zw);
                normal = DecodeViewNormalStereo (enc);
            }

            real3 GetWorldPos(real2 uv)
            {
                #if UNITY_REVERSED_Z
                    real depth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, uv).r;
                #else
                    // Adjust z to match NDC for OpenGL
                    real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, uv));
                #endif
                return ComputeWorldSpacePosition(uv, depth, UNITY_MATRIX_I_VP);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformWorldToHClip(v.vertex.xyz);
                o.uv = v.uv;

                o.screenPos = ComputeScreenPos(o.vertex);

                return o;
            }

            float3 frag (v2f i) : SV_Target
            {
                float3 col = tex2D(_MainTex, i.uv);

                float waterLineMask = SAMPLE_TEXTURE2D(_HorizonLineTexture, sampler_HorizonLineTexture, i.uv).r;
                // float4 depthNormals = SAMPLE_TEXTURE2D(_CameraDepthNormalsTexture, sampler_CameraDepthNormalsTexture, i.uv);

                // float depthMask = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv).r;
                // float depth = LinearEyeDepth(depthMask, _ZBufferParams.y);

                float3 normal;
                float depth;

                DecodeDepthNormal(
                    SAMPLE_TEXTURE2D(_CameraDepthNormalsTexture, sampler_CameraDepthNormalsTexture, i.uv),
                    depth,
                    normal
                );

                normal = mul( (float3x3)_CamToWorld, normal);
                

                float3 aboveWater = col * waterLineMask;

                //Generates a voronoi noise that is split on th R and G.
                float3 causticsNoise = float3
                (
                    pow(VoronoiNoise((i.uv + (RGBSplit / 100)), angleOffset + (_Time * speed), cellDensity).x, width),
                    pow(VoronoiNoise((i.uv), angleOffset + (_Time * speed), cellDensity).x, width),
                    pow(VoronoiNoise((i.uv - (RGBSplit / 100)), angleOffset + (_Time * speed), cellDensity).x, width)
                );

                //the final caustics mapped to the main color and waterline texture.
                float3 caustics = ((causticsNoise * depth * intensity) + col) * (1 - waterLineMask);

                //final combination
                return aboveWater + caustics;
            }
            ENDHLSL
        }
    }
}
