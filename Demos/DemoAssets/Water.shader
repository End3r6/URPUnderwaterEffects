Shader "WorldsEndWater/Water"
{
    Properties
    {
        _SmallWaves("SmallWaves", 2D) = "white" {}
        _WavesHeight("Waves Height", Float) = 2.0

        [Header(Normal Maps)]
        _NormalWaves("Normal Waves", 2D) = "bump" {}
        _Bump("Bump", Float) = 1
        _BumpSpeed("Bump Speed", Vector) = (0.1, 0.1, -0.05, -0.05)
        
        [Header(Specular)]
        _Smoothness("Specular", Range(0, 1)) = 1
        [HDR]_SpecularTint("Specular Tint", Color) = (1, 1, 1, 1)

        [Header(Color)]
        _ShallowColor("Shallow Color", Color) = (1, 1, 1, 1)
        _DeepColor("Deep Color", Color) = (0, 0, 0, 1)
        _SeaDepth("Depth", Float) = 0.5

        [Header(Refraction)]
        _Refraction("Refraction", Float) = 0.5

        [Header(Caustics)]
        _Caustics("Caustics Texture", 2D) = "white" {}
        _Speed("Speed", Float) = 0.5
        _Tiling("Tiling", Float) = 10 
        _RGBSplit("RGB Split", Float) = 0.5
        _Intensity("Intensity", Float) = 1
    }

    SubShader
    {
        ZWrite On
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 300

        Tags
        {
            "Queue" = "Transparent" 
            "RenderType" = "Transparent" 
            "RenderPipeline" = "UniversalRenderPipeline"
        }

        Pass
        {
            Name "Base"
            Tags { "LightMode" = "UniversalForward"}
            Cull Off

            HLSLPROGRAM

            #pragma target 5.0

            #pragma vertex vert
            #pragma fragment frag
            
            #pragma multi_compile_fog
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _ _SHADOWS_SOFT

            #define _SPECULAR_COLOR

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            #include "Assets/BasicUnderwaterFog/Rendering/Features/Shaders/HLSL/Noise.hlsl"
            #include "Assets/BasicUnderwaterFog/Rendering/Features/Shaders/HLSL/Caustics.hlsl"

            // the original vertex struct
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;

                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;

                float2 uv : TEXCOORD0;

                float3 positionWS : TEXCOORD1;

                float4 screenPos : TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _NormalWaves_ST;
                half4 _ShallowColor;
                half4 _DeepColor;
                half4 _SpecularTint;
            CBUFFER_END

            TEXTURE2D(_CameraOpaqueTexture);
            SAMPLER(sampler_CameraOpaqueTexture);

            sampler2D _NormalWaves;
            sampler2D _SmallWaves;

            float4 _MainWave, _SmallWave, _MediumMaves;

            float _Smoothness, _Bump, _SeaDepth, _WavesHeight, _Refraction;
            float4 _BumpSpeed;

            half4x4 _MainLightDirection;
            float _Tiling, _Speed, _RGBSplit, _Intensity;

            void InitializeFragmentNormal(inout v2f i, inout float4 normals) 
            {
                float4 normalMap = tex2D(_NormalWaves, float2(i.uv.x + (_Time.x * _BumpSpeed.x), i.uv.y + (_Time.y * _BumpSpeed.y))) * tex2D(_NormalWaves, float2(i.uv.x + (_Time.x * _BumpSpeed.z), i.uv.y + (_Time.y * _BumpSpeed.w)));
                i.normal.xy = normalMap.wy * 2 - 1;
                i.normal.z = sqrt(1 - saturate(dot(i.normal.xy, i.normal.xy)));

                i.normal.xy *= _Bump;

                i.normal = i.normal.xzy;

                i.normal = normalize(i.normal);
                normals = normalMap;
            }

            float3 NormalFromHeight(float In, float bumpScale)
            {
                float3 normal;

                normal.x = ddx(In);
                normal.y = ddy(In);
                normal.z = sqrt(1 - normal.x * normal.x - normal.y * normal.y); // Reconstruct z component to get a unit normal.

                return normal * float3(bumpScale, bumpScale, 1);
            }

            v2f vert (appdata v)
            {
                v2f o;

                // float waves = tex2Dlod(_SmallWaves, float4(v.uv, 1, 1)) * _WavesHeight;
                VertexPositionInputs posnInputs = GetVertexPositionInputs(v.vertex);
                VertexNormalInputs normInputs = GetVertexNormalInputs(v.normal);

                //Output
                o.screenPos = ComputeScreenPos(posnInputs.positionCS);
            
                o.vertex =  posnInputs.positionCS;

                o.positionWS = posnInputs.positionWS;

                o.normal = normInputs.normalWS;

                o.uv = TRANSFORM_TEX(v.uv, _NormalWaves);

                return o;
            }

            float4 frag(v2f i) : SV_TARGET
            {                
                float4 normalMap;
                InitializeFragmentNormal(i, normalMap);

                //Screen
                float2 screenUV = (i.screenPos.xy) / i.screenPos.w;

                //Depth
                float depthMask = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV + (i.normal.xy * _Refraction));

                float4 opaqueTexture = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, screenUV + (i.normal.xy * _Refraction));

                float colorDepth = saturate(depthMask * _SeaDepth);

                half4 color = lerp(_DeepColor, _ShallowColor, colorDepth);

                float2 positionNDC = i.vertex.xy / _ScaledScreenParams.xy;

                // sample scene depth using screen-space coordinates
                #if UNITY_REVERSED_Z
                    real depth = SampleSceneDepth(positionNDC);
                #else
                    real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(UV));
                #endif

                float3 positionWS = ComputeWorldSpacePosition(positionNDC, depth, UNITY_MATRIX_I_VP);

                float3 positionOS = TransformWorldToObject(positionWS);

                half2 uv = mul(positionWS, _MainLightDirection).xy;

                half2 uv1 = Panner(uv, _Speed, 1 / _Tiling);
                half2 uv2 = Panner(uv, 1 * _Speed, -1 / _Tiling);

                half4 tex1 = SampleCaustics(uv1, _RGBSplit / 100);
                half4 tex2 = SampleCaustics(uv2, _RGBSplit / 100);

                half4 caustics = min(tex1, tex2) * _Intensity;

                // //Light info
                InputData lightInput = (InputData)0;
                lightInput.normalWS = normalize(i.normal);
                lightInput.positionWS = i.positionWS;

                lightInput.viewDirectionWS = GetWorldSpaceNormalizeViewDir(i.positionWS);
                lightInput.shadowCoord = TransformWorldToShadowCoord(i.positionWS);
                
                SurfaceData surfaceData = (SurfaceData)0;
                surfaceData.albedo = (color.rgb + caustics + (opaqueTexture * 0.2));
                surfaceData.alpha = color.a;

                surfaceData.specular = _SpecularTint;
                surfaceData.smoothness = _Smoothness;

                return UniversalFragmentBlinnPhong(lightInput, surfaceData);
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ColorMask 0

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _GLOSSINESS_FROM_BASE_ALPHA

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            // -------------------------------------
            // Universal Pipeline keywords

            // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/Shaders/SimpleLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }
    }
}