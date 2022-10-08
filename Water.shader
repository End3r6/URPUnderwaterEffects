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

        [Header(Intersection Foam)]
        _InterFoamMap("Intersection Foam Map", 2D) = "black" {}
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

            TEXTURE2D(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);

            TEXTURE2D(_CameraOpaqueTexture);
            SAMPLER(sampler_CameraOpaqueTexture);

            sampler2D _NormalWaves;
            sampler2D _SmallWaves;

            float4 _MainWave, _SmallWave, _MediumMaves;

            float _Smoothness, _Bump, _SeaDepth, _WavesHeight;
            float4 _BumpSpeed;

            void InitializeFragmentNormal(inout v2f i) 
            {
                float4 normalMap = tex2D(_NormalWaves, float2(i.uv.x + (_Time.x * _BumpSpeed.x), i.uv.y + (_Time.y * _BumpSpeed.y))) * tex2D(_NormalWaves, float2(i.uv.x + (_Time.x * _BumpSpeed.z), i.uv.y + (_Time.y * _BumpSpeed.w)));
                i.normal.xy = normalMap.wy * 2 - 1;
                i.normal.z = sqrt(1 - saturate(dot(i.normal.xy, i.normal.xy)));

                i.normal.xy *= _Bump;

                i.normal = i.normal.xzy;

                i.normal = normalize(i.normal);
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
                InitializeFragmentNormal(i);

                //Screen
                float2 screenUV = (i.screenPos.xy) / i.screenPos.w;

                //Depth
                half4 depthMask = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV);

                float3 colorDepth = depthMask * _SeaDepth;
                half4 color = lerp(_DeepColor, _ShallowColor, colorDepth.x * _SeaDepth);

                // //Light info
                InputData lightInput = (InputData)0;
                lightInput.normalWS = normalize(i.normal);
                lightInput.positionWS = i.positionWS;

                lightInput.viewDirectionWS = GetWorldSpaceNormalizeViewDir(i.positionWS);
                lightInput.shadowCoord = TransformWorldToShadowCoord(i.positionWS);
                
                SurfaceData surfaceData = (SurfaceData)0;
                surfaceData.albedo = color.rgb;
                surfaceData.alpha = color.a;

                surfaceData.specular = _SpecularTint;
                surfaceData.smoothness = _Smoothness;

                return UniversalFragmentBlinnPhong(lightInput, surfaceData);

                // return float4(colorDepth, 1);
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