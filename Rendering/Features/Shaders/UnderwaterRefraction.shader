Shader "Hidden/UnderwaterRefraction"
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
            };

            float scale, intensity, speed;

            sampler2D _MainTex;

            TEXTURE2D(_HorizonLineTexture);
            SAMPLER(sampler_HorizonLineTexture);

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
                o.vertex = TransformWorldToHClip(v.vertex.xyz);
                o.uv = v.uv;

                return o;
            }

            float3 frag (v2f i) : SV_Target
            {
                float3 col = tex2D(_MainTex, i.uv);

                float waterLineMask = SAMPLE_TEXTURE2D(_HorizonLineTexture, sampler_HorizonLineTexture, i.uv).r;
                float2 noise = NormalFromHeight(GradientNoise(i.uv + (_Time.y * (speed / 100)), scale), intensity);

                float3 refColor = tex2D(_MainTex, i.uv + noise) * (1 - waterLineMask);

                float3 aboveWater = col * waterLineMask;

                float3 finalColor = refColor + aboveWater;

                return finalColor;
            }
            ENDHLSL
        }
    }
}
